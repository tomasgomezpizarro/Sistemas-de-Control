%% Trabajo de Laboratorio Integrador - Sistemas de Control
% TP de Laboratorio 2: Desarrollo de Controladores (P y PI)
% Script de simulación y cálculo
clear; clc; close all;

%% Configuración de rutas
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end
fig_dir = fullfile(script_dir, 'figuras');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% =========================================================================
%% PARTE 1: CONTROL PROPORCIONAL
%% =========================================================================

%% 1. Parámetros de la planta (Figura 1)
R1 = 100e3;          % 100 kOhm
C1 = 0.1e-6;         % 0.1 uF
tau1 = R1 * C1;      % 0.01 s -> polo en -100 rad/s

R2 = 47e3;           % 47 kOhm
C2 = 0.1e-6;         % 0.1 uF
tau2 = R2 * C2;      % 0.0047 s -> polo en -212.77 rad/s

s = tf('s');
Sys1 = 1 / (tau1 * s + 1);
Sys2_sin_kp = 1 / (tau2 * s + 1);

% Función de transferencia de la planta sin ganancia kp
G = Sys1 * Sys2_sin_kp;
G = minreal(G);

fprintf('=== FUNCIÓN DE TRANSFERENCIA DE LA PLANTA G(s) (sin kp) ===\n');
G

%% 2. Punto 1: Especificaciones y Lugar Geométrico de las Raíces (LGR)
% Especificaciones:
% - PO <= 5 %
% - Ts <= 0.10 s (criterio del 2%)
% - ess = 0 para escalón unitario

% 2.1 Amortiguamiento mínimo para PO <= 5%:
% PO = 100 * exp(-pi*xi / sqrt(1 - xi^2)) <= 5
PO_max = 5;
xi_min = -log(PO_max / 100) / sqrt(pi^2 + (log(PO_max / 100))^2);

% 2.2 Requisito de Ts <= 0.10 s:
% Ts ~ 4 / (xi * wn) <= 0.10 s -> xi * wn >= 40 rad/s -> Re(s) <= -40 rad/s
Ts_max = 0.10;
sigma_min = 4 / Ts_max; % 40 rad/s

% 2.3 Análisis de ramas del LGR:
% Polos de lazo abierto:
polos_la = pole(G);
p1 = polos_la(1); % -100
p2 = polos_la(2); % -212.766
sigma_a = (p1 + p2) / 2; % Punto de ruptura = -156.383 rad/s

% Como sigma_a = -156.38 rad/s < -40 rad/s, cualquier polo complejo
% cumple holgadamente Ts <= 0.10 s (Ts ~ 4/156.38 ~ 0.0256 s).

% Para xi = xi_min (~0.6901):
% xi * wn = |sigma_a| = 156.383 rad/s
% wn_deseado = |sigma_a| / xi_min
wn_deseado = abs(sigma_a) / xi_min;
wd_deseado = wn_deseado * sqrt(1 - xi_min^2);
polo_deseado = sigma_a + 1j * wd_deseado;

% Polinomio característico: s^2 + (1/tau1 + 1/tau2)*s + (1 + kp)/(tau1*tau2) = 0
% wn^2 = (1 + kp) / (tau1 * tau2) -> kp = wn^2 * tau1 * tau2 - 1
kp_teor = (wn_deseado^2) * (tau1 * tau2) - 1;

fprintf('=== PUNTO 1: DISEÑO POR LUGAR DE LAS RAÍCES ===\n');
fprintf('xi mínimo para PO <= 5%%: %.4f\n', xi_min);
fprintf('sigma mínimo para Ts <= 0.10 s: %.2f rad/s\n', sigma_min);
fprintf('Punto de ruptura del LGR: sigma = %.2f rad/s\n', sigma_a);
fprintf('Polo deseado en lazo cerrado: %.2f + %.2fj rad/s\n', real(polo_deseado), imag(polo_deseado));
fprintf('kp teórico para xi = %.4f: %.4f\n\n', xi_min, kp_teor);

% Gráfico del Lugar de las Raíces
fig1 = figure('Position', [100, 100, 750, 500]);
rlocus(G);
hold on;
sgrid(xi_min, []);
plot(real(polo_deseado), imag(polo_deseado), 'r*', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', sprintf('Polo con kp = %.2f (\\xi = %.2f)', kp_teor, xi_min));
plot(real(polo_deseado), -imag(polo_deseado), 'r*', 'MarkerSize', 10, 'LineWidth', 2, ...
    'HandleVisibility', 'off');
xline(-sigma_min, 'k--', 'LineWidth', 1.2, 'DisplayName', sprintf('Límite Ts = 0.10s (\\sigma = -%d)', sigma_min));
title('Lugar de las Raíces de G(s) y punto de operación de kp');
xlabel('Eje Real (1/s)');
ylabel('Eje Imaginario (rad/s)');
legend('Location', 'best');
grid on;
xlim([-300, 50]);
ylim([-250, 250]);

saveas(fig1, fullfile(fig_dir, 'punto1_lgr.png'));
close(fig1);
fprintf('Figura guardada: %s\n', fullfile(fig_dir, 'punto1_lgr.png'));
