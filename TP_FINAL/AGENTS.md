# Instrucciones para Agentes LLM: TP Final (Proyecto parcial 2)

## 1. Contexto
**Variante 4: Posición de un motor de CC** (Grupo 2: Tomás Gómez Pizarro, Mikael Rodríguez). Control por realimentación de estados.

- **Consigna oficial**: `pp2_v4_G2.pdf`.
- **Referencia del modelo**: CTMS, *DC Motor Position: System Modeling* (mismas ecuaciones, otros parámetros).
- **Reglas generales**: estilo y dinámica de trabajo en el `AGENTS.md` de la raíz. El usuario hace el TP y el agente supervisa/explica.

## 2. Datos
- J θ̈ + bθ̇ = K i ; L di/dt + R i = V − K θ̇
- J = 5e-6, b = 4e-6, K = 0.03, R = 3, L = 0.4e-3.
- Se miden θ, θ̇ e i. |V| ≤ 12 V.
- Escalón de 1 rad: Ts ≤ 50 ms, PO ≤ 5 %, ess = 0.

## 3. Entregables
1. Script MATLAB `TP_Final.m` (se entrega .m, no .mlx) que reproduzca todo; figuras en `figuras/`.
2. Presentación de 8 a 10 diapositivas para la defensa, en Beamer.

## 4. Puntos de la consigna
1. Modelo con x = [θ θ̇ i]ᵀ, significado de cada estado.
2. Análisis: polos, estabilidad, controlabilidad.
3. Diseño: V = −Kx + N r (ubicación de polos o LQR), justificar.
4. Verificación: θ(t) y V(t); menor Ts logrado sin superar 12 V y qué lo limita.

## 5. Estado de Avance
- **Punto 1**: hecho en `TP_Final.m` (parámetros, matrices, ss). Verificación con el CTMS: el usuario comparó la estructura de las matrices con la página (no va en el script).
- **Punto 2.1/2.2**: hecho. Polos 0, −61,3, −7439,5: marginalmente estable. (Sin constantes de tiempo en el script.)
- **Punto 2.3**: hecho con det(Pc) ≠ 0 (criterio de las transparencias). det(Pc) = −5,625e17 → controlable.
- **Punto 3**: método ubicación de polos (acker, como en las transparencias). ζ = 0,8, ωn = 110 → −88 ± j66; p3 = 10σ = −880 (regla Dorf; diapos usan 20×). K = [0,7099 −0,01892 −2,578]. `format shortG` agregado a pedido. Variable `Kc` (K es la constante del motor). 3.3: ess sin N con dcgain = −0,4087. 3.4: N = 1/dcgain(sys_sinN) = k1 en el script; la deducción fila por fila (ẋ=0 → θ̇=0, i=0, V=0 → N=k1, V(0+)=k1·r) va en la presentación.
- **Punto 4.1**: hecho. lsim sobre sys_LC, V = −Kx + N r, figura `figuras/punto4_theta_V.png` (tema claro forzado como en Lab 3). Ts = 35,4 ms, PO = 1,50 %, ess = 0. |V|máx = 4,39 V en t = 2,44 ms: el pico NO está en t = 0+ (V(0+) = k1 = 0,71 V) por el k3 negativo (−k3·i suma tensión mientras crece la corriente). La cota k1 ≤ 12 no alcanza: hay que verificar max|V| simulando.
- **Punto 4.2**: barrido ωn = 100:1:250 (ζ = 0,8, p3 = 10σ), figura `figuras/punto4_barrido_wn.png`. Límite: ωn = 185 → Ts = 21,04 ms, |V|máx = 11,92 V. Vmáx crece ~ωn² y Ts ~1/ωn. ζ = 0,8 justificado con exploración aparte (ωn límite ≈ 186 casi independiente de ζ; 0,8 da el menor Ts por el efecto de la banda del 2 %). 4.3: figura `punto4_theta_V.png` con ambos diseños superpuestos (ωn 110 y 185). Diseño límite: K = [3,377 0,00139 −2,290], N = 3,377, Ts 21,04 ms, PO 1,50 %. Script revisado y aprobado por el usuario. Figuras con `theme(fig,'light')`.
- **Presentación (Beamer)**: estructura de 10 diapos propuesta (portada, problema, modelo, análisis, elección de polos, K por comparación, N, verificación, barrido, qué lo limita). Decisiones pendientes del usuario: (1) ¿línea sobre por qué no LQR?, (2) ¿diapos de respaldo?, (3) ¿tabla de ζ (requiere agregarla al script)?, (4) nombre `presentacion/TP_Final_GomezPizarro_Rodriguez.tex`.
