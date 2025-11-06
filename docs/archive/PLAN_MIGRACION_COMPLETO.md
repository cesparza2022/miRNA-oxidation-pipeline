# 🐍 PLAN COMPLETO DE MIGRACIÓN A SNAKEMAKE

**Estado actual:** Paso 1 completo (6 paneles + viewer HTML) ✅  
**Fecha:** 2025-01-30

---

## ✅ COMPLETADO

### FASE 0: Preparación Base ✅
- ✅ Estructura de directorios
- ✅ `config/config.yaml`
- ✅ Conda environments (deshabilitados - usando R local)
- ✅ `.gitignore` y `README.md`

### FASE 1: Paso 1 Completo ✅
- ✅ **FASE 1.1:** 6 scripts R adaptados
- ✅ **FASE 1.2:** Reglas Snakemake creadas
- ✅ **FASE 1.3:** Integrado en Snakefile
- ✅ **FASE 1.4:** Viewer HTML generado automáticamente
- ✅ **Verificación:** Todos los paneles ejecutados exitosamente

**Outputs generados:**
- 6 figuras PNG
- 6 tablas CSV
- 1 viewer HTML (`viewers/step1.html`)

---

## 📋 PRÓXIMOS PASOS (Paso a Paso)

### **PASO 2: Migrar Paso 1.5 (VAF Quality Control)**

**Objetivo:** Migrar los 2 scripts del Paso 1.5 a Snakemake

**Scripts a migrar:**
1. `01_apply_vaf_filter.R` - Aplica filtro VAF >= 0.5
2. `02_generate_diagnostic_figures.R` - Genera 11 figuras

**Tareas:**
- [ ] **Tarea 2.1:** Revisar scripts originales de `step1_5/scripts/`
- [ ] **Tarea 2.2:** Adaptar rutas en scripts para Snakemake
- [ ] **Tarea 2.3:** Crear `rules/step1_5.smk` con 2 reglas
- [ ] **Tarea 2.4:** Crear regla agregadora `all_step1_5`
- [ ] **Tarea 2.5:** Crear script `build_step1_5_viewer.R`
- [ ] **Tarea 2.6:** Agregar regla `generate_step1_5_viewer` en `viewers.smk`
- [ ] **Tarea 2.7:** Integrar en `Snakefile` principal
- [ ] **Tarea 2.8:** Probar ejecución completa (dry-run + real)
- [ ] **Tarea 2.9:** Verificar outputs y viewer HTML

**Estimación:** ~1 hora (podemos hacerlo en 2-3 mensajes)

---

### **PASO 3: Migrar Paso 2 (Comparaciones ALS vs Control)**

**Objetivo:** Migrar los scripts del Paso 2 a Snakemake

**Scripts a migrar:**
- ~15 scripts individuales para figuras 2.1-2.12
- Script para density heatmaps (2.13-2.15)

**Tareas:**
- [ ] **Tarea 3.1:** Identificar todos los scripts de `step2/scripts/`
- [ ] **Tarea 3.2:** Adaptar rutas en cada script
- [ ] **Tarea 3.3:** Crear `rules/step2.smk` con reglas para cada figura
- [ ] **Tarea 3.4:** Manejar golden copies (2.13-2.15)
- [ ] **Tarea 3.5:** Crear script `build_step2_viewer.R`
- [ ] **Tarea 3.6:** Agregar regla `generate_step2_viewer` en `viewers.smk`
- [ ] **Tarea 3.7:** Integrar en `Snakefile` principal
- [ ] **Tarea 3.8:** Probar ejecución completa
- [ ] **Tarea 3.9:** Verificar viewer HTML con imágenes embebidas

**Estimación:** ~2-3 horas (podemos hacerlo en 4-5 mensajes)

---

### **PASO 4: Pipeline Completo y Testing**

**Objetivo:** Asegurar que todo funciona end-to-end

**Tareas:**
- [ ] **Tarea 4.1:** Actualizar regla `all` para incluir todos los pasos
- [ ] **Tarea 4.2:** Ejecutar pipeline completo: `snakemake -j 1`
- [ ] **Tarea 4.3:** Verificar todos los outputs
- [ ] **Tarea 4.4:** Crear script de validación `validate_pipeline.R`
- [ ] **Tarea 4.5:** Documentar uso completo

**Estimación:** ~30 min

---

### **PASO 5: Documentación y GitHub**

**Objetivo:** Preparar para GitHub

**Tareas:**
- [ ] **Tarea 5.1:** Actualizar `README.md` con instrucciones completas
- [ ] **Tarea 5.2:** Crear `CHANGELOG.md`
- [ ] **Tarea 5.3:** Agregar ejemplos de uso
- [ ] **Tarea 5.4:** Crear `.github/workflows/` (CI/CD básico - opcional)
- [ ] **Tarea 5.5:** Documentar estructura y convenciones

