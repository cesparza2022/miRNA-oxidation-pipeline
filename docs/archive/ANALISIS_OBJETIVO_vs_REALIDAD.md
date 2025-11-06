# 📊 ANÁLISIS: Qué Queremos vs Qué Tenemos

**Fecha:** 2025-11-01  
**Objetivo:** Comparar el objetivo final con la realidad actual para identificar gaps y planificar mejoras

---

## 🎯 QUÉ QUEREMOS (Objetivo Final)

### Visión Ideal
Un pipeline **simple y directo** como los pipelines estándar de GitHub (nf-core, skipper, etc.):

```
INPUT: Un archivo CSV
  ↓
./run.sh input.csv
  ↓
OUTPUTS: Todas las gráficas + tablas + viewers HTML
```

### Características Deseadas

1. **Input Simple y Único**
   - Un solo archivo CSV como entrada
   - Formato bien documentado
   - Validación automática del formato

2. **Ejecución Simple**
   - Un comando: `./run.sh input.csv`
   - Sin configuración manual necesaria
   - Auto-detección de parámetros

3. **Output Completo**
   - Todas las figuras (Step 1 + Step 1.5 + Step 2)
   - Todas las tablas CSV
   - Viewers HTML interactivos
   - Todo en directorio organizado

4. **Pipeline Genérico**
   - Funciona con cualquier dataset (ALS + Control)
   - No hardcodea rutas específicas
   - Configurable pero con defaults sensatos

---

## 🔍 QUÉ TENEMOS (Estado Actual)

### Input Actual (Confuso)

**Múltiples archivos de entrada:**
1. `processed_clean`: `/Users/cesaresparza/.../final_processed_data_CLEAN.csv`
   - Usado por: Step 1 (paneles B, E, F, G)
   
2. `raw`: `/Users/cesaresparza/.../miRNA_count.Q33.txt`
   - Usado por: Step 1 (paneles C, D)
   
3. `step1_original`: `/Users/cesaresparza/.../step1_original_data.csv`
   - Usado por: Step 1.5 (necesita SNV + total counts)

**Problemas:**
- ❌ Rutas hardcodeadas (absolutas, usuario-específicas)
- ❌ Múltiples inputs en lugar de uno solo
- ❌ No claro cuál es el "input principal"
- ❌ Usuario debe editar `config.yaml` manualmente

### Ejecución Actual

**Comandos disponibles:**
```bash
# Opción 1: Snakemake directo
snakemake -j 4

# Opción 2: Por pasos
snakemake -j 4 all_step1
snakemake -j 1 all_step1_5

# Opción 3: Panel individual
snakemake -j 1 outputs/step1/figures/step1_panelB_*.png
```

**Problemas:**
- ⚠️ Requiere editar `config.yaml` antes de ejecutar
- ⚠️ No hay script simple `run.sh` funcional aún
- ⚠️ No hay validación de input automática
- ✅ Snakemake funciona correctamente
- ✅ Paralelización funciona

### Output Actual

**Genera correctamente:**
- ✅ Step 1: 6 figuras + 6 tablas + viewer HTML
- ✅ Step 1.5: 11 figuras + 7 tablas + viewer HTML
- ✅ Step 2: Estructura lista pero no completado
- ✅ Viewers HTML funcionan

**Estructura:**
```
outputs/
├── step1/
│   ├── figures/ (6 PNGs)
│   ├── tables/ (6 CSVs)
│   └── logs/
├── step1_5/
│   ├── figures/ (11 PNGs)
│   ├── tables/ (7 CSVs)
│   └── logs/
└── step2/ (vacío por ahora)
```

**Problemas:**
- ⚠️ Outputs están bien organizados pero faltan algunos pasos

---

## 📋 GAPS (Diferencias)

### Gap 1: Input ❌

**Queremos:**
```
Un solo archivo CSV → Pipeline procesa todo
```

**Tenemos:**
```
3 archivos diferentes con rutas hardcodeadas
Usuario debe editar config.yaml manualmente
```

**Gap:**
- Falta unificación de inputs
- Falta auto-configuración
- Falta validación de formato

---

### Gap 2: Ejecución ⚠️

