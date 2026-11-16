%% Proyecto parcial 2 - Sistemas de Control
% Variante 4: Posición de un motor de CC (realimentación de estados)
% Autores: Tomás Gómez Pizarro - Mikael Rodríguez
clear; clc; close all;
format shortG   % muestra cada número con su escala (sin factor común)

%% Rutas
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end
fig_dir = fullfile(script_dir, 'figuras');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end
% Figuras con fondo claro, independiente del tema de MATLAB (igual que en el Lab 3)
s_cfg = settings;
s_cfg.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'light';

%% =========================================================================
%% PUNTO 1: MODELO EN ESPACIO DE ESTADOS
%% =========================================================================
% Parámetros del motor
J = 5e-6;     % momento de inercia del rotor y la carga [kg.m^2]
b = 4e-6;     % coeficiente de fricción viscosa [N.m.s]
K = 0.03;     % constante de torque = constante de fem [N.m/A] = [V.s/rad]
R = 3;        % resistencia de armadura [Ohm]
L = 0.4e-3;   % inductancia de armadura [H]

% Estados:  x1 = theta   posición angular del eje [rad]
%           x2 = omega   velocidad angular del eje [rad/s]
%           x3 = i       corriente de armadura [A]
% Entrada:  u = V        tensión de armadura [V]
% Salida:   y = theta
%
%   x1' = x2
%   x2' = -(b/J) x2 + (K/J) x3
%   x3' = -(K/L) x2 - (R/L) x3 + (1/L) V
A = [0   1     0;
     0  -b/J   K/J;
     0  -K/L  -R/L];
B = [0; 0; 1/L];
C = [1 0 0];
D = 0;

planta = ss(A, B, C, D);
planta.StateName  = {'theta', 'omega', 'i'};
planta.InputName  = 'V';
planta.OutputName = 'theta';

disp('=== Punto 1: modelo en espacio de estados ===');
disp('A ='); disp(A);
disp('B ='); disp(B);
disp('C ='); disp(C);
disp('D ='); disp(D);

%% =========================================================================
%% PUNTO 2: ANÁLISIS DE LA PLANTA
%% =========================================================================
disp('=== Punto 2: análisis de la planta ===');

%% 2.1 Polos de lazo abierto (autovalores de A)
polos_LA = eig(A);
disp('Polos de lazo abierto [1/s]:');
disp(polos_LA);

%% 2.2 Estabilidad
% Un polo simple en el origen y el resto en el semiplano izquierdo:
% sistema marginalmente estable.
if all(real(polos_LA) < 0)
    disp('Todos los polos con parte real negativa: sistema estable.');
elseif any(real(polos_LA) > 0)
    disp('Hay polos con parte real positiva: sistema inestable.');
else
    disp('Polo en el origen y el resto con parte real negativa: sistema marginalmente estable.');
end

%% 2.3 Controlabilidad
% Matriz de controlabilidad Pc = [B  AB  A^2B]. Como el sistema es SISO,
% Pc es cuadrada (3x3) y es controlable si det(Pc) ~= 0.
Pc = [B, A*B, A^2*B];
disp('Matriz de controlabilidad Pc = [B AB A^2B]:');
disp(Pc);
fprintf('det(Pc) = %.4g\n', det(Pc));
if det(Pc) ~= 0
    disp('det(Pc) distinto de cero: el sistema es controlable.');
else
    disp('det(Pc) = 0: el sistema no es controlable.');
end

%% =========================================================================
%% PUNTO 3: DISEÑO POR UBICACIÓN DE POLOS
%% =========================================================================
disp('=== Punto 3: diseño de la realimentación de estados ===');

