import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/user_profile.dart';

/// Lee y escribe el perfil del usuario en Firestore.
///
/// Un único documento por usuario en `users/{uid}`, lo que mantiene el uso
/// holgado dentro del plan gratuito (una lectura al entrar, una escritura al
/// guardar). Las reglas de seguridad (`firestore.rules`) garantizan que cada
/// usuario solo accede a su propio documento.
class ProfileRepository {
  ProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Carga el perfil del usuario. Si no existe todavía (primer inicio de
  /// sesión), lo crea con los valores por defecto y lo devuelve.
  Future<UserProfile> loadOrCreate(String uid) async {
    final snapshot = await _doc(uid).get();
    if (!snapshot.exists) {
      await _doc(uid).set(UserProfile.initial.toMap());
      return UserProfile.initial;
    }
    return UserProfile.fromMap(snapshot.data());
  }

  /// Guarda el perfil completo (merge para no borrar campos futuros).
  Future<void> save(String uid, UserProfile profile) {
    return _doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }
}

/// Provider del repositorio de perfil.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(FirebaseFirestore.instance),
);