**Queremos:**
```
./run.sh input.csv  → Todo funciona automáticamente
```

**Tenemos:**
```
1. Editar config.yaml con rutas
2. snakemake -j 4
```

**Gap:**
- `run.sh` existe pero no actualiza config automáticamente
- Falta validación de input antes de ejecutar
- Falta manejo de errores claro

---

### Gap 3: Genericidad ⚠️

**Queremos:**
```
Pipeline genérico que funciona con cualquier dataset
```

**Tenemos:**
```
Rutas hardcodeadas a archivos específicos del usuario
Nombres de columnas asumidos pero no validados
```

**Gap:**
- Pipeline funciona pero no es portable
- Falta detección automática de formato
- Falta documentación clara del formato esperado

---

### Gap 4: Step 2 📋

**Queremos:**
```
Pipeline completo: Step 1 + Step 1.5 + Step 2
```

**Tenemos:**
```
Step 1 ✅ Completo
Step 1.5 ✅ Completo
Step 2 ❌ Incompleto (solo estructura)
```

**Gap:**
- Falta completar Step 2 (comparaciones grupo vs grupo)

---

## 🎯 DECISIONES NECESARIAS

### Pregunta 1: ¿Cuál debe ser el INPUT PRINCIPAL?

**Opción A: Archivo RAW original**
- Input: `miRNA_count.Q33.txt`
- Pipeline hace: split, collapse, procesamiento, análisis
- **Pro:** Más genérico, empieza desde raw
- **Contra:** Más lento, requiere más procesamiento

**Opción B: Archivo PROCESADO (split-collapse)**
- Input: `step1_original_data.csv` (ya procesado)
- Pipeline hace: análisis directo
- **Pro:** Más rápido, usuario ya procesó datos
- **Contra:** Asume formato específico

**Opción C: Ambos (auto-detección)**
- Pipeline detecta si es raw o processed
- **Pro:** Más flexible
- **Contra:** Más complejo de implementar

**⚠️ NECESITAMOS DECIDIR:** ¿Cuál queremos?

---

### Pregunta 2: ¿Cómo manejamos metadata (grupos)?

**Estado actual:**
- Step 1 y 1.5: No requieren metadata (funcionan sin grupos)
- Step 2: Requiere metadata (comparación ALS vs Control)

**Opciones:**

**Opción A: Input opcional**
```bash
./run.sh input.csv [metadata.csv]  # metadata opcional
```

**Opción B: Auto-detección**
- Pipeline busca metadata en directorio
- Si no encuentra, solo ejecuta Step 1 + 1.5

**Opción C: Configuración manual**
- Usuario edita config.yaml para metadata
- Más explícito pero menos automático

**⚠️ NECESITAMOS DECIDIR:** ¿Cómo lo manejamos?

---

### Pregunta 3: ¿Qué debe hacer el pipeline automáticamente?

**Opciones:**

**Nivel 1: Mínimo (actual)**
- Usuario edita config.yaml
- Ejecuta snakemake
- ✅ Funciona pero requiere configuración manual

**Nivel 2: Intermedio (propuesto)**
- Usuario pasa input como argumento
- run.sh actualiza config.yaml automáticamente
- Ejecuta pipeline
- ✅ Más simple pero aún requiere entender estructura

**Nivel 3: Máximo (ideal)**
- Usuario pasa input
- Pipeline valida formato
- Pipeline auto-detecta tipo (raw/processed)
- Pipeline decide qué steps ejecutar
- Pipeline genera todo automáticamente
- ✅ Máximo automatismo pero más complejo

**⚠️ NECESITAMOS DECIDIR:** ¿Hasta dónde queremos automatizar?

---

## 💡 RECOMENDACIONES

### Recomendación 1: Unificar Input (PRIORIDAD ALTA)

**Proponer:**
- Input principal: Archivo procesado (split-collapse)
- Formato: CSV con columnas `miRNA name`, `pos:mut`, y columnas de muestra
- Pipeline asume que datos ya están en formato correcto

**Razón:**
- Más rápido (no procesa raw)
- Usuario controla pre-procesamiento
- Más simple de validar

---

