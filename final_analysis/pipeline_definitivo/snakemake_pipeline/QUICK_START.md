# ⚡ Inicio Rápido - 5 Minutos

Guía rápida para empezar a usar el pipeline en 5 minutos.

---

## 📋 Requisitos Previos

Solo necesitas tener instalado **Conda** o **Mamba**:

```bash
# Verificar si tienes conda
conda --version

# O verificar si tienes mamba
mamba --version
```

**Si no tienes conda/mamba:** [Instalar Miniconda](https://docs.conda.io/en/latest/miniconda.html) (5 minutos)

---

## 🚀 Setup en 3 Pasos

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/cesparza2022/als-mirna-oxidation-pipeline.git
cd als-mirna-oxidation-pipeline/final_analysis/pipeline_definitivo/snakemake_pipeline
```

### Paso 2: Crear el ambiente (10-15 minutos con conda, 5-8 con mamba)

**Opción A: Setup automático (recomendado)**

```bash
# Ejecutar script de setup
bash setup.sh --mamba  # Usa mamba (más rápido)
# o
bash setup.sh --conda  # Usa conda
```

**Opción B: Manual**

```bash
# Con conda
conda env create -f environment.yaml

# O con mamba (más rápido)
mamba env create -f environment.yaml
```

### Paso 3: Activar y configurar

```bash
# Activar ambiente
conda activate als_mirna_pipeline

# Configurar datos
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Edita las rutas a tus archivos de datos
```

**En `config.yaml`, actualiza:**
```yaml
input_data_clean: "/ruta/a/tu/data/final_processed_data_CLEAN.csv"
input_data_raw: "/ruta/a/tu/data/raw_data.csv"
```

---

## ✅ Verificar Instalación

```bash
# Verificar que todo está instalado
bash setup.sh --check

# O manualmente
snakemake --version  # Debe mostrar: snakemake, version 7.32.x
R --version          # Debe mostrar: R version 4.3.2
```

---

## 🧪 Probar el Pipeline

### Dry-run (ver qué haría sin ejecutar):

```bash
snakemake -n
```

### Ejecutar un paso específico:

```bash
# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Pipeline completo
snakemake -j 4
```

---

## 📁 Ver Resultados

Los resultados se generan en:

- **Figuras:** `outputs/{step}/figures/`
- **Tablas:** `outputs/{step}/tables/`
- **Viewers HTML:** `outputs/{step}/viewers/`

---

## ❓ Problemas Comunes

**"Conda/Mamba no encontrado"**
- Instala Miniconda desde: https://docs.conda.io/en/latest/miniconda.html
- Reinicia tu terminal después de instalar

**"Snakemake not found"**
- Activa el ambiente: `conda activate als_mirna_pipeline`

**"File not found"**
- Verifica las rutas en `config/config.yaml`
- Usa rutas absolutas

**Para más ayuda:** Consulta [SETUP.md](SETUP.md)

---

## 🎯 Siguiente Paso

Una vez configurado, revisa:
- [README.md](README.md) - Documentación completa
- [SETUP.md](SETUP.md) - Guía detallada de instalación
- [GUIA_VIEWERS.md](GUIA_VIEWERS.md) - Cómo usar los viewers HTML

---

**¿Listo?** `conda activate als_mirna_pipeline && snakemake -n`


Guía rápida para empezar a usar el pipeline en 5 minutos.

---

## 📋 Requisitos Previos

Solo necesitas tener instalado **Conda** o **Mamba**:

```bash
# Verificar si tienes conda
conda --version

# O verificar si tienes mamba
mamba --version
```

**Si no tienes conda/mamba:** [Instalar Miniconda](https://docs.conda.io/en/latest/miniconda.html) (5 minutos)

---

## 🚀 Setup en 3 Pasos

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/cesparza2022/als-mirna-oxidation-pipeline.git
cd als-mirna-oxidation-pipeline/final_analysis/pipeline_definitivo/snakemake_pipeline
```

### Paso 2: Crear el ambiente (10-15 minutos con conda, 5-8 con mamba)

**Opción A: Setup automático (recomendado)**

```bash
# Ejecutar script de setup
bash setup.sh --mamba  # Usa mamba (más rápido)
# o
bash setup.sh --conda  # Usa conda
```

**Opción B: Manual**

```bash
# Con conda
conda env create -f environment.yaml

# O con mamba (más rápido)
mamba env create -f environment.yaml
```

### Paso 3: Activar y configurar

```bash
# Activar ambiente
conda activate als_mirna_pipeline

# Configurar datos
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Edita las rutas a tus archivos de datos
```

**En `config.yaml`, actualiza:**
```yaml
input_data_clean: "/ruta/a/tu/data/final_processed_data_CLEAN.csv"
input_data_raw: "/ruta/a/tu/data/raw_data.csv"
```

---

## ✅ Verificar Instalación

```bash
# Verificar que todo está instalado
bash setup.sh --check

# O manualmente
snakemake --version  # Debe mostrar: snakemake, version 7.32.x
R --version          # Debe mostrar: R version 4.3.2
```

---

## 🧪 Probar el Pipeline

### Dry-run (ver qué haría sin ejecutar):

```bash
snakemake -n
```

### Ejecutar un paso específico:

```bash
# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Pipeline completo
snakemake -j 4
```

---

## 📁 Ver Resultados

Los resultados se generan en:

- **Figuras:** `outputs/{step}/figures/`
- **Tablas:** `outputs/{step}/tables/`
- **Viewers HTML:** `outputs/{step}/viewers/`

---

## ❓ Problemas Comunes

**"Conda/Mamba no encontrado"**
- Instala Miniconda desde: https://docs.conda.io/en/latest/miniconda.html
- Reinicia tu terminal después de instalar

**"Snakemake not found"**
- Activa el ambiente: `conda activate als_mirna_pipeline`

**"File not found"**
- Verifica las rutas en `config/config.yaml`
- Usa rutas absolutas

**Para más ayuda:** Consulta [SETUP.md](SETUP.md)

---

## 🎯 Siguiente Paso

Una vez configurado, revisa:
- [README.md](README.md) - Documentación completa
- [SETUP.md](SETUP.md) - Guía detallada de instalación
- [GUIA_VIEWERS.md](GUIA_VIEWERS.md) - Cómo usar los viewers HTML

---

**¿Listo?** `conda activate als_mirna_pipeline && snakemake -n`


Guía rápida para empezar a usar el pipeline en 5 minutos.

---

## 📋 Requisitos Previos

Solo necesitas tener instalado **Conda** o **Mamba**:

```bash
# Verificar si tienes conda
conda --version

# O verificar si tienes mamba
mamba --version
```

**Si no tienes conda/mamba:** [Instalar Miniconda](https://docs.conda.io/en/latest/miniconda.html) (5 minutos)

---

## 🚀 Setup en 3 Pasos

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/cesparza2022/als-mirna-oxidation-pipeline.git
cd als-mirna-oxidation-pipeline/final_analysis/pipeline_definitivo/snakemake_pipeline
```

### Paso 2: Crear el ambiente (10-15 minutos con conda, 5-8 con mamba)

**Opción A: Setup automático (recomendado)**

```bash
# Ejecutar script de setup
bash setup.sh --mamba  # Usa mamba (más rápido)
# o
bash setup.sh --conda  # Usa conda
```

**Opción B: Manual**

```bash
# Con conda
conda env create -f environment.yaml

# O con mamba (más rápido)
mamba env create -f environment.yaml
```

### Paso 3: Activar y configurar

```bash
# Activar ambiente
conda activate als_mirna_pipeline

# Configurar datos
cp config/config.yaml.example config/config.yaml
nano config/config.yaml  # Edita las rutas a tus archivos de datos
```

**En `config.yaml`, actualiza:**
```yaml
input_data_clean: "/ruta/a/tu/data/final_processed_data_CLEAN.csv"
input_data_raw: "/ruta/a/tu/data/raw_data.csv"
```

---

## ✅ Verificar Instalación

```bash
# Verificar que todo está instalado
bash setup.sh --check

# O manualmente
snakemake --version  # Debe mostrar: snakemake, version 7.32.x
R --version          # Debe mostrar: R version 4.3.2
```

---

## 🧪 Probar el Pipeline

### Dry-run (ver qué haría sin ejecutar):

```bash
snakemake -n
```

### Ejecutar un paso específico:

```bash
# Solo Step 1
snakemake -j 4 all_step1

# Solo Step 1.5
snakemake -j 1 all_step1_5

# Pipeline completo
snakemake -j 4
```

---

## 📁 Ver Resultados

Los resultados se generan en:

- **Figuras:** `outputs/{step}/figures/`
- **Tablas:** `outputs/{step}/tables/`
- **Viewers HTML:** `outputs/{step}/viewers/`

---

## ❓ Problemas Comunes

**"Conda/Mamba no encontrado"**
- Instala Miniconda desde: https://docs.conda.io/en/latest/miniconda.html
- Reinicia tu terminal después de instalar

**"Snakemake not found"**
- Activa el ambiente: `conda activate als_mirna_pipeline`

**"File not found"**
- Verifica las rutas en `config/config.yaml`
- Usa rutas absolutas

**Para más ayuda:** Consulta [SETUP.md](SETUP.md)

---

## 🎯 Siguiente Paso

Una vez configurado, revisa:
- [README.md](README.md) - Documentación completa
- [SETUP.md](SETUP.md) - Guía detallada de instalación
- [GUIA_VIEWERS.md](GUIA_VIEWERS.md) - Cómo usar los viewers HTML

---

**¿Listo?** `conda activate als_mirna_pipeline && snakemake -n`

