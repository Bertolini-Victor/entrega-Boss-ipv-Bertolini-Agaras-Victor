<div align="center">

# Dragon In Space

**Action-platformer 2D desarrollado en Godot Engine 4.x, optimizado para WebGL / HTML5**

[![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.x-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Language](https://img.shields.io/badge/Language-GDScript-355570?style=for-the-badge&logo=godot-engine&logoColor=white)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
[![Platform](https://img.shields.io/badge/Platform-HTML5_/_WebGL-E65100?style=for-the-badge&logo=html5&logoColor=white)](#)
[![Genre](https://img.shields.io/badge/Genre-2D_Action_Platformer-D84315?style=for-the-badge)](#)
[![UNQ](https://img.shields.io/badge/UNQ-Introducci%C3%B3n_al_Desarrollo_de_Videojuegos-8E24AA?style=for-the-badge)](#contexto-académico)

</div>

---

## Descripción

**Dragon In Space** es un videojuego de acción y plataformas en 2D que combina mecánicas clásicas de precisión con combate elemental táctico. 

Encarnás al **Tío Iroh** (*Avatar: La Leyenda de Aang*), quien despierta herido a bordo de una misteriosa estación espacial industrial alienígena. Sin entender la tecnología del lugar pero guiado por su filosofía de calma y equilibrio, Iroh debe atravesar sectores fortificados —el **Piso Inferior**, la **Zona Media** de plataformas y el **Puente Superior**— para derrotar al temible **Mecha-Tank** y rescatar al príncipe **Zuko**.

El juego está diseñado con una resolución nativa de 288×216 píxeles escalada en modo `canvas_items`, garantizando un rendimiento fluido tanto en plataformas de escritorio como en compilaciones web WebGL/HTML5.

---

## Controles

| Acción | Tecla / Entrada | Descripción |
| :--- | :---: | :--- |
| **Moverse a la izquierda / derecha** | `A` / `D` | Desplazamiento horizontal con aceleración progresiva, fricción y frenado (*skid stop*). |
| **Saltar** | `Espacio` | Salto de altura variable (*jump cut*), con tolerancia de borde (*coyote time*) y precarga (*jump buffer*). |
| **Ataque Melee (Fire Slash)** | `Clic Izquierdo` | Golpe ígneo cuerpo a cuerpo orientado hacia el cursor del ratón. |
| **Aliento de Fuego (Fire Breath)** | `Q` | Ráfaga continua de fuego que daña enemigos y destruye muros debilitados (consume Chi). |
| **Ataque de Rayo (Lightning)** | `E` | Disparo perforante de alta potencia para atravesar defensas enemigas (consume Chi). |
| **Bloqueo / Parry** | `Clic Derecho` | Bloqueo activo. Al parar proyectiles con timing preciso, anula el daño y recarga la reserva de Chi. |
| **Redirección de Energía** | `R` | Técnica avanzada de desvío y contraataque tras absorber proyectiles cargados. |
| **Menú de Pausa** | `Escape` / Botón `\|\|` (HUD) | Congela el juego y despliega el menú con opciones de reanudar, música y retorno al inicio. |

---

## Características Principales

- **Economía de Chi Basada en Combate:**  
  El Chi no se regenera de forma pasiva; se obtiene recolectando orbes esparcidos en el escenario o ejecutando parries exitosos frente a proyectiles enemigos. Esto premia la defensa activa y el timing sobre el juego impulsivo.
- **Sistema de Parry y Redirección:**  
  Mecánica central inspirada en las enseñanzas de Iroh: absorber la fuerza del adversario y usarla a favor, convirtiendo ataques letales en recursos para abrirse paso.
- **Encuentro con Boss Final (Mecha-Tank):**  
  Batalla climática en la arena superior con fases de combate, escudos de protección, invocación de esbirros de asalto y telegrafiado claro de ataques.
- **Sistema de Terminales de Pistas (Hint Signs):**  
  Terminales industriales interactivos con detección de proximidad y textos optimizados para WebGL que orientan al jugador sobre el uso del Chi y los muros rompibles.
- **Shaders Personalizados 2D:**  
  Efectos visuales dedicados de resplandor (*glow*) para los orbes de energía, teletransportación y proyectiles elementales.
- **Cinemática de Introducción Narrativa:**  
  Secuencia introductoria animada con opción de salto (*Skip*) para sumergir rápidamente al jugador en la historia.
- **Menú de Pausa Funcional en CanvasLayer:**  
  Menú independiente con procesamiento en pausa (`PROCESS_MODE_ALWAYS`) que permite pausar/reanudar la música de fondo en tiempo real y regresar de forma segura al menú principal.

---

## Estructura del Proyecto

```text
├── assets/
│   ├── music/               # Pistas de audio y efectos de sonido
│   └── textures/            # Spritesheets, cinemáticas, tilesets y elementos del entorno
│       ├── background/      # Fondos espaciales e industriales
│       ├── enemies/         # Sprites de torretas, golems y boss frames
│       ├── environment/     # Textura procesada del terminal de pistas (hint_terminal.png)
│       ├── intro_animation/ # Frames de la cinemática de introducción
│       ├── player/          # Sprites y animaciones de Iroh (idle, ataque, parry, aliento)
│       └── ui/              # Pantallas de victoria, derrota, menú y HUD
├── src/
│   ├── Main.gd / Main.tscn  # Escena principal y orquestación del nivel 1 y arena del boss
│   ├── entities/
│   │   ├── enemies/         # Lógica y escenas de Golem, Turret y Boss
│   │   ├── player/          # Controlador de Iroh, habilidades de combate y proyectiles
│   │   └── projectiles/     # Sistema base de proyectiles
│   ├── environment/         # Plataformas, ascensores, muros destructibles y orbes de Chi
│   │   └── interactables/   # Sistema de carteles interactivos (HintSign.tscn / HintSign.gd)
│   ├── shaders/             # Shaders de resplandor (chi_glow)
│   └── ui/                  # HUD, PauseMenu, MainMenu, GameOver, WinCredits e Intro
└── project.godot            # Configuración general de Godot Engine 4 (InputMap, resolución, capas)
```

---

## Créditos

- **Desarrollador / Diseñador Original:** Víctor Bertolini Agaras
- **Arte base de enemigos y Animación de Intro:** Victoria Struba ([@vick_st.art](https://www.instagram.com/vick_st.art) en Instagram)
- **Diseño y Sprites de Iroh:** Sebastián Torres
- **Música y Efectos de Sonido:** Recursos de uso libre (*Free to use*)

---

## Contexto Académico

- **Materia:** Introducción al Desarrollo de Videojuegos
- **Institución:** Universidad Nacional de Quilmes (UNQ)
- **Equipo:** El mate del Oeste — Mesa 2
- **Autor:** Víctor H. Bertolini Agaras
