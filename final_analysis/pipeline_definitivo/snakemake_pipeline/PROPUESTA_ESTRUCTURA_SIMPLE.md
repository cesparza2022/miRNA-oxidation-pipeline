# 💡 Propuesta: Estructura Simple tipo Pipeline GitHub

## 🎯 Objetivo

Simplificar el pipeline para que sea tan simple como los pipelines estándar de GitHub:
- **Input**: Un archivo CSV
- **Output**: Todas las gráficas y tablas
- **Comando**: `./run.sh input.csv` o `snakemake -j 4`

## 📐 Estructura Propuesta (Inspirada en nf-core/snakemake pipelines)

```
snakemake_pipeline/
├── README.md                    # ⭐ README simple y directo
├── run.sh                      # 🚀 Script ejecutor simple
├── config/
│   └── config.yaml             # ⚙️ Configuración simple
├── Snakefile                    # Orquestador principal
├── rules/                       # Reglas Snakemake
│   ├── step1.smk
│   ├── step1_5.smk
│   └── viewers.smk
├── scripts/                     # Scripts R
│   ├── step1/
│   ├── step1_5/
│   └── utils/
├── envs/                        # Ambientes conda
│   ├── r_base.yaml
│   └── r_analysis.yaml
├── outputs/                     # Salidas (generadas automáticamente)
│   ├── step1/
│   ├── step1_5/
│   └── step2/
└── viewers/                     # Viewers HTML (generados)
    ├── step1.html
    └── step1_5.html
```

## 🚀 Uso Propuesto

### Opción A: Script Wrapper (Más Simple)
```bash
./run.sh input.csv
```

### Opción B: Snakemake Directo
```bash
# 1. Configurar input en config.yaml
# 2. Ejecutar
snakemake -j 4
```

## 📝 Cambios Necesarios

### 1. ✅ Script `run.sh` (Ya creado)
- Verifica dependencias
- Prepara ambiente
- Ejecuta pipeline
- Muestra resumen

### 2. ⚠️ Configuración Automática de Input
**Actual**: Rutas hardcodeadas en `config.yaml`
**Propuesto**: Auto-detección o argumento de línea de comandos

**Solución A (Simple)**: 
```yaml
# config.yaml
paths:
  data:
    input: null  # Se actualiza automáticamente o por argumento
```

**Solución B (Mejor)**: 
```bash
# run.sh actualiza config.yaml automáticamente
./run.sh input.csv  # Actualiza config.yaml con esta ruta
```

### 3. ⚠️ README Simplificado
**Ya creado**: `README_SIMPLE.md`

Contiene:
- Formato de input esperado
- Uso básico
- Ejemplos
- Troubleshooting simple

### 4. 📋 Validación de Input
Agregar script que valide formato de input antes de ejecutar:

```bash
# scripts/validate_input.R
# Verifica:
# - Columnas requeridas existen
# - Formato de pos:mut es correcto
# - Columnas de muestra tienen formato correcto
```

## 🔄 Flujo Propuesto

```
1. Usuario ejecuta: ./run.sh input.csv
   ↓
2. run.sh:
   - Valida input
   - Actualiza config.yaml (opcional)
   - Verifica dependencias
   - Prepara directorios
   ↓
3. Ejecuta: snakemake -j 4
   ↓
4. Pipeline:
   - Step 1: Análisis exploratorio
   - Step 1.5: Control calidad VAF
   - Genera viewers HTML
   ↓
5. run.sh muestra resumen:
   - Número de figuras generadas
   - Número de tablas generadas
   - Ubicación de viewers
```

## 📊 Comparación con Pipelines Estándar

### nf-core/chipseq
```bash
nextflow run nf-core/chipseq --input samplesheet.csv
```

### Nuestro Pipeline (Propuesto)
```bash
./run.sh input.csv
```

**Similitudes**:
- Un solo comando
- Input como argumento
- Outputs en directorio organizado
- README simple

## ✅ Implementación Priorizada

### Fase 1: Básico (Ya hecho)
- ✅ `run.sh` creado
- ✅ `README_SIMPLE.md` creado
- ⚠️ Auto-actualización de config.yaml

### Fase 2: Mejoras
- ⚠️ Validación de input
- ⚠️ Auto-detección de formato
- ⚠️ Mensajes de error claros

### Fase 3: Avanzado
- 📋 Tests automatizados
- 📋 Ejemplo de datos incluido
- 📋 CI/CD para GitHub

## 🎯 Próximos Pasos

1. **Implementar auto-actualización de config.yaml en run.sh**
   ```bash
   # En run.sh, agregar:
   if [ -n "$1" ]; then
       sed -i '' "s|input:.*|input: \"$INPUT_FILE\"|" config/config.yaml
   fi
   ```

2. **Crear script de validación de input**
   ```r
   # scripts/validate_input.R
   # Valida formato antes de ejecutar pipeline
   ```

3. **Agregar datos de ejemplo**
   ```
   example_data/
   └── sample_input.csv  # Dataset pequeño para pruebas
   ```

4. **Simplificar config.yaml**
   ```yaml
   # Solo lo esencial
   input: null  # Se actualiza automáticamente
   output_dir: "outputs"
   threads: 4
   ```

## 💡 Ventajas de Esta Estructura

1. **Simple**: Un comando para ejecutar todo
2. **Estándar**: Similar a pipelines de GitHub populares
3. **Clara**: README directo al punto
4. **Mantenible**: Estructura organizada
5. **Reproducible**: Snakemake maneja dependencias

---

**Estado**: Propuesta lista para implementar
**Prioridad**: Fase 1 (básico) casi completo, solo falta auto-configuración

