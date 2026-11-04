%% Trabajo de Laboratorio Integrador - Sistemas de Control
% TP de Laboratorio 2: Desarrollo de Controladores (P y PI)
clear; clc; close all;

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
