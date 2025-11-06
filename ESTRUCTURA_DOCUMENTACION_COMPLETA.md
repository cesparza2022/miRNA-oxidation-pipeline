# 📁 ESTRUCTURA Y DOCUMENTACIÓN COMPLETA DEL PIPELINE

**Fecha:** 2025-01-21  
**Pipeline:** miRNA Oxidation Analysis Pipeline (Snakemake)

---

## 📂 ESTRUCTURA DE DIRECTORIOS

```
snakemake_pipeline/
├── config/                    # Configuración
│   ├── config.yaml            # Configuración principal (NO en git)
│   ├── config.yaml.example    # Template de configuración
│   └── config.yaml.backup     # Backup
│
├── scripts/                   # Scripts R por step
│   ├── step1/                 # 6 scripts (exploratory analysis)
│   ├── step1_5/               # 2 scripts (VAF quality control)
│   ├── step2/                 # 5 scripts (statistical comparisons)
│   ├── step3/                 # 2 scripts (clustering analysis)
│   ├── step4/                 # 2 scripts (family analysis)
│   ├── step5/                 # 2 scripts (expression correlation)
│   ├── step6/                 # 3 scripts (functional analysis)
│   ├── step7/                 # 2 scripts (biomarker analysis)
│   └── utils/                 # 26 scripts utilitarios
│
├── rules/                     # Snakemake rules por step
│   ├── step1.smk
│   ├── step1_5.smk
│   ├── step2.smk
│   ├── step3.smk
│   ├── step4.smk
│   ├── step5.smk
│   ├── step6.smk
│   ├── step7.smk
│   ├── validation.smk
│   ├── output_structure.smk
│   ├── pipeline_info.smk
│   ├── summary.smk
│   └── viewers.smk
│
├── docs/                      # Documentación completa
│   ├── INDEX.md               # Índice de documentación
│   ├── USER_GUIDE.md          # Guía de usuario completa
│   ├── PIPELINE_OVERVIEW.md   # Resumen científico
│   ├── HOW_IT_WORKS.md        # Explicación técnica
│   ├── DATA_FORMAT_AND_FLEXIBILITY.md
│   ├── FLEXIBLE_GROUP_SYSTEM.md
│   ├── METHODOLOGY.md         # Metodología estadística
│   ├── OUTPUT_STRUCTURE.md
│   ├── PIPELINE_EXECUTION_ORDER.md
│   └── ... (más archivos)
│
├── envs/                      # Conda environments
│   ├── r_base.yaml
│   └── r_analysis.yaml
│
├── results/                   # Outputs (generados automáticamente)
│   ├── step1/
│   ├── step1_5/
│   ├── step2/
│   ├── step3/
│   ├── step4/
│   ├── step5/
│   ├── step6/
│   ├── step7/
│   └── pipeline_info/
│
├── viewers/                   # HTML viewers (generados automáticamente)
│
├── Snakefile                  # Orquestador principal
├── README.md                  # Documentación principal
├── QUICK_START.md             # Inicio rápido
├── SETUP.md                   # Instalación
├── .gitignore                 # Archivos ignorados
└── LICENSE                    # Licencia
```

---

## 📚 DOCUMENTACIÓN DISPONIBLE

### **Documentación Principal**

1. **README.md** - Documentación principal del pipeline
   - Descripción general
   - Instalación
   - Uso básico
   - Troubleshooting

2. **QUICK_START.md** - Guía de inicio rápido (5 minutos)
   - Instalación rápida
   - Configuración mínima
   - Ejecución básica

3. **SETUP.md** - Guía de instalación detallada
   - Requisitos del sistema
   - Instalación de dependencias
   - Configuración del entorno

### **Documentación Técnica (docs/)**

1. **INDEX.md** - Índice completo de documentación
   - Organización de toda la documentación
   - Enlaces a todas las guías

2. **USER_GUIDE.md** - Guía de usuario completa
   - Instalación paso a paso
   - Configuración detallada
   - Ejecución del pipeline
   - Interpretación de outputs
   - Troubleshooting avanzado

3. **PIPELINE_OVERVIEW.md** - Resumen científico
   - Contexto científico
   - Descripción de cada step
   - Metodología general

4. **HOW_IT_WORKS.md** - Explicación técnica
   - Arquitectura del pipeline
   - Sistema flexible de grupos
   - Flujo de datos

5. **DATA_FORMAT_AND_FLEXIBILITY.md** - Formato de datos
   - Especificación de formato de input
   - Parsing de grupos
   - Flexibilidad del sistema

6. **FLEXIBLE_GROUP_SYSTEM.md** - Sistema de grupos
   - Uso de metadata files
   - Pattern matching fallback
   - Configuración

7. **METHODOLOGY.md** - Metodología estadística
   - Validación de asunciones
   - Análisis de batch effects
   - Análisis de confounders
   - Selección de tests

8. **OUTPUT_STRUCTURE.md** - Estructura de outputs
   - Organización de resultados
   - Naming conventions
   - Formatos de archivos

9. **PIPELINE_EXECUTION_ORDER.md** - Orden de ejecución
   - Dependencias entre steps
   - Orden de ejecución
   - Paralelización

10. **DECISIONES_DISENO.md** - Decisiones de diseño
    - Justificación científica
    - Umbrales configurables
    - Metodología

---

## 🔧 CONFIGURACIÓN

### **Archivos de Configuración**

1. **config/config.yaml.example** - Template
   - Ejemplo completo comentado
   - Explicación de cada parámetro
   - Paths de ejemplo

2. **config/config.yaml** - Configuración actual
   - Configuración real del proyecto
   - NO incluido en git (por seguridad)
   - Usa paths relativos cuando es posible

### **Parámetros Principales**

```yaml
paths:
  data:
    raw: "../../../organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
    processed_clean: "..."
    step1_original: "..."
    metadata: null  # Opcional

analysis:
  vaf_filter_threshold: 0.5
  alpha: 0.05
  log2fc_threshold_step2: 0.58
  seed_region:
    start: 2
    end: 8
```

---

## 📊 ESTADÍSTICAS DEL PIPELINE

- **Total scripts R:** ~44 scripts
- **Total rules Snakemake:** 11 archivos .smk
- **Documentación:** ~15 archivos .md
- **Steps:** 7 steps principales + 1 step de QC
- **Outputs por step:** Figuras PNG + Tablas CSV + Logs

---

## 🎯 FLUJO DE EJECUCIÓN

```
1. validate_configuration  → Valida config.yaml
2. validate_packages       → Valida paquetes R
3. create_output_structure  → Crea directorios
4. all_step1               → Análisis exploratorio (6 paneles)
5. all_step1_5             → VAF quality control
6. all_step2               → Comparaciones estadísticas
7. all_step3               → Clustering (requiere step2)
8. all_step4, all_step5, all_step6  → Paralelo (requieren step2, step3)
9. all_step7               → Biomarker analysis (requiere step6)
10. validate_pipeline_completion → Validación final
```

---

## ✅ ESTADO ACTUAL

- ✅ Estructura completa y organizada
- ✅ Documentación exhaustiva
- ✅ Configuración flexible
- ✅ Validaciones robustas
- ✅ Listo para producción

---

**Última actualización:** 2025-01-21

