# Design Document: Student Authentication and Core Flow

## Overview

This design document outlines the stabilization and refinement of the core student authentication and home page experience for the ISET Com Restaurant Reservation System. The system will focus exclusively on the student role, providing a clean, reliable authentication flow with Firebase, dynamic data display, and seamless access to reservation functionality.

The design emphasizes simplicity, reliability, and real-time data synchronization while maintaining the existing Flutter architecture and Firebase backend infrastructure.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Firebase Auth  │    │   Firestore     │
│   (Students)    │◄──►│   Service       │◄──►│   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   App State     │    │  Auth Util      │    │  User Document  │
│   Management    │    │  (Role Check)   │    │  Real-time Sync │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack

**Frontend:**
- Flutter 3.x with Dart
- Provider for state management (existing FFAppState)
- Firebase SDK for Flutter
- Real-time Firestore listeners

**Backend:**
- Firebase Authentication (user management)
- Cloud Firestore (user data and reservations)
- Existing Firebase Cloud Functions (if needed)

**Security:**
- Role-based access control (student-only)
- Session management with 24-hour timeout
- Input validation and sanitization

## Components and Interfaces

### 1. Authentication Service (Enhanced)

**Purpose:** Manages student authentication with role validation and session management.

**Key Methods:**
```dart
class StudentAuthService {
  Future<UserCredential> signInStudent(String email, String password);
  Future<void> signOut();
  Future<bool> isStudentRole(String uid);
  Future<UserRecord?> getStudentDocument(String uid);
  Stream<User?> get authStateChanges;
  bool get isLoggedIn;
  Future<bool> isSessionValid();
}
```

**Authentication Flow:**
1. Student enters email/password
2. Firebase Auth validates credentials
3. System retrieves user document from Firestore
4. System validates user has 'student' role
5. System initializes real-time data sync
6. System navigates to home screen

**Role Validation:**
- Only users with role 'student' can access the app
- Non-student users receive clear rejection message
- Role validation occurs on every app startup

### 2. Student Data Manager

**Purpose:** Manages real-time synchronization of student data with Firestore.

**Key Methods:**
```dart
class StudentDataManager {
  Future<void> initializeStudentSync(String uid);
  Stream<UserRecord> getStudentDataStream(String uid);
  Future<void> refreshStudentData();
  UserRecord? get currentStudent;
  double get balance;
  int get tickets;
  String get displayName;
}
```

**Real-Time Synchronization:**
- Firestore listener for user document changes
- Automatic UI updates when data changes
- Offline capability with cached data
- Error handling with retry mechanisms

### 3. Student Home Screen Controller

**Purpose:** Manages the home screen state and navigation for students.

**Key Methods:**
```dart
class StudentHomeController {
  Future<void> loadHomeData();
  void navigateToReservation();
  void navigateToQRCode();
  void navigateToHistory();
  bool get hasActiveReservations;
  List<ReservationRecord> get upcomingReservations;
}
```

**Home Screen Features:**
- Dynamic greeting with student name
- Real-time balance and ticket display
- Quick action buttons (Reserve, QR Code, History)
- Today's menu display (if available)
- Error states and loading indicators

### 4. Session Manager

**Purpose:** Handles session persistence and validation.

**Key Methods:**
```dart
class SessionManager {
  Future<bool> restoreSession();
  Future<void> validateSession();
  Future<void> clearSession();
  bool get isSessionExpired;
  Duration get timeUntilExpiry;
}
```

**Session Management:**
- 24-hour session timeout
- Automatic session restoration on app startup
- Secure token storage
- Session validation on critical operations

## Data Models

### Enhanced User Document Structure
```typescript
interface StudentRecord {
  uid: string;                    // Firebase Auth UID
  email: string;                  // Student email
  displayName: string;            // Full name
  nom: string;                    // French name field
  role: 'student';                // Must be student
  classe?: string;                // Student class
  pocket: number;                 // Account balance (DT)
  tickets: number;                // Available tickets
  language: 'fr' | 'ar' | 'en';  // Preferred language
  notificationsEnabled: boolean;  // Push notification preference
  createdTime: Timestamp;         // Account creation
  lastLogin: Timestamp;           // Last login time
}
```

