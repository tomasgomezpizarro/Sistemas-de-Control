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
- `consigna_TP_Lab2.pdf`: enunciado y anexo de Simscape (Tabla A0 con los parámetros del TL081).
- `figuras/`: esquemas y gráficos del informe.

Pendientes de crear: Live Script `.mlx`, modelos `.slx` del lazo con P y con PI.

## 4. Entrega
Informe con resumen teórico, deducciones completas, resultados de simulación con las comparaciones solicitadas y conclusiones. Se adjuntan los `.mlx` y `.slx`; las figuras del informe deben poder regenerarse ejecutando esos archivos.

## 5. Estado de Avance
- **Punto 1 (Control P - LGR)**: Completo. $k_p \approx 1{,}41$ elegido en la cota $\xi = 0{,}69$ ($PO \le 5\%$). Justificación física y del compromiso de error estacionario documentada. Gráfico del LGR interactivo guardado (`figuras/punto1_lgr.png`).
- **Punto 2 (Control P - Verificación al escalón)**: Completo. $PO = 4{,}98\%$, $T_s = 26{,}5\text{ ms}$, $e_{ss} = 41{,}5\%$. Gráfico de respuesta al escalón generado (`figuras/punto2_escalon.png`).
- **Punto 3 (Control P - Valores comerciales E24)**: Completo. Búsqueda sistemática sobre la serie E24: $R_7 = 1{,}6\text{ k}\Omega$, $R_9 = 3{,}9\text{ k}\Omega \implies k_p \approx 1{,}4103$. Recálculo y verificación de cumplimiento de $PO \le 5\%$.
- **Punto 4 (Control P - Simulación circuital en Simscape con TL081)**: Siguiente paso.
