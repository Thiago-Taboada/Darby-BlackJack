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
- `.kiro/steering/project-map.md` — índice vivo de la documentación por área
  (apunta a un documento por cada parte del código).

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
    counting/    # Sistemas de conteo (Hi-Lo), running/true count, entrenador
    strategy/    # Tabla de estrategia básica (pendiente)
    probability/ # Probabilidades desde la composición real del shoe (pendiente)
  data/          # Firebase: auth y repositorios de Firestore
  features/      # UI por feature (Riverpod + widgets)
    auth/        # Login, registro y recuperación de contraseña
    table/       # Mesa de juego, conteo y modos de entrenamiento
    betting/ training/ stats/ settings/   # (pendientes)
  shared/        # Tema, widgets comunes, utilidades
test/
  engine/        # Tests del motor (prioridad máxima)
  features/      # Tests del controlador de la mesa
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
flutter run -d chrome   # ejecutar en el navegador (validar móvil con DevTools)
flutter test            # correr tests (incluye los del motor)
flutter build web       # compilar la versión web
```

Para validar el diseño mobile first en web: abrir DevTools (F12) y activar el
modo responsive (Ctrl+Shift+M) para reducir la ventana a tamaño de móvil. No hace
falta emulador de Android para el desarrollo diario.

## Firebase
El proyecto usa solo servicios del plan gratuito (Spark): **Auth** (email/
contraseña + recuperación) y **Cloud Firestore**. No usa Cloud Functions (serían
plan de pago): el motor del juego vive en el cliente.

- La configuración de tu proyecto (`lib/firebase_options.dart`, `google-services.json`,
  `GoogleService-Info.plist`) la genera `flutterfire configure` y está en
  `.gitignore`: cada quien conecta su propio proyecto Firebase.
- Reglas de seguridad de Firestore en `firestore.rules` (cada usuario solo
  accede a su propio documento `users/{uid}`). Desplegarlas con:

```bash
firebase deploy --only firestore:rules
```

## Estado del desarrollo
Ver etapas y checklist en `PLAN.md`. Hecho hasta ahora:

- **Motor completo**: cartas, shoe multi-baraja sin reemplazo con carta de corte,
  reglas de mesa, flujo de la mano (Hit/Stand/Double/Surrender) y pagos.
- **Conteo Hi-Lo**: running count, true count y entrenador de precisión.
- **Mesa jugable** (web y Android) con panel de conteo, botón mostrar/ocultar y
  modos de entrenamiento (Libre / Prueba).
- **Cuentas y persistencia**: registro/login/recuperación y guardado del saldo,
  preferencias y estadísticas en Firestore.

Pendiente: split e insurance, historial de manos y gráficas de progreso, modo
guiado de conteo, y las ampliaciones de etapas posteriores.
