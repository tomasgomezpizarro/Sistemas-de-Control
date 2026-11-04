%% Trabajo de Laboratorio Integrador - Sistemas de Control
% TP de Laboratorio 2: Desarrollo de Controladores (P y PI)
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

%% =========================================================================
%% MODELO DE LA PLANTA G(s)
%% =========================================================================
R1 = 100e3;          % 100 kOhm
C1 = 0.1e-6;         % 0.1 uF
tau1 = R1 * C1;      % 0.01 s -> polo en -100 rad/s

R2 = 47e3;           % 47 kOhm
C2 = 0.1e-6;         % 0.1 uF
tau2 = R2 * C2;      % 0.0047 s -> polo en -212.77 rad/s

s = tf('s');
G = 1 / ((tau1 * s + 1) * (tau2 * s + 1));

disp('=========================================================================');
disp('=== FUNCIÓN DE TRANSFERENCIA DE LA PLANTA G(s) ===');
disp('=========================================================================');
G

%% =========================================================================
%% PRIMERA PARTE: CONTROL PROPORCIONAL
%% =========================================================================

%% Punto 1: Lugar de las Raíces para ajuste de kp
figure('Name', 'Parte 1 - Punto 1: Lugar de las Raíces - Planta G(s)');
rlocus(G);
sgrid(0.69, []);
title('Lugar de las Raíces de G(s) - Control Proporcional');
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;

%% Punto 2: Verificación de la respuesta al escalón en lazo cerrado
kp = 1.41;
T = feedback(kp * G, 1);

info  = stepinfo(T);
y_inf = dcgain(T);
ess   = 1 - y_inf;

fprintf('\n=== PARTE 1 - PUNTO 2: MÉTRICAS AL ESCALÓN (kp = %.2f) ===\n', kp);
fprintf('Sobrepaso (PO):                 %.4f %%  (Especificación: <= 5 %%)\n', info.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)  (Especificación: <= 0.10 s)\n', info.SettlingTime, info.SettlingTime*1e3);
fprintf('Tiempo de pico (Tp):            %.4f s (%.2f ms)\n', info.PeakTime, info.PeakTime*1e3);
fprintf('Valor en estado estacionario:   %.4f V\n', y_inf);
fprintf('Error estacionario (ess):       %.4f (%.2f %%)  (Especificación: = 0)\n', ess, ess*100);

% Gráfico de la respuesta al escalón
fig2 = figure('Name', 'Parte 1 - Punto 2: Respuesta al escalón (kp = 1.41)');
step(T);
grid on;
title(sprintf('Respuesta al escalón en lazo cerrado (k_p = %.2f)', kp));
xlabel('Tiempo (s)');
ylabel('Amplitud (V)');
saveas(fig2, fullfile(fig_dir, 'punto2_escalon.png'));

%% Punto 3: Elección de valores comerciales (serie E24) para R7 y R9
R7 = 1.6e3;    % 1.6 kOhm (E24)
R9 = 3.9e3;    % 3.9 kOhm (E24)
kp_real = 1 + R7 / R9;

T_real = feedback(kp_real * G, 1);
info_real  = stepinfo(T_real);
y_inf_real = dcgain(T_real);
ess_real   = 1 - y_inf_real;

fprintf('\n=== PARTE 1 - PUNTO 3: VALORES COMERCIALES E24 (R7 = %.1f kOhm, R9 = %.1f kOhm) ===\n', R7*1e-3, R9*1e-3);
fprintf('kp obtenido con E24:            %.6f\n', kp_real);
fprintf('Sobrepaso (PO):                 %.4f %%  (Especificación: <= 5 %%)\n', info_real.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)  (Especificación: <= 0.10 s)\n', info_real.SettlingTime, info_real.SettlingTime*1e3);
fprintf('Tiempo de pico (Tp):            %.4f s (%.2f ms)\n', info_real.PeakTime, info_real.PeakTime*1e3);
fprintf('Valor en estado estacionario:   %.4f V\n', y_inf_real);
fprintf('Error estacionario (ess):       %.4f (%.2f %%)  (Especificación: = 0)\n', ess_real, ess_real*100);

