# Reglas del proyecto — Darby Blackjack

Reglas permanentes que aplican a todo el trabajo en este proyecto. Tienen
prioridad sobre cualquier comportamiento por defecto.

## Git: nunca hago commits ni branches
- NO hago commits bajo ninguna circunstancia.
- NO creo, cambio ni borro branches.
- NO hago push, merge, rebase ni ninguna operación que mueva el historial.
- Mi trabajo termina en: modificar/crear archivos y **avisar al usuario** con un
  resumen corto y objetivo de los cambios para que él los revise y haga el commit.
- Si una tarea parece requerir un commit, me detengo y se lo dejo al usuario.

## Firebase: solo plan gratuito (Spark)
- Usar únicamente funciones incluidas en el plan gratuito de Firebase (Spark).
- Servicios permitidos: Firebase Auth (email/pass, recuperación de contraseña),
  Cloud Firestore dentro de los límites gratuitos, Firebase Hosting.
- **Evitar** cualquier cosa que requiera el plan de pago (Blaze):
  - Cloud Functions requieren Blaze → NO usarlas en el MVP. El motor del juego
    vive en el cliente (ver PLAN.md). Si en el futuro se necesita servidor
    autoritativo, avisar primero porque implica subir de plan.
  - Evitar Cloud Storage, outbound networking de Functions, y cualquier API que
    facture por uso fuera de la cuota gratuita.
- Diseñar el modelo de datos de Firestore para mantenerse holgadamente dentro de
  las cuotas gratuitas (lecturas/escrituras/almacenamiento): minimizar lecturas,
  agregar estadísticas, evitar escrituras por frame.
- Ante la duda de si algo requiere Blaze, preguntar antes de implementarlo.

## Documentación incremental (skills)
- A medida que el proyecto crece, mantener actualizada la documentación en
  `.kiro/steering/` para no tener que leer todo el código en cada tarea.
- La idea: cada área del proyecto tiene un documento que explica qué hace, dónde
  están sus archivos y cómo se relaciona con el resto. Antes de trabajar en un
  área, leer su documento en vez de recorrer todo el repo.
- Ver `project-map.md` como índice vivo de estos documentos.
- Cuando se complete o cambie de forma significativa un área del proyecto,
  actualizar (o crear) su documento de área y el índice.

## Recordatorio de arquitectura
- El motor del juego (`lib/engine/`) es Dart puro: sin Flutter ni Firebase.
- Mantener separado el estado interno (carta oculta, orden del shoe) del estado
  observable que ve la UI.
- Detalles completos en `PLAN.md` (raíz del proyecto).
