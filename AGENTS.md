# Instrucciones del Proyecto para Agentes LLM (`TP_Lab1_Control`)

## 1. Contexto del Trabajo Práctico
Este repositorio contiene el **Trabajo de Laboratorio Integrador: Modelado de sistemas – Características y medidas de desempeño** de la materia **Sistemas de Control** (MATLAB / Simulink / Simscape).

- **Consigna oficial completa**: `consigna_TP_Lab1.pdf` (ubicada en la raíz de este repositorio).
- **División del trabajo**:
  - **Tomás**: Realizó la **Parte A completa (Puntos 1, 2, 3 y 4)** y el **Punto 5 de la Parte B** (verificación en Simscape con amplificadores operacionales ideales).
  - **Mikael (compañero de grupo)**: Revisará el **Punto 5.d** (que quedó pendiente de revisión humana), hará un repaso guiado de los **Puntos 1 al 5** para comprender todo lo hecho, y realizará los **Puntos 6 y 7 de la Parte B** (op-amp real TL081 y análisis de sensibilidad a tolerancias).

## 2. Estructura de Archivos del Repositorio
- `consigna_TP_Lab1.pdf`: Enunciado completo del trabajo práctico y su Anexo (parámetros del TL081, tabla de resistores serie E24 y pautas de Simscape).
  *Nota sobre actualización de consignas*:
  - **Punto 2**: Añade explícitamente *"Por simulación Matlab"* para obtener y verificar las métricas temporales ($PO, T_p, T_s, t_r, y(\infty)$).
  - **Punto 3**: Añade *"Por simulación Matlab, compruebe contra el error calculado para este sistema"* tanto para escalón unitario ($e_{ss} = 1/12\text{ V}$) como para rampa ($e_{ss} \to \infty$ implementado con `lsim`).
  - **Punto 4**: Aclara en el enunciado que *"también se puede considerar los valores cero e infinito"* para los pares comerciales $R_7/R_9$ (respaldando $R_7=0\,\Omega$ y $R_9\to\infty$ para $k=1$).
  - **Punto 7.c**: Se simplificó eliminando la pregunta sobre condiciones de relevancia y comparación de polos con ancho de banda; ahora pregunta únicamente *"¿Cuál de los dos efectos domina?"*.
- `TP_Lab1_GomezPizarro_Rodriguez.tex` y `TP_Lab1_GomezPizarro_Rodriguez.pdf`: Informe en LaTeX. Actualmente tiene redactados y revisados los **Puntos 1, 2, 3 y 4** (Parte A completa), indicando explícitamente en el Punto 4 que los parámetros de la tabla fueron calculados en MATLAB (`TP_Lab1.m`, Control System Toolbox).
- `TP_Lab1.m`: Script principal de MATLAB que utiliza funciones nativas del *Control System Toolbox* (`tf`, `feedback`, `damp`, `stepinfo`, `dcgain`) para el cálculo de parámetros nominales (Puntos 1 a 3) y el barrido de los cuatro valores de $k$ con resistores comerciales E24 para armar la tabla del Punto 4. (Deberá extenderse con las simulaciones del Punto 5 y exportarse como Live Script `.mlx` para la entrega final).
- `TP_Lab1_Ideal.slx`: Modelo físico en Simscape del circuito de la Figura 1 usando bloques `Op-Amp` ideales (`fl_lib/Electrical/Electrical Elements/Op-Amp`), solver `ode23t` y $t_{\text{stop}} = 0,05\text{ s}$ (para el Punto 5).
- `TP_Lab1_TL081.slx`: Modelo físico en Simscape usando bloques `Band-Limited Op-Amp` configurados con los parámetros del TL081 (para los Puntos 6 y 7).
- `figuras/`: Esquemas del circuito (`figura_1.png`), diagrama de bloques (`figura_2.png`) y gráficos de resultados.