**Estimación:** ~1 hora

---

## 🎯 ESTRATEGIA DE EJECUCIÓN

**Recomendación:** Hacer cada paso en mensajes separados:

1. **Mensaje 1:** Planificar y revisar scripts (solo lectura)
2. **Mensaje 2:** Adaptar scripts y crear reglas (escritura)
3. **Mensaje 3:** Probar y verificar (ejecución)

Esto evita que se trabe y permite revisar entre pasos.

---

## 📊 RESUMEN DE ESTADO

| Fase | Estado | Paneles/Scripts | Outputs |
|------|--------|-----------------|---------|
| **FASE 0** | ✅ | Estructura base | - |
| **FASE 1** | ✅ | 6 paneles + viewer | 6 figuras, 6 tablas, 1 HTML |
| **FASE 2** | ⏳ | 2 scripts + viewer | Pendiente |
| **FASE 3** | ⏳ | ~15 scripts + viewer | Pendiente |
| **FASE 4** | ⏳ | Testing completo | Pendiente |
| **FASE 5** | ⏳ | Documentación | Pendiente |

**Progreso total:** ~25% (FASE 1 completada)

---

## 🚀 COMANDO ACTUAL

**Para ejecutar solo Paso 1:**
```bash
cd snakemake_pipeline
snakemake -j 1 all_step1 generate_step1_viewer
```

**Para ver qué se ejecutaría:**
```bash
snakemake -n  # Dry-run completo
```

---

**Próximo paso sugerido:** Empezar con PASO 2, Tarea 2.1 (revisar scripts del Paso 1.5)


**Estado actual:** Paso 1 completo (6 paneles + viewer HTML) ✅  
**Fecha:** 2025-01-30

---

## ✅ COMPLETADO

### FASE 0: Preparación Base ✅
- ✅ Estructura de directorios
- ✅ `config/config.yaml`
- ✅ Conda environments (deshabilitados - usando R local)
- ✅ `.gitignore` y `README.md`

### FASE 1: Paso 1 Completo ✅
- ✅ **FASE 1.1:** 6 scripts R adaptados
- ✅ **FASE 1.2:** Reglas Snakemake creadas
- ✅ **FASE 1.3:** Integrado en Snakefile
- ✅ **FASE 1.4:** Viewer HTML generado automáticamente
- ✅ **Verificación:** Todos los paneles ejecutados exitosamente

**Outputs generados:**
- 6 figuras PNG
- 6 tablas CSV
- 1 viewer HTML (`viewers/step1.html`)

---

## 📋 PRÓXIMOS PASOS (Paso a Paso)

### **PASO 2: Migrar Paso 1.5 (VAF Quality Control)**

**Objetivo:** Migrar los 2 scripts del Paso 1.5 a Snakemake

**Scripts a migrar:**
1. `01_apply_vaf_filter.R` - Aplica filtro VAF >= 0.5
2. `02_generate_diagnostic_figures.R` - Genera 11 figuras

**Tareas:**
- [ ] **Tarea 2.1:** Revisar scripts originales de `step1_5/scripts/`
- [ ] **Tarea 2.2:** Adaptar rutas en scripts para Snakemake
- [ ] **Tarea 2.3:** Crear `rules/step1_5.smk` con 2 reglas
- [ ] **Tarea 2.4:** Crear regla agregadora `all_step1_5`
- [ ] **Tarea 2.5:** Crear script `build_step1_5_viewer.R`
- [ ] **Tarea 2.6:** Agregar regla `generate_step1_5_viewer` en `viewers.smk`
- [ ] **Tarea 2.7:** Integrar en `Snakefile` principal
- [ ] **Tarea 2.8:** Probar ejecución completa (dry-run + real)
- [ ] **Tarea 2.9:** Verificar outputs y viewer HTML

**Estimación:** ~1 hora (podemos hacerlo en 2-3 mensajes)

---

### **PASO 3: Migrar Paso 2 (Comparaciones ALS vs Control)**

**Objetivo:** Migrar los scripts del Paso 2 a Snakemake

**Scripts a migrar:**
- ~15 scripts individuales para figuras 2.1-2.12
- Script para density heatmaps (2.13-2.15)

