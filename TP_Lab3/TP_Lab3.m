%% Trabajo de Laboratorio Integrador - Sistemas de Control
% TP de Laboratorio 3: Desarrollo de controlador atraso-adelanto
% Autores: Tomás Gómez Pizarro - Mikael Rodríguez
clear; clc; close all;

%% Rutas
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end
fig_dir = fullfile(script_dir, 'figuras');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% Configuración de visualización
% true: abre las ventanas de las figuras; false: segundo plano y guarda PNGs
mostrar_graficos = false;
if mostrar_graficos
    vis_opt = 'on';
else
    vis_opt = 'off';
end
% Figuras con fondo claro (para el informe impreso), independiente del tema de MATLAB
s_cfg = settings;
s_cfg.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'light';
set(groot, 'defaultFigureColor', 'w');

%% =========================================================================
%% MODELO DE LA PLANTA G(s)
%% =========================================================================
R1 = 100e3;  C1 = 0.1e-6;  tau1 = R1 * C1;   % 0.01 s   -> polo en -100 rad/s
R2 = 47e3;   C2 = 0.1e-6;  tau2 = R2 * C2;   % 0.0047 s -> polo en -212.77 rad/s
p1 = 1 / tau1;
p2 = 1 / tau2;

s = tf('s');
G = 1 / ((tau1 * s + 1) * (tau2 * s + 1));

disp('=========================================================================');
disp('=== FUNCIÓN DE TRANSFERENCIA DE LA PLANTA G(s) ===');
disp('=========================================================================');
G

%% =========================================================================
%% PUNTO 1: DISEÑO DEL COMPENSADOR DE ADELANTO
%% =========================================================================

%% 1.a Región del plano s que cumple las especificaciones
PO_max = 5;          % [%]
Ts_max = 0.02;       % [s] (criterio del 2 %)

zeta_min  = -log(PO_max/100) / sqrt(pi^2 + log(PO_max/100)^2);
sigma_min = 4 / Ts_max;

fprintf('\n=== PUNTO 1.a: REGIÓN DEL PLANO s ===\n');
fprintf('zeta mínimo (PO <= %.0f %%):   %.4f\n', PO_max, zeta_min);
fprintf('sigma mínimo (Ts <= %.0f ms): %.1f 1/s\n', Ts_max*1e3, sigma_min);

%% 1.b Punto de diseño s_d (dentro de la región, con margen)
zeta_d  = 0.72;      % PO teórico ~ 3.8 %
sigma_d = 230;       % Ts estimado = 4/230 ~ 17.4 ms
wd_d    = sigma_d * sqrt(1 - zeta_d^2) / zeta_d;
wn_d    = sigma_d / zeta_d;
sd      = -sigma_d + 1j * wd_d;

PO_d = 100 * exp(-pi * zeta_d / sqrt(1 - zeta_d^2));
Ts_d = 4 / sigma_d;

fprintf('\n=== PUNTO 1.b: PUNTO DE DISEÑO s_d ===\n');
fprintf('zeta_d = %.2f, sigma_d = %.0f 1/s\n', zeta_d, sigma_d);
fprintf('s_d = %.1f +/- j%.1f   (wn = %.1f rad/s)\n', real(sd), imag(sd), wn_d);
fprintf('PO teórico: %.2f %%   Ts estimado (4/sigma): %.2f ms\n', PO_d, Ts_d*1e3);

%% 1.c Deficiencia angular en s_d
ang_p1 = rad2deg(angle(sd + p1));
ang_p2 = rad2deg(angle(sd + p2));
ang_G  = -(ang_p1 + ang_p2);
phi    = -180 - ang_G;               % ángulo que debe aportar Gc

fprintf('\n=== PUNTO 1.c: CONDICIÓN DE ÁNGULO EN s_d ===\n');
fprintf('Ángulo del polo en -%.2f:  %.2f°\n', p1, ang_p1);
fprintf('Ángulo del polo en -%.2f: %.2f°\n', p2, ang_p2);
fprintf('Fase de G(s_d):             %.2f°\n', ang_G);
fprintf('Ángulo a aportar por Gc:    %.2f°\n', phi);

