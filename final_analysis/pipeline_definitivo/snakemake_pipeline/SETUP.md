# 🛠️ Guía de Instalación y Configuración

**Pipeline:** ALS miRNA Oxidation Analysis Pipeline  
**Última actualización:** 2025-11-02

---

## 📋 Requisitos Previos

Antes de comenzar, necesitas tener instalado uno de los siguientes:

- **Conda** (Miniconda o Anaconda) - [Descargar Miniconda](https://docs.conda.io/en/latest/miniconda.html)
- **Mamba** (más rápido que conda) - [Instalación](https://mamba.readthedocs.io/en/latest/installation.html)

### Verificar instalación:

```bash
# Verificar conda
conda --version

# O verificar mamba
mamba --version
```

---

## 🚀 Instalación Completa del Ambiente

### Opción 1: Ambiente Completo (Recomendado)

Este método instala Python, Snakemake, R y todos los paquetes necesarios en un solo ambiente:

```bash
# Navegar al directorio del pipeline
cd snakemake_pipeline

# Crear ambiente con conda (tarda ~10-15 minutos)
conda env create -f environment.yaml

# Activar el ambiente
conda activate als_mirna_pipeline

# Verificar instalación
snakemake --version
R --version
```

**Alternativa con mamba (más rápido, ~5-8 minutos):**

```bash
mamba env create -f environment.yaml
mamba activate als_mirna_pipeline
```

### Opción 2: Instalación Manual por Componentes

Si prefieres instalar componentes por separado:

#### 2.1. Instalar Snakemake y Python

```bash
# Con conda
conda install -c bioconda -c conda-forge snakemake=7.32 python=3.10

# O con mamba (más rápido)
mamba install -c bioconda -c conda-forge snakemake=7.32 python=3.10
```

#### 2.2. Instalar R y Paquetes R

```bash
# Crear ambiente R base
conda env create -f envs/r_analysis.yaml
conda activate r_analysis

# O instalar R manualmente
conda install -c conda-forge r-base=4.3.2
```

#### 2.3. Instalar Paquetes R Adicionales

Si falta algún paquete, instalarlo con conda:

```bash
conda install -c conda-forge r-package-name
```

O desde R:

```R
install.packages("package-name")
```

---

## ✅ Verificar Instalación

Ejecuta estos comandos para verificar que todo está instalado correctamente:

```bash
# Verificar Snakemake
snakemake --version
# Debe mostrar: snakemake, version 7.32.x o superior

# Verificar Python
python --version
# Debe mostrar: Python 3.10.x o superior

# Verificar R
R --version
# Debe mostrar: R version 4.3.2 o superior

# Verificar paquetes R críticos
Rscript -e "library(ggplot2); library(dplyr); library(pheatmap); cat('✅ Todos los paquetes R están instalados\n')"
```

---

## 🔧 Configuración del Pipeline

### 1. Configurar rutas de datos

```bash
# Copiar archivo de configuración de ejemplo
cp config/config.yaml.example config/config.yaml

# Editar configuración (usa tu editor preferido)
nano config/config.yaml
# o
vim config/config.yaml
# o en macOS
open -a TextEdit config/config.yaml
```

**Archivos importantes a configurar en `config.yaml`:**

```yaml
# Ruta a tu archivo de datos procesado (CSV)
input_data_clean: "/ruta/a/tu/data/final_processed_data_CLEAN.csv"

# Ruta a tu archivo de datos crudos (CSV)
input_data_raw: "/ruta/a/tu/data/raw_data.csv"

# Rutas de salida (opcional, tienen valores por defecto)
output_figures: "outputs/{step}/figures"
output_tables: "outputs/{step}/tables"
```

### 2. Verificar que los archivos de datos existen

```bash
# Verificar que los archivos configurados existen
python3 -c "
import yaml
with open('config/config.yaml') as f:
    config = yaml.safe_load(f)
    import os
    for key in ['input_data_clean', 'input_data_raw']:
        if key in config:
            path = config[key]
            exists = os.path.exists(path)
            print(f'{key}: {path} - {\"✅ Existe\" if exists else \"❌ NO existe\"}')
"
```

---

## 🧪 Probar el Pipeline

### Dry-run (sin ejecutar, solo ver qué haría):

```bash
# Ver qué haría el pipeline completo
snakemake -n

# Ver qué haría solo Step 1
snakemake -n all_step1

# Ver qué haría solo Step 1.5
snakemake -n all_step1_5
```

### Ejecutar un paso específico:

```bash
# Ejecutar solo un panel de Step 1
snakemake -j 1 panel_b_gt_count_by_position

# Ejecutar Step 1 completo
snakemake -j 4 all_step1

# Ejecutar Step 1.5 completo
snakemake -j 1 all_step1_5
```

### Ejecutar pipeline completo:

```bash
snakemake -j 4
```

**Parámetros importantes:**
- `-j 4`: Usa 4 cores/jobs en paralelo (ajusta según tu CPU)
- `-j 1`: Ejecución secuencial (más lento pero más seguro)
- `-n`: Dry-run (no ejecuta, solo muestra qué haría)

---

## 🔄 Actualizar el Ambiente

Si agregamos nuevos paquetes o actualizamos dependencias:

```bash
# Activar ambiente
conda activate als_mirna_pipeline

# Actualizar ambiente con cambios
conda env update -f environment.yaml --prune
```

El flag `--prune` elimina paquetes que ya no están en el archivo YAML.

---

## 🐛 Solución de Problemas

### Problema: "Package not found" en R

**Solución:** Instalar el paquete faltante

```bash
# Con conda (preferido)
conda install -c conda-forge r-package-name

# O desde R
Rscript -e "install.packages('package-name', repos='https://cloud.r-project.org')"
```

### Problema: "Snakemake not found"

**Solución:** Verificar que el ambiente esté activado

```bash
conda activate als_mirna_pipeline
snakemake --version
```

### Problema: "R script execution failed"

**Solución:** Verificar que R está en el PATH y los paquetes están instalados

```bash
which R
R --version
Rscript -e "library(ggplot2)"  # Probar paquete común
```

### Problema: Archivos de datos no encontrados

**Solución:** Verificar rutas en `config/config.yaml`

```bash
# Ver configuración actual
cat config/config.yaml | grep input_data

# Verificar que los archivos existen
ls -lh /ruta/configurada/en/config.yaml
```

---

## 📦 Estructura de Ambientes

El pipeline usa dos archivos de ambiente:

1. **`environment.yaml`** - Ambiente completo (recomendado)
   - Python 3.10
   - Snakemake 7.32
   - R 4.3.2
   - Todos los paquetes R necesarios

2. **`envs/r_analysis.yaml`** - Solo R y paquetes R (para uso con R local)

3. **`envs/r_base.yaml`** - R base mínimo (no recomendado para este pipeline)

---

## 💡 Recomendaciones

1. **Usa `mamba` en lugar de `conda`** - Es significativamente más rápido
2. **Ejecuta `snakemake -n` primero** - Verifica que todo esté configurado antes de ejecutar
3. **Revisa los logs** - Están en `outputs/{step}/logs/` si algo falla
4. **Usa `-j 1` la primera vez** - Ejecución secuencial es más fácil de debuggear

---

## 🔗 Enlaces Útiles

- [Documentación de Snakemake](https://snakemake.readthedocs.io)
- [Instalación de Conda](https://docs.conda.io/en/latest/miniconda.html)
- [Instalación de Mamba](https://mamba.readthedocs.io/en/latest/installation.html)
- [Conda-forge channel](https://conda-forge.org)

---

**¿Problemas?** Revisa los logs en `outputs/{step}/logs/` o consulta la documentación en `README.md`.

