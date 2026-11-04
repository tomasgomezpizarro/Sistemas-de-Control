%% Trabajo de Laboratorio Integrador - Sistemas de Control
% TP de Laboratorio 2: Desarrollo de Controladores (P y PI)
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
%% PRIMERA PARTE: CONTROL PROPORCIONAL
%% =========================================================================

%% Parámetros de la planta (Figura 1)
R1 = 100e3;          % 100 kOhm
C1 = 0.1e-6;         % 0.1 uF
tau1 = R1 * C1;      % 0.01 s

R2 = 47e3;           % 47 kOhm
C2 = 0.1e-6;         % 0.1 uF
tau2 = R2 * C2;      % 0.0047 s

s = tf('s');
G = 1 / ((tau1 * s + 1) * (tau2 * s + 1));

disp('=== Función de transferencia de la planta G(s) (sin ganancia kp) ===');
G

%% Punto 1: Lugar de las Raíces para ajuste de kp
% Graficamos el LGR de G(s) con la cota de amortiguamiento xi = 0.69 (PO <= 5%)
figure('Name', 'Lugar de las Raíces - Planta G(s)');
rlocus(G);
sgrid(0.69, []);
title('Lugar de las Raíces de G(s)');
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;

%% Punto 2: Verificación de la respuesta al escalón en lazo cerrado
kp = 1.41;
T = feedback(kp * G, 1);

info  = stepinfo(T);
y_inf = dcgain(T);
ess   = 1 - y_inf;

fprintf('\n=== PUNTO 2: MÉTRICAS DE LA RESPUESTA AL ESCALÓN (kp = %.2f) ===\n', kp);
fprintf('Sobrepaso (PO):                 %.4f %%  (Especificación: <= 5 %%)\n', info.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)  (Especificación: <= 0.10 s)\n', info.SettlingTime, info.SettlingTime*1e3);
fprintf('Tiempo de pico (Tp):            %.4f s (%.2f ms)\n', info.PeakTime, info.PeakTime*1e3);
fprintf('Valor en estado estacionario:   %.4f V\n', y_inf);
fprintf('Error estacionario (ess):       %.4f (%.2f %%)  (Especificación: = 0)\n', ess, ess*100);

% Gráfico de la respuesta al escalón
fig2 = figure('Name', 'Punto 2: Respuesta al escalón (kp = 1.41)');
step(T);
grid on;
title(sprintf('Respuesta al escalón en lazo cerrado (k_p = %.2f)', kp));
xlabel('Tiempo (s)');
ylabel('Amplitud (V)');
saveas(fig2, fullfile(fig_dir, 'punto2_escalon.png'));

%% Punto 3: Elección de valores comerciales (serie E24) para R7 y R9
% Relación teórica de la etapa de ganancia no inversora:
% kp = 1 + R7 / R9  =>  R7 / R9 = kp - 1 = 0.41
%
% A partir de la búsqueda exhaustiva en la serie E24:
% Se eligen R7 = 1.6 kOhm y R9 = 3.9 kOhm (relación 1.6 / 3.9 = 0.410256)
R7 = 1.6e3;    % 1.6 kOhm (E24)
R9 = 3.9e3;    % 3.9 kOhm (E24)
kp_real = 1 + R7 / R9;

T_real = feedback(kp_real * G, 1);
info_real  = stepinfo(T_real);
y_inf_real = dcgain(T_real);
ess_real   = 1 - y_inf_real;

fprintf('\n=== PUNTO 3: VALORES COMERCIALES E24 (R7 = %.1f kOhm, R9 = %.1f kOhm) ===\n', R7*1e-3, R9*1e-3);
fprintf('kp obtenido con E24:            %.6f\n', kp_real);
fprintf('Sobrepaso (PO):                 %.4f %%  (Especificación: <= 5 %%)\n', info_real.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)  (Especificación: <= 0.10 s)\n', info_real.SettlingTime, info_real.SettlingTime*1e3);
fprintf('Tiempo de pico (Tp):            %.4f s (%.2f ms)\n', info_real.PeakTime, info_real.PeakTime*1e3);
fprintf('Valor en estado estacionario:   %.4f V\n', y_inf_real);
fprintf('Error estacionario (ess):       %.4f (%.2f %%)  (Especificación: = 0)\n', ess_real, ess_real*100);


%% Punto 4: Simulación circuital en Simscape con op-amps TL081 (Fig. 2)
% Se carga el modelo circuital con componentes comerciales (R7=1.6k, R9=3.9k)
% y modelos reales Band-Limited Op-Amp para los operacionales TL081.
mdl = 'TP_Lab2_TL081';
load_system(fullfile(script_dir, [mdl '.slx']));

out_sim = sim(mdl);
t_sim   = out_sim.simlog.Voltage_Sensor.V.series.time;
y_sim   = out_sim.simlog.Voltage_Sensor.V.series.values;

% Grilla temporal uniforme para evaluar la función de transferencia T_real
t_unif = linspace(0, max(t_sim), 5000)';
y_ft   = step(T_real, t_unif);

% Interpolación para calcular el error máximo instantáneo
[t_sim_u, idx_u] = unique(t_sim);
y_sim_interp     = interp1(t_sim_u, y_sim(idx_u), t_unif, 'pchip');
err_max_p4       = max(abs(y_sim_interp - y_ft));

% Medición de parámetros sobre la simulación en Simscape
y_inf_sim = y_sim(end);
ess_sim   = 1 - y_inf_sim;
info_sim  = stepinfo(y_sim, t_sim, y_inf_sim);

fprintf('\n=== PUNTO 4: SIMULACIÓN EN SIMSCAPE CON TL081 (R7 = 1.6k, R9 = 3.9k) ===\n');
fprintf('Error máximo |y(Simscape) - y(FT)|: %.4e V (%.3f mV)\n', err_max_p4, err_max_p4*1e3);
fprintf('Sobrepaso Simscape (PO):            %.2f %%  (FT: %.2f %%)\n', info_sim.Overshoot, info_real.Overshoot);
fprintf('Tiempo de estab. Simscape (Ts):     %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim.SettlingTime, info_sim.SettlingTime*1e3, info_real.SettlingTime*1e3);
fprintf('Tiempo de pico Simscape (Tp):       %.4f s (%.2f ms)  (FT: %.2f ms)\n', info_sim.PeakTime, info_sim.PeakTime*1e3, info_real.PeakTime*1e3);
fprintf('Valor final Simscape:               %.4f V  (FT: %.4f V)\n', y_inf_sim, y_inf_real);
fprintf('Error estacionario Simscape (ess):  %.4f (%.2f %%)  (FT: %.2f %%)\n', ess_sim, ess_sim*100, ess_real*100);

% Superposición gráfica de la respuesta al escalón: FT vs Simscape
fig4 = figure('Name', 'Punto 4: Superposición FT vs Simscape TL081', 'Position', [100, 100, 720, 420]);
plot(t_unif * 1e3, y_ft, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Modelo Lineal FT (T_{real})');
hold on;
plot(t_sim * 1e3, y_sim, 'r--', 'LineWidth', 1.4, 'DisplayName', 'Circuito Simscape (TL081)');
grid on;
title('Respuesta al escalón unitario: Modelo por FT vs. Simscape (TL081, k_p \approx 1.41)');
xlabel('Tiempo (ms)');
ylabel('Tensión de salida (V)');
legend('Location', 'southeast');
saveas(fig4, fullfile(fig_dir, 'punto4_simscape_vs_ft.png'));
close(fig4);
close_system(mdl);
