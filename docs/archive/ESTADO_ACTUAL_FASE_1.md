# 📊 ESTADO ACTUAL: FASE 1 - Migración Paso 1

**Última actualización:** 2025-01-28

---

## ✅ Completado

### Paso 1.1 (Parcial):
- ✅ Creado `scripts/utils/functions_common.R` (funciones compartidas)
- ✅ Adaptado primer script: `scripts/step1/01_panel_b_gt_count_by_position.R`
- ⏳ Pendiente: Adaptar scripts restantes (03, 04, 05, 06, 07)

### Paso 1.2 (Parcial):
- ✅ Creado `rules/step1.smk` con regla para Panel B
- ✅ Creado `Snakefile` principal (incluye step1.smk)
- ⏳ Pendiente: Agregar reglas para paneles C, D, E, F, G

---

## 📁 Archivos Creados

### Scripts R:
```
snakemake_pipeline/
├── scripts/
│   ├── utils/
│   │   └── functions_common.R  ✅ (funciones compartidas)
│   └── step1/
│       └── 01_panel_b_gt_count_by_position.R  ✅ (adaptado para Snakemake)
```

### Reglas Snakemake:
```
snakemake_pipeline/
├── Snakefile  ✅ (orquestador principal)
└── rules/
    └── step1.smk  ✅ (regla para Panel B)
```

---

## 🔍 Verificación Necesaria

Antes de continuar, necesitamos:

1. **Verificar rutas de datos:**
   - ✅ Input: `config/config.yaml` tiene ruta a `final_processed_data.csv`
   - ⚠️ Verificar que el archivo existe en esa ubicación

2. **Instalar Snakemake** (cuando esté listo para probar):
   ```bash
   conda install -c bioconda -c conda-forge snakemake
   ```

3. **Probar Panel B** antes de continuar:
   ```bash
   cd snakemake_pipeline
   snakemake -n panel_b_gt_count_by_position  # Dry-run
   snakemake -j 1 panel_b_gt_count_by_position  # Ejecutar
   ```

---

## 📋 Próximos Pasos

### Inmediato:
1. Verificar/ajustar ruta de input en `config/config.yaml`
2. Probar ejecución de Panel B (si Snakemake está disponible)
3. Adaptar scripts restantes (03, 04, 05, 06, 07) siguiendo el mismo patrón

### Patrón a seguir:
Cada script adaptado debe:
- Recibir `input`, `output`, `params` desde `snakemake@...`
- Usar `load_processed_data()` de `functions_common.R`
- Usar `ensure_output_dir()` para crear directorios
- Usar `theme_professional` y `COLOR_GT` de `functions_common.R`

---

## ⚠️ Notas

- Los scripts originales usan `../pipeline_2/final_processed_data_CLEAN.csv`
- En Snakemake, la ruta viene desde `config.yaml`
- Necesitamos decidir qué versión de datos usar (CLEAN vs normal)

---

**Estado:** 🟡 En progreso - Primer script y reglas creadas, pendiente verificación y adaptar resto

