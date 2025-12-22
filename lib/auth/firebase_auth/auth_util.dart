import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/app_state.dart';
import '/backend/schema/user_record.dart';

enum UserRole { student, staff, admin }

/// AuthService provides comprehensive authentication and authorization functionality
/// following the production architecture requirements for role-based access control.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Session timeout duration (24 hours as per requirements)
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // Failed login attempt tracking
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutTimes = {};
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;
  
  /// Check if user is currently logged in
  bool get isLoggedIn => currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  /// Implements requirements 3.2, 3.3 for secure authentication
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      // Check if account is locked out
      if (_isAccountLockedOut(email)) {
        throw Exception('Compte verrouillé. Réessayez dans ${lockoutDuration.inMinutes} minutes.');
      }

      // Validate password strength for new sessions
      if (!isPasswordStrong(password)) {
        throw Exception('Le mot de passe ne respecte pas les critères de sécurité.');
      }

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Clear failed attempts on successful login
        _failedAttempts.remove(email);
        _lockoutTimes.remove(email);

        // Update last login time and create/update user document
        await _updateLastLogin(result.user!.uid);
        await _ensureUserDocument(result.user!);
        
        // Verify and set custom claims if needed
        await _ensureUserRole(result.user!.uid);
        
        // Initialize real-time user data synchronization
        await _initializeUserDataSync(result.user!.uid);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      // Track failed attempts
      _trackFailedAttempt(email);
      
      String errorMessage = _getErrorMessage(e.code);
      throw Exception(errorMessage);
    } catch (e) {
      if (e.toString().contains('Compte verrouillé')) {
        rethrow;
      }
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  /// Sign out current user
  /// Implements session management requirements
  Future<void> signOut() async {
    try {
      // Clear user data from app state before signing out
      FFAppState().logout();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur de déconnexion: ${e.toString()}');
    }
  }

  /// Get user role from custom claims
  /// Implements requirement 1.1 for role assignment
  Future<UserRole?> getUserRole([String? uid]) async {
    final user = uid != null ? null : currentUser;
    if (user == null && uid == null) return null;

    try {
      final targetUid = uid ?? user!.uid;
      
      // First try to get from custom claims
      if (uid == null) {
        final idTokenResult = await user!.getIdTokenResult();
        final role = idTokenResult.claims?['role'] as String?;
        
        if (role != null) {
          return _parseUserRole(role);
        }
      }
      
      // Fallback to Firestore document
      final userDoc = await _firestore.collection('user').doc(targetUid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] as String?;
        return _parseUserRole(role);
      }
      
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Set user role (admin only operation)
  /// Implements requirement 1.4 for immediate permission enforcement
  Future<void> setUserRole(String uid, UserRole role) async {
    try {
      // Verify current user is admin
      final currentRole = await getUserRole();
      if (currentRole != UserRole.admin) {
        throw Exception('Accès non autorisé. Seuls les administrateurs peuvent modifier les rôles.');
      }

      // Call Cloud Function to set custom claims
      final callable = _functions.httpsCallable('setUserRole');
      await callable.call({
        'uid': uid,
        'role': role.name,
      });

      // Update Firestore document
      await _firestore.collection('user').doc(uid).update({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      throw Exception('Erreur de modification du rôle: ${e.toString()}');
    }
  }

  /// Check if user has specific role
  /// Implements requirements 1.2, 1.3 for access control
  Future<bool> hasRole(UserRole role) async {
    final userRole = await getUserRole();
    return userRole == role;
  }

  /// Check if user has any of the specified roles
  Future<bool> hasAnyRole(List<UserRole> roles) async {
    final userRole = await getUserRole();
    return userRole != null && roles.contains(userRole);
  }

  /// Validate user has permission for specific operation
  /// Implements authorization guards for protected routes
  Future<bool> hasPermission(String operation) async {
    final role = await getUserRole();
    if (role == null) return false;

    switch (operation) {
      case 'admin_dashboard':
      case 'manage_users':
      case 'manage_time_slots':
      case 'manage_menu':
      case 'view_analytics':
        return role == UserRole.admin;
      
      case 'scan_qr':
      case 'validate_tickets':
        return role == UserRole.staff || role == UserRole.admin;
      
      case 'make_reservation':
      case 'view_menu':
      case 'view_profile':
        return role == UserRole.student || role == UserRole.staff || role == UserRole.admin;
      
      default:
        return false;
    }
  }

  /// Get current user document from Firestore
  Future<UserRecord?> getCurrentUserDocument() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('user').doc(user.uid).get();
      if (doc.exists) {
        return UserRecord.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user document: $e');
      return null;
    }
  }

  /// Create user with role (admin only)
  /// Implements user creation with proper role assignment
  Future<Map<String, dynamic>> createUserWithRole({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? cin,
    String? classe,
    String? phoneNumber,
  }) async {
    try {
      // Verify current user is admin
      final currentRole = await getUserRole();
      if (currentRole != UserRole.admin) {
        throw Exception('Accès non autorisé. Seuls les administrateurs peuvent créer des utilisateurs.');
      }

      // Validate password strength
      if (!isPasswordStrong(password)) {
        throw Exception(getPasswordStrengthMessage(password));
      }

      // Validate CIN if provided (8 digits for Tunisia)
      if (cin != null && cin.isNotEmpty) {
        if (!RegExp(r'^\d{8}$').hasMatch(cin)) {
          throw Exception('Le CIN doit contenir exactement 8 chiffres.');
        }
      }

      final callable = _functions.httpsCallable('createUserWithRole');
      final result = await callable.call({
        'email': email,
        'password': password,
        'displayName': displayName,
        'role': role.name,
        'cin': cin,
        'classe': classe,
        'phoneNumber': phoneNumber,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur de création d\'utilisateur: ${e.toString()}');
    }
  }

  /// Reset password
  /// Implements requirement 3.7 for password reset functionality
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      throw Exception(errorMessage);
    }
  }

  /// Validate password strength
  /// Implements requirement 3.8 for password requirements
  bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    
    return hasUppercase && hasLowercase && hasDigits;
  }

  /// Get password strength validation message
  String getPasswordStrengthMessage(String password) {
    if (password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    
    List<String> missing = [];
    if (!password.contains(RegExp(r'[A-Z]'))) {
      missing.add('une majuscule');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      missing.add('une minuscule');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      missing.add('un chiffre');
    }
    
    if (missing.isNotEmpty) {
      return 'Le mot de passe doit contenir ${missing.join(', ')}';
    }
    
    return 'Mot de passe fort';
  }

  /// Check if session has expired
  /// Implements requirement 3.6 for session timeout
  Future<bool> isSessionExpired() async {
    final user = currentUser;
    if (user == null) return true;

    try {
      final userDoc = await getCurrentUserDocument();
      if (userDoc?.lastLogin == null) return true;

      final lastLogin = userDoc!.lastLogin!;
      final now = DateTime.now();
      return now.difference(lastLogin) > sessionTimeout;
    } catch (e) {
      return true;
    }
  }

  /// Force session refresh if needed
  Future<void> refreshSessionIfNeeded() async {
    if (await isSessionExpired()) {
      await signOut();
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }
  }

  // Private helper methods

  UserRole? _parseUserRole(String? role) {
    switch (role) {
      case 'student':
        return UserRole.student;
      case 'staff':
        return UserRole.staff;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }

  bool _isAccountLockedOut(String email) {
    final lockoutTime = _lockoutTimes[email];
    if (lockoutTime == null) return false;
    
    return DateTime.now().difference(lockoutTime) < lockoutDuration;
  }

  void _trackFailedAttempt(String email) {
    _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
    
    if (_failedAttempts[email]! >= maxFailedAttempts) {
      _lockoutTimes[email] = DateTime.now();
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('user').doc(uid).update({
        'last_login': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    try {
      final userDoc = await _firestore.collection('user').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await _firestore.collection('user').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'display_name': user.displayName ?? '',
          'created_time': FieldValue.serverTimestamp(),
          'role': 'student', // Default role
          'pocket': 0.0,
          'tickets': 0,
          'language': 'fr',
          'notifications_enabled': true,
        });
      }
    } catch (e) {
      print('Error ensuring user document: $e');
    }
  }

  Future<void> _ensureUserRole(String uid) async {
    try {
      final userDoc = await _firestore.collection('user').doc(uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] as String?;
        if (role != null) {
          // Ensure custom claims match Firestore
          final callable = _functions.httpsCallable('setUserRole');
          await callable.call({
            'uid': uid,
            'role': role,
          });
        }
      }
    } catch (e) {
      print('Error ensuring user role: $e');
    }
  }

  /// Initialize real-time user data synchronization with app state
  Future<void> _initializeUserDataSync(String uid) async {
    try {
      // Initialize user synchronization in app state
      await FFAppState().initializeUserSync(uid);
    } catch (e) {
      print('Error initializing user data sync: $e');
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cette adresse e-mail.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'email-already-in-use':
        return 'Cette adresse e-mail est déjà utilisée.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-credential':
        return 'Identifiants invalides. Vérifiez votre e-mail et mot de passe.';
      case 'network-request-failed':
        return 'Erreur de réseau. Vérifiez votre connexion internet.';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée.';
      default:
        return 'Erreur d\'authentification: $errorCode';
    }
  }
}

/// Legacy AuthManager class for backward compatibility
/// Delegates to AuthService for all operations
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final AuthService _authService = AuthService();

  // Delegate all methods to AuthService
  User? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<UserRole?> getUserRole() => _authService.getUserRole();
  Future<bool> hasRole(UserRole role) => _authService.hasRole(role);
  Future<bool> hasAnyRole(List<UserRole> roles) => _authService.hasAnyRole(roles);

  Future<User?> signInWithEmail(BuildContext context, String email, String password) async {
    final result = await _authService.signInWithEmail(email, password);
    return result.user;
  }

  Future<User?> createUserWithEmail(BuildContext context, String email, String password) async {
    // This method is deprecated - use AuthService.createUserWithRole instead
    throw Exception('Méthode dépréciée. Utilisez AuthService.createUserWithRole à la place.');
  }

  Future<Map<String, dynamic>> createUserWithRole({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? cin,
    String? classe,
    String? phoneNumber,
  }) => _authService.createUserWithRole(
    email: email,
    password: password,
    displayName: displayName,
    role: role,
    cin: cin,
    classe: classe,
    phoneNumber: phoneNumber,
  );

  Future<Map<String, dynamic>> setUserRole(String uid, UserRole role) async {
    await _authService.setUserRole(uid, role);
    return {'success': true};
  }

  Future<DocumentSnapshot?> getUserDocument() async {
    final userRecord = await _authService.getCurrentUserDocument();
    if (userRecord != null) {
      return userRecord.reference.get();
    }
    return null;
  }

  Future<void> updateUserDocument(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    await FirebaseFirestore.instance.collection('user').doc(user.uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _authService.signOut();
  Future<void> resetPassword(String email) => _authService.resetPassword(email);
  bool isPasswordStrong(String password) => _authService.isPasswordStrong(password);
  String getPasswordStrengthMessage(String password) => _authService.getPasswordStrengthMessage(password);
}

// Global instances
final AuthService authService = AuthService();
final AuthManager authManager = AuthManager();

// Helper functions for backward compatibility
Future<User?> signInWithEmail(
  BuildContext context,
  String email,
  String password,
) async {
  final result = await authService.signInWithEmail(email, password);
  return result.user;
}

Future<User?> createUserWithEmail(
  BuildContext context,
  String email,
  String password,
) {
  throw Exception('Méthode dépréciée. Utilisez AuthService.createUserWithRole à la place.');
}

Future<void> signOut() => authService.signOut();

User? get currentUser => authService.currentUser;
bool get loggedIn => authService.isLoggedIn;
Stream<User?> get authStateChanges => authService.authStateChanges;