### Recomendación 2: Auto-configuración Simple (PRIORIDAD MEDIA)

**Proponer:**
```bash
./run.sh input.csv  # Actualiza config.yaml y ejecuta
```

**Implementar:**
- `run.sh` toma input como argumento
- Actualiza `config.yaml` automáticamente
- Valida que archivo existe
- Ejecuta pipeline

**Razón:**
- Balance entre simplicidad y control
- Usuario no edita YAML manualmente
- Pero puede si quiere (config.yaml sigue siendo editable)

---

### Recomendación 3: Metadata Opcional (PRIORIDAD MEDIA)

**Proponer:**
```bash
./run.sh input.csv [metadata.csv]  # metadata opcional
```

**Comportamiento:**
- Sin metadata: Ejecuta Step 1 + Step 1.5 (solo análisis exploratorio)
- Con metadata: Ejecuta Step 1 + Step 1.5 + Step 2 (comparaciones)

**Razón:**
- Permite usar pipeline sin grupos
- Agrega funcionalidad cuando metadata disponible
- Flexible y claro

---

### Recomendación 4: Completar Step 2 (PRIORIDAD BAJA)

**Proponer:**
- Step 2 como fase futura
- Por ahora: Step 1 + Step 1.5 completos y funcionando

**Razón:**
- Step 1 y 1.5 ya funcionan bien
- Step 2 requiere decisiones sobre metadata
- Mejor consolidar lo que funciona primero

---

## 📊 PLAN DE ACCIÓN PROPUESTO

### Fase 1: Unificar y Simplificar Input ⚡
1. Decidir: ¿raw o processed como input principal?
2. Simplificar config.yaml: Solo una ruta de input
3. Actualizar todas las reglas para usar el mismo input

### Fase 2: Auto-configuración 🔧
1. Implementar auto-actualización en run.sh
2. Validación básica de input (existe, formato CSV)
3. Mensajes de error claros

### Fase 3: Validación y Documentación 📚
1. Script de validación de formato
2. README actualizado con formato esperado
3. Ejemplo de datos pequeño incluido

### Fase 4: Metadata Opcional (futuro) 🔮
1. Implementar metadata como argumento opcional
2. Auto-detección de grupos
3. Step 2 condicional basado en metadata

---

## ❓ PREGUNTAS PARA DISCUTIR

1. **¿Raw o Processed como input principal?**
   - ¿Prefieres que usuario procese datos primero?
   - ¿O prefieres pipeline completo desde raw?

2. **¿Qué tan automático queremos?**
   - ¿Solo auto-config o también auto-detección de formato?

3. **¿Metadata cómo lo manejamos?**
   - ¿Opcional como argumento?
   - ¿O parte de configuración?

4. **¿Prioridad de pasos?**
   - ¿Primero consolidar Step 1 + 1.5?
   - ¿O empezar a trabajar en Step 2?

---

**Estado:** Documento para discusión  
**Próximo paso:** Decidir respuestas a preguntas antes de implementar


**Fecha:** 2025-11-01  
**Objetivo:** Comparar el objetivo final con la realidad actual para identificar gaps y planificar mejoras

---

## 🎯 QUÉ QUEREMOS (Objetivo Final)

### Visión Ideal
Un pipeline **simple y directo** como los pipelines estándar de GitHub (nf-core, skipper, etc.):

```
INPUT: Un archivo CSV
  ↓
./run.sh input.csv
  ↓
OUTPUTS: Todas las gráficas + tablas + viewers HTML
```

### Características Deseadas

1. **Input Simple y Único**
   - Un solo archivo CSV como entrada
   - Formato bien documentado
   - Validación automática del formato

2. **Ejecución Simple**
   - Un comando: `./run.sh input.csv`
   - Sin configuración manual necesaria
   - Auto-detección de parámetros

3. **Output Completo**
   - Todas las figuras (Step 1 + Step 1.5 + Step 2)
   - Todas las tablas CSV
   - Viewers HTML interactivos
   - Todo en directorio organizado

4. **Pipeline Genérico**
   - Funciona con cualquier dataset (ALS + Control)
   - No hardcodea rutas específicas
   - Configurable pero con defaults sensatos

---

