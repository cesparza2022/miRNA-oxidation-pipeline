# 📋 PASO 2: PLAN GRANULAR - Paso a Paso

**Objetivo:** Migrar Paso 1.5 a Snakemake en pasos pequeños y verificables

---

## ✅ COMPLETADO HASTA AHORA

- ✅ Scripts adaptados (MENSAJE 2)
- ✅ Reglas Snakemake creadas (MENSAJE 3)
- ✅ Viewer HTML creado (MENSAJE 4)

---

## 🔄 PASOS RESTANTES (GRANULARES)

### **PASO 2.1: Verificar sintaxis (rápido)**
- ✅ Ya hecho con dry-run
- ✅ Todo correcto

### **PASO 2.2: Probar Script 1 solo** ⏳ SIGUIENTE
**Objetivo:** Ejecutar solo el filtro VAF y verificar que genera las 4 tablas

**Comando:**
```bash
snakemake -j 1 apply_vaf_filter
```

**Verificar:**
- ¿Se ejecutó sin errores?
- ¿Generó las 4 tablas CSV?
- ¿Los logs muestran algo sospechoso?

**Si funciona:** → PASO 2.3
**Si falla:** → Revisar y corregir

---

### **PASO 2.3: Probar Script 2 solo**
**Objetivo:** Ejecutar solo la generación de figuras (asumiendo que Script 1 ya corrió)

**Comando:**
```bash
snakemake -j 1 generate_diagnostic_figures
```

**Verificar:**
- ¿Se ejecutó sin errores?
- ¿Generó las 11 figuras PNG?
- ¿Generó las 3 tablas adicionales?

**Si funciona:** → PASO 2.4
**Si falla:** → Revisar y corregir

---

### **PASO 2.4: Probar viewer solo**
**Objetivo:** Generar el viewer HTML (asumiendo que las figuras ya existen)

**Comando:**
```bash
snakemake -j 1 generate_step1_5_viewer
```

**Verificar:**
- ¿Se generó el HTML?
- ¿Se puede abrir en el navegador?
- ¿Muestra todas las figuras?

**Si funciona:** → PASO 2.5
**Si falla:** → Revisar y corregir

---

### **PASO 2.5: Ejecutar todo junto**
**Objetivo:** Verificar que todo funciona end-to-end

**Comando:**
```bash
snakemake -j 1 all_step1_5 generate_step1_5_viewer
```

**Verificar:**
- ¿Todo se ejecutó en orden?
- ¿Todos los outputs están presentes?
- ¿El viewer funciona?

---

## 🎯 PRÓXIMO PASO

**PASO 2.2:** Ejecutar Script 1 solo
- Es el más rápido de probar
- Si falla, es fácil de corregir
- Genera solo 4 tablas (no figuras pesadas)

¿Empezamos con PASO 2.2?

