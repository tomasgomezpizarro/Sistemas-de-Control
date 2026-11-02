# Instrucciones para Agentes LLM: Sistemas de Control

Repositorio con los trabajos de laboratorio de la materia **Sistemas de Control** (FAMAF), hechos en MATLAB / Simulink / Simscape.

## 1. Organización
- Cada TP vive en su propia carpeta y es autocontenido: consigna, script, modelos, figuras e informe.
  - `TP_Lab1/`: Modelado de sistemas, características y medidas de desempeño. Completo.
  - `TP_Lab2/`: Desarrollo de controladores P y PI. En curso.
- Cada carpeta tiene su `AGENTS.md` con el contexto de ese TP. Leerlo antes de trabajar en él.
- Usar rutas relativas a la carpeta del TP (en MATLAB, `fileparts(mfilename('fullpath'))`). Las figuras del informe deben poder regenerarse ejecutando el script.
- No modificar `TP_Lab1/` salvo pedido explícito.

## 2. Reglas de Estilo y Redacción del Informe
1. **Tono de estudiante real de ingeniería**: La redacción debe ser sobria, directa, clara y concisa. **Evitar terminología inflada o adjetivos típicos de IA** (como *"demostraremos fielmente"*, *"disminuye monótonamente"*, *"error inaceptablemente alto"*).
2. **Solo lo que pide la consigna**:
   - No agregar demostraciones de libro de texto no solicitadas.
   - No duplicar gráficos: cada figura aparece en el punto que la pide.
3. **Estética limpia en LaTeX**: Mantener formato `article` estándar en negro, sin encabezados coloreados ni exceso de recuadros `\boxed{}`.

## 3. Dinámica de Trabajo con el Usuario
- **Flujo paso a paso con verificación de aprendizaje**: Avanzar de a un subpunto a la vez. En cada paso, el agente ejecuta/implementa lo necesario, explica de forma clara tanto la parte práctica (código/bloques de MATLAB/Simscape) como la teórica/física, y cierra con **preguntas de seguimiento y entendimiento** para verificar que el usuario comprendió todo antes de pasar al siguiente paso.
- **Visualización de PDFs**: El IDE abre los enlaces `[archivo.pdf](file:///...)` como binario crudo. Nunca usar links `file://` clickeables para PDFs; en su lugar, abrirlos en Google Chrome mediante `google-chrome "/ruta/absoluta/archivo.pdf" >/dev/null 2>&1 &` o dejar la ruta en un bloque de código.
