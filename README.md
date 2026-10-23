# Darby Blackjack

Plataforma de **práctica y entrenamiento de conteo de cartas** en Blackjack.
El objetivo no es un blackjack al azar, sino un simulador matemáticamente
coherente donde el zapato (shoe) se comporta como en un casino real y el jugador
aprende a contar cartas en condiciones realistas.

Construido con **Flutter** (mobile first) y **Firebase** (plan gratuito Spark).

## Documentación
- `requisitos.md` — requisitos originales e ideas del proyecto.
- `PLAN.md` — plan de implementación, arquitectura y etapas de desarrollo.
- `.kiro/steering/project-rules.md` — reglas permanentes del proyecto.
- `.kiro/steering/project-map.md` — índice vivo de la documentación por área.

## Arquitectura (resumen)
El núcleo del juego es **Dart puro** (sin Flutter ni Firebase), para poder
testearlo y simularlo de forma aislada, y mantener separado el estado interno
(carta oculta, orden del shoe) del estado observable que ve la UI.

```
lib/
  engine/        # Motor del juego — Dart puro (sin Flutter/Firebase)
    cards/       # Carta, palo, rango, valor de mano (as flexible)
    shoe/        # Shoe multi-baraja, mezcla, corte, cartas restantes
    rules/       # Reglas configurables de mesa (S17/H17, DAS, pagos...)
    game/        # Flujo de la mano, acciones, resolución, pagos
    counting/    # Sistemas de conteo (Hi-Lo), running/true count
    strategy/    # Tabla de estrategia básica
    probability/ # Probabilidades desde la composición real del shoe
  data/          # Firebase: repositorios, DTOs, mapeo Firestore
  features/      # UI por feature (Riverpod + widgets)
    auth/ table/ betting/ training/ stats/ settings/
  shared/        # Tema, widgets comunes, utilidades
test/
  engine/        # Tests del motor (prioridad máxima)
```

## Stack
- Estado: `flutter_riverpod`
- Modelos inmutables + serialización: `freezed`, `json_serializable`
- Navegación: `go_router`
- Backend: `firebase_core`, `firebase_auth`, `cloud_firestore`
- Gráficas: `fl_chart`
- Codegen: `build_runner`

## Puesta en marcha
```bash
flutter pub get
flutter run            # ejecutar la app
flutter test           # correr tests (incluye los del motor)
dart run build_runner build --delete-conflicting-outputs   # generar código freezed/json
```

> **Firebase aún no está conectado.** Se configurará en la Etapa 4 con
> `flutterfire configure`, que genera `lib/firebase_options.dart` (ignorado por
> git). El proyecto usa solo servicios del plan gratuito: Auth, Firestore y
> Hosting. No se usan Cloud Functions (requieren plan de pago).

## Estado del desarrollo
Ver etapas y checklist en `PLAN.md`. Etapa actual: **1 — Fundamentos del juego**.
