# 📊 STEP 8: Sequence-Based Analysis (Paper Reference Methods)

**Fecha de implementación:** 2025-11-04  
**Propósito:** Implementar métodos de análisis basados en secuencia del paper de referencia

---

## 🎯 Objetivo

Este paso implementa los métodos de análisis basados en secuencia del paper de referencia:
> "Widespread 8-oxoguanine modifications of miRNA seeds differentially regulate redox-dependent cancer development"

Los análisis incluyen:
1. **Análisis de contexto trinucleótido (XGY)**: Identifica enriquecimiento de contextos específicos alrededor de G>T
2. **Sequence logos por posición**: Muestra conservación de secuencia en posiciones hotspot
3. **Análisis temporal**: Acumulación de G>T en timepoints (si disponibles)

---

## 📋 Análisis Implementados

### **8.1: Análisis de Contexto Trinucleótido (XGY)**

**Script:** `scripts/step8/01_trinucleotide_context.R`

**Qué hace:**
1. Extrae contexto trinucleótido (XGY) alrededor de cada G>T
2. Clasifica contextos: GpG, CpG, ApG, UpG
3. Calcula enriquecimiento (test binomial)
4. Genera visualizaciones de distribución y enriquecimiento

**Outputs:**
- `S8_trinucleotide_enrichment.csv`: Tabla de enriquecimiento por contexto
- `S8_context_summary.csv`: Resumen de contextos por miRNA
- `S8_trinucleotide_context.png`: Figura con distribución y ratios de enriquecimiento

**Interpretación:**
- **GpG enriquecido** → Confirma susceptibilidad a oxidación en dinucleótidos GG
- **CpG moderado** → Contexto moderadamente oxidable
- **ApG/UpG bajos** → Contextos menos susceptibles

---

### **8.2: Sequence Logos por Posición**

**Script:** `scripts/step8/02_position_specific_logos.R`

**Qué hace:**
1. Agrupa miRNAs con G>T en posiciones hotspot (2, 3, 5)
2. Extrae ventana ±3 alrededor del G
3. Alinea secuencias por el G central
4. Genera sequence logos mostrando conservación

**Outputs:**
- `S8_logo_position_2.png`: Logo para posición 2
- `S8_logo_position_3.png`: Logo para posición 3
- `S8_logo_position_5.png`: Logo para posición 5
- `S8_logos_summary.csv`: Resumen de secuencias por posición

**Interpretación:**
- **Alta conservación en posición -1** → Motivo funcional (ej: GG si >50% G)
- **Alta conservación general** → Posición crítica para función
- **Baja conservación** → Variabilidad natural o múltiples motivos

---

### **8.3: Análisis Temporal**

**Script:** `scripts/step8/03_temporal_patterns.R`

**Qué hace:**
1. Detecta timepoints en nombres de muestras (patrón: T0, T6, T18, etc.)
2. Calcula acumulación de G>T por timepoint
3. Genera visualizaciones de acumulación temporal
4. Si no hay timepoints, crea placeholder con mensaje informativo

**Outputs:**
- `S8_temporal_accumulation.csv`: Tabla de acumulación por timepoint
- `S8_temporal_patterns.png`: Figura con acumulación temporal y distribución de ratios

**Interpretación:**
- **Acumulación positiva** → G>T aumenta con el tiempo (no degradación aleatoria)
- **Acumulación negativa** → G>T disminuye (posible reparación)
- **Sin cambio** → Estable o degradación aleatoria

---

## 🔧 Requisitos

### **Dependencias R Adicionales:**
- `ggseqlogo` (para sequence logos)
- `Biostrings` (Bioconductor, para análisis de secuencias)

**Instalación automática:** Los scripts instalan automáticamente estos paquetes si no están disponibles.

### **Datos Requeridos:**
- Datos VAF-filtered de Step 1.5
- Secuencias de miRNAs (miRBase) - actualmente usa base de datos curada
- (Opcional) Timepoints en nombres de muestras para análisis temporal

---

## 🚀 Uso

### **Ejecutar Step 8 completo:**

```bash
cd snakemake_pipeline
snakemake -j 1 all_step8
```

### **Ejecutar análisis individual:**

```bash
# Solo análisis de contexto trinucleótido
snakemake -j 1 step8_trinucleotide_context

# Solo sequence logos
snakemake -j 1 step8_sequence_logos

# Solo análisis temporal
snakemake -j 1 step8_temporal_analysis
```

### **Incluir en pipeline completo:**

Editar `Snakefile` y descomentar:
```python
# rules.all_step8.output,  # Uncomment to include Step 8
```

---

## 📊 Outputs

### **Tablas:**
- `results/step8/tables/S8_trinucleotide_enrichment.csv`
- `results/step8/tables/S8_context_summary.csv`
- `results/step8/tables/S8_logos_summary.csv`
- `results/step8/tables/S8_temporal_accumulation.csv`

### **Figuras:**
- `results/step8/figures/S8_trinucleotide_context.png`
- `results/step8/figures/S8_logo_position_2.png`
- `results/step8/figures/S8_logo_position_3.png`
- `results/step8/figures/S8_logo_position_5.png`
- `results/step8/figures/S8_temporal_patterns.png`

---

## 🔬 Métodos Científicos

### **Contexto Trinucleótido (XGY):**
- **Enriquecimiento:** Test binomial (H0: p = 0.25 para cada contexto)
- **Interpretación:** GpG enriquecido → Confirma susceptibilidad a oxidación

### **Sequence Logos:**
- **Método:** `ggseqlogo` con método "bits"
- **Alineación:** Por G central (posición de oxidación)
- **Ventana:** ±3 nucleótidos alrededor del G

### **Análisis Temporal:**
- **Detección:** Patrones en nombres de muestras (T0, T6, etc.)
- **Métrica:** Acumulación = Count(t_final) - Count(t_inicial)
- **Ratio:** Acumulación relativa = Count(t_final) / Count(t_inicial)

---

## 📝 Notas Importantes

1. **Secuencias de miRBase:**
   - Actualmente usa base de datos curada (limitada a ~20 miRNAs comunes)
   - En producción, integrar con `miRBaseConverter` o descargar `mature.fa`

2. **Target Prediction:**
   - Step 6.3 usa simulación de targets
   - En producción, integrar con TargetScan, miRDB, o miRTarBase

3. **Análisis Temporal:**
   - Requiere timepoints en nombres de muestras
   - Si no hay, genera placeholder con mensaje informativo

4. **Step Opcional:**
   - Step 8 está comentado por defecto en `Snakefile`
   - Descomentar para incluir en pipeline completo

---

## 🔗 Referencias

- Paper de referencia: "Widespread 8-oxoguanine modifications of miRNA seeds differentially regulate redox-dependent cancer development" (Nature Cell Biology, 2023)
- miRBase: https://www.mirbase.org/
- ggseqlogo: https://omarwagih.github.io/ggseqlogo/

---

**Última actualización:** 2025-11-04

