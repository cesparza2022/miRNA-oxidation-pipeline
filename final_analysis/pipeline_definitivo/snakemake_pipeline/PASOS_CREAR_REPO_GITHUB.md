# 📝 Pasos para Crear Repositorio en GitHub

## Paso 1: Crear el Repositorio en GitHub

1. **Abre tu navegador** y ve a: **https://github.com/new**

2. **Rellena el formulario:**
   - **Repository name**: `als-mirna-oxidation-pipeline`
   - **Description**: `Reproducible Snakemake pipeline for analyzing G>T oxidation patterns in miRNAs`
   - **Visibility**: Elige **Public** o **Private** (tu decisión)
   - ⚠️ **IMPORTANTE**: **NO marques** ninguna de estas opciones:
     - ❌ "Add a README file" (ya tenemos uno)
     - ❌ "Add .gitignore" (ya tenemos uno)
     - ❌ "Choose a license" (opcional, puedes agregarlo después)
   
3. **Click en "Create repository"** (botón verde)

4. **Después de crear**, GitHub te mostrará una página con instrucciones. 
   - **NO sigas esas instrucciones** (son para repositorios vacíos)
   - **En su lugar, copia la URL del repositorio** que aparece arriba
   - Formato: `https://github.com/TU_USUARIO/als-mirna-oxidation-pipeline.git`

---

## Paso 2: Compartir la URL

Una vez que tengas la URL, solo dímela y ejecutaré estos comandos automáticamente:

```bash
git remote add origin <LA_URL_QUE_ME_DES>
git branch -M main
git push -u origin main
```

**Ejemplo de URL que necesito:**
```
https://github.com/cesaresparza/als-mirna-oxidation-pipeline.git
```

---

## Paso 3: Verificar Conexión

Después de conectar, podrás:
- Ver tu código en GitHub
- Hacer cambios localmente
- Hacer `git push` para subir cambios
- Crear PRs desde branches

---

## 💡 Tip

Si ya tienes el repositorio creado pero no recuerdas la URL:
1. Ve a tu perfil de GitHub
2. Busca en "Repositories"
3. Click en el repositorio
4. Click en el botón verde "Code"
5. Copia la URL que aparece (HTTPS)

---

**¿Listo? Ve a https://github.com/new y créalo, luego dame la URL** 🚀

