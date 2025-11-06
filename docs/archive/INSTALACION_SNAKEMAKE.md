# 📦 Guía de Instalación de Snakemake

**Fecha:** 2025-01-28

---

## Opción 1: Con Conda/Mamba (Recomendado)

Si tienes conda o mamba instalado:

```bash
# Con conda
conda install -c bioconda -c conda-forge snakemake

# O con mamba (más rápido)
mamba install -c bioconda -c conda-forge snakemake
```

**Ventajas:**
- Maneja dependencias automáticamente
- Compatible con nuestros conda environments (r_base.yaml, r_analysis.yaml)

---

## Opción 2: Con Pip

Si prefieres usar pip:

```bash
pip install snakemake
# O
pip3 install snakemake
```

**Nota:** Puede requerir instalar dependencias manualmente.

---

## Opción 3: Instalar Miniconda primero

Si no tienes conda instalado:

### macOS:
```bash
# Descargar e instalar Miniconda
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
bash Miniconda3-latest-MacOSX-arm64.sh

# Luego instalar Snakemake
conda install -c bioconda -c conda-forge snakemake
```

### Linux:
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
conda install -c bioconda -c conda-forge snakemake
```

---

## Verificar Instalación

Después de instalar:

```bash
snakemake --version
```

Deberías ver algo como: `snakemake, version 8.x.x`

---

## Próximos Pasos

Una vez instalado, puedes probar el pipeline:

```bash
cd snakemake_pipeline
snakemake -n all_step1              # Dry-run
snakemake -j 1 panel_b_gt_count_by_position  # Ejecutar un panel
```


**Fecha:** 2025-01-28

---

## Opción 1: Con Conda/Mamba (Recomendado)

Si tienes conda o mamba instalado:

```bash
# Con conda
conda install -c bioconda -c conda-forge snakemake

# O con mamba (más rápido)
mamba install -c bioconda -c conda-forge snakemake
```

**Ventajas:**
- Maneja dependencias automáticamente
- Compatible con nuestros conda environments (r_base.yaml, r_analysis.yaml)

---

## Opción 2: Con Pip

Si prefieres usar pip:

```bash
pip install snakemake
# O
pip3 install snakemake
```

**Nota:** Puede requerir instalar dependencias manualmente.

---

## Opción 3: Instalar Miniconda primero

Si no tienes conda instalado:

### macOS:
```bash
# Descargar e instalar Miniconda
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
bash Miniconda3-latest-MacOSX-arm64.sh

# Luego instalar Snakemake
conda install -c bioconda -c conda-forge snakemake
```

### Linux:
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
conda install -c bioconda -c conda-forge snakemake
```

---

## Verificar Instalación

Después de instalar:

```bash
snakemake --version
```

Deberías ver algo como: `snakemake, version 8.x.x`

---

## Próximos Pasos

Una vez instalado, puedes probar el pipeline:

```bash
cd snakemake_pipeline
snakemake -n all_step1              # Dry-run
snakemake -j 1 panel_b_gt_count_by_position  # Ejecutar un panel
```


**Fecha:** 2025-01-28

---

## Opción 1: Con Conda/Mamba (Recomendado)

Si tienes conda o mamba instalado:

```bash
# Con conda
conda install -c bioconda -c conda-forge snakemake

# O con mamba (más rápido)
mamba install -c bioconda -c conda-forge snakemake
```

**Ventajas:**
- Maneja dependencias automáticamente
- Compatible con nuestros conda environments (r_base.yaml, r_analysis.yaml)

---

## Opción 2: Con Pip

Si prefieres usar pip:

```bash
pip install snakemake
# O
pip3 install snakemake
```

**Nota:** Puede requerir instalar dependencias manualmente.

---

## Opción 3: Instalar Miniconda primero

Si no tienes conda instalado:

### macOS:
```bash
# Descargar e instalar Miniconda
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
bash Miniconda3-latest-MacOSX-arm64.sh

# Luego instalar Snakemake
conda install -c bioconda -c conda-forge snakemake
```

### Linux:
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
conda install -c bioconda -c conda-forge snakemake
```

---

## Verificar Instalación

Después de instalar:

```bash
snakemake --version
```

Deberías ver algo como: `snakemake, version 8.x.x`

---

## Próximos Pasos

Una vez instalado, puedes probar el pipeline:

```bash
cd snakemake_pipeline
snakemake -n all_step1              # Dry-run
snakemake -j 1 panel_b_gt_count_by_position  # Ejecutar un panel
```

