# Design Document: ISET Com Restaurant Reservation System - Production Architecture

## Overview

This design document outlines the transformation of the ISET Com Restaurant Reservation System from a FlutterFlow UI prototype into a secure, scalable, production-ready application. The system will implement a three-tier architecture with Flutter mobile clients, Firebase backend services, and external payment integration with Tunisia's D17 system.

The design emphasizes security-first principles, real-time data synchronization, role-based access control, and comprehensive audit logging. All hardcoded UI elements will be replaced with dynamic, backend-driven data while maintaining the existing user experience.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Firebase Cloud │    │   D17 Payment   │
│   (Students)    │◄──►│   Functions     │◄──►│     System      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
┌─────────────────┐           │
│   Flutter App   │           │
│    (Staff)      │◄──────────┤
└─────────────────┘           │
┌─────────────────┐           ▼
│   Flutter App   │    ┌─────────────────┐
│   (Admins)      │◄──►│   Firestore     │
└─────────────────┘    │   Database      │
                       └─────────────────┘
```

### Technology Stack

**Frontend:**
- Flutter 3.x with Dart
- Firebase SDK for Flutter
- Provider for state management
- QR Code generation/scanning libraries
- Local secure storage for offline capabilities

**Backend:**
- Firebase Authentication (user management)
- Cloud Firestore (primary database)
- Firebase Cloud Functions (business logic)
- Firebase Cloud Storage (file uploads)
- Firebase Cloud Messaging (push notifications)

**External Integrations:**
- D17 Payment System (Tunisia national payment)
- Firebase Analytics (usage tracking)
- Firebase Crashlytics (error monitoring)

### Security Architecture

**Authentication Flow:**
1. User authenticates via Firebase Auth
2. Custom claims set for user role (student/staff/admin)
3. JWT tokens include role information
4. Firestore security rules validate role on every request

**Data Access Control:**
- Firestore security rules enforce RBAC at database level
- Cloud Functions validate permissions before operations
- API endpoints protected with Firebase Auth middleware
- Sensitive operations require additional verification

## Components and Interfaces

### 1. Authentication Service

**Purpose:** Manages user authentication, role assignment, and session management.

**Key Methods:**
```dart
class AuthService {
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> setUserRole(String uid, UserRole role);
  Future<UserRole> getUserRole(String uid);
  Stream<User?> get authStateChanges;
}
```

**Security Features:**
- Password strength validation (8+ chars, mixed case, numbers)
- Account lockout after 5 failed attempts
- Session timeout after 24 hours of inactivity
- Custom claims for role-based access

### 2. Reservation Service

**Purpose:** Handles meal reservations, capacity management, and payment integration.

**Key Methods:**
```dart
class ReservationService {
  Future<Reservation> createReservation(String timeSlotId, String userId);
  Future<void> cancelReservation(String reservationId);
  Future<List<Reservation>> getUserReservations(String userId);
  Future<PaymentResult> processPayment(String reservationId, PaymentDetails details);
  Stream<List<TimeSlot>> getAvailableTimeSlots(DateTime date);
}
```

**Business Rules:**
- Atomic capacity updates using Firestore transactions
- Payment verification before reservation confirmation
- Automatic cleanup of expired pending reservations
- Real-time capacity updates via Firestore listeners

### 3. QR Token Service

**Purpose:** Generates and validates secure QR codes for restaurant entry.

**Key Methods:**
```dart
class QRTokenService {
  Future<String> generateQRToken(String reservationId);
  Future<QRValidationResult> validateQRToken(String token);
  Future<void> markTicketAsUsed(String reservationId, String staffId);
}
```

**Security Implementation:**
- JWT-based tokens with HMAC-SHA256 signing
- 1-hour expiration after time slot end
- Cryptographic signature prevents forgery
- One-time use enforcement via database flags

**Token Structure:**
```json
{
  "iss": "isetcom-restaurant",
  "sub": "reservation_id",
  "aud": "restaurant-entry",
  "exp": 1640995200,
  "iat": 1640908800,
  "user_id": "student_uid",
  "time_slot": "2024-01-15T12:30:00Z",
  "capacity": 1
}
```

### 4. Admin Management Service

**Purpose:** Provides administrative functions for system management.

**Key Methods:**
```dart
class AdminService {
  Future<void> createTimeSlot(TimeSlotData data);
  Future<void> updateTimeSlotCapacity(String slotId, int newCapacity);
  Future<void> createUser(UserData userData, UserRole role);
  Future<void> updateUserRole(String uid, UserRole newRole);
  Future<List<AuditLog>> getAuditLogs(DateTime from, DateTime to);
  Future<AnalyticsData> getSystemAnalytics(DateTime date);
}
```

**Administrative Controls:**
- Bulk operations for time slot creation
- User role management with audit trails
- System configuration updates
- Real-time analytics and reporting

### 5. Payment Integration Service

**Purpose:** Handles D17 payment system integration and verification.

**Key Methods:**
```dart
class PaymentService {
  Future<PaymentRequest> initiatePayment(String reservationId, double amount);
  Future<PaymentStatus> verifyPayment(String transactionId);
  Future<void> handlePaymentWebhook(Map<String, dynamic> webhookData);
  Future<void> processRefund(String transactionId, double amount);
}
```

**D17 Integration Flow:**
1. Student initiates payment in app
2. Cloud Function creates payment request with D17
3. Student redirected to D17 payment interface
4. D17 sends webhook notification on completion
5. Cloud Function verifies payment and updates reservation
6. Student receives confirmation notification

**Security Measures:**
- Webhook signature verification
- Idempotent payment processing
- Transaction reconciliation
- Fraud detection and monitoring

## Data Models

### User Document Structure
```typescript
interface UserRecord {
  uid: string;                    // Firebase Auth UID
  email: string;                  // User email address
  displayName: string;            // Full name
  role: 'student' | 'staff' | 'admin';
  cin?: number;                   // National ID (8 digits)
  classe?: string;                // Student class
  phoneNumber?: string;           // Contact number
  pocket: number;                 // Account balance (DT)
  tickets: number;                // Available tickets
  language: 'fr' | 'ar' | 'en';  // Preferred language
  notificationsEnabled: boolean;  // Push notification preference
  createdTime: Timestamp;         // Account creation
  lastLogin?: Timestamp;          // Last login time
}
```

### Reservation Document Structure
```typescript
interface ReservationRecord {
  id: string;                     // Unique reservation ID
  userId: string;                 // Reference to user
  timeSlotId: string;             // Reference to time slot
  status: 'pending' | 'confirmed' | 'used' | 'cancelled' | 'expired';
  createdAt: Timestamp;           // Creation time
  confirmedAt?: Timestamp;        // Payment confirmation
  usedAt?: Timestamp;             // Entry scan time
  qrToken?: string;               // Generated QR token
  paymentId?: string;             // D17 transaction ID
  amount: number;                 // Payment amount (DT)
  capacity: number;               // Number of seats (default: 1)
}
```

### Time Slot Document Structure
```typescript
interface TimeSlotRecord {
  id: string;                     // Unique slot ID
  date: Timestamp;                // Slot date
  startTime: Timestamp;           // Start time
  endTime: Timestamp;             // End time
  maxCapacity: number;            // Maximum seats
  currentReservations: number;    // Current bookings
  price: number;                  // Meal price (DT)
  mealType: 'breakfast' | 'lunch' | 'dinner';
  isActive: boolean;              // Availability flag
  createdBy: string;              // Admin who created
  createdAt: Timestamp;           // Creation time
}
```

### Menu Item Document Structure
```typescript
interface PlatRecord {
  id: string;                     // Unique item ID
  nom: string;                    // Dish name
  description: string;            // Description
  ingredients: string;            // Ingredient list
  prix: number;                   // Price (DT)
  categorie: 'entree' | 'plat_principal' | 'dessert';
  image?: string;                 // Firebase Storage URL
  availableDate: Timestamp;       // Menu date
  isActive: boolean;              // Availability
  createdBy: string;              // Admin who added
  createdAt: Timestamp;           // Creation time
}
```

### Audit Log Document Structure
```typescript
interface AuditLogRecord {
  id: string;                     // Unique log ID
  timestamp: Timestamp;           // Action time
  userId: string;                 // Acting user
  userRole: string;               // User's role
  action: string;                 // Action type
  resource: string;               // Affected resource
  resourceId?: string;            // Resource identifier
  details: Record<string, any>;   // Action details
  ipAddress?: string;             // Client IP
  userAgent?: string;             // Client info
  result: 'success' | 'failure';  // Operation result
  errorMessage?: string;          // Error details
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Now I'll analyze the acceptance criteria to determine which can be tested as properties:

<function_calls>
<invoke name="prework">
<parameter name="featureName">production-architecture

### Property Reflection

After analyzing the acceptance criteria, I identified several areas where properties can be consolidated to eliminate redundancy:

**Access Control Properties:** Requirements 1.2 and 1.3 both test role-based access denial and can be combined into a comprehensive access control property that covers all role restrictions.

**Data Display Properties:** Requirements 2.1 and 2.2 both test data consistency between storage and display, which can be unified into a single property about data synchronization.

**Transaction Properties:** Requirements 17.2 and 17.3 both verify transaction usage and can be combined into one property about atomic operations.

**QR Token Properties:** Requirements 7.1, 7.2, 8.1, and 8.2 all relate to QR token security and can be consolidated into comprehensive token validation properties.

### Converting EARS to Properties

Based on the prework analysis, here are the key correctness properties:

**Property 1: Role-Based Access Control**
*For any* user with a specific role, attempting to access features not permitted for that role should result in an authorization error and access denial.
**Validates: Requirements 1.2, 1.3**

**Property 2: Authentication Role Assignment**
*For any* successful user authentication, exactly one role (student, staff, or admin) should be assigned to the user.
**Validates: Requirements 1.1**

**Property 3: Data Display Consistency**
*For any* user data displayed in the UI, the displayed values should match the corresponding values stored in Firestore.
**Validates: Requirements 2.1, 2.2, 2.5**

**Property 4: Time Slot Query Accuracy**
*For any* date selected by a student, the system should return only time slots that match that specific date from Firestore.
**Validates: Requirements 4.1**

**Property 5: Time Slot Display Completeness**
*For any* time slot displayed to users, all required fields (current_reservations, max_capacity, start_time, end_time) should be present and accurate.
**Validates: Requirements 4.2**

**Property 6: Reservation Capacity Validation**
*For any* reservation creation attempt, the system should only allow the reservation if the time slot has available capacity (current_reservations < max_capacity).
**Validates: Requirements 5.1**

**Property 7: Atomic Reservation Updates**
*For any* successful reservation creation, the time slot's current_reservations counter should be atomically incremented by exactly the reservation capacity.
**Validates: Requirements 5.3, 17.2**

**Property 8: Payment Backend Verification**
*For any* payment status update, the change should originate from backend verification with D17, never from client-side requests.
**Validates: Requirements 6.2, 6.5**

**Property 9: QR Token Security**
*For any* generated QR token, it should contain all required fields (reservation_id, user_id, time_slot, expiration) and be cryptographically signed.
**Validates: Requirements 7.1, 7.2**

**Property 10: QR Token Validation**
*For any* QR token validation attempt, tokens with invalid signatures should be rejected with appropriate error messages.
**Validates: Requirements 8.1, 8.2**

**Property 11: Audit Logging Completeness**
*For any* system action (QR scan, reservation creation, admin operation), an audit log entry should be created with all required fields.
**Validates: Requirements 8.7**

**Property 12: Transaction Usage**
*For any* operation that modifies shared state (reservation creation, capacity updates), Firestore transactions should be used to ensure atomicity.
**Validates: Requirements 17.3**

**Property 13: Input Validation**
*For any* user input received by the system, it should be validated and sanitized before processing to prevent injection attacks.
**Validates: Requirements 19.4**

**Property 14: Offline Data Access**
*For any* previously loaded data (reservations, QR codes), it should remain accessible when the device is offline.
**Validates: Requirements 21.1, 21.2**

## Error Handling

### Error Categories and Responses

**Authentication Errors:**
- Invalid credentials → "Email ou mot de passe incorrect"
- Account disabled → "Compte désactivé. Contactez l'administration"
- Session expired → Automatic redirect to login with message

**Authorization Errors:**
- Insufficient permissions → "Accès non autorisé pour votre rôle"
- Resource not found → "Ressource introuvable"
- Rate limit exceeded → "Trop de tentatives. Réessayez dans 5 minutes"

**Validation Errors:**
- Invalid input format → Field-specific error messages
- Business rule violations → Context-specific explanations
- Capacity exceeded → "Créneau complet. Choisissez un autre horaire"

**Payment Errors:**
- D17 service unavailable → "Service de paiement temporairement indisponible"
- Payment declined → "Paiement refusé. Vérifiez vos informations"
- Transaction timeout → "Délai de paiement expiré. Réessayez"

**Network Errors:**
- Connection timeout → "Connexion lente. Vérifiez votre réseau"
- Server unavailable → "Service temporairement indisponible"
- Offline mode → "Mode hors ligne. Certaines fonctions sont limitées"

### Error Recovery Strategies

**Automatic Retry:**
- Network requests with exponential backoff (1s, 2s, 4s, 8s)
- Failed Cloud Function calls (max 3 attempts)
- Payment verification checks (every 30s for 5 minutes)

**Graceful Degradation:**
- Show cached data when real-time updates fail
- Allow QR code viewing offline
- Disable features requiring network connectivity

**User-Initiated Recovery:**
- "Réessayer" buttons for failed operations
- "Actualiser" options for stale data
- Manual sync triggers for offline changes

## Testing Strategy

### Dual Testing Approach

The system will employ both unit testing and property-based testing to ensure comprehensive coverage:

**Unit Tests:**
- Verify specific examples and edge cases
- Test integration points between components
- Validate error conditions and boundary values
- Focus on concrete scenarios and known failure modes

**Property-Based Tests:**
- Verify universal properties across all inputs
- Test system behavior with randomized data
- Ensure correctness properties hold under all conditions
- Provide comprehensive input coverage through randomization

### Property-Based Testing Configuration

**Framework:** We will use the `test` package with custom property testing utilities for Dart/Flutter.

**Test Configuration:**
- Minimum 100 iterations per property test
- Each property test references its design document property
- Tag format: **Feature: production-architecture, Property {number}: {property_text}**

**Example Property Test Structure:**
```dart
testProperty('Feature: production-architecture, Property 1: Role-Based Access Control', () {
  // Generate random users with different roles
  // Generate random restricted endpoints
  // Verify access is properly denied based on role
}, iterations: 100);
```

**Property Test Categories:**

1. **Security Properties:**
   - Role-based access control enforcement
   - Input validation and sanitization
   - QR token cryptographic verification
   - Payment verification backend-only updates

2. **Data Consistency Properties:**
   - UI display matches database values
   - Atomic transaction usage
   - Audit log completeness
   - Real-time synchronization accuracy

3. **Business Logic Properties:**
   - Reservation capacity validation
   - Time slot query accuracy
   - Payment flow correctness
   - Offline data accessibility

**Unit Test Focus Areas:**

1. **Authentication Edge Cases:**
   - Password reset flows
   - Account lockout scenarios
   - Session timeout handling
   - Role assignment edge cases

2. **Payment Integration:**
   - D17 webhook signature verification
   - Payment timeout scenarios
   - Refund processing
   - Transaction reconciliation

3. **QR Code System:**
   - Token expiration handling
   - Signature verification failures
   - Duplicate scan prevention
   - Staff validation workflows

4. **Admin Operations:**
   - Bulk time slot creation
   - User role modifications
   - System configuration updates
   - Analytics calculation accuracy

### Testing Infrastructure

**Firebase Emulator Suite:**
- Local Firestore for isolated testing
- Auth emulator for user management testing
- Cloud Functions emulator for backend logic
- Storage emulator for file upload testing

**Test Data Management:**
- Automated test data generation
- Database cleanup between tests
- Consistent test environments
- Reproducible test scenarios

**Continuous Integration:**
- Automated test execution on code commits
- Property test results tracking
- Performance regression detection
- Security vulnerability scanning

The combination of unit tests and property-based tests ensures both specific functionality correctness and general system reliability across all possible inputs and scenarios.