## 🔍 QUÉ TENEMOS (Estado Actual)

### Input Actual (Confuso)

**Múltiples archivos de entrada:**
1. `processed_clean`: `/Users/cesaresparza/.../final_processed_data_CLEAN.csv`
   - Usado por: Step 1 (paneles B, E, F, G)
   
2. `raw`: `/Users/cesaresparza/.../miRNA_count.Q33.txt`
   - Usado por: Step 1 (paneles C, D)
   
3. `step1_original`: `/Users/cesaresparza/.../step1_original_data.csv`
   - Usado por: Step 1.5 (necesita SNV + total counts)

**Problemas:**
- ❌ Rutas hardcodeadas (absolutas, usuario-específicas)
- ❌ Múltiples inputs en lugar de uno solo
- ❌ No claro cuál es el "input principal"
- ❌ Usuario debe editar `config.yaml` manualmente

### Ejecución Actual

**Comandos disponibles:**
```bash
# Opción 1: Snakemake directo
snakemake -j 4

# Opción 2: Por pasos
snakemake -j 4 all_step1
snakemake -j 1 all_step1_5

# Opción 3: Panel individual
snakemake -j 1 outputs/step1/figures/step1_panelB_*.png
```

**Problemas:**
- ⚠️ Requiere editar `config.yaml` antes de ejecutar
- ⚠️ No hay script simple `run.sh` funcional aún
- ⚠️ No hay validación de input automática
- ✅ Snakemake funciona correctamente
- ✅ Paralelización funciona

### Output Actual

**Genera correctamente:**
- ✅ Step 1: 6 figuras + 6 tablas + viewer HTML
- ✅ Step 1.5: 11 figuras + 7 tablas + viewer HTML
- ✅ Step 2: Estructura lista pero no completado
- ✅ Viewers HTML funcionan

**Estructura:**
```
outputs/
├── step1/
│   ├── figures/ (6 PNGs)
│   ├── tables/ (6 CSVs)
│   └── logs/
├── step1_5/
│   ├── figures/ (11 PNGs)
│   ├── tables/ (7 CSVs)
│   └── logs/
└── step2/ (vacío por ahora)
```

**Problemas:**
- ⚠️ Outputs están bien organizados pero faltan algunos pasos

---

## 📋 GAPS (Diferencias)

### Gap 1: Input ❌

**Queremos:**
```
Un solo archivo CSV → Pipeline procesa todo
```

**Tenemos:**
```
3 archivos diferentes con rutas hardcodeadas
Usuario debe editar config.yaml manualmente
```

**Gap:**
- Falta unificación de inputs
- Falta auto-configuración
- Falta validación de formato

---

### Gap 2: Ejecución ⚠️

**Queremos:**
```
./run.sh input.csv  → Todo funciona automáticamente
```

**Tenemos:**
```
1. Editar config.yaml con rutas
2. snakemake -j 4
```

**Gap:**
- `run.sh` existe pero no actualiza config automáticamente
- Falta validación de input antes de ejecutar
- Falta manejo de errores claro

---

### Gap 3: Genericidad ⚠️

**Queremos:**
```
Pipeline genérico que funciona con cualquier dataset
```

**Tenemos:**
```
Rutas hardcodeadas a archivos específicos del usuario
Nombres de columnas asumidos pero no validados
```

**Gap:**
- Pipeline funciona pero no es portable
- Falta detección automática de formato
- Falta documentación clara del formato esperado

---

### Gap 4: Step 2 📋

**Queremos:**
```
Pipeline completo: Step 1 + Step 1.5 + Step 2
```

**Tenemos:**
```
Step 1 ✅ Completo
Step 1.5 ✅ Completo
Step 2 ❌ Incompleto (solo estructura)
```

**Gap:**
- Falta completar Step 2 (comparaciones grupo vs grupo)

---

## 🎯 DECISIONES NECESARIAS

### Pregunta 1: ¿Cuál debe ser el INPUT PRINCIPAL?

**Opción A: Archivo RAW original**
- Input: `miRNA_count.Q33.txt`
- Pipeline hace: split, collapse, procesamiento, análisis
- **Pro:** Más genérico, empieza desde raw
- **Contra:** Más lento, requiere más procesamiento

