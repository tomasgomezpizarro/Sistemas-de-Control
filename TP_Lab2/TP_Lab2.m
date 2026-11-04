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
fprintf('Sobrepaso (PO):                 %.2f %%  (Especificación: <= 5 %%)\n', info.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)  (Especificación: <= 0.10 s)\n', info.SettlingTime, info.SettlingTime*1e3);
fprintf('Tiempo de pico (Tp):            %.4f s (%.2f ms)\n', info.PeakTime, info.PeakTime*1e3);
fprintf('Valor en estado estacionario:   %.4f V\n', y_inf);
fprintf('Error estacionario (ess):       %.4f (%.2f %%)  (Especificación: = 0)\n', ess, ess*100);

% Gráfico de la respuesta al escalón
fig2 = figure('Name', 'Punto 2: Respuesta al escalón (kp = 1.4)');
step(T);
grid on;
title(sprintf('Respuesta al escalón en lazo cerrado (k_p = %.2f)', kp));
xlabel('Tiempo (s)');
ylabel('Amplitud (V)');
saveas(fig2, fullfile(fig_dir, 'punto2_escalon.png'));