%% Punto 4: Simulación circuital en Simscape con op-amps TL081 (Fig. 2)
mdl = 'TP_Lab2_TL081';
if exist([mdl '.slx'], 'file') || exist(fullfile(script_dir, [mdl '.slx']), 'file')
    load_system(fullfile(script_dir, [mdl '.slx']));
    out_sim = sim(mdl);
    t_sim   = out_sim.simlog.Voltage_Sensor.V.series.time;
    y_sim   = out_sim.simlog.Voltage_Sensor.V.series.values;

    t_unif = linspace(0, max(t_sim), 5000)';
    y_ft   = step(T_real, t_unif);

    [t_sim_u, idx_u] = unique(t_sim);
    y_sim_interp     = interp1(t_sim_u, y_sim(idx_u), t_unif, 'pchip');
    err_max_p4       = max(abs(y_sim_interp - y_ft));

    y_inf_sim = y_sim(end);
    ess_sim   = 1 - y_inf_sim;
    info_sim  = stepinfo(y_sim, t_sim, y_inf_sim);

    fprintf('\n=== PARTE 1 - PUNTO 4: SIMULACIÓN EN SIMSCAPE CON TL081 ===\n');
    fprintf('Error máximo |y(Simscape) - y(FT)|: %.4e V (%.3f mV)\n', err_max_p4, err_max_p4*1e3);
    fprintf('Sobrepaso Simscape (PO):            %.2f %%  (FT: %.2f %%)\n', info_sim.Overshoot, info_real.Overshoot);
    fprintf('Tiempo de estab. Simscape (Ts):     %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim.SettlingTime, info_sim.SettlingTime*1e3, info_real.SettlingTime*1e3);
    fprintf('Tiempo de pico Simscape (Tp):       %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim.PeakTime, info_sim.PeakTime*1e3, info_real.PeakTime*1e3);
    fprintf('Valor final Simscape:               %.4f V  (FT: %.4f V)\n', y_inf_sim, y_inf_real);
    fprintf('Error estacionario Simscape (ess):  %.4f (%.2f %%)  (FT: %.2f %%)\n', ess_sim, ess_sim*100, ess_real*100);

    fig4 = figure('Name', 'Parte 1 - Punto 4: Superposición FT vs Simscape TL081', 'Position', [100, 100, 720, 420]);
    plot(t_unif * 1e3, y_ft, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Modelo Lineal FT (T_{real})');
    hold on;
    plot(t_sim * 1e3, y_sim, 'r--', 'LineWidth', 1.4, 'DisplayName', 'Circuito Simscape (TL081)');
    grid on;
    title('Respuesta al escalón unitario: Modelo por FT vs. Simscape (TL081, k_p \approx 1.41)');
    xlabel('Tiempo (ms)');
    ylabel('Tensión de salida (V)');
    legend('Location', 'southeast');
    saveas(fig4, fullfile(fig_dir, 'punto4_simscape_vs_ft.png'));
    close_system(mdl);
else
    fprintf('\n[Aviso] No se encontró el modelo %s.slx en el directorio. Se omite simulación de Simscape.\n', mdl);
end

%% =========================================================================
%% SEGUNDA PARTE: CONTROL PROPORCIONAL-INTEGRAL (PI)
%% =========================================================================

%% Punto 1: Condiciones de estabilidad (Routh-Hurwitz)
slope_routh = (tau1 + tau2) / (tau1 * tau2);

fprintf('\n=== PARTE 2 - PUNTO 1: CONDICIONES DE ESTABILIDAD (ROUTH) ===\n');
fprintf('Condición 1: ki > 0\n');
fprintf('Condición 2: ki < %.2f * (1 + kp)\n', slope_routh);
fprintf('Para kp > 0, cualquier ki en ese rango asegura estabilidad en lazo cerrado.\n');

%% Punto 2.a: Especificaciones en el plano s y región admisible
PO_max = 5;
xi_min = -log(PO_max / 100) / sqrt(pi^2 + (log(PO_max / 100))^2);
Ts_max = 0.10;
sigma_min = 4 / Ts_max; % 40 rad/s
theta_rad = acos(xi_min);

fprintf('\n=== PARTE 2 - PUNTO 2.a: REQUISITOS EN EL PLANO s ===\n');
fprintf('xi mínimo para PO <= 5%%:            %.4f (~0.69)\n', xi_min);
fprintf('sigma mínimo (xi*wn) para Ts<=0.1s: %.2f rad/s\n', sigma_min);

fig2a = figure('Name', 'Parte 2 - Punto 2.a: Región admisible en el plano s', 'Position', [100, 100, 700, 480]);
hold on;
sig_grid = linspace(-180, -sigma_min, 300);
w_top = -sig_grid * tan(theta_rad);
w_bot =  sig_grid * tan(theta_rad);
fill([sig_grid, fliplr(sig_grid)], [w_bot, fliplr(w_top)], [0.85 0.95 0.85], ...
    'EdgeColor', 'none', 'DisplayName', 'Región admisible');

r_line = linspace(0, 220, 150);
plot(-r_line*cos(theta_rad),  r_line*sin(theta_rad), 'b-', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Límite PO \\leq 5%%%% (\\xi = %.2f, \\theta = %.1f^\\circ)', xi_min, rad2deg(theta_rad)));
plot(-r_line*cos(theta_rad), -r_line*sin(theta_rad), 'b-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
xline(-sigma_min, 'r--', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Límite T_s \\leq 0.10 s (\\xi\\omega_n \\geq %d rad/s)', sigma_min));
yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
xline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
grid on;
xlim([-180, 40]);
ylim([-150, 150]);
title('Región de polos dominantes en el plano s (Punto 2.a)');
xlabel('Eje Real \sigma (1/s)');
ylabel('Eje Imaginario j\omega (rad/s)');
legend('Location', 'southwest');

text(-sigma_min - 3, 110, '\xi\omega_n = 40', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
text(-120, 125, 'Cono \xi \geq 0.69', 'Color', 'b', 'FontWeight', 'bold');
text(-120, 20, {'Región', 'admisible'}, 'Color', [0 0.5 0], 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

saveas(fig2a, fullfile(fig_dir, 'pi_punto2a_region_s.png'));

%% Punto 2.b: Centro de las asíntotas sigma_a en función de z
z_max_asintota = 312.766 - 80;

fprintf('\n=== PARTE 2 - PUNTO 2.b: ASÍNTOTAS DEL LUGAR DE LAS RAÍCES ===\n');
fprintf('Número de polos n = 3, ceros m = 1 => n - m = 2\n');
fprintf('Ángulos de asíntotas: phi = +-90° (estrictamente verticales)\n');
fprintf('Centro de asíntotas: sigma_a(z) = (z - 312.77) / 2\n');
fprintf('Para que sigma_a quede a la izquierda de -40 rad/s: z < %.2f rad/s\n', z_max_asintota);

%% Punto 2.c: Lugar de las Raíces para ajuste de kp con PI (z = 120 rad/s)
z_pi = 120;
L_unit = ((s + z_pi) / s) * G;

figure('Name', 'Parte 2 - Punto 2.c: Lugar de las Raíces - Controlador PI (z = 120 rad/s)');
rlocus(L_unit);
sgrid(0.69, []);
title(sprintf('Lugar de las Raíces con controlador PI (z = %d rad/s)', z_pi));
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;

% Selección de ganancia sobre la cota xi = 0.69 (análogo al Punto 1)
kp_ini = 0.84;
ki_ini = kp_ini * z_pi; % 100.8 rad/s

T_ini = feedback(kp_ini * L_unit, 1);
info_ini = stepinfo(T_ini);
[wn_ini, xi_ini, p_ini] = damp(T_ini);
idx_c = find(abs(imag(p_ini)) > 1e-3);

fprintf('\n=== PARTE 2 - PUNTO 2.c: RESULTADOS CON kp = %.2f (xi = 0.69) ===\n', kp_ini);
fprintf('kp inicial:                     %.4f\n', kp_ini);
fprintf('ki inicial:                     %.4f rad/s\n', ki_ini);
if ~isempty(idx_c)
    fprintf('Polos dominantes:               %.2f +- %.2fj rad/s (xi = %.4f)\n', ...
        real(p_ini(idx_c(1))), abs(imag(p_ini(idx_c(1)))), xi_ini(idx_c(1)));
end
fprintf('Sobrepaso obtenido (PO):        %.2f %%  (Especificación: <= 5 %%)\n', info_ini.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)  (Especificación: <= 0.10 s)\n', info_ini.SettlingTime, info_ini.SettlingTime*1e3);

%% Punto 2.d: Efecto del cero en lazo cerrado y ajuste de kp
wn_dom = wn_ini(idx_c(1));
xi_dom = xi_ini(idx_c(1));
T_proto = tf(wn_dom^2, [1, 2*xi_dom*wn_dom, wn_dom^2]);
info_proto = stepinfo(T_proto);

% Ajuste de ganancia para compensar el cero (mayor amortiguamiento, ej: xi ~ 0.75):
kp_aj = 0.73;
ki_aj = kp_aj * z_pi; % 87.6
T_aj = feedback(kp_aj * L_unit, 1);
info_aj = stepinfo(T_aj);
[wn_aj, xi_aj, p_aj] = damp(T_aj);

y_inf_aj = dcgain(T_aj);
ess_aj = 1 - y_inf_aj;

fprintf('\n=== PARTE 2 - PUNTO 2.d: EFECTO DEL CERO Y AJUSTE DE kp ===\n');
fprintf('Prototipo 2do orden sin cero (xi=0.69): PO = %.2f %%\n', info_proto.Overshoot);
fprintf('Sistema PI real con kp=%.4f (con cero): PO = %.2f %%\n', kp_ini, info_ini.Overshoot);
fprintf('kp ajustado:                    %.4f\n', kp_aj);
fprintf('ki ajustado:                    %.4f rad/s\n', ki_aj);
fprintf('Sobrepaso ajustado (PO):        %.2f %%  (CUMPLE <= 5 %%)\n', info_aj.Overshoot);
fprintf('Tiempo de estab. ajustado (Ts): %.4f s (%.2f ms)  (CUMPLE <= 0.10 s)\n', info_aj.SettlingTime, info_aj.SettlingTime*1e3);
fprintf('Error estacionario (ess):       %.4f  (CUMPLE = 0)\n', ess_aj);

% Gráfico: Comparación temporal del Efecto del Cero
fig_cero = figure('Name', 'Parte 2 - Punto 2.d: Efecto del Cero de Lazo Cerrado');
t_cero = linspace(0, 0.10, 2000);
[y_proto, t_p] = step(T_proto, t_cero);
[y_ini_c, ~]   = step(T_ini, t_cero);
[y_aj_c, ~]    = step(T_aj, t_cero);

plot(t_p*1e3, y_proto, 'k--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Prototipo 2^{do} orden sin cero (\\xi = 0.69, PO = %.2f %%)', info_proto.Overshoot));
hold on;
plot(t_p*1e3, y_ini_c, 'r-', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Sistema PI k_p = %.2f (con cero z = %d, PO = %.2f %%)', kp_ini, z_pi, info_ini.Overshoot));
plot(t_p*1e3, y_aj_c, 'b-.', 'LineWidth', 1.8, ...
    'DisplayName', sprintf('Sistema PI compensado k_p = %.2f (PO = %.2f %%)', kp_aj, info_aj.Overshoot));
yline(1.0, 'k:');
yline(1.05, 'm:', 'LineWidth', 1.1, 'DisplayName', 'Límite PO = 5%');
grid on;
title('Efecto del cero de lazo cerrado sobre el sobrepaso transitorio');
xlabel('Tiempo (ms)');
ylabel('Tensión de salida y(t) [V]');
legend('Location', 'southeast');
saveas(fig_cero, fullfile(fig_dir, 'pi_punto2_efecto_cero.png'));

%% Punto 3: Implementación analógica con Op-Amps y dimensionamiento E24
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

fprintf('\n=== PARTE 2 - PUNTO 3: COMPONENTES COMERCIALES E24 ===\n');
fprintf('RPI1 = %d kOhm, RPI2 = %d kOhm, CPI = %.1f uF\n', RPI1_com/1e3, RPI2_com/1e3, CPI_com*1e6);
fprintf('RINV1 = %d kOhm, RINV2 = %d kOhm (Ganancia -1)\n', RINV1_com/1e3, RINV2_com/1e3);
fprintf('Valores efectivos: kp = %.4f, ki = %.2f rad/s, z = %.2f rad/s\n', kp_com, ki_com, z_com);

disp('=========================================================================');
disp('=== EJECUCIÓN COMPLETA FINALIZADA EXITOSAMENTE ===');
disp('=========================================================================');