**Opción B: Archivo PROCESADO (split-collapse)**
- Input: `step1_original_data.csv` (ya procesado)
- Pipeline hace: análisis directo
- **Pro:** Más rápido, usuario ya procesó datos
- **Contra:** Asume formato específico

**Opción C: Ambos (auto-detección)**
- Pipeline detecta si es raw o processed
- **Pro:** Más flexible
- **Contra:** Más complejo de implementar

**⚠️ NECESITAMOS DECIDIR:** ¿Cuál queremos?

---

### Pregunta 2: ¿Cómo manejamos metadata (grupos)?

**Estado actual:**
- Step 1 y 1.5: No requieren metadata (funcionan sin grupos)
- Step 2: Requiere metadata (comparación ALS vs Control)

**Opciones:**

**Opción A: Input opcional**
```bash
./run.sh input.csv [metadata.csv]  # metadata opcional
```

**Opción B: Auto-detección**
- Pipeline busca metadata en directorio
- Si no encuentra, solo ejecuta Step 1 + 1.5

**Opción C: Configuración manual**
- Usuario edita config.yaml para metadata
- Más explícito pero menos automático

**⚠️ NECESITAMOS DECIDIR:** ¿Cómo lo manejamos?

---

### Pregunta 3: ¿Qué debe hacer el pipeline automáticamente?

**Opciones:**

**Nivel 1: Mínimo (actual)**
- Usuario edita config.yaml
- Ejecuta snakemake
- ✅ Funciona pero requiere configuración manual

**Nivel 2: Intermedio (propuesto)**
- Usuario pasa input como argumento
- run.sh actualiza config.yaml automáticamente
- Ejecuta pipeline
- ✅ Más simple pero aún requiere entender estructura

**Nivel 3: Máximo (ideal)**
- Usuario pasa input
- Pipeline valida formato
- Pipeline auto-detecta tipo (raw/processed)
- Pipeline decide qué steps ejecutar
- Pipeline genera todo automáticamente
- ✅ Máximo automatismo pero más complejo

**⚠️ NECESITAMOS DECIDIR:** ¿Hasta dónde queremos automatizar?

---

## 💡 RECOMENDACIONES

### Recomendación 1: Unificar Input (PRIORIDAD ALTA)

**Proponer:**
- Input principal: Archivo procesado (split-collapse)
- Formato: CSV con columnas `miRNA name`, `pos:mut`, y columnas de muestra
- Pipeline asume que datos ya están en formato correcto

**Razón:**
- Más rápido (no procesa raw)
- Usuario controla pre-procesamiento
- Más simple de validar

---

### Recomendación 2: Auto-configuración Simple (PRIORIDAD MEDIA)

**Proponer:**
```bash
./run.sh input.csv  # Actualiza config.yaml y ejecuta
```

**Implementar:**
- `run.sh` toma input como argumento
- Actualiza `config.yaml` automáticamente
- Valida que archivo existe
- Ejecuta pipeline

**Razón:**
- Balance entre simplicidad y control
- Usuario no edita YAML manualmente
- Pero puede si quiere (config.yaml sigue siendo editable)

---

### Recomendación 3: Metadata Opcional (PRIORIDAD MEDIA)

**Proponer:**
```bash
./run.sh input.csv [metadata.csv]  # metadata opcional
```

**Comportamiento:**
- Sin metadata: Ejecuta Step 1 + Step 1.5 (solo análisis exploratorio)
- Con metadata: Ejecuta Step 1 + Step 1.5 + Step 2 (comparaciones)

**Razón:**
- Permite usar pipeline sin grupos
- Agrega funcionalidad cuando metadata disponible
- Flexible y claro

---

### Recomendación 4: Completar Step 2 (PRIORIDAD BAJA)

**Proponer:**
- Step 2 como fase futura
- Por ahora: Step 1 + Step 1.5 completos y funcionando

**Razón:**
- Step 1 y 1.5 ya funcionan bien
- Step 2 requiere decisiones sobre metadata
- Mejor consolidar lo que funciona primero

---

## 📊 PLAN DE ACCIÓN PROPUESTO

