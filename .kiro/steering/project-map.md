---
inclusion: manual
---

# Mapa del proyecto — índice de documentación

Índice vivo de la documentación de Darby Blackjack. En vez de leer todo el
código, consultar aquí qué documento explica cada área. Se actualiza a medida
que el proyecto crece.

## Documentos base
- `PLAN.md` (raíz) — plan de implementación completo, arquitectura y etapas.
- `requisitos.md` (raíz) — requisitos originales e ideas.
- `README.md` (raíz) — visión general, stack y puesta en marcha.
- `.kiro/steering/project-rules.md` — reglas permanentes (git, Firebase, docs).

## Estado general
- Proyecto Flutter inicializado (`flutter create`), plataformas: android, ios, web.
- Dependencias instaladas: riverpod, go_router, freezed, json_serializable,
  fl_chart, firebase_core/auth, cloud_firestore; dev: build_runner, freezed, json_serializable.
- Estructura de carpetas de `lib/` y `test/` creada (carpetas vacías con `.gitkeep`).
- `main.dart` con `ProviderScope` + pantalla placeholder. `flutter analyze` limpio.
- Motor completo: `cards`, `shoe`, `rules`, `game`, `counting` (con `CountTrainer`)
  implementados y testeados (58 tests en verde). Split e insurance aún no.
- UI: mesa jugable con conteo Hi-Lo + modos de entrenamiento (Libre / Prueba).
- **Firebase conectado** (proyecto `darbyblackjack`): Auth (login/registro/
  recuperación) + Firestore (perfil: saldo, preferencias, stats). `AuthGate`
  enruta login/mesa. Reglas en `firestore.rules`. `flutter build web` compila.
- Etapas 1, 2, 4 (auth + persistencia de perfil) y parte de la 5 hechas.
- PENDIENTE del usuario: desplegar reglas con
  `firebase deploy --only firestore:rules`.
  Siguiente natural: historial/gráficas (Etapa 5) o split (Etapa 1 ampliada).

## Documentos de área
> Se irán creando conforme se construya cada parte. Cada entrada apunta a un
> documento que explica el propósito, los archivos clave y las relaciones del
> área, para no tener que recorrer todo el repo.

| Área | Estado | Documento | Archivos principales |
| --- | --- | --- | --- |
| Motor: cartas y shoe | ✅ hecho | `engine-cards-shoe.md` | `lib/engine/cards/`, `lib/engine/shoe/` |
| Motor: reglas y juego | ✅ hecho | `engine-rules-game.md` | `lib/engine/rules/`, `lib/engine/game/` |
| Motor: conteo | ✅ hecho | `engine-counting.md` | `lib/engine/counting/` |
| Datos / Firebase | ✅ auth + perfil | `data-firebase.md` | `lib/data/`, `lib/features/auth/`, `firestore.rules` |
| UI: mesa y fichas | 🟡 jugable (MVP) | `ui-table.md` | `lib/features/table/` |
| UI: auth | ✅ hecho | `data-firebase.md` | `lib/features/auth/` |
| Entrenamiento y stats | 🟡 modo prueba | `engine-counting.md`, `ui-table.md` | `lib/engine/counting/count_trainer.dart`, `lib/features/table/` |

## Cómo mantener este índice
- Al terminar o cambiar mucho un área, crear/actualizar su documento en
  `.kiro/steering/` (p. ej. `engine-shoe.md`) y poner aquí el enlace y el estado.
- Mantener los "archivos principales" al día para localizar código rápido.
