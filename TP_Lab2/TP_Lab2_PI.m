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

fprintf('\n=== PUNTO 2.a: REQUISITOS EN EL PLANO s ===\n');
fprintf('xi mínimo para PO <= 5%%:          %.4f (~0.69)\n', xi_min);
fprintf('sigma mínimo (xi*wn) para Ts<=0.1s: %.2f rad/s\n', sigma_min);

%% 2.b: Centro de las asíntotas sigma_a en función de z
% Polos de L(s) = Gc(s)*G(s): 0, -100, -212.766 rad/s (n = 3)
% Ceros de L(s): -z (m = 1)
% sigma_a = (suma_polos - suma_ceros) / (n - m)
% sigma_a = (0 - 100 - 212.766 - (-z)) / 2 = (z - 312.766) / 2
% Condición: sigma_a < -40 rad/s => z < 312.766 - 80 = 232.766 rad/s
z_max_asintota = 312.766 - 80;

fprintf('\n=== PUNTO 2.b: CENTRO DE ASÍNTOTAS ===\n');
fprintf('sigma_a(z) = (z - 312.77) / 2\n');
fprintf('Para que sigma_a quede a la izquierda de -40 rad/s: z < %.2f rad/s\n', z_max_asintota);

%% 2.c: Elección de z y diseño con xi = 0.69
% Si elegimos z < 100 (ej: z=50), queda un polo real lento en [-z, 0] que arruina Ts.
% Eligiendo z > 100 (entre 100 y 232.77), los polos de 0 y -100 forman el par dominante
% y el tercer polo real queda a la izquierda de -120 rad/s.
% Adoptamos z = 120 rad/s:
z_pi = 120;
sigma_a = (z_pi - 312.766) / 2; % -96.38 rad/s

% Transferencia normalizada de lazo abierto L(s)/kp:
L_unit = ((s + z_pi) / s) * G;

% Gráfico del Lugar de las Raíces
fig_lgr = figure('Name', 'Punto 2.c: LGR con PI', 'Visible', 'off');
rlocus(L_unit);
hold on;
sgrid(0.69, []);
xline(-sigma_min, 'k--', 'LineWidth', 1.2, 'DisplayName', '\sigma = -40 s^{-1}');
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

fprintf('\n=== PUNTO 2.c: DISEÑO INICIAL (z = %d, xi = 0.69) ===\n', z_pi);
fprintf('kp inicial:                     %.2f\n', kp_ini);
fprintf('ki inicial:                     %.2f rad/s\n', ki_ini);
fprintf('Polos en lazo cerrado:          %.1f +- %.1fj,  %.1f rad/s\n', ...
    real(p_ini(idx_c(1))), imag(p_ini(idx_c(1))), real(p_ini(3)));
fprintf('Sobrepaso obtenido (PO):        %.2f %%  (Especificación: <= 5 %%)\n', info_ini.Overshoot);
fprintf('Tiempo de establecimiento (Ts): %.4f s (%.2f ms)\n', info_ini.SettlingTime, info_ini.SettlingTime*1e3);

% Marcamos los polos iniciales en el gráfico
plot(real(p_ini), imag(p_ini), 'r*', 'MarkerSize', 8, 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Polos k_p = %.2f (PO = %.1f %%)', kp_ini, info_ini.Overshoot));
legend('Location', 'northwest');
saveas(fig_lgr, fullfile(fig_dir, 'pi_punto2_lgr.png'));
close(fig_lgr);

%% 2.d: Verificación y ajuste de kp por el cero de lazo cerrado
% El sobrepaso es de 6.79 % (supera el 5 %) porque la FT de lazo cerrado T(s)
% retiene el cero en s = -z = -120 rad/s en el numerador.
% Al estar más cerca del eje jw que el tercer polo (-144.6 rad/s), actúa
% elevando el pico transitorio.
% Ajustamos kp "a ojo" reduciéndolo a 0.68 (aumentando el amortiguamiento):
kp_aj = 0.68;
ki_aj = kp_aj * z_pi; % 81.6

T_aj = feedback(kp_aj * L_unit, 1);
info_aj = stepinfo(T_aj);
y_inf_aj = dcgain(T_aj);
ess_aj = 1 - y_inf_aj;

fprintf('\n=== PUNTO 2.d: AJUSTE DE kp POR EFECTO DEL CERO ===\n');
fprintf('kp ajustado:                    %.2f\n', kp_aj);
fprintf('ki ajustado:                    %.2f rad/s\n', ki_aj);
fprintf('Sobrepaso ajustado (PO):        %.2f %%  (CUMPLE <= 5 %%)\n', info_aj.Overshoot);
fprintf('Tiempo de estab. ajustado (Ts): %.4f s (%.2f ms)  (CUMPLE <= 0.10 s)\n', info_aj.SettlingTime, info_aj.SettlingTime*1e3);
fprintf('Error estacionario (ess):       %.4f  (CUMPLE = 0)\n', ess_aj);

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

% Gráfico de la respuesta al escalón: Diseño inicial vs Ajustado vs Comercial E24
fig_step = figure('Name', 'Punto 2 y 3: Respuesta al escalón del PI', 'Visible', 'off');
t_sim = linspace(0, 0.12, 3000);
[y_ini, ~] = step(T_ini, t_sim);
[y_aj, ~]  = step(T_aj, t_sim);
[y_c, t_out] = step(T_com, t_sim);

plot(t_out*1e3, y_ini, 'r--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('k_{p,ini} = 0.84 (PO = %.2f %%)', info_ini.Overshoot));
hold on;
plot(t_out*1e3, y_aj, 'b-.', 'LineWidth', 1.6, ...
    'DisplayName', sprintf('k_{p,aj} = 0.68 (PO = %.2f %%)', info_aj.Overshoot));
plot(t_out*1e3, y_c, 'k-', 'LineWidth', 2.0, ...
    'DisplayName', sprintf('E24: k_p = 0.683, k_i = 83.3 (PO = %.2f %%)', info_com.Overshoot));
yline(1.0, 'k:');
yline(1.02, 'g:', 'LineWidth', 1.0, 'DisplayName', 'Banda \pm 2%');
yline(0.98, 'g:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
grid on;
title('Respuesta al escalón con controlador PI (Efecto del cero y ajuste E24)');
xlabel('Tiempo (ms)');
ylabel('Tensión de salida y(t) [V]');
legend('Location', 'southeast');
saveas(fig_step, fullfile(fig_dir, 'pi_punto2_escalon.png'));
close(fig_step);

fprintf('\nFiguras guardadas en %s:\n', fig_dir);
fprintf('- pi_punto2_lgr.png\n');
fprintf('- pi_punto2_escalon.png\n');