### App State Structure
```dart
class StudentAppState {
  UserRecord? currentStudent;
  bool isLoggedIn;
  bool isOnline;
  String? lastError;
  bool isLoading;
  List<ReservationRecord> reservations;
  List<PlatRecord> todaysMenu;
  DateTime lastSyncTime;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

<function_calls>
<invoke name="prework">
<parameter name="featureName">student-authentication-flow

### Property Reflection

After analyzing the acceptance criteria, I identified several areas where properties can be consolidated to eliminate redundancy:

**Authentication Properties:** Requirements 1.1, 1.2, and 1.3 all relate to successful authentication flow and can be combined into a comprehensive authentication property.

**Data Display Properties:** Requirements 2.1, 2.2, and 2.3 all test data consistency between Firestore and UI display, which can be unified into a single data synchronization property.

**Real-time Update Properties:** Requirements 5.1, 5.2, and 5.3 all test real-time updates and can be combined into one comprehensive real-time synchronization property.

**Error Handling Properties:** Requirements 6.1, 6.2, and 6.3 all test error handling and can be consolidated into comprehensive error handling properties.

### Converting EARS to Properties

Based on the prework analysis, here are the key correctness properties:

**Property 1: Student Authentication Flow**
*For any* valid student credentials (email and password), the authentication process should successfully authenticate via Firebase, load the user document, verify student role, and navigate to home screen.
**Validates: Requirements 1.1, 1.2, 1.3**

**Property 2: Role-Based Access Control**
*For any* user with a non-student role attempting to access the system, access should be denied with an appropriate error message.
**Validates: Requirements 1.4**

**Property 3: Data Display Consistency**
*For any* student data displayed in the UI (name, balance, tickets), the displayed values should match the corresponding values stored in the student's Firestore document.
**Validates: Requirements 2.1, 2.2, 2.3, 2.5**

**Property 4: Real-Time Data Synchronization**
*For any* change to student data in Firestore (balance, tickets, reservations), the UI should reflect the change within 2 seconds.
**Validates: Requirements 2.4, 5.1, 5.2, 5.3**

**Property 5: Session Persistence**
*For any* successful student authentication, the session should remain valid for 24 hours and be automatically restored when the app is reopened.
**Validates: Requirements 4.1, 4.2**

**Property 6: Session Expiration Handling**
*For any* expired session, the system should redirect to login with an appropriate message and clear all cached data.
**Validates: Requirements 4.3, 4.4**

**Property 7: Input Validation**
*For any* user input (email, password), the system should validate the input format and strength before attempting authentication.
**Validates: Requirements 1.7, 6.6**

**Property 8: Error Message Display**
*For any* authentication failure or system error, the system should display clear, user-friendly error messages in French.
**Validates: Requirements 1.6, 6.1**

**Property 9: Navigation Functionality**
*For any* navigation action from the home screen (reservation, QR code, history), the system should navigate to the appropriate screen.
**Validates: Requirements 3.2, 3.5, 8.1**

**Property 10: Offline Mode Handling**
*For any* network connectivity loss, the system should display offline indicators and gracefully handle the offline state.
**Validates: Requirements 5.4, 6.4**

**Property 11: Loading State Display**
*For any* asynchronous operation (data loading, authentication), the system should display appropriate loading indicators.
**Validates: Requirements 3.7, 6.5**

**Property 12: Reservation System Access**
*For any* student accessing the reservation system, time slots should display accurate capacity information and prevent double-booking.
**Validates: Requirements 8.2, 8.3, 8.5**

## Error Handling

### Error Categories and Responses

**Authentication Errors:**
- Invalid credentials → "Email ou mot de passe incorrect"
- Non-student role → "Accès réservé aux étudiants uniquement"
- Account disabled → "Compte désactivé. Contactez l'administration"
- Network error → "Erreur de connexion. Vérifiez votre réseau"

**Data Loading Errors:**
- User document not found → "Données utilisateur introuvables"
- Network timeout → "Délai de connexion dépassé"
- Firestore permission denied → "Accès aux données refusé"
- Sync failure → "Erreur de synchronisation des données"

**Session Errors:**
- Session expired → "Session expirée. Veuillez vous reconnecter"
- Invalid session → "Session invalide. Reconnexion requise"
- Token refresh failed → "Erreur de renouvellement de session"

**Input Validation Errors:**
- Invalid email format → "Format d'email invalide"
- Weak password → "Mot de passe trop faible (8+ caractères requis)"
- Empty fields → "Veuillez remplir tous les champs"

### Error Recovery Strategies

**Automatic Retry:**
- Network requests with exponential backoff (1s, 2s, 4s)
- Failed authentication attempts (max 3 retries)
- Data sync failures (retry every 30 seconds)

**User-Initiated Recovery:**
- "Réessayer" buttons for failed operations
- "Actualiser" options for stale data
- Manual logout/login for session issues

**Graceful Degradation:**
- Show cached data when real-time sync fails
- Allow viewing of previously loaded information
- Disable features requiring network connectivity

## Testing Strategy

### Dual Testing Approach

The system will employ both unit testing and property-based testing to ensure comprehensive coverage:

**Unit Tests:**
- Verify specific authentication scenarios
- Test error handling edge cases
- Validate UI state transitions
- Test offline/online mode switching

**Property-Based Tests:**
- Verify authentication works for all valid student credentials
- Test data consistency across all possible data values
- Ensure real-time sync works for all data changes
- Validate error handling for all failure scenarios

### Property-Based Testing Configuration

**Framework:** We will use the `test` package with custom property testing utilities for Dart/Flutter.

**Test Configuration:**
- Minimum 100 iterations per property test
- Each property test references its design document property
- Tag format: **Feature: student-authentication-flow, Property {number}: {property_text}**

**Example Property Test Structure:**
```dart
testProperty('Feature: student-authentication-flow, Property 1: Student Authentication Flow', () {
  // Generate random valid student credentials
  // Attempt authentication
  // Verify successful flow completion
}, iterations: 100);
```

**Property Test Categories:**

1. **Authentication Properties:**
   - Student authentication flow validation
   - Role-based access control enforcement
   - Session management and persistence
   - Input validation and error handling

2. **Data Consistency Properties:**
   - UI display matches Firestore data
   - Real-time synchronization accuracy
   - Offline data accessibility
   - Error state handling

3. **Navigation Properties:**
   - Home screen navigation functionality
   - Reservation system access
   - Profile information display
   - Loading state management

**Unit Test Focus Areas:**

1. **Authentication Edge Cases:**
   - Invalid email formats
   - Weak password scenarios
   - Network failure during auth
   - Non-student role handling

2. **Data Synchronization:**
   - Firestore listener setup
   - Real-time update handling
   - Offline mode transitions
   - Sync error recovery

3. **UI State Management:**
   - Loading indicator display
   - Error message presentation
   - Navigation state handling
   - Session restoration

4. **Session Management:**
   - Session timeout handling
   - Token refresh scenarios
   - Logout cleanup
   - Session validation

### Testing Infrastructure

**Firebase Emulator Suite:**
- Local Firestore for isolated testing
- Auth emulator for authentication testing
- Offline mode simulation
- Real-time listener testing

**Test Data Management:**
- Automated student account generation
- Consistent test data cleanup
- Reproducible test scenarios
- Mock data for offline testing

**Continuous Integration:**
- Automated test execution on commits
- Property test results tracking
- Performance regression detection
- Authentication flow validation

The combination of unit tests and property-based tests ensures both specific functionality correctness and general system reliability across all possible student interactions and data scenarios.