%% 1.d Cero del compensador: cancela el polo de la planta en -1/tau2
z_l    = p2;
ang_z  = rad2deg(angle(sd + z_l));
ang_pl = ang_z - phi;                % ángulo que debe tener el polo
p_l    = sigma_d + wd_d / tand(ang_pl);

fprintf('\n=== PUNTO 1.d: CERO Y POLO DEL ADELANTO ===\n');
fprintf('Cero z_l = %.2f 1/s  (aporta %.2f°)\n', z_l, ang_z);
fprintf('Ángulo que debe aportar el polo: %.2f°\n', ang_pl);
fprintf('Polo p_l = %.2f 1/s\n', p_l);

%% 1.e Ganancia Ka por condición de módulo
L0 = (s + z_l) / (s + p_l) * G;      % lazo sin Ka
Ka = 1 / abs(evalfr(L0, sd));

fprintf('\n=== PUNTO 1.e: CONDICIÓN DE MÓDULO ===\n');
fprintf('Ka = %.4f\n', Ka);

Gc = Ka * (s + z_l) / (s + p_l);
disp('Compensador de adelanto Gc(s):');
Gc

T_lead = feedback(Gc * G, 1);
polos_lc = pole(T_lead);
fprintf('Polos de lazo cerrado:\n');
fprintf('   %.2f %+.2fj\n', [real(polos_lc) imag(polos_lc)].');

%% Figura: Lugar de las raíces del sistema compensado
fig1 = figure('Name', 'Punto 1: LGR con compensador de adelanto', 'Position', [100, 100, 720, 520], 'Visible', vis_opt);
rlocus(L0);
hold on;
sgrid(zeta_min, []);
xl = [-700 50];  yl = [-400 400];
plot([-sigma_min -sigma_min], yl, '--', 'Color', [0.2 0.6 0.2], 'LineWidth', 1);
plot(real(sd)*[1 1], imag(sd)*[1 -1], 'kd', 'MarkerFaceColor', [0.9 0.6 0.1], 'MarkerSize', 8);
plot(real(polos_lc), imag(polos_lc), 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
text(real(sd)+10, imag(sd)+25, sprintf('s_d = %.0f \\pm j%.1f', real(sd), imag(sd)));
text(-sigma_min+8, -370, sprintf('\\sigma = %.0f', sigma_min), 'Color', [0.2 0.6 0.2]);
xlim(xl); ylim(yl);
title(sprintf('Lugar de las raíces con adelanto (z_l = %.1f, p_l = %.1f, K_a = %.2f)', z_l, p_l, Ka));
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;
hold off;
saveas(fig1, fullfile(fig_dir, 'punto1_lgr_adelanto.png'));
if ~mostrar_graficos, close(fig1); end

%% =========================================================================
%% PUNTO 2: RESPUESTA AL ESCALÓN CON EL ADELANTO
%% =========================================================================
ess_max = 0.06;
info2  = stepinfo(T_lead, 'SettlingTimeThreshold', 0.02);
Kp2    = dcgain(Gc * G);
y_inf2 = dcgain(T_lead);
ess2   = 1 - y_inf2;
si_no  = {'NO', 'SI'};

fprintf('\n=== PUNTO 2: RESPUESTA AL ESCALÓN (ADELANTO) ===\n');
fprintf('PO  = %.2f %%      (<= %.0f %%)   Cumple: %s\n', info2.Overshoot, PO_max, si_no{(info2.Overshoot <= PO_max)+1});
fprintf('Ts  = %.2f ms     (<= %.0f ms)  Cumple: %s\n', info2.SettlingTime*1e3, Ts_max*1e3, si_no{(info2.SettlingTime <= Ts_max)+1});
fprintf('Kp  = %.3f   y(inf) = %.4f\n', Kp2, y_inf2);
fprintf('ess = %.4f       (<= %.2f)    Cumple: %s\n', ess2, ess_max, si_no{(ess2 <= ess_max)+1});

t2 = linspace(0, 0.04, 2000);
y2 = step(T_lead, t2);
fig2 = figure('Name', 'Punto 2: Escalón con adelanto', 'Position', [100, 100, 720, 440], 'Visible', vis_opt);
plot(t2*1e3, y2, 'b', 'LineWidth', 1.4); hold on;
yline(y_inf2*(1 + PO_max/100), 'r--', 'PO = 5 %');
yline(y_inf2*[0.98 1.02], ':', 'Color', [0.4 0.4 0.4]);
yline(1, 'k-.', 'Referencia');
xline(Ts_max*1e3, '--', 'Color', [0.2 0.6 0.2], 'Label', 'T_s máx');
xline(info2.SettlingTime*1e3, 'k:', 'Label', sprintf('T_s = %.1f ms', info2.SettlingTime*1e3));
ylim([0 1.1]);
title(sprintf('Respuesta al escalón con adelanto (PO = %.2f %%, T_s = %.1f ms, e_{ss} = %.3f)', info2.Overshoot, info2.SettlingTime*1e3, ess2));
xlabel('Tiempo (ms)'); ylabel('Amplitud (V)');
grid on; hold off;
saveas(fig2, fullfile(fig_dir, 'punto2_escalon_adelanto.png'));
if ~mostrar_graficos, close(fig2); end

%% =========================================================================
%% PUNTO 3: DISEÑO DEL COMPENSADOR DE ATRASO
%% =========================================================================

%% 3.a Relación alfa = z_a/p_a
Kp_req    = 1/ess_max - 1;           % e_ss = 1/(1+Kp) <= 0.06
alpha_min = Kp_req / Kp2;
alpha     = 12;                      % margen sobre alpha_min

fprintf('\n=== PUNTO 3.a: RELACIÓN DEL ATRASO ===\n');
fprintf('Kp requerido >= %.2f   Kp con adelanto = %.3f\n', Kp_req, Kp2);
fprintf('alfa mínimo = %.2f   alfa elegido = %d   (Kp = %.2f, ess = %.4f)\n', ...
        alpha_min, alpha, alpha*Kp2, 1/(1 + alpha*Kp2));

%% 3.b Ubicación del cero: regla clásica y barrido
za_list = [sigma_d/10, 40, 60, 70, 80, 85, 90, 95, 110];
fprintf('\n=== PUNTO 3.b: BARRIDO DE z_a (alfa = %d) ===\n', alpha);
fprintf('   z_a     p_a     PO [%%]   Ts [ms]   polo LC más lento\n');
for za_i = za_list
    Gca_i = (s + za_i) / (s + za_i/alpha);
    T_i   = feedback(Gc * Gca_i * G, 1);
    inf_i = stepinfo(T_i, 'SettlingTimeThreshold', 0.02);
    p_i   = pole(T_i);
    fprintf('%7.1f %7.2f %8.2f %9.1f %10.1f\n', za_i, za_i/alpha, inf_i.Overshoot, ...
            inf_i.SettlingTime*1e3, max(real(p_i)));
end

z_a = 85;
p_a = z_a / alpha;
Gca = (s + z_a) / (s + p_a);
fprintf('\nElegido: z_a = %.0f, p_a = %.2f\n', z_a, p_a);
disp('Compensador de atraso Gca(s):');
Gca

%% =========================================================================
%% PUNTO 4: SISTEMA FINAL (ADELANTO + ATRASO)
%% =========================================================================
% Gc ya incluye Ka, así que Gtotal = Ka*Gca*(s+z_l)/(s+p_l) = Gca*Gc
Gtotal = Gca * Gc;
Sys_c  = feedback(Gtotal * G, 1);

disp('Función de transferencia a lazo cerrado Sys_c (zpk, sin la cancelación en -212.77):');
zpk(minreal(Sys_c, 1e-3))
polos_c = pole(Sys_c);
fprintf('Polos de lazo cerrado:\n');
fprintf('   %.2f %+.2fj\n', [real(polos_c) imag(polos_c)].');

info4  = stepinfo(Sys_c, 'SettlingTimeThreshold', 0.02);
Kp4    = dcgain(Gtotal * G);
y_inf4 = dcgain(Sys_c);
ess4   = 1 - y_inf4;

fprintf('\n=== PUNTO 4: RESPUESTA AL ESCALÓN (ADELANTO-ATRASO) ===\n');
fprintf('PO  = %.2f %%      (<= %.0f %%)   Cumple: %s\n', info4.Overshoot, PO_max, si_no{(info4.Overshoot <= PO_max)+1});
fprintf('Ts  = %.2f ms     (<= %.0f ms)  Cumple: %s\n', info4.SettlingTime*1e3, Ts_max*1e3, si_no{(info4.SettlingTime <= Ts_max)+1});
fprintf('Kp  = %.2f   y(inf) = %.4f\n', Kp4, y_inf4);
fprintf('ess = %.4f       (<= %.2f)    Cumple: %s\n', ess4, ess_max, si_no{(ess4 <= ess_max)+1});

y4 = step(Sys_c, t2);
fig4 = figure('Name', 'Punto 4: Escalón con adelanto-atraso', 'Position', [100, 100, 720, 440], 'Visible', vis_opt);
plot(t2*1e3, y4, 'b', 'LineWidth', 1.4); hold on;
yline(y_inf4*(1 + PO_max/100), 'r--', 'PO = 5 %');
yline(y_inf4*[0.98 1.02], ':', 'Color', [0.4 0.4 0.4]);
yline(1, 'k-.', 'Referencia', 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
xline(Ts_max*1e3, '--', 'Color', [0.2 0.6 0.2], 'Label', 'T_s máx');
xline(info4.SettlingTime*1e3, 'k:', 'Label', sprintf('T_s = %.1f ms', info4.SettlingTime*1e3));
ylim([0 1.1]);
title(sprintf('Respuesta al escalón con adelanto-atraso (PO = %.2f %%, T_s = %.1f ms, e_{ss} = %.3f)', info4.Overshoot, info4.SettlingTime*1e3, ess4));
xlabel('Tiempo (ms)'); ylabel('Amplitud (V)');
grid on; hold off;
saveas(fig4, fullfile(fig_dir, 'punto4_escalon_adelanto_atraso.png'));
if ~mostrar_graficos, close(fig4); end

%% =========================================================================
%% PUNTO 5: COMPARACIÓN ADELANTO vs ADELANTO-ATRASO
%% =========================================================================
t5 = linspace(0, 0.06, 3000);
y5_lead = step(T_lead, t5);
y5_ll   = step(Sys_c,  t5);

fprintf('\n=== PUNTO 5: COMPARACIÓN ===\n');
fprintf('                  PO [%%]   Ts [ms]   ess\n');
fprintf('Adelanto        %7.2f %9.1f %8.4f\n', info2.Overshoot, info2.SettlingTime*1e3, ess2);
fprintf('Adelanto-atraso %7.2f %9.1f %8.4f\n', info4.Overshoot, info4.SettlingTime*1e3, ess4);

fig5 = figure('Name', 'Punto 5: Comparación', 'Position', [100, 100, 720, 440], 'Visible', vis_opt);
plot(t5*1e3, y5_lead, 'Color', [0.85 0.33 0.1], 'LineWidth', 1.4); hold on;
plot(t5*1e3, y5_ll, 'b', 'LineWidth', 1.4);
yline(1, 'k-.', 'Referencia', 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
xline(Ts_max*1e3, '--', 'Color', [0.2 0.6 0.2], 'Label', 'T_s máx');
ylim([0 1.1]);
legend(sprintf('Adelanto (e_{ss} = %.3f)', ess2), sprintf('Adelanto-atraso (e_{ss} = %.3f)', ess4), ...
       'Location', 'southeast');
title('Respuesta al escalón: adelanto vs adelanto-atraso');
xlabel('Tiempo (ms)'); ylabel('Amplitud (V)');
grid on; hold off;
saveas(fig5, fullfile(fig_dir, 'punto5_comparacion.png'));
if ~mostrar_graficos, close(fig5); end
