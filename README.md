<div align="center">

# Dragon in Space

**Plataformero 2D de acción y scroll lateral sobre calma, timing y redirección de energía**

[![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.x-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Language](https://img.shields.io/badge/Language-GDScript-355570?style=for-the-badge&logo=godot-engine&logoColor=white)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
[![Genre](https://img.shields.io/badge/Genre-2D_Action_Platformer-E65100?style=for-the-badge)](#)
[![UNQ](https://img.shields.io/badge/UNQ-Introducci%C3%B3n_al_Desarrollo_de_Videojuegos-8E24AA?style=for-the-badge)](#contexto-académico)

</div>

---

## Demo Jugable (Web / HTML5)

> **Estado**: *En desarrollo* — Próximamente disponible para jugar directamente desde el navegador (exportación Web / HTML5).

<!--
Descomentar y reemplazar URL cuando esté publicada la build HTML5 (itch.io / GitHub Pages):

[![Play in Browser](https://img.shields.io/badge/Jugar_en_el_Navegador-HTML5_Build-2E7D32?style=for-the-badge&logo=html5&logoColor=white)](https://TU-LINK-AQUI)

- **Link directo a la demo**: [Jugar Dragon in Space en el navegador](https://TU-LINK-AQUI)
-->

---

## Sinopsis

En **Dragon in Space**, encarnás al **Tío Iroh** (*Avatar: La Leyenda de Aang*), quien se encuentra herido y varado en el interior de una estación espacial alienígena. Debilitado por sus heridas y rodeado de tecnología desconocida, Iroh debe abrirse paso a través de tres sectores de la nave —el **Hangar**, la **Zona Media** y el **Puente de Mando**— para rescatar a **Zuko**, recuperando su conexión con el Chi pieza por pieza y descubriendo nuevas aplicaciones de su técnica de redirección de energía.

---

## Pilares de Diseño

1. **Calma y control por sobre fuerza bruta**  
   El poder se gana replicando la filosofía de Iroh: spamear ataques resulta ineficiente y riesgoso. El posicionamiento, la lectura del entorno y el timing preciso del bloqueo/parry son las herramientas centrales para sobrevivir.
2. **Progresión con identidad táctica**  
   Cada técnica desbloqueada aporta una utilidad cualitativamente distinta en el combate y la navegación (impacto cercano, fuego a distancia, rayo cargado capaz de anular plasma enemigo y redirección total), en lugar de limitarse a un simple aumento numérico de daño.
3. **Daño legible**  
   Iroh comienza vulnerable (**2 corazones de vida**), por lo que toda amenaza y ataque enemigo cuenta con un telegrafiado claro que permite reaccionar con precisión.

---

## Controles

| Acción | Entrada | Descripción |
| :--- | :---: | :--- |
| **Moverse a la izquierda / derecha** | `A` / `D` | Movimiento horizontal con aceleración, fricción y *skid* de cambio de dirección |
| **Saltar** | `Espacio` | Salto de altura variable (*jump cut*), *coyote time* y *jump buffer* |
| **Golpe Cuerpo a Cuerpo** | `Clic Izquierdo` | Ataque básico de corto alcance orientado hacia el cursor |
| **Fuego Control (Bola de Fuego)** | `Q` | Disparo de fuego a media distancia *(se desbloquea al reunir 100 de Chi)* |
| **Bloqueo / Parry** | `Clic Derecho` | Detiene proyectiles enemigos dentro de la ventana de timing sin recibir daño |

Rayo Control (`E`, mantener) y Redirección de Energía (`R`) están desactivados en esta versión.

---

## Mecánicas y Sistemas Principales

- **Movimiento Plataformero Clásico**: Física de salto asimétrica (gravedad diferenciada de subida y caída), *coyote time*, *jump buffering* e interacción física con obstáculos dinámicos.
- **Economía de Chi**: Recolección de orbes de energía (`ChiOrb`) en el escenario y recompensas al derrotar amenazas para llenar el medidor de Chi (`0–100`) y despertar habilidades de control elemental.
- **Exclusión Mutua de Combate**: Las técnicas ofensivas respetan ventanas de ejecución y enfriamiento sin solaparse, exigiendo compromiso en cada decisión de ataque o defensa.
- **Flujo Completo de Partida**: Ciclo integrado de escenas (`IntroCredits` → `MainMenu` → `Main` → `GameOver` / `WinCredits` → `MainMenu`) con HUD reactivo de salud, barra de Chi y notificaciones en pantalla.

---

## Estructura del Proyecto

```text
├── assets/
│   ├── fonts/               # Tipografías de interfaz
│   └── textures/            # Spritesheets, efectos visuales y texturas de entorno
├── src/
│   ├── Main.gd / Main.tscn  # Escena principal y orquestación del nivel
│   ├── entities/
│   │   ├── player/
│   │   │   ├── character/   # Controlador principal del jugador (Player.gd / Player.tscn)
│   │   │   ├── abilities/   # Golpe cuerpo a cuerpo y sistema de bloqueo/redirección (MeleeAttack, ParryController)
│   │   │   └── weapons/     # Controladores y proyectiles de Fuego Control y Rayo Control
│   │   ├── enemies/
│   │   │   └── turret/      # Torretas alienígenas, proyectiles y spawners
│   │   └── projectiles/     # Clase y escena base de proyectiles (Projectile.gd / Projectile.tscn)
│   ├── environment/         # Plataformas, rampas, muros, obstáculos físicos, meta y ChiOrbs
│   └── ui/                  # HUD, introducción, menú principal, victoria, derrota y créditos
└── project.godot            # Configuración general del motor e InputMap
```

---

## Ejecución del Proyecto

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/Bertolini-Victor/entrega-Boss-ipv-Bertolini-Agaras-Victor.git
   ```
2. Abrir **Godot Engine 4.4+** e importar el archivo `project.godot` ubicado en la raíz del repositorio.
3. Presionar **`F5`** (o el botón *Run Project*) para iniciar el juego desde la secuencia de introducción.

---

## Contexto Académico

- **Materia**: Introducción al Desarrollo de Videojuegos
- **Institución**: Universidad Nacional de Quilmes (UNQ)
- **Equipo**: El mate del Oeste — Mesa 2
- **Autor**: Victor H. Bertolini Agaras
