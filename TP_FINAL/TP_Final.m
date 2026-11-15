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
