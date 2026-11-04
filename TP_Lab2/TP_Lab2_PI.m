%% Trabajo de Laboratorio Integrador - Sistemas de Control
% TP de Laboratorio 2: Segunda Parte - Control Proporcional-Integral (PI)
% Script autocontenido de cálculo analítico y diseño por Lugar de las Raíces
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

%% =========================================================================
%% 1. MODELO DE LA PLANTA (Sin ganancia kp)
%% =========================================================================
R1 = 100e3;          % 100 kOhm
C1 = 0.1e-6;         % 0.1 uF
tau1 = R1 * C1;      % 0.01 s -> polo en -100 rad/s

R2 = 47e3;           % 47 kOhm
C2 = 0.1e-6;         % 0.1 uF
tau2 = R2 * C2;      % 0.0047 s -> polo en -212.77 rad/s

s = tf('s');
G = 1 / ((tau1 * s + 1) * (tau2 * s + 1));

disp('=== FUNCIÓN DE TRANSFERENCIA DE LA PLANTA G(s) ===');
G

%% =========================================================================
%% 2. PUNTO 1: CONDICIONES DE ESTABILIDAD (ROUTH-HURWITZ)
%% =========================================================================
% Ecuación característica de lazo cerrado:
% s*(tau1*s+1)*(tau2*s+1) + (kp*s + ki) = 0
% a3*s^3 + a2*s^2 + a1*s + a0 = 0
% a3 = tau1*tau2 = 4.7e-5
% a2 = tau1 + tau2 = 0.0147
% a1 = 1 + kp
% a0 = ki
%
% Criterio de Routh:
% s^3 | a3                 a1
% s^2 | a2                 a0
% s^1 | (a2*a1 - a3*a0)/a2 0
% s^0 | a0
%
% Condiciones:
% 1) a0 > 0                   => ki > 0
% 2) (a2*a1 - a3*a0)/a2 > 0   => ki < (a2/a3)*(1 + kp)
slope_routh = (tau1 + tau2) / (tau1 * tau2);

fprintf('\n=== PUNTO 1: CONDICIONES DE ESTABILIDAD (ROUTH) ===\n');
fprintf('Condición 1: ki > 0\n');
fprintf('Condición 2: ki < %.2f * (1 + kp)\n', slope_routh);
fprintf('Para kp > 0, cualquier ki en ese rango asegura estabilidad en lazo cerrado.\n');

%% =========================================================================
%% 3. PUNTO 2: DISEÑO DEL PI CON EL LUGAR DE LAS RAÍCES
%% =========================================================================

%% 2.a: Especificaciones en el plano s
PO_max = 5;
xi_min = -log(PO_max / 100) / sqrt(pi^2 + (log(PO_max / 100))^2);
Ts_max = 0.10;
sigma_min = 4 / Ts_max; % 40 rad/s
theta_rad = acos(xi_min);

fprintf('\n=== PUNTO 2.a: REQUISITOS EN EL PLANO s ===\n');
fprintf('xi minimo para PO <= 5%%:          %.4f (~0.69)\n', xi_min);
fprintf('sigma minimo (xi*wn) para Ts<=0.1s: %.2f rad/s\n', sigma_min);

% Grafico de la region de polos dominantes en el plano s
fig2a = figure('Name', 'Punto 2.a: Region admisible en el plano s', 'Position', [100, 100, 680, 480], 'Visible', 'off');
hold on;
sig_grid = linspace(-180, -sigma_min, 200);
w_top = -sig_grid * tan(theta_rad);
w_bot =  sig_grid * tan(theta_rad);
fill([sig_grid, fliplr(sig_grid)], [w_bot, fliplr(w_top)], [0.85 0.95 0.85], ...
    'EdgeColor', 'none', 'DisplayName', 'Region admisible');
