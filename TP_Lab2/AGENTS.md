# Instrucciones para Agentes LLM: TP de Laboratorio 2

## 1. Contexto
**Trabajo de laboratorio integrador: Desarrollo de controladores** (simulación en MATLAB / Simulink / Simscape). Se diseñan un controlador P y un PI para la planta de la Fig. 1 de la consigna, y cada diseño se verifica en Simscape con valores comerciales y op-amps TL081.

- **Consigna oficial**: `consigna_TP_Lab2.pdf` (en esta carpeta).
- **Reglas generales**: estilo del informe y dinámica de trabajo en el `AGENTS.md` de la raíz del repositorio.
- **División del trabajo**: a definir.

## 2. Especificaciones (lazo cerrado)
- $PO \le 5\%$
- $T_s \le 0{,}10$ s
- $e_{ss} = 0$ para escalón unitario

## 3. Estructura de Archivos
- consigna_TP_Lab2.pdf: enunciado y anexo de Simscape (Tabla A0 con los parámetros del TL081).
- `figuras/`: esquemas y gráficos del informe.
- TP_Lab2.m: script único y autocontenido con todos los cálculos, diseños (P y PI) y simulaciones.
- TP_Lab2_TL081.slx: modelo circuital en Simscape con operacionales reales TL081 para el lazo con control P.
- TP_Lab2_PI_TL081.slx: modelo circuital en Simscape con operacionales reales TL081 para el lazo con control PI.
- TP_Lab2_GomezPizarro_Rodriguez.tex / .pdf: informe del trabajo de laboratorio.

## 4. Entrega
Informe con resumen teórico, deducciones completas, resultados de simulación con las comparaciones solicitadas y conclusiones. Se adjuntan los `.mlx` y `.slx`; las figuras del informe deben poder regenerarse ejecutando esos archivos.

## 5. Estado de Avance
- **Punto 1 (Control P - LGR)**: Completo. $k_p \approx 1{,}41$ elegido en la cota $\xi = 0{,}69$ ($PO \le 5\%$). Justificación física y del compromiso de error estacionario documentada. Gráfico del LGR interactivo guardado (`figuras/punto1_lgr.png`).
- **Punto 2 (Control P - Verificación al escalón)**: Completo. $PO = 4{,}98\%$, $T_s = 26{,}5\text{ ms}$, $e_{ss} = 41{,}5\%$. Gráfico de respuesta al escalón generado (`figuras/punto2_escalon.png`).
- **Punto 3 (Control P - Valores comerciales E24)**: Completo. Búsqueda sistemática sobre la serie E24: $R_7 = 1{,}6\text{ k}\Omega$, $R_9 = 3{,}9\text{ k}\Omega \implies k_p \approx 1{,}4103$. Recálculo y verificación de cumplimiento de $PO \le 5\%$.
- **Punto 4 (Control P - Simulación circuital en Simscape con TL081)**: Completo. Modelo `TP_Lab2_TL081.slx` derivado y adaptado de TP1. Superposición con FT graficada (`figuras/punto4_simscape_vs_ft.png`), error máximo cuantificado ($0{,}017\text{ mV}$) y parámetros medidos con `stepinfo`.
- **Segunda Parte (Control PI)**: Puntos 1, 2 y 3 analíticos completos. Punto 4.a (simulación en Simscape con `TP_Lab2_PI_TL081.slx`, superposición con FT y error máximo cuantificado en $0{,}032\text{ mV}$) y Punto 4.b completados.
- **Punto 4.c**: Completo. A_lim ≈ 7,30 V (pico de vPI = 8,5 V); con A = 8 V satura: PO = 3,56 %, Ts = 61,6 ms. Figura `figuras/pi_punto4c_saturacion.png`.
- **Punto 5 (Comparación final)**: Completo (figura, tabla y discusión en el informe). Conclusiones generales escritas.