### Fase 1: Unificar y Simplificar Input ⚡
1. Decidir: ¿raw o processed como input principal?
2. Simplificar config.yaml: Solo una ruta de input
3. Actualizar todas las reglas para usar el mismo input

### Fase 2: Auto-configuración 🔧
1. Implementar auto-actualización en run.sh
2. Validación básica de input (existe, formato CSV)
3. Mensajes de error claros

### Fase 3: Validación y Documentación 📚
1. Script de validación de formato
2. README actualizado con formato esperado
3. Ejemplo de datos pequeño incluido

### Fase 4: Metadata Opcional (futuro) 🔮
1. Implementar metadata como argumento opcional
2. Auto-detección de grupos
3. Step 2 condicional basado en metadata

---

## ❓ PREGUNTAS PARA DISCUTIR

1. **¿Raw o Processed como input principal?**
   - ¿Prefieres que usuario procese datos primero?
   - ¿O prefieres pipeline completo desde raw?

2. **¿Qué tan automático queremos?**
   - ¿Solo auto-config o también auto-detección de formato?

3. **¿Metadata cómo lo manejamos?**
   - ¿Opcional como argumento?
   - ¿O parte de configuración?

4. **¿Prioridad de pasos?**
   - ¿Primero consolidar Step 1 + 1.5?
   - ¿O empezar a trabajar en Step 2?

---

**Estado:** Documento para discusión  
**Próximo paso:** Decidir respuestas a preguntas antes de implementar


**Fecha:** 2025-11-01  
**Objetivo:** Comparar el objetivo final con la realidad actual para identificar gaps y planificar mejoras

---

## 🎯 QUÉ QUEREMOS (Objetivo Final)

### Visión Ideal
Un pipeline **simple y directo** como los pipelines estándar de GitHub (nf-core, skipper, etc.):

```
INPUT: Un archivo CSV
  ↓
./run.sh input.csv
  ↓
OUTPUTS: Todas las gráficas + tablas + viewers HTML
```

### Características Deseadas

1. **Input Simple y Único**
   - Un solo archivo CSV como entrada
   - Formato bien documentado
   - Validación automática del formato

2. **Ejecución Simple**
   - Un comando: `./run.sh input.csv`
   - Sin configuración manual necesaria
   - Auto-detección de parámetros

3. **Output Completo**
   - Todas las figuras (Step 1 + Step 1.5 + Step 2)
   - Todas las tablas CSV
   - Viewers HTML interactivos
   - Todo en directorio organizado

4. **Pipeline Genérico**
   - Funciona con cualquier dataset (ALS + Control)
   - No hardcodea rutas específicas
   - Configurable pero con defaults sensatos

---

## 🔍 QUÉ TENEMOS (Estado Actual)

### Input Actual (Confuso)

**Múltiples archivos de entrada:**
1. `processed_clean`: `/Users/cesaresparza/.../final_processed_data_CLEAN.csv`
   - Usado por: Step 1 (paneles B, E, F, G)
   
2. `raw`: `/Users/cesaresparza/.../miRNA_count.Q33.txt`
   - Usado por: Step 1 (paneles C, D)
   
3. `step1_original`: `/Users/cesaresparza/.../step1_original_data.csv`
   - Usado por: Step 1.5 (necesita SNV + total counts)

**Problemas:**
- ❌ Rutas hardcodeadas (absolutas, usuario-específicas)
- ❌ Múltiples inputs en lugar de uno solo
- ❌ No claro cuál es el "input principal"
- ❌ Usuario debe editar `config.yaml` manualmente

### Ejecución Actual

**Comandos disponibles:**
```bash
# Opción 1: Snakemake directo
snakemake -j 4

# Opción 2: Por pasos
snakemake -j 4 all_step1
snakemake -j 1 all_step1_5

# Opción 3: Panel individual
snakemake -j 1 outputs/step1/figures/step1_panelB_*.png
```

**Problemas:**
- ⚠️ Requiere editar `config.yaml` antes de ejecutar
- ⚠️ No hay script simple `run.sh` funcional aún
- ⚠️ No hay validación de input automática
- ✅ Snakemake funciona correctamente
- ✅ Paralelización funciona

