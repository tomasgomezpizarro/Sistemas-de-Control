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
fig1 = figure('Name', 'Parte 1 - Punto 1: Lugar de las Raíces - Planta G(s)', 'Position', [100, 100, 700, 480], 'Visible', vis_opt);
rlocus(G);
sgrid(0.69, []);
title('Lugar de las Raíces de G(s) - Control Proporcional');
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;
saveas(fig1, fullfile(fig_dir, 'punto1_lgr.png'));
if ~mostrar_graficos, close(fig1); end

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
fig2 = figure('Name', 'Parte 1 - Punto 2: Respuesta al escalón (kp = 1.41)', 'Position', [100, 100, 700, 440], 'Visible', vis_opt);
step(T);
grid on;
title(sprintf('Respuesta al escalón en lazo cerrado (k_p = %.2f)', kp));
xlabel('Tiempo (s)');
ylabel('Amplitud (V)');
saveas(fig2, fullfile(fig_dir, 'punto2_escalon.png'));
if ~mostrar_graficos, close(fig2); end

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
mdl_p = 'TP_Lab2_TL081';
if exist([mdl_p '.slx'], 'file') || exist(fullfile(script_dir, [mdl_p '.slx']), 'file')
    load_system(fullfile(script_dir, [mdl_p '.slx']));
    set_param(mdl_p, 'StopTime', '0.12');
    set_param(mdl_p, 'SimscapeLogLimitData', 'off');
    set_param(mdl_p, 'LimitDataPoints', 'off');
    out_sim_p = sim(mdl_p);
    t_sim_p   = out_sim_p.simlog.Voltage_Sensor.V.series.time;
    y_sim_p   = out_sim_p.simlog.Voltage_Sensor.V.series.values;

    t_unif_p = linspace(0, max(t_sim_p), 5000)';
    y_ft_p   = step(T_real, t_unif_p);

    [t_sim_p_u, idx_p_u] = unique(t_sim_p);
    y_sim_p_interp       = interp1(t_sim_p_u, y_sim_p(idx_p_u), t_unif_p, 'pchip');
    err_max_p4           = max(abs(y_sim_p_interp - y_ft_p));

    y_inf_sim_p = y_sim_p(end);
    ess_sim_p   = 1 - y_inf_sim_p;
    info_sim_p  = stepinfo(y_sim_p, t_sim_p, y_inf_sim_p);

    fprintf('\n=== PARTE 1 - PUNTO 4: SIMULACIÓN EN SIMSCAPE CON TL081 ===\n');
    fprintf('Error máximo |y(Simscape) - y(FT)|: %.4e V (%.3f mV)\n', err_max_p4, err_max_p4*1e3);
    fprintf('Sobrepaso Simscape (PO):            %.2f %%  (FT: %.2f %%)\n', info_sim_p.Overshoot, info_real.Overshoot);
    fprintf('Tiempo de estab. Simscape (Ts):     %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim_p.SettlingTime, info_sim_p.SettlingTime*1e3, info_real.SettlingTime*1e3);
    fprintf('Tiempo de pico Simscape (Tp):       %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim_p.PeakTime, info_sim_p.PeakTime*1e3, info_real.PeakTime*1e3);
    fprintf('Valor final Simscape:               %.4f V  (FT: %.4f V)\n', y_inf_sim_p, y_inf_real);
    fprintf('Error estacionario Simscape (ess):  %.4f (%.2f %%)  (FT: %.2f %%)\n', ess_sim_p, ess_sim_p*100, ess_real*100);

    fig4 = figure('Name', 'Parte 1 - Punto 4: Superposición FT vs Simscape TL081', 'Position', [100, 100, 720, 420], 'Visible', vis_opt);
    plot(t_unif_p * 1e3, y_ft_p, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Modelo Lineal FT (T_{real})');
    hold on;
    plot(t_sim_p * 1e3, y_sim_p, 'r--', 'LineWidth', 1.4, 'DisplayName', 'Circuito Simscape (TL081)');
    grid on;
    title('Respuesta al escalón unitario: Modelo por FT vs. Simscape (TL081, k_p \approx 1.41)');
    xlabel('Tiempo (ms)');
    ylabel('Tensión de salida (V)');
    legend('Location', 'southeast');
    saveas(fig4, fullfile(fig_dir, 'punto4_simscape_vs_ft.png'));
    if ~mostrar_graficos, close(fig4); end
    close_system(mdl_p, 0);
else
    fprintf('\n[Aviso] No se encontró el modelo %s.slx en el directorio. Se omite simulación de Simscape.\n', mdl_p);
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

fig2a = figure('Name', 'Parte 2 - Punto 2.a: Región admisible en el plano s', 'Position', [100, 100, 700, 480], 'Visible', vis_opt);
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
if ~mostrar_graficos, close(fig2a); end

%% Punto 2.b: Centro de las asíntotas sigma_a en función de z
z_max_asintota = 312.766 - 80;

fprintf('\n=== PARTE 2 - PUNTO 2.b: ASÍNTOTAS DEL LUGAR DE LAS RAÍCES ===\n');
fprintf('Número de polos n = 3, ceros m = 1 => n - m = 2\n');
fprintf('Ángulos de asíntotas: phi = +-90° (estrictamente verticales)\n');
fprintf('Centro de asíntotas: sigma_a(z) = (z - 312.77) / 2\n');
fprintf('Para que sigma_a quede a la izquierda de -40 rad/s: z < %.2f rad/s\n', z_max_asintota);

%% Punto 2.c: Elección de z y Lugar de las Raíces para ajuste de kp con PI
z_lento = 50;
L_lento = ((s + z_lento) / s) * G;
z_pi = 120;
L_unit = ((s + z_pi) / s) * G;

% Gráfico comparativo z=50 vs z=120
fig_comp_z = figure('Name', 'Comparación de ubicación del cero z', 'Position', [100, 100, 950, 420], 'Visible', vis_opt);
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
if ~mostrar_graficos, close(fig_comp_z); end

% LGR detallado con z = 120 rad/s
fig_lgr = figure('Name', 'Parte 2 - Punto 2.c: Lugar de las Raíces - Controlador PI (z = 120 rad/s)', 'Position', [100, 100, 720, 480], 'Visible', vis_opt);
rlocus(L_unit);
hold on;
sgrid(0.69, []);
xline(-sigma_min, 'r--', 'LineWidth', 1.5, 'DisplayName', '\xi\omega_n \geq 40');
sigma_a = (z_pi - 312.766) / 2;
xline(sigma_a, 'm:', 'LineWidth', 1.5, 'DisplayName', sprintf('\\sigma_a = %.1f', sigma_a));
xlim([-250, 20]);
ylim([-160, 160]);
title(sprintf('Lugar de las Raíces con controlador PI (z = %d rad/s)', z_pi));
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;
legend('Location', 'northwest');
saveas(fig_lgr, fullfile(fig_dir, 'pi_punto2_lgr.png'));
if ~mostrar_graficos, close(fig_lgr); end

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

% Ajuste de ganancia para compensar el cero (mayor amortiguamiento):
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
fig_cero = figure('Name', 'Parte 2 - Punto 2.d: Efecto del Cero de Lazo Cerrado', 'Position', [100, 100, 720, 440], 'Visible', vis_opt);
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
yline(1.0, 'k:', 'HandleVisibility', 'off');
yline(1.05, 'm:', 'LineWidth', 1.1, 'DisplayName', 'Límite PO = 5%');
grid on;
title('Efecto del cero de lazo cerrado sobre el sobrepaso transitorio');
xlabel('Tiempo (ms)');
ylabel('Tensión de salida y(t) [V]');
legend('Location', 'southeast');
saveas(fig_cero, fullfile(fig_dir, 'pi_punto2_efecto_cero.png'));
if ~mostrar_graficos, close(fig_cero); end

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
fprintf('Sobrepaso efectivo (PO):        %.2f %%  (<= 5 %%)\n', info_com.Overshoot);
fprintf('Tiempo de estab. efectivo (Ts): %.4f s (%.2f ms)  (<= 0.10 s)\n', info_com.SettlingTime, info_com.SettlingTime*1e3);
fprintf('Error estacionario (ess):       %.4f  (= 0)\n', ess_com);

% Gráfico: Respuesta al escalón E24 vs Continuo
fig_step = figure('Name', 'Punto 3: Respuesta al escalón E24', 'Position', [100, 100, 720, 440], 'Visible', vis_opt);
t_sim_step = linspace(0, 0.12, 3000);
[y_aj, ~]  = step(T_aj, t_sim_step);
[y_c, t_out] = step(T_com, t_sim_step);

plot(t_out*1e3, y_aj, 'b--', 'LineWidth', 1.6, ...
    'DisplayName', sprintf('Continuo k_p = %.2f (PO = %.2f %%, T_s = %.1f ms)', kp_aj, info_aj.Overshoot, info_aj.SettlingTime*1e3));
hold on;
plot(t_out*1e3, y_c, 'k-', 'LineWidth', 2.0, ...
    'DisplayName', sprintf('E24: R_{PI1}=120k, R_{PI2}=82k (PO = %.2f %%, T_s = %.1f ms)', info_com.Overshoot, info_com.SettlingTime*1e3));
yline(1.0, 'k:', 'HandleVisibility', 'off');
yline(1.02, 'g:', 'LineWidth', 1.0, 'DisplayName', 'Banda \\pm 2%%');
yline(0.98, 'g:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
xline(info_com.SettlingTime*1e3, 'r:', 'LineWidth', 1.2, ...
    'DisplayName', sprintf('T_s = %.1f ms', info_com.SettlingTime*1e3));
grid on;
title('Respuesta al escalón: Controlador continuo vs Implementación E24');
xlabel('Tiempo (ms)');
ylabel('Tensión de salida y(t) [V]');
legend('Location', 'southeast');
saveas(fig_step, fullfile(fig_dir, 'pi_punto3_escalon_e24.png'));
if ~mostrar_graficos, close(fig_step); end

%% Punto 4: Simulación circuital en Simscape con TL081 (Fig. 5)
mdl_pi = 'TP_Lab2_PI_TL081';
if exist([mdl_pi '.slx'], 'file') || exist(fullfile(script_dir, [mdl_pi '.slx']), 'file')
    load_system(fullfile(script_dir, [mdl_pi '.slx']));
    set_param(mdl_pi, 'StopTime', '0.12');
    set_param(mdl_pi, 'SimscapeLogLimitData', 'off');
    set_param(mdl_pi, 'LimitDataPoints', 'off');
    
    out_sim_pi = sim(mdl_pi);
    t_sim_pi   = out_sim_pi.simlog.Voltage_Sensor.V.series.time;
    y_sim_pi   = out_sim_pi.simlog.Voltage_Sensor.V.series.values;
    vo1_sim    = out_sim_pi.simlog.Sensor_Vo1.V.series.values;
    vpi_sim    = out_sim_pi.simlog.Sensor_Vpi.V.series.values;

    t_unif_pi = linspace(0, max(t_sim_pi), 5000)';
    y_ft_pi   = step(T_com, t_unif_pi);

    [t_sim_pi_u, idx_pi_u] = unique(t_sim_pi);
    y_sim_pi_interp        = interp1(t_sim_pi_u, y_sim_pi(idx_pi_u), t_unif_pi, 'pchip');
    err_max_pi             = max(abs(y_sim_pi_interp - y_ft_pi));

    y_inf_sim_pi = y_sim_pi(end);
    ess_sim_pi   = 1 - y_inf_sim_pi;
    info_sim_pi  = stepinfo(y_sim_pi, t_sim_pi, y_inf_sim_pi);

    fprintf('\n=== PARTE 2 - PUNTO 4.a: SIMULACIÓN EN SIMSCAPE CON TL081 (FIG. 5) ===\n');
    fprintf('Error máximo |y(Simscape) - y(FT)|: %.4e V (%.3f mV)\n', err_max_pi, err_max_pi*1e3);
    fprintf('Sobrepaso Simscape (PO):            %.2f %%  (FT: %.2f %%)\n', info_sim_pi.Overshoot, info_com.Overshoot);
    fprintf('Tiempo de estab. Simscape (Ts):     %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim_pi.SettlingTime, info_sim_pi.SettlingTime*1e3, info_com.SettlingTime*1e3);
    fprintf('Tiempo de pico Simscape (Tp):       %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim_pi.PeakTime, info_sim_pi.PeakTime*1e3, info_com.PeakTime*1e3);
    fprintf('Valor final Simscape:               %.4f V  (FT: %.4f V)\n', y_inf_sim_pi, y_inf_com);
    fprintf('Error estacionario Simscape (ess):  %.4f (%.2f %%)  (FT: %.2f %%)\n', ess_sim_pi, ess_sim_pi*100, ess_com*100);

    fig4a = figure('Name', 'Parte 2 - Punto 4.a: Superposición FT vs Simscape TL081 (PI)', 'Position', [100, 100, 720, 420], 'Visible', vis_opt);
    plot(t_unif_pi * 1e3, y_ft_pi, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Modelo Lineal FT (T_{com})');
    hold on;
    plot(t_sim_pi * 1e3, y_sim_pi, 'r--', 'LineWidth', 1.4, 'DisplayName', 'Circuito Simscape (TL081)');
    yline(1.0, 'k:', 'HandleVisibility', 'off');
    yline(1.02, 'g:', 'LineWidth', 0.8, 'DisplayName', 'Banda \\pm 2%%');
    yline(0.98, 'g:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
    grid on;
    title('Respuesta al escalón unitario: Modelo por FT vs. Simscape (Controlador PI, TL081)');
    xlabel('Tiempo (ms)');
    ylabel('Tensión de salida y(t) [V]');
    legend('Location', 'southeast');
    saveas(fig4a, fullfile(fig_dir, 'pi_punto4a_simscape_vs_ft.png'));
    if ~mostrar_graficos, close(fig4a); end

    % 4.b: Gráfico de tensiones internas y(t), vo1(t) y vPI(t)
    fig4b = figure('Name', 'Parte 2 - Punto 4.b: Tensiones Internas Simscape (PI)', 'Position', [100, 100, 750, 520], 'Visible', vis_opt);
    subplot(2, 1, 1);
    plot(t_sim_pi * 1e3, y_sim_pi, 'b-', 'LineWidth', 1.6);
    grid on;
    title('Tensión de salida del sistema y(t)');
    xlabel('Tiempo (ms)');
    ylabel('y(t) [V]');
    yline(1.0, 'k:', 'HandleVisibility', 'off');

    subplot(2, 1, 2);
    plot(t_sim_pi * 1e3, vo1_sim, 'm--', 'LineWidth', 1.4, 'DisplayName', 'v_{o1}(t) (Salida etapa PI inversora)');
    hold on;
    plot(t_sim_pi * 1e3, vpi_sim, 'r-', 'LineWidth', 1.5, 'DisplayName', 'v_{PI}(t) (Salida inversor unitario)');
    grid on;
    title('Tensiones en el controlador PI');
    xlabel('Tiempo (ms)');
    ylabel('Tensión [V]');
    legend('Location', 'southeast');

    saveas(fig4b, fullfile(fig_dir, 'pi_punto4b_tensiones_internas.png'));
    if ~mostrar_graficos, close(fig4b); end

    % Mediciones experimentales sobre la simulación (Punto 4.b)
    [vpi_max, idx_vpi_max] = max(vpi_sim);
    [vo1_min, idx_vo1_min] = min(vo1_sim);
    fprintf('\n=== PARTE 2 - PUNTO 4.b: TENSIONES MEDIDAS EN EL CONTROLADOR PI ===\n');
    idx_0p = find(t_sim_pi >= 20e-6, 1);   % justo después del salto (el aporte integral en 20 us es despreciable)
    fprintf('Salto inicial medido vo1(0+): %.4f V (en t = %.0f us)\n', vo1_sim(idx_0p), t_sim_pi(idx_0p)*1e6);
    fprintf('Tensión mínima medida vo1:    %.4f V (en t = %.2f ms)\n', vo1_min, t_sim_pi(idx_vo1_min)*1e3);
    fprintf('Pico máximo medido vPI:       %.4f V (en t = %.2f ms)\n', vpi_max, t_sim_pi(idx_vpi_max)*1e3);
    fprintf('Valor final medido vPI(inf):  %.4f V\n', vpi_sim(end));

    %% Punto 4.c: Aumento de la amplitud del escalón hasta saturar vPI (±8.5 V)
    % Mientras el circuito es lineal, vPI escala con la amplitud: el pico llega a
    % 8.5 V para A_lim = 8.5 / max(vPI con escalón de 1 V).
    A_lim  = 8.5 / vpi_max;
    A_list = [1, A_lim, 8];
    blk_step = find_system(mdl_pi, 'BlockType', 'Step');
    blk_step = blk_step{1};
    res_4c = struct('A', {}, 't', {}, 'y', {}, 'vpi', {}, 'info', {});
    for k = 1:numel(A_list)
        set_param(blk_step, 'After', num2str(A_list(k), 8));
        out_k = sim(mdl_pi);
        res_4c(k).A    = A_list(k);
        res_4c(k).t    = out_k.simlog.Voltage_Sensor.V.series.time;
        res_4c(k).y    = out_k.simlog.Voltage_Sensor.V.series.values;
        res_4c(k).vpi  = out_k.simlog.Sensor_Vpi.V.series.values;
        res_4c(k).info = stepinfo(res_4c(k).y, res_4c(k).t, A_list(k));
    end
    set_param(blk_step, 'After', '1');   % se restituye el escalón unitario

    fprintf('\n=== PARTE 2 - PUNTO 4.c: AMPLITUD DEL ESCALÓN Y SATURACIÓN DE vPI ===\n');
    fprintf('Amplitud límite (pico de vPI = 8.5 V): A_lim = %.2f V\n', A_lim);
    fprintf('%-10s | %-12s | %-9s | %-10s\n', 'A [V]', 'max vPI [V]', 'PO [%]', 'Ts [ms]');
    for k = 1:numel(res_4c)
        fprintf('%-10.2f | %-12.2f | %-9.2f | %-10.1f\n', res_4c(k).A, max(res_4c(k).vpi), ...
            res_4c(k).info.Overshoot, res_4c(k).info.SettlingTime*1e3);
    end
    fprintf('Modelo FT (cualquier A):             PO = %.2f %%, Ts = %.1f ms\n', info_com.Overshoot, info_com.SettlingTime*1e3);

    fig4c = figure('Name', 'Parte 2 - Punto 4.c: Saturación de vPI', 'Position', [100, 100, 750, 560], 'Visible', vis_opt);
    estilos = {'b-', 'g--', 'r-'};
    subplot(2, 1, 1);
    plot(t_unif_pi*1e3, y_ft_pi, 'k:', 'LineWidth', 2.0, 'DisplayName', 'Modelo FT');
    hold on;
    for k = 1:numel(res_4c)
        plot(res_4c(k).t*1e3, res_4c(k).y / res_4c(k).A, estilos{k}, 'LineWidth', 1.4, ...
            'DisplayName', sprintf('Simscape, A = %.2f V', res_4c(k).A));
    end
    grid on; xlim([0 120]);
    xlabel('Tiempo (ms)'); ylabel('y(t) / A');
    title('Salida normalizada por la amplitud del escalón');
    legend('Location', 'southeast');
    subplot(2, 1, 2);
    hold on;
    for k = 1:numel(res_4c)
        plot(res_4c(k).t*1e3, res_4c(k).vpi, estilos{k}, 'LineWidth', 1.4, ...
            'DisplayName', sprintf('A = %.2f V', res_4c(k).A));
    end
    yline(8.5, 'm:', 'LineWidth', 1.2, 'DisplayName', 'Saturación +8.5 V');
    grid on; box on; xlim([0 120]); ylim([0 9.5]);
    xlabel('Tiempo (ms)'); ylabel('v_{PI}(t) [V]');
    title('Tensión de salida del controlador v_{PI}');
    legend('Location', 'southeast');
    saveas(fig4c, fullfile(fig_dir, 'pi_punto4c_saturacion.png'));
    if ~mostrar_graficos, close(fig4c); end

    close_system(mdl_pi, 0);
else
    fprintf('\n[Aviso] No se encontró el modelo %s.slx en el directorio.\n', mdl_pi);
end

%% =========================================================================
%% PUNTO 5: COMPARACIÓN FINAL (CONTROL P vs CONTROL PI EN SIMSCAPE)
%% =========================================================================
if exist('y_sim_p', 'var') && exist('y_sim_pi', 'var')
    fig5 = figure('Name', 'Punto 5: Comparación Simscape Control P vs PI', 'Position', [100, 100, 750, 440], 'Visible', vis_opt);
    plot(t_sim_p * 1e3, y_sim_p, 'r--', 'LineWidth', 1.6, ...
        'DisplayName', sprintf('Control P (k_p = %.2f)', kp_real));
    hold on;
    plot(t_sim_pi * 1e3, y_sim_pi, 'b-', 'LineWidth', 1.8, ...
        'DisplayName', 'Control PI');

    yline(1.0, 'k:', 'LineWidth', 1.0, 'DisplayName', 'Referencia r(t) = 1 V');

    grid on;
    xlim([0, 120]);
    ylim([0, 1.15]);
    title('Respuesta al escalón unitario en Simscape (TL081): control P y PI');
    xlabel('Tiempo (ms)');
    ylabel('Tensión de salida y(t) [V]');
    legend('Location', 'southeast', 'FontSize', 9);

    saveas(fig5, fullfile(fig_dir, 'punto5_comparacion_p_vs_pi.png'));
    if ~mostrar_graficos, close(fig5); end

    fprintf('\n=========================================================================\n');
    fprintf('=== TABLA COMPARATIVA DE DESEMPEÑO: CONTROL P vs CONTROL PI (SIMSCAPE) ===\n');
    fprintf('=========================================================================\n');
    fprintf('%-25s | %-18s | %-18s\n', 'Parámetro', 'Control P (TL081)', 'Control PI (TL081)');
    fprintf('-------------------------------------------------------------------------\n');
    fprintf('%-25s | %15.2f %% | %15.2f %%\n', 'Sobrepaso (PO)', info_sim_p.Overshoot, info_sim_pi.Overshoot);
    fprintf('%-25s | %15.2f ms | %15.2f ms\n', 'Tiempo de estab. (Ts 2%)', info_sim_p.SettlingTime*1e3, info_sim_pi.SettlingTime*1e3);
    fprintf('%-25s | %15.2f ms | %15.2f ms\n', 'Tiempo de pico (Tp)', info_sim_p.PeakTime*1e3, info_sim_pi.PeakTime*1e3);
    fprintf('%-25s | %16.4f V | %16.4f V\n', 'Valor final y(inf)', y_sim_p(end), y_sim_pi(end));
    fprintf('%-25s | %15.2f %% | %15.2f %%\n', 'Error estacionario (ess)', abs(ess_sim_p)*100, abs(ess_sim_pi)*100);
    fprintf('=========================================================================\n');
end

disp('=========================================================================');
disp('=== EJECUCIÓN COMPLETA DEL TP2 FINALIZADA EXITOSAMENTE ===');
disp('=========================================================================');