## 2.1. Estado de Avance Actual (Informe Completo - Puntos 1 al 7)
- **Puntos 1 a 4 (Parte A)**: Modelado analítico, parámetros temporales y error en régimen permanente (para escalón y rampa) verificados por simulación en MATLAB (`TP_Lab1.m`), y tabla para resistores comerciales E24.
- **Punto 5 (Parte B - Op-Amps Ideales)**: Implementado sobre el diseño limpio de `TP_Lab1_Ideal.slx` (5 bloques `GND` locales, sin cables cruzados) y graficado en `figuras/punto5b_k11.png`, `figuras/punto5c_error_k11.png` y `figuras/punto5d_barrido_k.png`.
- **Punto 6 (Parte B - Op-Amp no ideal TL081)**: Implementado sobre `TP_Lab1_TL081.slx` y graficado en `figuras/punto6a_comparacion.png` y `figuras/punto6c_saturacion.png`. Se eliminaron conceptos fuera de programa (*slew rate*, ancho de banda interno / polos de alta frecuencia del operacional) dejando únicamente el análisis en zona lineal vs. saturación en $\pm 8,5\text{ V}$.
- **Punto 7 (Parte B - Sensibilidad a tolerancias)**: Justificación analítica de los casos extremos ($\pm 5\%$ en $R$, $\pm 10\%$ en $C$), simulación únicamente en Simscape (`figuras/punto7b_tolerancias.png`, sin líneas punteadas superpuestas) y comparación directa con el efecto del TL081 en régimen lineal (Punto 7.c). Se eliminó la sección de Conclusiones para mantener el informe conciso.

## 2.2. Instrucciones Especiales para el Agente que Asista a Mikael
1. **Propuesta inicial obligatoria al comenzar la sesión**: Apenas Mikael inicie la conversación, el agente **debe proponerle hacer primero un recorrido/revisión interactiva de los Puntos 1 al 5** (tanto de las deducciones teóricas en `TP_Lab1_GomezPizarro_Rodriguez.tex` como del código en `TP_Lab1.m` y el modelo `TP_Lab1_Ideal.slx`) para que él también comprenda y aprenda a fondo todo lo que ya se construyó antes de encarar los Puntos 6 y 7.
2. **Revisión humana del Punto 5.d**: Validar especialmente con Mikael los resultados, el gráfico `figuras/punto5d_barrido_k.png` y la tabla comparativa del Punto 5.d, que quedaron listos pero sin revisión humana de Tomás.
3. **Continuación con Puntos 6 y 7**: Una vez que Mikael esté al día con los Puntos 1–5, aplicar la misma dinámica paso a paso (explicación teórica/práctica + preguntas de seguimiento) para resolver el Punto 6 (op-amp no ideal TL081 con `TP_Lab1_TL081.slx`) y el Punto 7 (sensibilidad a tolerancias de $\pm 5\%$ en resistores y $\pm 10\%$ en capacitores).

## 3. Reglas de Estilo y Redacción del Informe (`TP_Lab1_GomezPizarro_Rodriguez.tex`)
1. **Tono de estudiante real de ingeniería**: La redacción debe ser sobria, directa, clara y concisa. **Evitar terminología inflada o adjetivos típicos de IA** (como *"demostraremos fielmente"*, *"disminuye monótonamente"*, *"error inaceptablemente alto"*).
2. **Solo lo que pide la consigna**:
   - No agregar demostraciones de libro de texto no solicitadas (por ejemplo, en el Punto 2 usar directamente la ecuación temporal y las fórmulas de segundo orden sin expandir fracciones simples ni derivar para demostrar de dónde sale $T_p$).
   - No duplicar gráficos: los Puntos 2 y 4 de la Parte A son analíticos (ecuaciones y tabla); los gráficos superponiendo la función de transferencia teórica (`step`) contra el circuito físico en Simscape corresponden al **Punto 5** (Parte B).
3. **Estética limpia en LaTeX**: Mantener formato `article` estándar en negro, sin encabezados coloreados ni exceso de recuadros `\boxed{}`.

## 4. Dinámica de Trabajo con el Usuario
- **Flujo paso a paso con verificación de aprendizaje**: Avanzar de a un subpunto a la vez. En cada paso, el agente ejecuta/implementa lo necesario, explica de forma clara tanto la parte práctica (código/bloques de MATLAB/Simscape) como la teórica/física, y cierra con **preguntas de seguimiento y entendimiento** para verificar que el usuario comprendió todo antes de pasar al siguiente paso.
- **Visualización de PDFs**: El IDE abre los enlaces `[archivo.pdf](file:///...)` como binario crudo. Nunca usar links `file://` clickeables para PDFs; en su lugar, abrirlos en Google Chrome mediante `google-chrome "/ruta/absoluta/archivo.pdf" >/dev/null 2>&1 &` o dejar la ruta en un bloque de código.
