# 🔗 Conectar con GitHub - Guía Rápida

## Situación Actual

- ✅ Repositorio local inicializado
- ✅ Commit inicial realizado (47 archivos)
- ❌ No hay conexión con GitHub todavía

## Pasos para Conectar

### Opción A: Si YA creaste el repositorio en GitHub

1. Ve a tu repositorio en GitHub (ej: `https://github.com/tuusuario/als-mirna-oxidation-pipeline`)
2. Copia la URL (botón verde "Code" → HTTPS)
3. Dime la URL y ejecutaré:

```bash
git remote add origin <URL>
git branch -M main
git push -u origin main
```

### Opción B: Si NO has creado el repositorio aún

1. Ve a: https://github.com/new
2. Configura:
   - **Repository name**: `als-mirna-oxidation-pipeline`
   - **Description**: `Reproducible Snakemake pipeline for analyzing G>T oxidation patterns in miRNAs`
   - **Visibility**: Public o Private
   - ⚠️ **NO marques** "Initialize with README" (ya tenemos uno)
   - **NO agregues** .gitignore ni license
3. Click "Create repository"
4. Copia la URL que te muestra GitHub
5. Dime la URL y ejecutaré los comandos

---

## Después de Conectar

Una vez conectado, podrás:
- Trabajar localmente
- Hacer commits
- Hacer push a GitHub
- Crear PRs desde branches

---

## Formato de URL Esperado

```
https://github.com/USERNAME/REPO_NAME.git
```

Ejemplo:
```
https://github.com/cesaresparza/als-mirna-oxidation-pipeline.git
```