**Tareas:**
- [ ] **Tarea 3.1:** Identificar todos los scripts de `step2/scripts/`
- [ ] **Tarea 3.2:** Adaptar rutas en cada script
- [ ] **Tarea 3.3:** Crear `rules/step2.smk` con reglas para cada figura
- [ ] **Tarea 3.4:** Manejar golden copies (2.13-2.15)
- [ ] **Tarea 3.5:** Crear script `build_step2_viewer.R`
- [ ] **Tarea 3.6:** Agregar regla `generate_step2_viewer` en `viewers.smk`
- [ ] **Tarea 3.7:** Integrar en `Snakefile` principal
- [ ] **Tarea 3.8:** Probar ejecución completa
- [ ] **Tarea 3.9:** Verificar viewer HTML con imágenes embebidas

**Estimación:** ~2-3 horas (podemos hacerlo en 4-5 mensajes)

---

### **PASO 4: Pipeline Completo y Testing**

**Objetivo:** Asegurar que todo funciona end-to-end

**Tareas:**
- [ ] **Tarea 4.1:** Actualizar regla `all` para incluir todos los pasos
- [ ] **Tarea 4.2:** Ejecutar pipeline completo: `snakemake -j 1`
- [ ] **Tarea 4.3:** Verificar todos los outputs
- [ ] **Tarea 4.4:** Crear script de validación `validate_pipeline.R`
- [ ] **Tarea 4.5:** Documentar uso completo

**Estimación:** ~30 min

---

### **PASO 5: Documentación y GitHub**

**Objetivo:** Preparar para GitHub

**Tareas:**
- [ ] **Tarea 5.1:** Actualizar `README.md` con instrucciones completas
- [ ] **Tarea 5.2:** Crear `CHANGELOG.md`
- [ ] **Tarea 5.3:** Agregar ejemplos de uso
- [ ] **Tarea 5.4:** Crear `.github/workflows/` (CI/CD básico - opcional)
- [ ] **Tarea 5.5:** Documentar estructura y convenciones

**Estimación:** ~1 hora

---

## 🎯 ESTRATEGIA DE EJECUCIÓN

**Recomendación:** Hacer cada paso en mensajes separados:

1. **Mensaje 1:** Planificar y revisar scripts (solo lectura)
2. **Mensaje 2:** Adaptar scripts y crear reglas (escritura)
3. **Mensaje 3:** Probar y verificar (ejecución)

Esto evita que se trabe y permite revisar entre pasos.

---

## 📊 RESUMEN DE ESTADO

| Fase | Estado | Paneles/Scripts | Outputs |
|------|--------|-----------------|---------|
| **FASE 0** | ✅ | Estructura base | - |
| **FASE 1** | ✅ | 6 paneles + viewer | 6 figuras, 6 tablas, 1 HTML |
| **FASE 2** | ⏳ | 2 scripts + viewer | Pendiente |
| **FASE 3** | ⏳ | ~15 scripts + viewer | Pendiente |
| **FASE 4** | ⏳ | Testing completo | Pendiente |
| **FASE 5** | ⏳ | Documentación | Pendiente |

**Progreso total:** ~25% (FASE 1 completada)

---

## 🚀 COMANDO ACTUAL

**Para ejecutar solo Paso 1:**
```bash
cd snakemake_pipeline
snakemake -j 1 all_step1 generate_step1_viewer
```

**Para ver qué se ejecutaría:**
```bash
snakemake -n  # Dry-run completo
```

---

**Próximo paso sugerido:** Empezar con PASO 2, Tarea 2.1 (revisar scripts del Paso 1.5)


**Estado actual:** Paso 1 completo (6 paneles + viewer HTML) ✅  
**Fecha:** 2025-01-30

---

## ✅ COMPLETADO

### FASE 0: Preparación Base ✅
- ✅ Estructura de directorios
- ✅ `config/config.yaml`
- ✅ Conda environments (deshabilitados - usando R local)
- ✅ `.gitignore` y `README.md`

### FASE 1: Paso 1 Completo ✅
- ✅ **FASE 1.1:** 6 scripts R adaptados
- ✅ **FASE 1.2:** Reglas Snakemake creadas
- ✅ **FASE 1.3:** Integrado en Snakefile
- ✅ **FASE 1.4:** Viewer HTML generado automáticamente
- ✅ **Verificación:** Todos los paneles ejecutados exitosamente

**Outputs generados:**
- 6 figuras PNG
- 6 tablas CSV
- 1 viewer HTML (`viewers/step1.html`)

---

## 📋 PRÓXIMOS PASOS (Paso a Paso)

### **PASO 2: Migrar Paso 1.5 (VAF Quality Control)**

**Objetivo:** Migrar los 2 scripts del Paso 1.5 a Snakemake

**Scripts a migrar:**
1. `01_apply_vaf_filter.R` - Aplica filtro VAF >= 0.5
2. `02_generate_diagnostic_figures.R` - Genera 11 figuras

