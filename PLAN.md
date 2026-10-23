# Plan de implementación — Darby Blackjack (Flutter + Firebase)

Plataforma de práctica y entrenamiento de conteo de cartas. El objetivo no es un
blackjack al azar, sino un simulador matemáticamente coherente donde el zapato
(shoe) se comporta como en un casino real y el jugador aprende a contar.

Este plan traduce `requisitos.md` en una arquitectura concreta y un orden de
construcción por etapas.

---

## 0. Decisiones de arquitectura (leer primero)

### Separación motor / UI (requisito 13)
El núcleo del juego se escribe en **Dart puro**, sin ninguna dependencia de
Flutter ni de Firebase. Esto permite:
- Probar el motor con tests unitarios rápidos (reglas, pagos, conteo, shoe).
- Simular miles de manos sin UI (requisito 12).
- Mover el motor a un servidor autoritativo más adelante sin reescribir la UI.

### ¿Dónde vive la lógica autoritativa?
- **Fase 1 (recomendada ahora): motor en el cliente.** Firebase se usa para
  autenticación y persistencia (saldo, preferencias, estadísticas, historial).
  Funciona offline, desarrollo rápido, suficiente para fichas virtuales.
- **Fase futura (si hay dinero real / compras in-app): motor autoritativo en
  Cloud Functions.** El shoe y la carta oculta del crupier viven en el servidor;
  el cliente solo recibe lo observable. Como el motor ya está aislado, esto se
  inserta sin rehacer el núcleo.

> La "información oculta" (carta boca abajo del crupier, cartas no vistas) se
> modela desde el día 1 separando el **estado interno** del motor del **estado
> observable** que se expone a la UI. Así el requisito se cumple aunque el motor
> corra en el cliente, y la migración a servidor es trivial.

### Stack técnico
| Capa | Elección | Motivo |
| --- | --- | --- |
| Framework | Flutter (mobile first, también web/desktop) | Un solo código, requisito 10 |
| Estado | Riverpod | Testeable, sin boilerplate, buena separación |
| Modelos | freezed + json_serializable | Inmutabilidad, igualdad, serialización |
| Navegación | go_router | Rutas declarativas, deep links |
| Auth | Firebase Auth | Email/pass + recuperación (requisito 7) |
| Base de datos | Cloud Firestore | Perfil, saldo, stats, historial, configs |
| Servidor (futuro) | Cloud Functions | Motor autoritativo, validación anti-trampas |
| Gráficas | fl_chart | Progreso y estadísticas (requisito 8) |
| Tests | flutter_test + test | Reglas, pagos, conteo (requisito 13) |

### Estructura de carpetas propuesta
```
lib/
  engine/                 # Dart puro, SIN Flutter/Firebase
    cards/                # Card, Rank, Suit, valor de mano, as flexible
    shoe/                 # Shoe, baraja, mezcla, corte, cartas restantes
    rules/                # TableRules (S17/H17, DAS, surrender, pagos...)
    game/                 # GameState, acciones, resolución, pagos
    counting/             # Estrategia de conteo (Hi-Lo), RC, TC
    strategy/             # Tabla de estrategia básica
    probability/          # Probabilidades desde composición real
  data/                   # Firebase: repos, DTOs, mapeo Firestore
  features/               # UI por feature (Riverpod + widgets)
    auth/
    table/                # mesa de juego
    betting/
    training/
    stats/
    settings/
  shared/                 # tema, widgets comunes, utilidades
  app.dart                # router, tema, providers raíz
  main.dart
test/
  engine/                 # tests del motor (prioridad máxima)
functions/                # Cloud Functions (fase futura)
```

---

## 1. Diseño del motor (lo que hay que clavar antes de nada)

> Tu propia conclusión: "La decisión más importante antes de programar será
> definir exactamente cómo funciona el zapato, cuándo se baraja y qué información
> conoce el jugador." Esta sección es esa definición.

### 1.1 Cartas
- `Suit` (4 palos), `Rank` (2–10, J, Q, K, A).
- Valor de mano con **as flexible**: función que calcula el mejor total (as = 1
  u 11) y expone si la mano es "suave" (soft) para las reglas del crupier.
- `Hand`: lista de cartas + total + flags (soft, blackjack natural, bust).

