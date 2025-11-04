# 📦 Preparación para GitHub

## ✅ Checklist antes de subir

### 1. Archivos de Configuración
- ✅ `config/config.yaml.example` creado (sin rutas personales)
- ✅ `.gitignore` actualizado (excluye config.yaml y outputs)
- ⚠️ `config/config.yaml` está en .gitignore (no se subirá)

### 2. Documentación
- ✅ `README.md` principal creado (formato GitHub estándar)
- ✅ `README_SIMPLE.md` para usuarios nuevos
- ✅ Otros documentos de referencia incluidos

### 3. Datos Sensibles
- ✅ Rutas absolutas personales removidas del repo
- ✅ Datos grandes en .gitignore
- ✅ Outputs en .gitignore

### 4. Estructura
- ✅ Estructura de directorios limpia
- ✅ Scripts organizados
- ✅ Archivos temporales excluidos

---

## 🚀 Pasos para Subir a GitHub

### Paso 1: Preparar Repositorio Local

```bash
cd snakemake_pipeline

# Inicializar git si no existe
git init

# Crear .gitignore (ya existe, verificar contenido)
cat .gitignore

# Agregar archivos
git add .

# Primer commit
git commit -m "Initial commit: ALS miRNA oxidation analysis pipeline"
```

### Paso 2: Crear Repositorio en GitHub

1. Ve a https://github.com/new
2. Nombre sugerido: `als-mirna-oxidation-pipeline`
3. Descripción: "Reproducible Snakemake pipeline for analyzing G>T oxidation patterns in miRNAs"
4. **No** inicializar con README (ya tenemos uno)
5. Crear repositorio

### Paso 3: Conectar y Subir

```bash
# Agregar remote (reemplaza USERNAME y REPO_NAME)
git remote add origin https://github.com/USERNAME/als-mirna-oxidation-pipeline.git

# Verificar remote
git remote -v

# Subir código
git branch -M main
git push -u origin main
```

---

## 📋 Archivos que NO se subirán (gitignore)

- ✅ `config/config.yaml` (contiene rutas personales)
- ✅ `outputs/` (archivos generados)
- ✅ `viewers/*.html` (generados automáticamente)
- ✅ `.snakemake/` (cache de Snakemake)
- ✅ `*.log` (logs)
- ✅ Datos grandes (`.csv`, `.txt` grandes)

---

## 📋 Archivos que SÍ se subirán

- ✅ `README.md`
- ✅ `README_SIMPLE.md`
- ✅ `Snakefile`
- ✅ `run.sh`
- ✅ `config/config.yaml.example`
- ✅ `scripts/` (todos los scripts R)
- ✅ `rules/` (todas las reglas Snakemake)
- ✅ `envs/` (archivos conda)
- ✅ `environment.yaml`
- ✅ `.gitignore`
- ✅ Documentación (`.md` files)

---

## 🔒 Seguridad

### Antes de subir, verifica:

1. **No hay rutas personales** en archivos que se subirán:
   ```bash
   # Buscar rutas personales
   grep -r "/Users/cesaresparza" --exclude-dir=.git .
   ```

2. **No hay datos sensibles**:
   - No incluir datos reales
   - No incluir API keys
   - No incluir información personal

3. **Config.yaml está en gitignore**:
   ```bash
   grep "config.yaml" .gitignore
   ```

---

## 📝 README para GitHub

El `README.md` principal está listo para GitHub con:
- ✅ Badges (Snakemake, R, License)
- ✅ Quick Start guide
- ✅ Installation instructions
- ✅ Usage examples
- ✅ Project structure
- ✅ Troubleshooting

---

## 🎯 Recomendaciones Adicionales

### 1. Licencia
Agregar archivo `LICENSE` (MIT, GPL, etc.)

### 2. Contributing Guidelines
Crear `CONTRIBUTING.md` con guidelines

### 3. Issues Template
Crear `.github/ISSUES_TEMPLATE.md` para reportar bugs

### 4. Release Tags
Para versiones:
```bash
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0
```

---

## ✅ Estado Actual

- ✅ .gitignore preparado
- ✅ config.yaml.example creado
- ✅ README.md para GitHub listo
- ✅ Estructura lista para subir
- ⚠️ Falta: Verificar que no hay rutas personales en scripts

---

## 🚀 Próximo Paso

1. Revisar que no hay rutas personales en scripts
2. Ejecutar comandos de git para inicializar
3. Crear repositorio en GitHub
4. Push inicial

---

**¿Listo para subir?** Ejecuta los comandos de arriba o pídeme que los ejecute paso a paso.