**Tareas:**
- [ ] **Tarea 2.1:** Revisar scripts originales de `step1_5/scripts/`
- [ ] **Tarea 2.2:** Adaptar rutas en scripts para Snakemake
- [ ] **Tarea 2.3:** Crear `rules/step1_5.smk` con 2 reglas
- [ ] **Tarea 2.4:** Crear regla agregadora `all_step1_5`
- [ ] **Tarea 2.5:** Crear script `build_step1_5_viewer.R`
- [ ] **Tarea 2.6:** Agregar regla `generate_step1_5_viewer` en `viewers.smk`
- [ ] **Tarea 2.7:** Integrar en `Snakefile` principal
- [ ] **Tarea 2.8:** Probar ejecución completa (dry-run + real)
- [ ] **Tarea 2.9:** Verificar outputs y viewer HTML

**Estimación:** ~1 hora (podemos hacerlo en 2-3 mensajes)

---

### **PASO 3: Migrar Paso 2 (Comparaciones ALS vs Control)**

**Objetivo:** Migrar los scripts del Paso 2 a Snakemake

**Scripts a migrar:**
- ~15 scripts individuales para figuras 2.1-2.12
- Script para density heatmaps (2.13-2.15)

**Tareas:**
- [ ] **Tarea 3.1:** Identificar todos los scripts de `step2/scripts/`
- [ ] **Tarea 3.2:** Adaptar rutas en cada script
- [ ] **Tarea 3.3:** Crear `rules/step2.smk` con reglas para cada figura
- [ ] **Tarea 3.4:** Manejar golden copies (2.13-2.15)
- [ ] **Tarea 3.5:** Crear script `build_step2_viewer.R`
- [ ] **Tarea 3.6:** Agregar regla `generate_step2_viewer` en `viewers.smk`
- [ ] **Tarea 3.7:** Integrar en `Snakefile` principal
- [ ] **Tarea 3.8:** Probar ejecución completa
- [ ] **Tarea 3.9:** Verificar viewer HTML con imágenes embebidas

**Estimación:** ~2-3 horas (podemos hacerlo en 4-5 mensajes)

---

### **PASO 4: Pipeline Completo y Testing**

**Objetivo:** Asegurar que todo funciona end-to-end

**Tareas:**
- [ ] **Tarea 4.1:** Actualizar regla `all` para incluir todos los pasos
- [ ] **Tarea 4.2:** Ejecutar pipeline completo: `snakemake -j 1`
- [ ] **Tarea 4.3:** Verificar todos los outputs
- [ ] **Tarea 4.4:** Crear script de validación `validate_pipeline.R`
- [ ] **Tarea 4.5:** Documentar uso completo

**Estimación:** ~30 min

---

### **PASO 5: Documentación y GitHub**

**Objetivo:** Preparar para GitHub

**Tareas:**
- [ ] **Tarea 5.1:** Actualizar `README.md` con instrucciones completas
- [ ] **Tarea 5.2:** Crear `CHANGELOG.md`
- [ ] **Tarea 5.3:** Agregar ejemplos de uso
- [ ] **Tarea 5.4:** Crear `.github/workflows/` (CI/CD básico - opcional)
- [ ] **Tarea 5.5:** Documentar estructura y convenciones

**Estimación:** ~1 hora

---

## 🎯 ESTRATEGIA DE EJECUCIÓN

**Recomendación:** Hacer cada paso en mensajes separados:

1. **Mensaje 1:** Planificar y revisar scripts (solo lectura)
2. **Mensaje 2:** Adaptar scripts y crear reglas (escritura)
3. **Mensaje 3:** Probar y verificar (ejecución)

Esto evita que se trabe y permite revisar entre pasos.

---

## 📊 RESUMEN DE ESTADO

| Fase | Estado | Paneles/Scripts | Outputs |
|------|--------|-----------------|---------|
| **FASE 0** | ✅ | Estructura base | - |
| **FASE 1** | ✅ | 6 paneles + viewer | 6 figuras, 6 tablas, 1 HTML |
| **FASE 2** | ⏳ | 2 scripts + viewer | Pendiente |
| **FASE 3** | ⏳ | ~15 scripts + viewer | Pendiente |
| **FASE 4** | ⏳ | Testing completo | Pendiente |
| **FASE 5** | ⏳ | Documentación | Pendiente |

**Progreso total:** ~25% (FASE 1 completada)

---

## 🚀 COMANDO ACTUAL

**Para ejecutar solo Paso 1:**
```bash
cd snakemake_pipeline
snakemake -j 1 all_step1 generate_step1_viewer
```

**Para ver qué se ejecutaría:**
```bash
snakemake -n  # Dry-run completo
```

---

**Próximo paso sugerido:** Empezar con PASO 2, Tarea 2.1 (revisar scripts del Paso 1.5)