### Output Actual

**Genera correctamente:**
- ✅ Step 1: 6 figuras + 6 tablas + viewer HTML
- ✅ Step 1.5: 11 figuras + 7 tablas + viewer HTML
- ✅ Step 2: Estructura lista pero no completado
- ✅ Viewers HTML funcionan

**Estructura:**
```
outputs/
├── step1/
│   ├── figures/ (6 PNGs)
│   ├── tables/ (6 CSVs)
│   └── logs/
├── step1_5/
│   ├── figures/ (11 PNGs)
│   ├── tables/ (7 CSVs)
│   └── logs/
└── step2/ (vacío por ahora)
```

**Problemas:**
- ⚠️ Outputs están bien organizados pero faltan algunos pasos

---

## 📋 GAPS (Diferencias)

### Gap 1: Input ❌

**Queremos:**
```
Un solo archivo CSV → Pipeline procesa todo
```

**Tenemos:**
```
3 archivos diferentes con rutas hardcodeadas
Usuario debe editar config.yaml manualmente
```

**Gap:**
- Falta unificación de inputs
- Falta auto-configuración
- Falta validación de formato

---

### Gap 2: Ejecución ⚠️

**Queremos:**
```
./run.sh input.csv  → Todo funciona automáticamente
```

**Tenemos:**
```
1. Editar config.yaml con rutas
2. snakemake -j 4
```

**Gap:**
- `run.sh` existe pero no actualiza config automáticamente
- Falta validación de input antes de ejecutar
- Falta manejo de errores claro

---

### Gap 3: Genericidad ⚠️

**Queremos:**
```
Pipeline genérico que funciona con cualquier dataset
```

**Tenemos:**
```
Rutas hardcodeadas a archivos específicos del usuario
Nombres de columnas asumidos pero no validados
```

**Gap:**
- Pipeline funciona pero no es portable
- Falta detección automática de formato
- Falta documentación clara del formato esperado

---

### Gap 4: Step 2 📋

**Queremos:**
```
Pipeline completo: Step 1 + Step 1.5 + Step 2
```

**Tenemos:**
```
Step 1 ✅ Completo
Step 1.5 ✅ Completo
Step 2 ❌ Incompleto (solo estructura)
```

**Gap:**
- Falta completar Step 2 (comparaciones grupo vs grupo)

---

## 🎯 DECISIONES NECESARIAS

### Pregunta 1: ¿Cuál debe ser el INPUT PRINCIPAL?

**Opción A: Archivo RAW original**
- Input: `miRNA_count.Q33.txt`
- Pipeline hace: split, collapse, procesamiento, análisis
- **Pro:** Más genérico, empieza desde raw
- **Contra:** Más lento, requiere más procesamiento

**Opción B: Archivo PROCESADO (split-collapse)**
- Input: `step1_original_data.csv` (ya procesado)
- Pipeline hace: análisis directo
- **Pro:** Más rápido, usuario ya procesó datos
- **Contra:** Asume formato específico

**Opción C: Ambos (auto-detección)**
- Pipeline detecta si es raw o processed
- **Pro:** Más flexible
- **Contra:** Más complejo de implementar

**⚠️ NECESITAMOS DECIDIR:** ¿Cuál queremos?

---

### Pregunta 2: ¿Cómo manejamos metadata (grupos)?

**Estado actual:**
- Step 1 y 1.5: No requieren metadata (funcionan sin grupos)
- Step 2: Requiere metadata (comparación ALS vs Control)

**Opciones:**

**Opción A: Input opcional**
```bash
./run.sh input.csv [metadata.csv]  # metadata opcional
```

**Opción B: Auto-detección**
- Pipeline busca metadata en directorio
- Si no encuentra, solo ejecuta Step 1 + 1.5

**Opción C: Configuración manual**
- Usuario edita config.yaml para metadata
- Más explícito pero menos automático

**⚠️ NECESITAMOS DECIDIR:** ¿Cómo lo manejamos?

---

### Pregunta 3: ¿Qué debe hacer el pipeline automáticamente?

**Opciones:**

