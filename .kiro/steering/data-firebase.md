---
inclusion: manual
---

# Área: Datos / Firebase

Autenticación y persistencia con Firebase (plan gratuito Spark). Cubre el
requisito 7 (cuentas, guardado del progreso, continuar en otro dispositivo).
NO usa Cloud Functions (requieren Blaze): el motor sigue en el cliente.

## Configuración del proyecto Firebase
- Proyecto: `darbyblackjack`. Plataformas registradas: web, android (ios de más).
- `lib/firebase_options.dart` lo generó `flutterfire configure` y está en
  `.gitignore` (específico del proyecto; las apiKey de cliente no son secretas).
- Servicios usados: **Auth** (email/contraseña + recuperación) y **Firestore**.
- Inicialización: `Firebase.initializeApp` en `lib/main.dart` antes de `runApp`.

## Archivos
- `lib/data/auth_repository.dart` — `AuthRepository` (signIn, register,
  sendPasswordReset, signOut, authStateChanges) + `AuthFailure` (mensajes en
  español). Providers: `authRepositoryProvider`, `authStateProvider` (Stream).
- `lib/data/profile_repository.dart` — `ProfileRepository`: `loadOrCreate(uid)`
  y `save(uid, profile)` sobre `users/{uid}`. Provider: `profileRepositoryProvider`.
- `lib/data/models/user_profile.dart` — `UserProfile` (balance, showCount,
  totalChecks, correctChecks, bestStreak) con `toMap`/`fromMap` tolerante.
- `lib/features/auth/auth_gate.dart` — `AuthGate`: según `authStateProvider`
  muestra `AuthScreen` (sin sesión) o `TableScreen` (con sesión).
- `lib/features/auth/auth_screen.dart` — login / registro / recuperar contraseña.

## Modelo de datos en Firestore
- Un documento por usuario: `users/{uid}` con los campos de `UserProfile`.
- Diseñado para quedar holgado en cuotas gratuitas: 1 lectura al entrar, 1
  escritura al resolver ronda / cambiar preferencia / comprobar conteo. Nada de
  escrituras por frame.

## Reglas de seguridad (requisito 7 y 13)
- `firestore.rules`: cada usuario autenticado solo lee/escribe su propio
  `users/{uid}` (y subcolecciones). Todo lo demás denegado.
- `firebase.json` apunta a `firestore.rules` y `firestore.indexes.json`.
- Desplegar reglas (dentro de Spark): `firebase deploy --only firestore:rules`.

## Integración con la mesa
`TableController` (ver `ui-table.md`):
- Al construirse llama a `_loadProfile()`: si hay sesión, carga saldo,
  preferencia de conteo y stats de por vida; si no, usa valores por defecto.
- `_uid` es defensivo: si Firebase no está disponible (tests) o no hay sesión,
  devuelve null y la persistencia es un no-op (la mesa funciona en memoria).
- `_persist()` guarda tras: resolver ronda (saldo), toggle de conteo, y
  `checkCount` (stats acumuladas). Fire-and-forget con `.ignore()`.
- `signOut()` persiste y cierra sesión. Botón en la AppBar de la mesa.

## Qué NO está hecho todavía
- Historial detallado de manos/sesiones en subcolecciones (ahora solo perfil agregado).
- Gráficas de evolución (Etapa 5, con fl_chart).
- Desplegar las reglas: lo hace el usuario con el comando de arriba.

## Tests
- `test/widget_test.dart` — `AuthGate` muestra login cuando no hay sesión
  (overriding `authStateProvider`, sin tocar Firebase real).
- Los tests del controlador no requieren Firebase gracias al `_uid` defensivo.