%% 3.1 Polos deseados
% PO <= 5 %  -> zeta >= 0.69. Se toma zeta = 0.8 (margen para el 3er polo).
% Ts ~ 4/(zeta*wn) <= 50 ms -> zeta*wn >= 80 -> wn >= 100. Se toma wn = 110.
zeta = 0.8;
wn   = 110;
sigma = zeta*wn;                     % parte real del par dominante
wd    = wn*sqrt(1 - zeta^2);         % parte imaginaria
p_dom = [-sigma + 1j*wd, -sigma - 1j*wd];
% Tercer polo: 10 veces más a la izquierda que el par dominante (Dorf)
p3 = -10*sigma;
polos_deseados = [p_dom, p3];
disp('Polos deseados de lazo cerrado:');
disp(polos_deseados.');

%% 3.2 Ganancia de realimentación K (fórmula de Ackermann)
Kc = acker(A, B, polos_deseados);    % Kc para no pisar la constante K del motor
disp('K = [k1 k2 k3]:');
disp(Kc);
disp('Polos de lazo cerrado, eig(A - B*K):');
disp(eig(A - B*Kc));

%% 3.3 Error en estado estacionario sin prealimentación (N = 1)
% Con u = -K x + r, la ganancia de continua del lazo cerrado no es 1.
sys_sinN = ss(A - B*Kc, B, C, D);
theta_ss_sinN = dcgain(sys_sinN);
ess_sinN = 1 - theta_ss_sinN;
fprintf('Sin N: theta_ss = %.4f rad, ess = %.4f (escalón de 1 rad)\n', ...
    theta_ss_sinN, ess_sinN);

%% 3.4 Ganancia de prealimentación N
% Se escala la referencia para que theta_ss = r. Por linealidad,
% N = 1/dcgain(sistema sin N). En este sistema da N = k1.
Nbar = 1/dcgain(sys_sinN);
fprintf('N = %.4f   (k1 = %.4f)\n', Nbar, Kc(1));

% Lazo cerrado final: x' = (A - B K) x + B N r,  y = theta
sys_LC = ss(A - B*Kc, B*Nbar, C, D);
ess = 1 - dcgain(sys_LC);
fprintf('Con N: ess = %.2g (escalón de 1 rad)\n', ess);

%% =========================================================================
%% PUNTO 4: VERIFICACIÓN
%% =========================================================================
disp('=== Punto 4: verificación ===');

%% 4.1 Respuesta al escalón de 1 rad: theta(t) y V(t)
t = (0:1e-5:0.1)';                   % paso chico para ver el salto de V en t = 0
r = ones(size(t));                   % escalón de 1 rad
[theta, t, x] = lsim(sys_LC, r, t);  % x(t): estados [theta omega i]
V = -x*Kc.' + Nbar*r;                % ley de control V = -K x + N r

info = stepinfo(theta, t, 1);        % criterio del 2 % por defecto
fprintf('Ts = %.2f ms, PO = %.2f %%, ess = %.2g\n', ...
    info.SettlingTime*1e3, info.Overshoot, ess);
fprintf('|V| máx = %.3f V (en t = %.2f ms)\n', max(abs(V)), ...
    t(find(abs(V) == max(abs(V)), 1))*1e3);

%% 4.2 Menor Ts sin superar 12 V: barrido de wn
% Se mantienen zeta = 0.8 y p3 = 10*sigma, y se aumenta wn.
% Para cada wn se recalculan K y N, se simula el escalón y se mide Ts y max|V|.
Vlim = 12;
wn_barrido = 100:1:250;
Ts_barrido = zeros(size(wn_barrido));
Vmax_barrido = zeros(size(wn_barrido));
for k = 1:numel(wn_barrido)
    wn_k = wn_barrido(k);
    sigma_k = zeta*wn_k;
    p_k = [-sigma_k + 1j*wn_k*sqrt(1-zeta^2), -sigma_k - 1j*wn_k*sqrt(1-zeta^2), -10*sigma_k];
    K_k = acker(A, B, p_k);
    N_k = 1/dcgain(ss(A - B*K_k, B, C, D));
    [th_k, ~, x_k] = lsim(ss(A - B*K_k, B*N_k, C, D), r, t);
    Ts_barrido(k)   = stepinfo(th_k, t, 1).SettlingTime;
    Vmax_barrido(k) = max(abs(-x_k*K_k.' + N_k*r));
end

% Mayor wn que no supera los 12 V
idx = find(Vmax_barrido <= Vlim, 1, 'last');
fprintf('Límite de 12 V: wn = %d rad/s -> Ts = %.2f ms, |V| máx = %.2f V\n', ...
    wn_barrido(idx), Ts_barrido(idx)*1e3, Vmax_barrido(idx));

fig = figure('Color', 'w');
subplot(2,1,1);
plot(wn_barrido, Ts_barrido*1e3, 'LineWidth', 1.5); hold on;
plot(wn_barrido(idx), Ts_barrido(idx)*1e3, 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; ylabel('T_s [ms]');
title('Barrido de \omega_n (\zeta = 0,8, p_3 = 10\sigma)');
subplot(2,1,2);
plot(wn_barrido, Vmax_barrido, 'LineWidth', 1.5); hold on;
yline(Vlim, '--r', '12 V');
plot(wn_barrido(idx), Vmax_barrido(idx), 'o', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; xlabel('\omega_n [rad/s]'); ylabel('|V|_{máx} [V]');
exportgraphics(fig, fullfile(fig_dir, 'punto4_barrido_wn.png'), 'Resolution', 200);

%% 4.3 Comparación: diseño original (wn = 110) y diseño límite de 12 V
wn_lim = wn_barrido(idx);
sigma_lim = zeta*wn_lim;
p_lim = [-sigma_lim + 1j*wn_lim*sqrt(1-zeta^2), -sigma_lim - 1j*wn_lim*sqrt(1-zeta^2), -10*sigma_lim];
K_lim = acker(A, B, p_lim);
N_lim = 1/dcgain(ss(A - B*K_lim, B, C, D));
[theta_lim, ~, x_lim] = lsim(ss(A - B*K_lim, B*N_lim, C, D), r, t);
V_lim = -x_lim*K_lim.' + N_lim*r;
info_lim = stepinfo(theta_lim, t, 1);
disp('Diseño límite:');
disp('K = [k1 k2 k3]:'); disp(K_lim);
fprintf('N = %.4f, Ts = %.2f ms, PO = %.2f %%, |V| máx = %.2f V\n', ...
    N_lim, info_lim.SettlingTime*1e3, info_lim.Overshoot, max(abs(V_lim)));

fig = figure('Color', 'w');
subplot(2,1,1);
plot(t*1e3, theta, 'LineWidth', 1.5); hold on;
plot(t*1e3, theta_lim, 'LineWidth', 1.5);
yline(1, '--k', 'HandleVisibility', 'off');
grid on; ylabel('\theta [rad]');
legend(sprintf('\\omega_n = %d rad/s (T_s = %.1f ms)', wn, info.SettlingTime*1e3), ...
       sprintf('\\omega_n = %d rad/s (T_s = %.1f ms)', wn_lim, info_lim.SettlingTime*1e3), ...
       'Location', 'southeast');
title('Respuesta al escalón de 1 rad');
subplot(2,1,2);
plot(t*1e3, V, 'LineWidth', 1.5); hold on;
plot(t*1e3, V_lim, 'LineWidth', 1.5);
yline(Vlim, '--r', '12 V');
ylim([-3 14]);
grid on; xlabel('t [ms]'); ylabel('V [V]');
exportgraphics(fig, fullfile(fig_dir, 'punto4_theta_V.png'), 'Resolution', 200);