**Nivel 1: Mínimo (actual)**
- Usuario edita config.yaml
- Ejecuta snakemake
- ✅ Funciona pero requiere configuración manual

**Nivel 2: Intermedio (propuesto)**
- Usuario pasa input como argumento
- run.sh actualiza config.yaml automáticamente
- Ejecuta pipeline
- ✅ Más simple pero aún requiere entender estructura

**Nivel 3: Máximo (ideal)**
- Usuario pasa input
- Pipeline valida formato
- Pipeline auto-detecta tipo (raw/processed)
- Pipeline decide qué steps ejecutar
- Pipeline genera todo automáticamente
- ✅ Máximo automatismo pero más complejo

**⚠️ NECESITAMOS DECIDIR:** ¿Hasta dónde queremos automatizar?

---

## 💡 RECOMENDACIONES

### Recomendación 1: Unificar Input (PRIORIDAD ALTA)

**Proponer:**
- Input principal: Archivo procesado (split-collapse)
- Formato: CSV con columnas `miRNA name`, `pos:mut`, y columnas de muestra
- Pipeline asume que datos ya están en formato correcto

**Razón:**
- Más rápido (no procesa raw)
- Usuario controla pre-procesamiento
- Más simple de validar

---

### Recomendación 2: Auto-configuración Simple (PRIORIDAD MEDIA)

**Proponer:**
```bash
./run.sh input.csv  # Actualiza config.yaml y ejecuta
```

**Implementar:**
- `run.sh` toma input como argumento
- Actualiza `config.yaml` automáticamente
- Valida que archivo existe
- Ejecuta pipeline

**Razón:**
- Balance entre simplicidad y control
- Usuario no edita YAML manualmente
- Pero puede si quiere (config.yaml sigue siendo editable)

---

### Recomendación 3: Metadata Opcional (PRIORIDAD MEDIA)

**Proponer:**
```bash
./run.sh input.csv [metadata.csv]  # metadata opcional
```

**Comportamiento:**
- Sin metadata: Ejecuta Step 1 + Step 1.5 (solo análisis exploratorio)
- Con metadata: Ejecuta Step 1 + Step 1.5 + Step 2 (comparaciones)

**Razón:**
- Permite usar pipeline sin grupos
- Agrega funcionalidad cuando metadata disponible
- Flexible y claro

---

### Recomendación 4: Completar Step 2 (PRIORIDAD BAJA)

**Proponer:**
- Step 2 como fase futura
- Por ahora: Step 1 + Step 1.5 completos y funcionando

**Razón:**
- Step 1 y 1.5 ya funcionan bien
- Step 2 requiere decisiones sobre metadata
- Mejor consolidar lo que funciona primero

---

## 📊 PLAN DE ACCIÓN PROPUESTO

### Fase 1: Unificar y Simplificar Input ⚡
1. Decidir: ¿raw o processed como input principal?
2. Simplificar config.yaml: Solo una ruta de input
3. Actualizar todas las reglas para usar el mismo input

### Fase 2: Auto-configuración 🔧
1. Implementar auto-actualización en run.sh
2. Validación básica de input (existe, formato CSV)
3. Mensajes de error claros

### Fase 3: Validación y Documentación 📚
1. Script de validación de formato
2. README actualizado con formato esperado
3. Ejemplo de datos pequeño incluido

### Fase 4: Metadata Opcional (futuro) 🔮
1. Implementar metadata como argumento opcional
2. Auto-detección de grupos
3. Step 2 condicional basado en metadata

---

## ❓ PREGUNTAS PARA DISCUTIR

1. **¿Raw o Processed como input principal?**
   - ¿Prefieres que usuario procese datos primero?
   - ¿O prefieres pipeline completo desde raw?

2. **¿Qué tan automático queremos?**
   - ¿Solo auto-config o también auto-detección de formato?

3. **¿Metadata cómo lo manejamos?**
   - ¿Opcional como argumento?
   - ¿O parte de configuración?

4. **¿Prioridad de pasos?**
   - ¿Primero consolidar Step 1 + 1.5?
   - ¿O empezar a trabajar en Step 2?

---

**Estado:** Documento para discusión  
**Próximo paso:** Decidir respuestas a preguntas antes de implementar

