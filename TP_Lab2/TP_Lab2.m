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

disp('=== FUNCIÓN DE TRANSFERENCIA DE LA PLANTA G(s) (sin ganancia kp) ===');
G

%% Punto 1: Establecer kp mediante el Lugar de las Raíces
% Especificaciones en lazo cerrado:
% - PO <= 5 % (requiere xi >= 0.69)
% - Ts <= 0.10 s
% - ess = 0 para escalón unitario (no puede cumplirse por ser sistema Tipo 0)

fig1 = figure('Name', 'Punto 1: Lugar de las Raíces');
rlocus(G);
hold on;
sgrid(0.69, []); % Línea de amortiguamiento xi = 0.69 (PO = 5%)
title('Lugar de las Raíces de G(s) y ajuste de k_p');
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
grid on;

% Selección interactiva con el mouse sobre la rama en la intersección con xi = 0.69:
% [kp, polos_cl] = rlocfind(G);

% Valor obtenido a partir del Lugar de las Raíces para xi = 0.69:
kp = 1.41;

fprintf('Valor de kp establecido mediante el LGR: %.2f\n', kp);

% Marcamos el punto de operación elegido sobre el LGR
[~, polos_cl] = rlocfind(G, kp); % Evalúa los polos para la ganancia kp
plot(real(polos_cl), imag(polos_cl), 'r*', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', sprintf('k_p = %.2f (\\xi = 0.69)', kp));
legend('Location', 'best');

saveas(fig1, fullfile(fig_dir, 'punto1_lgr.png'));
