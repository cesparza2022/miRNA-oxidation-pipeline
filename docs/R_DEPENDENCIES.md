# 📦 R PACKAGE DEPENDENCIES

**Versión:** 1.0  
**Fecha:** 2025-01-21  
**Propósito:** Documentación completa de dependencias R del pipeline

---

## 🎯 RESUMEN

El pipeline requiere **R 4.3.2+** y un conjunto específico de paquetes R con versiones mínimas. Todas las dependencias se instalan automáticamente cuando se crea el entorno conda desde `environment.yml`.

---

## 📋 PAQUETES REQUERIDOS

### **Core Tidyverse**

| Paquete | Versión Mínima | Descripción | Uso Principal |
|---------|---------------|-------------|---------------|
| `tidyverse` | 2.0.0 | Meta-paquete que incluye dplyr, tidyr, readr, etc. | Carga de datos, manipulación |
| `dplyr` | 1.1.0 | Manipulación de datos | Filtrar, agrupar, resumir |
| `tidyr` | 1.3.0 | Transformación de datos | Pivotar, separar, unir columnas |
| `readr` | 2.1.0 | Lectura de archivos | `read_csv()`, `read_tsv()` |
| `stringr` | 1.5.0 | Manipulación de strings | Extraer nombres de miRNAs, patrones |
| `ggplot2` | 3.4.0 | Visualización | Todas las figuras del pipeline |
| `tibble` | 3.2.0 | Estructura de datos moderna | Data frames mejorados |
| `scales` | 1.2.0 | Escalas para gráficos | Formateo de ejes, colores |
| `purrr` | 1.0.0 | Programación funcional | Iteración sobre listas |
| `forcats` | 1.0.0 | Factores | Manejo de factores categóricos |

### **Visualización Extendida**

| Paquete | Versión Mínima | Descripción | Uso Principal |
|---------|---------------|-------------|---------------|
| `patchwork` | 1.1.0 | Combinar múltiples gráficos | Paneles de múltiples figuras |
| `ggrepel` | 0.9.0 | Etiquetas sin solapamiento | Volcano plots, etiquetas |
| `pheatmap` | 1.0.12 | Heatmaps profesionales | Heatmaps de clustering, expresión |
| `viridis` | 0.6.0 | Paletas de colores | Escalas de color accesibles |
| `RColorBrewer` | 1.1.3 | Paletas de colores | Colores para grupos, clusters |
| `reshape2` | 1.4.4 | Transformación de datos | Reshape para visualización |

### **Análisis Estadístico**

| Paquete | Versión Mínima | Descripción | Uso Principal |
|---------|---------------|-------------|---------------|
| `pROC` | 1.18.0 | Curvas ROC | Análisis de biomarkers (Step 7) |
| `e1071` | 1.7.13 | Algoritmos de machine learning | Utilidades estadísticas |
| `cluster` | 2.1.4 | Análisis de clustering | Clustering jerárquico (Step 3) |
| `factoextra` | 1.0.7 | Visualización de PCA/clustering | Análisis de componentes principales |

### **Utilidades**

| Paquete | Versión Mínima | Descripción | Uso Principal |
|---------|---------------|-------------|---------------|
| `yaml` | 2.3.7 | Parsing YAML | Leer `config.yaml` |
| `base64enc` | 0.1.3 | Codificación Base64 | Embedding de imágenes en HTML |
| `jsonlite` | 1.8.7 | Parsing JSON | Generar reportes JSON |

---

## 🔧 INSTALACIÓN

### **Opción 1: Conda (Recomendado)**

Las dependencias se instalan automáticamente al crear el entorno:

```bash
conda env create -f environment.yml
conda activate mirna_oxidation_pipeline
```

### **Opción 2: Instalación Manual**

Si necesitas instalar paquetes manualmente en R:

```r
# Instalar desde CRAN
install.packages(c(
  "tidyverse", "ggplot2", "dplyr", "tidyr", "readr", 
  "stringr", "patchwork", "ggrepel", "pheatmap", 
  "viridis", "RColorBrewer", "pROC", "e1071", 
  "cluster", "factoextra", "yaml", "base64enc", "jsonlite"
))

# O instalar desde conda-forge
# conda install -c conda-forge -c bioconda r-tidyverse r-ggplot2 r-dplyr ...
```

---

## ✅ VALIDACIÓN DE VERSIONES

El pipeline valida automáticamente las versiones de paquetes antes de ejecutar:

```bash
# Validar manualmente
Rscript scripts/utils/validate_package_versions.R
```

O ejecutar el pipeline completo (la validación corre automáticamente):

```bash
snakemake -j 4
```

---

## 🔍 VERIFICACIÓN DE INSTALACIÓN

Para verificar que todos los paquetes están instalados correctamente:

```r
# En R
required_packages <- c(
  "tidyverse", "dplyr", "tidyr", "readr", "stringr", 
  "ggplot2", "patchwork", "ggrepel", "pheatmap", 
  "viridis", "RColorBrewer", "pROC", "cluster", 
  "factoextra", "yaml", "base64enc", "jsonlite"
)

missing <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
if (length(missing) > 0) {
  cat("Missing packages:", paste(missing, collapse = ", "), "\n")
} else {
  cat("All packages installed!\n")
}
```

---

## 📚 VERSIONES ESPECÍFICAS

### **R Base**
- **R**: 4.3.2+ (instalado vía conda)

### **Tidyverse**
- El meta-paquete `tidyverse` incluye todos los paquetes core listados arriba
- Versión mínima: 2.0.0 (compatible con R 4.3+)

### **Paquetes Opcionales**

Algunos paquetes son opcionales y solo se usan en ciertos steps:

- `clusterProfiler`: Para enriquecimiento funcional (Step 6) - **No incluido actualmente**
- `enrichR`: Alternativa para enriquecimiento - **No incluido actualmente**
- `g:Profiler`: Enriquecimiento comprehensivo - **No incluido actualmente**

**Nota:** Step 6 (Functional Analysis) actualmente usa una implementación simplificada. Para enriquecimiento completo, se recomienda agregar `clusterProfiler` o `enrichR`.

---

## 🐛 TROUBLESHOOTING

### **Error: "Package not found"**

1. Verificar que el entorno conda está activado:
   ```bash
   conda activate mirna_oxidation_pipeline
   ```

2. Recrear el entorno:
   ```bash
   conda env remove -n mirna_oxidation_pipeline
   conda env create -f environment.yml
   ```

### **Error: "Package version too old"**

1. Actualizar el paquete específico:
   ```bash
   conda update -c conda-forge -c bioconda r-<package-name>
   ```

2. O instalar desde CRAN:
   ```r
   install.packages("<package-name>")
   ```

### **Error: "Conflicts with other packages"**

Si hay conflictos de versiones:

1. Usar el entorno conda (recomendado) - maneja dependencias automáticamente
2. O crear un entorno R limpio con `renv`:
   ```r
   install.packages("renv")
   renv::init()
   renv::restore()
   ```

---

## 📖 REFERENCIAS

- **Tidyverse**: https://www.tidyverse.org/
- **ggplot2**: https://ggplot2.tidyverse.org/
- **Conda-forge**: https://conda-forge.org/
- **Bioconda**: https://bioconda.github.io/

---

**Última actualización:** 2025-01-21

