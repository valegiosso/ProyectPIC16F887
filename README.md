# ProyectPIC16F887

Proyecto MPLAB X para la materia **Electrónica Digital II (ED2)** — FCEFYN.  
Contiene los trabajos prácticos de programación en ASM para el microcontrolador **PIC16F887**, desarrollados de forma incremental a lo largo de la cursada.

---

## Requisitos

- [MPLAB X IDE](https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide) v5.x o superior
- Ensamblador **MPASM** (incluido en MPLAB X)
- Grabador compatible: PICkit 3, PICkit 4 o similar

---

## Estructura del repositorio
```
ProyectPIC16F887.X/
├── tp2_contador_8bits.asm   ← Código fuente del TP2
├── ...                      ← Futuros TPs
├── nbproject/               ← Configuración interna de MPLAB X (NO modificar)
│   ├── project.xml          ← Define el PIC target y archivos del proyecto
│   └── configurations.xml  ← Config bits y opciones de compilación
├── Makefile                 ← Generado por MPLAB X, no editar manualmente
├── .gitignore
└── README.md
```

> Cada TP es un archivo `.asm` independiente. Solo uno está activo en el
> proyecto a la vez (ver sección "Cambiar de TP" más abajo).

---

## Cómo abrir el proyecto

1. Clonar el repositorio:
```bash
   git clone https://github.com/valegiosso/ProyectPIC16F887.git
```
2. Abrir MPLAB X → **File → Open Project**
3. Navegar hasta la carpeta `ProyectPIC16F887.X` y seleccionarla
4. El proyecto ya tiene configurado el PIC16F887 y las opciones de compilación

---

## Cómo compilar

Una vez abierto el proyecto en MPLAB X:

- **Build:** `F11` o botón del martillo — compila y genera el `.hex` en `dist/`
- **Clean & Build:** `Shift + F11` — limpia archivos anteriores y recompila desde cero

El archivo `.hex` resultante queda en:
```
dist/default/production/ProyectPIC16F887.X.production.hex
```

---

## Cambiar de TP (activar otro archivo fuente)

Como hay un `.asm` por TP pero solo uno puede compilarse a la vez:

1. En el panel **Projects**, clic derecho sobre el `.asm` que querés activar
2. Seleccionar **"Add to project"** (si no está agregado) o verificar que no tenga el ícono de excluido
3. Clic derecho sobre los demás `.asm` → **"Exclude from project"**
4. Hacer **Clean & Build**

---

## Trabajos Prácticos

| TP | Archivo | Descripción |
|----|---------|-------------|
| TP2 | `tp2.asm` | Contador de 8 bits con pulsador en RA4, salida en Puerto B |
| ... | ... | ... |

---

## Configuración del hardware

- **Microcontrolador:** PIC16F887
- **Cristal:** 4 MHz (ciclo de instrucción = 1 µs)
- **Alimentación:** 5V
- Consultar cada archivo `.asm` para el pinout específico del TP correspondiente

---

## Notas de Git

Las carpetas `build/` y `dist/` están en `.gitignore` porque se regeneran al compilar.  
La carpeta `nbproject/` **sí está commiteada** porque contiene la configuración del PIC y del proyecto necesaria para abrirlo correctamente en MPLAB X.