### 1.2 Shoe (sistema real de barajas — requisito 2)
- Construir N barajas (1/2/4/6/8) × 52 cartas reales.
- Mezcla aleatoria con `Random` sembrable (semilla fija = tests reproducibles y
  simulaciones repetibles).
- **Sin reemplazo**: repartir saca la carta del shoe; no vuelve a salir hasta el
  siguiente barajado. Un test verifica que nunca salen cartas repetidas ni
  inexistentes dentro de un mismo zapato (requisito 13).
- Registro de cartas repartidas y restantes; conteo de barajas restantes
  (restantes / 52) para el True Count.
- **Punto de corte (cut card) configurable**: cuando se cruza, se marca
  "rebarajar al final de la ronda". Rebarajado solo cuando corresponde.
- Exponer `cardsRemaining`, `decksRemaining`, `composition` (cuántas de cada
  rango quedan) para probabilidades y conteo.

### 1.3 Estado interno vs observable (requisito 3 y 13)
- `GameState` interno conoce la carta oculta (hole card) y el orden del shoe.
- `ObservableState` es lo que se pasa a la UI: NO incluye la hole card hasta que
  se revela, ni las cartas futuras del shoe.
- El conteo observable solo suma cartas ya visibles. Ocultar/mostrar el conteo
  es un flag de UI que **no** altera el cálculo interno (requisito 3).

### 1.4 Reglas configurables (requisito 5)
`TableRules` con: nº barajas, penetración/corte, Soft 17 (H17/S17), doblar
(permitido / solo ciertos totales / DAS), split (nº de manos, resplit ases),
pago blackjack (3:2 vs 6:5), peek del crupier con As/10, rendición (surrender).
Presets "principiante" y "avanzado". Guardables por usuario (requisito 5 y 7).

### 1.5 Flujo de una mano (requisito 1)
Apuesta → reparto inicial → (peek si aplica) → turno jugador (Hit/Stand/Double/
Split) → turno crupier según reglas → resolución (blackjack natural, win/lose/
push, bust) → pagos correctos → actualizar saldo e historial.

### 1.6 Conteo (requisito 3)
- Estrategia Hi-Lo como primera implementación, detrás de una interfaz
  `CountingSystem` para añadir sistemas avanzados después sin tocar el núcleo.
- Running Count (suma de valores) y True Count (RC / barajas restantes).
- Valores Hi-Lo: 2–6 → +1 · 7–9 → 0 · 10–A → −1.

### 1.7 Tests del motor (prioridad máxima — requisito 13)
Reglas, pagos, as flexible, resolución del crupier (S17/H17), sin reemplazo,
corte/rebarajado, RC y TC. El motor no se da por bueno sin estos tests en verde.

---

## 2. Modelo de datos en Firebase

### Auth (Firebase Auth)
Registro, login/logout, recuperación de contraseña, perfil (requisito 7).

### Firestore (colecciones)
```
users/{uid}
  profile: { displayName, createdAt }
  wallet:  { balance, updatedAt }            # saldo de fichas
  prefs:   { sound, volume, animations, theme, showCount }
users/{uid}/tableConfigs/{configId}          # configs de mesa guardadas
users/{uid}/sessions/{sessionId}             # sesión: reglas, saldo inicial/final
users/{uid}/sessions/{sessionId}/hands/{id}  # historial de manos
users/{uid}/stats/{aggregateId}              # stats agregadas por sistema/barajas
```
- **Reglas de seguridad de Firestore**: cada usuario solo lee/escribe su propio
  `users/{uid}`. Esto protege datos (requisito 7).
- **Nota anti-trampas (requisito 13)**: con el motor en el cliente, el saldo es
  escribible por el cliente. Es aceptable para fichas virtuales. El blindaje real
  (que el cliente no pueda alterar saldo/resultado) llega con el motor en Cloud
  Functions; se deja señalado como punto de migración.
- Guardar estadísticas sin duplicar: cada mano/sesión con id único e idempotente.

---

## 3. Etapas de construcción

Sigo tu orden recomendado (sección 15), concretado en entregables.