r_line = linspace(0, 220, 100);
plot(-r_line*cos(theta_rad),  r_line*sin(theta_rad), 'b-', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Limite PO \\le 5%%%% (\\xi = %.2f, \\theta = %.1f°)', xi_min, rad2deg(theta_rad)));
plot(-r_line*cos(theta_rad), -r_line*sin(theta_rad), 'b-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
xline(-sigma_min, 'r--', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Limite Ts \\le 0.10 s (\\xi\\omega_n \\ge %d rad/s)', sigma_min));
yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
xline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
grid on;
xlim([-180, 40]);
ylim([-150, 150]);
title('Region de polos dominantes en el plano s (Punto 2.a)');
xlabel('Eje Real \sigma (1/s)');
ylabel('Eje Imaginario j\omega (rad/s)');
legend('Location', 'southwest');
saveas(fig2a, fullfile(fig_dir, 'pi_punto2a_region_s.png'));
close(fig2a);

%% 2.b: Centro de las asintotas sigma_a en funcion de z
% Polos de L(s) = Gc(s)*G(s): 0, -100, -212.766 rad/s (n = 3)
% Ceros de L(s): -z (m = 1)
% Exceso de polos sobre ceros: n - m = 3 - 1 = 2
% Angulos de las asintotas:
%   phi_k = (2*k + 1)*180° / (n - m) = (2*k + 1)*180° / 2
%   k = 0 => phi_0 = 90°
%   k = 1 => phi_1 = 270° = -90°
% Al ser los angulos exactamente +-90°, las asintotas son estrictamente verticales.
%
% Centro de asintotas:
% sigma_a = (suma_polos - suma_ceros) / (n - m)
% sigma_a = (0 - 100 - 212.766 - (-z)) / 2 = (z - 312.766) / 2
% Condicion: sigma_a < -40 rad/s => z < 312.766 - 80 = 232.766 rad/s
z_max_asintota = 312.766 - 80;

fprintf('\n=== PUNTO 2.b: ASINTOTAS DEL LUGAR DE LAS RAICES ===\n');
fprintf('Numero de polos n = 3, ceros m = 1 => n - m = 2\n');
fprintf('Angulos de asintotas: phi = +-90° (estrictamente verticales)\n');
fprintf('Centro de asintotas: sigma_a(z) = (z - 312.77) / 2\n');
fprintf('Para que sigma_a quede a la izquierda de -40 rad/s: z < %.2f rad/s\n', z_max_asintota);


%% 2.c: Elección de z y diseño con xi = 0.69
% Análisis de la ubicación del cero z:
% Caso 1 (z < 100 rad/s, ej: z = 50 rad/s):
%   El segmento [-z, 0] = [-50, 0] pertenece al LGR. La rama que parte de s = 0
%   termina en s = -z, atrapando un polo real lento cerca del origen (ej: s ~= -35 rad/s).
%   Esto viola la cota Ts <= 0.10 s (da Ts > 0.11 s).
% Caso 2 (z > 100 rad/s, ej: z = 120 rad/s):
%   El segmento [-100, 0] pertenece al LGR; las ramas de 0 y -100 colisionan y
%   emergen al plano complejo formando el par dominante. La rama de -212.8 rad/s
%   termina en el cero -120 rad/s, quedando el polo real confinado a la izquierda
%   de -120 rad/s (más rápido que la cota -40 rad/s).

% --- Figura Comparativa: Elección de z (z = 50 vs z = 120 rad/s) ---
z_lento = 50;
L_lento = ((s + z_lento) / s) * G;
z_pi = 120;
L_unit = ((s + z_pi) / s) * G;

fig_comp_z = figure('Name', 'Comparación de ubicación del cero z', 'Position', [100, 100, 950, 420], 'Visible', 'off');

subplot(1, 2, 1);
rlocus(L_lento);
hold on;
sgrid(0.69, []);
xline(-sigma_min, 'k--', 'LineWidth', 1.2);
xlim([-250, 10]);
ylim([-150, 150]);
title('Caso z = 50 rad/s < 100 rad/s');
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;
% Polo con kp = 0.84 en z = 50
T_lento_test = feedback(0.84 * L_lento, 1);
p_lento_test = pole(T_lento_test);
plot(real(p_lento_test), imag(p_lento_test), 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
text(-48, 25, 'Polo lento en [-z, 0]', 'Color', 'r', 'FontSize', 9, 'FontWeight', 'bold');

subplot(1, 2, 2);
rlocus(L_unit);
hold on;
sgrid(0.69, []);
xline(-sigma_min, 'k--', 'LineWidth', 1.2);
xlim([-250, 10]);
ylim([-150, 150]);
title('Caso seleccionado: z = 120 rad/s > 100 rad/s');
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;
T_120_test = feedback(0.84 * L_unit, 1);
p_120_test = pole(T_120_test);
plot(real(p_120_test), imag(p_120_test), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
text(-120, 100, 'Par complejo dominante', 'Color', 'r', 'FontSize', 9, 'FontWeight', 'bold');

sgtitle('Influencia de la posición del cero z en el Lugar de las Raíces');
saveas(fig_comp_z, fullfile(fig_dir, 'pi_punto2_comparacion_z.png'));
close(fig_comp_z);

% Cálculo de parámetros con z = 120 rad/s
sigma_a = (z_pi - 312.766) / 2; % -96.38 rad/s

% Gráfico del Lugar de las Raíces con diseño y cotas
fig_lgr = figure('Name', 'Punto 2: LGR con PI (z = 120)', 'Visible', 'off');
rlocus(L_unit);
hold on;
sgrid([0.69, 0.75], []);
xline(-sigma_min, 'k--', 'LineWidth', 1.2, 'DisplayName', '\sigma = -40 s^{-1} (T_s \le 0.10 s)');
xline(sigma_a, 'm:', 'LineWidth', 1.2, 'DisplayName', sprintf('\\sigma_a = %.1f s^{-1}', sigma_a));
title(sprintf('Lugar de las Raíces con controlador PI (z = %d rad/s)', z_pi));
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;

% En xi = 0.69 sobre la rama dominante:
kp_ini = 0.84;
ki_ini = kp_ini * z_pi; % 100.8

T_ini = feedback(kp_ini * L_unit, 1);
info_ini = stepinfo(T_ini);
[wn_ini, xi_ini, p_ini] = damp(T_ini);
idx_c = find(abs(imag(p_ini)) > 1e-3);

% Ajuste a xi = 0.75 para contrarrestar el cero:
kp_aj = 0.68;
ki_aj = kp_aj * z_pi; % 81.6
T_aj = feedback(kp_aj * L_unit, 1);
info_aj = stepinfo(T_aj);
[wn_aj, xi_aj, p_aj] = damp(T_aj);

fprintf('\n=== PUNTO 2.c: DISEÑO INICIAL (z = %d, xi = 0.69) ===\n', z_pi);
fprintf('kp inicial:                     %.2f\n', kp_ini);
fprintf('ki inicial:                     %.2f rad/s\n', ki_ini);
fprintf('Polos en lazo cerrado:          %.1f +- %.1fj,  %.1f rad/s\n', ...
    real(p_ini(idx_c(1))), imag(p_ini(idx_c(1))), real(p_ini(3)));
fprintf('Sobrepaso obtenido (PO):        %.2f %%  (Especificación: <= 5 %%)\n', info_ini.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)\n', info_ini.SettlingTime, info_ini.SettlingTime*1e3);

% Marcamos polos iniciales y ajustados en el gráfico de LGR
plot(real(p_ini), imag(p_ini), 'r*', 'MarkerSize', 8, 'LineWidth', 1.5, ...
    'DisplayName', sprintf('k_p = %.2f (\\xi = 0.69, PO = %.1f %%)', kp_ini, info_ini.Overshoot));
plot(real(p_aj), imag(p_aj), 'bd', 'MarkerFaceColor', 'b', 'MarkerSize', 6, ...
    'DisplayName', sprintf('k_p = %.2f (\\xi = 0.75, PO = %.1f %%)', kp_aj, info_aj.Overshoot));
legend('Location', 'northwest');
saveas(fig_lgr, fullfile(fig_dir, 'pi_punto2_lgr.png'));
close(fig_lgr);

%% 2.d: Verificación y ajuste de kp por el cero de lazo cerrado
% El sobrepaso es de 6.79 % (supera el 5 %) porque la FT de lazo cerrado T(s)
% retiene el cero en s = -z = -120 rad/s en el numerador.
% Construimos el modelo canónico de segundo orden sin cero para comparar el efecto:
wn_dom = wn_ini(idx_c(1));
xi_dom = xi_ini(idx_c(1));
T_proto = tf(wn_dom^2, [1, 2*xi_dom*wn_dom, wn_dom^2]);
info_proto = stepinfo(T_proto);

y_inf_aj = dcgain(T_aj);
ess_aj = 1 - y_inf_aj;

fprintf('\n=== PUNTO 2.d: EFECTO DEL CERO Y AJUSTE DE kp ===\n');
fprintf('Prototipo 2do orden sin cero (xi=0.69): PO = %.2f %%\n', info_proto.Overshoot);
fprintf('Sistema PI real con kp=0.84 (con cero): PO = %.2f %%\n', info_ini.Overshoot);
fprintf('kp ajustado:                    %.2f\n', kp_aj);
fprintf('ki ajustado:                    %.2f rad/s\n', ki_aj);
fprintf('Sobrepaso ajustado (PO):        %.2f %%  (CUMPLE <= 5 %%)\n', info_aj.Overshoot);
fprintf('Tiempo de estab. ajustado (Ts): %.4f s (%.2f ms)  (CUMPLE <= 0.10 s)\n', info_aj.SettlingTime, info_aj.SettlingTime*1e3);
fprintf('Error estacionario (ess):       %.4f  (CUMPLE = 0)\n', ess_aj);

% --- Figura: Demostración del Efecto del Cero en Lazo Cerrado ---
fig_cero = figure('Name', 'Efecto del Cero de Lazo Cerrado', 'Visible', 'off');
t_cero = linspace(0, 0.10, 2000);
[y_proto, t_p] = step(T_proto, t_cero);
[y_ini_c, ~]   = step(T_ini, t_cero);
[y_aj_c, ~]    = step(T_aj, t_cero);

plot(t_p*1e3, y_proto, 'k--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Prototipo 2^{do} orden sin cero (\\xi = 0.69, PO = %.2f %%)', info_proto.Overshoot));
hold on;
plot(t_p*1e3, y_ini_c, 'r-', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Sistema PI k_p = 0.84 (con cero z = 120, PO = %.2f %%)', info_ini.Overshoot));
plot(t_p*1e3, y_aj_c, 'b-.', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Sistema PI compensado k_p = 0.68 (PO = %.2f %%)', info_aj.Overshoot));
yline(1.0, 'k:');
yline(1.05, 'm:', 'LineWidth', 1.1, 'DisplayName', 'Límite PO = 5%');
grid on;
title('Efecto del cero de lazo cerrado sobre el sobrepaso transitorio');
xlabel('Tiempo (ms)');
ylabel('Tensión de salida y(t) [V]');
legend('Location', 'southeast');
saveas(fig_cero, fullfile(fig_dir, 'pi_punto2_efecto_cero.png'));
close(fig_cero);

%% =========================================================================
%% 4. PUNTO 3: IMPLEMENTACIÓN ANALÓGICA CON OP-AMPS (FIGS. 3 Y 4)
%% =========================================================================
% 3.a: Etapa PI inversora (Figura 3)
% V_o1(s) / V_i(s) = - Z_f(s) / Z_in(s)
% Z_in(s) = RPI1
% Z_f(s)  = RPI2 + 1 / (CPI * s)
% V_o1(s) / V_i(s) = - (RPI2 / RPI1 + 1 / (RPI1 * CPI * s))
% Por lo tanto:
% kp = RPI2 / RPI1
% ki = 1 / (RPI1 * CPI)
% z  = ki / kp = 1 / (RPI2 * CPI)

% 3.b: Inversor de ganancia -1 (Figura 4) y dimensionamiento comercial E24:
% Se utiliza un amplificador inversor con RINV1 = RINV2 para cancelar el signo menos.
% Consigna: CPI = 0.1 uF.
% Con z = 120 rad/s:
% RPI2 = 1 / (z * CPI) = 1 / (120 * 0.1e-6) = 83.33 kOhm -> RPI2 = 82 kOhm (E24)
% Con kp = 0.68:
% RPI1 = RPI2 / kp = 82 kOhm / 0.68 = 120.58 kOhm -> RPI1 = 120 kOhm (E24)
% Inversor:
% RINV1 = 10 kOhm, RINV2 = 10 kOhm (E24)
CPI_com   = 0.1e-6;   % 0.1 uF
RPI2_com  = 82e3;     % 82 kOhm (E24)
RPI1_com  = 120e3;    % 120 kOhm (E24)
RINV1_com = 10e3;     % 10 kOhm (E24)
RINV2_com = 10e3;     % 10 kOhm (E24)

kp_com = RPI2_com / RPI1_com;          % 82 / 120 = 0.6833
ki_com = 1 / (RPI1_com * CPI_com);     % 1 / (120k * 0.1u) = 83.33 rad/s
z_com  = 1 / (RPI2_com * CPI_com);     % 1 / (82k * 0.1u) = 121.95 rad/s

Gc_com = (kp_com * s + ki_com) / s;
T_com  = feedback(Gc_com * G, 1);
info_com  = stepinfo(T_com);
y_inf_com = dcgain(T_com);
ess_com   = 1 - y_inf_com;

fprintf('\n=== PUNTO 3: COMPONENTES COMERCIALES E24 ===\n');
fprintf('RPI1 = %d kOhm, RPI2 = %d kOhm, CPI = %.1f uF\n', RPI1_com/1e3, RPI2_com/1e3, CPI_com*1e6);
fprintf('RINV1 = %d kOhm, RINV2 = %d kOhm (Ganancia -1)\n', RINV1_com/1e3, RINV2_com/1e3);
fprintf('Valores efectivos: kp = %.4f, ki = %.2f rad/s, z = %.2f rad/s\n', kp_com, ki_com, z_com);
fprintf('Sobrepaso efectivo (PO):        %.2f %%  (<= 5 %%)\n', info_com.Overshoot);
fprintf('Tiempo de estab. efectivo (Ts): %.4f s (%.2f ms)  (<= 0.10 s)\n', info_com.SettlingTime, info_com.SettlingTime*1e3);
fprintf('Error estacionario (ess):       %.4f  (= 0)\n', ess_com);

% Gráfico de la respuesta al escalón: Diseño continuo vs Comercial E24
fig_step = figure('Name', 'Punto 3: Respuesta al escalón E24', 'Visible', 'off');
t_sim = linspace(0, 0.12, 3000);
[y_aj, ~]  = step(T_aj, t_sim);
[y_c, t_out] = step(T_com, t_sim);

plot(t_out*1e3, y_aj, 'b--', 'LineWidth', 1.6, ...
    'DisplayName', sprintf('Continuo k_p = 0.68 (PO = %.2f %%, T_s = %.1f ms)', info_aj.Overshoot, info_aj.SettlingTime*1e3));
hold on;
plot(t_out*1e3, y_c, 'k-', 'LineWidth', 2.0, ...
    'DisplayName', sprintf('E24: R_{PI1}=120k, R_{PI2}=82k (PO = %.2f %%, T_s = %.1f ms)', info_com.Overshoot, info_com.SettlingTime*1e3));
yline(1.0, 'k:');
yline(1.02, 'g:', 'LineWidth', 1.0, 'DisplayName', 'Banda \pm 2%');
yline(0.98, 'g:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
xline(info_com.SettlingTime*1e3, 'r:', 'LineWidth', 1.2, ...
    'DisplayName', sprintf('T_s = %.1f ms', info_com.SettlingTime*1e3));
grid on;
title('Respuesta al escalón: Controlador continuo vs Implementación E24');
xlabel('Tiempo (ms)');
ylabel('Tensión de salida y(t) [V]');
legend('Location', 'southeast');
saveas(fig_step, fullfile(fig_dir, 'pi_punto3_escalon_e24.png'));
close(fig_step);

fprintf('\nFiguras guardadas en %s:\n', fig_dir);
fprintf('- pi_punto2_comparacion_z.png\n');
fprintf('- pi_punto2_lgr.png\n');
fprintf('- pi_punto2_efecto_cero.png\n');
fprintf('- pi_punto3_escalon_e24.png\n');
