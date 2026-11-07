# Instrucciones para Agentes LLM: TP de Laboratorio 3

## 1. Contexto
**Trabajo de laboratorio integrador: Desarrollo de controlador atraso-adelanto.** Misma planta que el Lab 2 (polos en −100 y −212,77 rad/s) con la etapa de ganancia Ka = 1 + R7/R9. Se diseña un adelanto Gc = Ka(s+z_l)/(s+p_l) para PO y Ts, y luego un atraso para ess.

- **Consigna oficial**: `TP_Lab3_Adelanto_Atraso.pdf`.
- **Reglas generales**: estilo del informe y dinámica de trabajo en el `AGENTS.md` de la raíz.

## 2. Especificaciones (lazo cerrado)
- PO ≤ 5 %  →  ζ ≥ 0,69
- Ts ≤ 0,02 s (2 %)  →  σ ≥ 200 1/s
- ess ≤ 0,06 al escalón  →  Kp ≥ 15,67

## 3. Archivos
- `TP_Lab3.m`: script único con cálculos y figuras (se guardan en `figuras/`).
- `TP_Lab3.mlx`: el mismo script como Live Script (es el que se entrega junto con el PDF).
- `TP_Lab3_GomezPizarro_Rodriguez.tex/.pdf`: informe.

## 4. Decisiones de diseño
- Diseño analítico (condiciones de ángulo y módulo), no gráfico.
- Orden del relato: especificaciones → s_d → ángulo faltante → z → p → Ka.
- s_d = −230 ± j221,7 (ζ_d = 0,72, σ_d = 230): margen porque 4/σ es aproximado (en el vértice de la región Ts real ≈ 20,7 ms) y por tolerancias.
- z_l = 212,77 (cancela el polo rápido de la planta: deja 2º orden puro y Kp mayor que cancelando −100).
- Resultado: p_l = 360 (control: p_l = 2σ_d − 100), Ka = 3,104.
- Alejar p_l permitiría cumplir ess sólo con adelanto (con ζ=0,72: p_l ≈ 3300, Ka ≈ 247), inviable por saturación ±8,5 V (TL081) y ruido ×Ka: argumento para el atraso. Cancelar −100 en vez de −212,77 da Kp = 0,94.
- El usuario decidió NO incluir en el informe la ventana 0,745 < Ka < 0,89 del control P solo.
- NO incluir en el informe: la optimización (casos A/B, PI/PID) ni el chequeo de tolerancias ±5 % (el usuario lo considera cálculo que no haría sin IA). α = 12 se justifica cualitativamente (α = 10 da ess 0,052, cerca del límite).

## 5. Estado de Avance
- **Punto 1**: hecho (script, figura `punto1_lgr_adelanto.png`, informe).
- **Punto 2**: hecho (PO 3,84 %, Ts 18,5 ms, ess 0,353: no cumple ess). Figura `punto2_escalon_adelanto.png`.
- **Punto 3**: hecho. α = 12 (mín 8,54), z_a = 85, p_a = 7,08. Regla clásica z_a = σ_d/10 = 23 da Ts 163 ms (cola lenta del dipolo); barrido de z_a: cumple todo para 80–90. Sin figura (la consigna no la pide).
- **Punto 4**: hecho. Sys_c = 66045(s+85)/((s+78,44)(s²+388,6s+74820)); polos −194,3±j192,5 y −78,4. PO 0,69 %, Ts 13,5 ms, ess 0,0435: cumple todo. Figura `punto4_escalon_adelanto_atraso.png`.
- **Punto 5**: hecho. Figura `punto5_comparacion.png` (0–60 ms), tabla y conclusiones. TP completo salvo revisión del usuario.