### Etapa 1 — Fundamentos del juego  ·  Prioridad máxima
- [ ] Scaffolding del proyecto Flutter + dependencias + análisis estático.
- [ ] `engine/cards`: Card, Rank, Suit, Hand, valor con as flexible.
- [ ] `engine/shoe`: shoe N barajas, mezcla sembrable, sin reemplazo, corte.
- [ ] `engine/rules`: TableRules + presets.
- [ ] `engine/game`: flujo de mano, Hit/Stand/Double/Split, crupier, resolución, pagos.
- [ ] Separación estado interno / observable (hole card oculta).
- [ ] Tests unitarios del motor (reglas, pagos, sin reemplazo, resolución).
**Hecho cuando:** se puede jugar una mano completa por código y los tests pasan.

### Etapa 2 — Conteo de cartas
- [ ] Interfaz `CountingSystem` + implementación Hi-Lo.
- [ ] Running Count y True Count con barajas restantes estimadas.
- [ ] Conteo observable (solo cartas vistas) + flag mostrar/ocultar sin afectar cálculo.
- [ ] Tests de RC/TC.
**Hecho cuando:** el conteo es correcto y ocultarlo no altera el estado interno.

### Etapa 3 — Interfaz y fichas
- [ ] Mesa de casino (cartas, fichas, crupier) mobile first + responsive.
- [ ] Controles de acción (Hit/Stand/Double/Split) claros.
- [ ] Sistema de fichas y apuestas: saldo inicial, min/max, pagos, recarga.
- [ ] Botón mostrar/ocultar conteo, panel de barajas restantes, indicador de saldo.
- [ ] Animaciones de reparto/acciones + opción de reducirlas; sonidos opcionales + volumen.
- [ ] Historial de manos en memoria/local.
**Hecho cuando:** se juega una sesión completa desde la UI con apuestas y saldo.

### Etapa 4 — Cuentas y persistencia
- [ ] Firebase Auth: registro, login/logout, recuperación de contraseña.
- [ ] Perfil; guardar saldo, preferencias y configs de mesa en Firestore.
- [ ] Reglas de seguridad de Firestore (cada uid aislado).
- [ ] Guardar historial y sesiones; continuar en otro dispositivo.
**Hecho cuando:** un usuario cierra sesión, vuelve en otro dispositivo y recupera su progreso.

### Etapa 5 — Entrenamiento y estadísticas
- [ ] Modos: libre, guiado, práctica de conteo, prueba (conteo oculto), sesión completa.
- [ ] Dificultad configurable, explicación de errores, repetir ejercicios, retos progresivos.
- [ ] Stats: manos, % W/L/push, P&L, evolución de saldo, tiempo, precisión y
      velocidad de conteo, nº de errores.
- [ ] Gráficos (fl_chart), stats separadas por sistema y nº de barajas, comparación entre sesiones.
**Hecho cuando:** el usuario practica el conteo y ve su progreso medido.

### Etapa 6 — Ampliaciones
- [ ] Clasificaciones, retos diarios/semanales, logros, insignias, niveles.
- [ ] Sistemas de conteo avanzados (sobre la interfaz `CountingSystem`).
- [ ] Tabla de estrategia básica + jugada recomendada + explicación (requisito 9).
- [ ] Modo análisis: composición restante, probabilidades, simulación de miles de manos.
- [ ] Temas visuales adicionales; exportar estadísticas; informes.
- [ ] (Comercial, opcional) compras in-app / suscripción → requiere motor autoritativo.

---

## 4. MVP (primera versión imprescindible)

Según tu "recomendación final", el MVP = Etapas 1–4 completas + lo básico de la 5:
blackjack funcional, 1/2/4/6/8 barajas, shoe real sin reemplazo, Hi-Lo con
RC/TC y opción de ocultar, fichas y apuestas, reglas configurables, cuenta con
guardado, historial y stats básicas, y un modo de entrenamiento de conteo.

---

## 5. Riesgos y notas

- **Coherencia matemática del shoe**: el mayor riesgo. Se mitiga con tests y
  simulación (requisito 12) antes de pulir la UI.
- **Anti-trampas real**: limitado mientras el motor viva en el cliente. Decisión
  consciente para el MVP; migrar a Cloud Functions cuando haya dinero real.
- **Responsive mobile-first**: diseñar la mesa pensando primero en móvil y
  escalando a tablet/desktop, no al revés.

---

## 6. Próximo paso sugerido

Arrancar la **Etapa 1**: crear el proyecto Flutter con la estructura de carpetas
y construir `engine/cards` + `engine/shoe` con sus tests. Es el cimiento sobre el
que se apoya todo lo demás.
