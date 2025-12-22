# Requirements Document: ISET Com Restaurant Reservation System - Production Architecture

## Introduction

This document specifies the requirements for transforming the ISET Com Restaurant Reservation System from a FlutterFlow UI prototype into a secure, scalable, production-ready application. The system enables students to reserve meals, staff to validate tickets via QR scanning, and administrators to manage the entire restaurant operation including menus, time slots, users, and analytics.

## Glossary

- **System**: The ISET Com Restaurant Reservation System (mobile and web application)
- **Backend**: Firebase Cloud Functions and Firestore database infrastructure
- **D17**: The national Tunisian payment verification system
- **Student**: A user with role 'student' who can make reservations
- **Staff**: A user with role 'staff' who can scan and validate tickets
- **Admin**: A user with role 'admin' who has full system management capabilities
- **Time_Slot**: A specific date/time period with capacity limits for meal service
- **Reservation**: A booking made by a student for a specific time slot
- **QR_Token**: A unique, time-bound, cryptographically signed token for ticket validation
- **Payment_Transaction**: A record of payment verification with D17
- **Audit_Log**: A record of all system actions for compliance and debugging

## Requirements

### Requirement 1: Role-Based Access Control (RBAC)

**User Story:** As a system architect, I want strict role-based access control, so that users can only access features and data appropriate to their role.

#### Acceptance Criteria

1. WHEN a user authenticates, THE System SHALL assign exactly one role (student, staff, or admin)
2. WHEN a student attempts to access staff or admin features, THE System SHALL deny access and return an authorization error
3. WHEN a staff member attempts to access admin features, THE System SHALL deny access and return an authorization error
4. WHEN a user's role is changed, THE System SHALL immediately enforce the new permissions on their next request
5. THE System SHALL validate user roles on every backend API call using Firebase security rules
6. THE System SHALL store role information in both Firebase Auth custom claims and Firestore user documents
7. WHEN displaying UI elements, THE System SHALL hide or disable features not available to the current user's role

### Requirement 2: Dynamic User Data Display

**User Story:** As a student, I want to see my actual account information, so that I can track my balance, tickets, and reservations.

#### Acceptance Criteria

1. WHEN a student views the home screen, THE System SHALL display their actual name from the user document
2. WHEN a student views their balance, THE System SHALL display their current pocket balance from Firestore
3. WHEN a student views their tickets, THE System SHALL display their actual ticket count from Firestore
4. WHEN a student views reservations, THE System SHALL query and display only their own reservations
5. THE System SHALL never display hardcoded or mock user data
6. WHEN user data changes in Firestore, THE System SHALL reflect updates in the UI within 2 seconds
7. IF user data fails to load, THEN THE System SHALL display an error message and retry mechanism

### Requirement 3: Secure Authentication System

**User Story:** As a security administrator, I want secure authentication, so that only authorized users can access the system.

#### Acceptance Criteria

1. THE System SHALL use Firebase Authentication for all user authentication
2. WHEN a user logs in, THE System SHALL verify credentials with Firebase Auth
3. WHEN authentication succeeds, THE System SHALL create or update the user document in Firestore
4. WHEN authentication succeeds, THE System SHALL set custom claims for the user's role
5. THE System SHALL store authentication tokens securely using platform-specific secure storage
6. WHEN a session expires, THE System SHALL require re-authentication
7. THE System SHALL implement password reset functionality via Firebase Auth
8. THE System SHALL enforce minimum password strength requirements (8+ characters, mixed case, numbers)

### Requirement 4: Dynamic Time Slot Management

**User Story:** As a student, I want to see available time slots with real-time capacity, so that I can reserve a meal when space is available.

#### Acceptance Criteria

1. WHEN a student browses time slots, THE System SHALL query Firestore for slots matching the selected date
2. WHEN displaying time slots, THE System SHALL show current_reservations and max_capacity for each slot
3. WHEN a time slot reaches max_capacity, THE System SHALL mark it as unavailable
4. WHEN a time slot is marked is_active=false, THE System SHALL hide it from student views
5. THE System SHALL update time slot availability in real-time using Firestore listeners
6. WHEN an admin modifies a time slot, THE System SHALL immediately reflect changes to all connected clients
7. THE System SHALL prevent reservations for time slots in the past

### Requirement 5: Reservation Creation and Management

**User Story:** As a student, I want to create and manage reservations, so that I can secure my meal for a specific time.

#### Acceptance Criteria

1. WHEN a student creates a reservation, THE System SHALL validate the time slot has available capacity
2. WHEN a student creates a reservation, THE System SHALL check they haven't exceeded max_reservations_per_user limit
3. WHEN a reservation is created, THE System SHALL atomically increment the time_slot current_reservations counter
4. WHEN a reservation is created, THE System SHALL set status to 'pending' until payment is verified
5. WHEN a student cancels a reservation, THE System SHALL atomically decrement the time_slot current_reservations counter
6. THE System SHALL prevent students from creating duplicate reservations for the same time slot
7. WHEN a reservation time has passed, THE System SHALL prevent cancellation or modification

### Requirement 6: D17 Payment Integration

**User Story:** As a student, I want to pay for reservations via D17, so that my reservation is confirmed securely.

#### Acceptance Criteria

1. WHEN a student initiates payment, THE System SHALL create a payment transaction record with status 'pending'
2. WHEN payment is initiated, THE System SHALL send a verification request to D17 with reservation details
3. WHEN D17 confirms payment, THE System SHALL update the reservation status to 'confirmed'
4. WHEN D17 rejects payment, THE System SHALL update the reservation status to 'failed' and release the time slot
5. THE System SHALL never trust payment status from the client - all verification must occur on the backend
6. WHEN payment verification times out, THE System SHALL mark the reservation as 'expired' after 15 minutes
7. THE System SHALL store D17 transaction IDs for audit and reconciliation purposes
8. WHEN payment fails, THE System SHALL provide clear error messages to the student

### Requirement 7: QR Code Generation and Security

**User Story:** As a student, I want a secure QR code for my confirmed reservation, so that I can enter the restaurant.

#### Acceptance Criteria

1. WHEN a reservation is confirmed, THE System SHALL generate a unique QR token using cryptographic signing
2. THE QR_Token SHALL include reservation_id, user_id, time_slot, and expiration timestamp
3. THE QR_Token SHALL be signed with a server-side secret key to prevent forgery
4. WHEN generating a QR code, THE System SHALL set expiration to 1 hour after the time slot end time
5. THE System SHALL encode the QR_Token as a QR code image for display
6. WHEN a QR code is displayed, THE System SHALL show it prominently with reservation details
7. THE System SHALL prevent QR code generation for reservations with status other than 'confirmed'

### Requirement 8: Staff QR Scanning and Validation

**User Story:** As a staff member, I want to scan and validate QR codes, so that I can verify student tickets and grant restaurant access.

#### Acceptance Criteria

1. WHEN staff scans a QR code, THE System SHALL decode and verify the cryptographic signature
2. WHEN a QR token signature is invalid, THE System SHALL display "Invalid Ticket" and deny entry
3. WHEN a QR token is expired, THE System SHALL display "Expired Ticket" and deny entry
4. WHEN a QR token is valid, THE System SHALL query the reservation and check status is 'confirmed'
5. WHEN a reservation has already been used (used_at is not null), THE System SHALL display "Already Used" and deny entry
6. WHEN a valid unused ticket is scanned, THE System SHALL display student name, time slot, and "Valid" status
7. WHEN staff marks a ticket as used, THE System SHALL set used_at timestamp and prevent reuse
8. THE System SHALL log all scan attempts with timestamp, staff_id, and result for audit purposes

### Requirement 9: Dynamic Menu Display

**User Story:** As a student, I want to see today's menu, so that I know what meals are available.

#### Acceptance Criteria

1. WHEN a student views the home screen, THE System SHALL query Firestore for today's menu items
2. WHEN displaying menu items, THE System SHALL show nom, description, ingredients, prix, and image
3. WHEN no menu is available for today, THE System SHALL display a message "Menu not yet published"
4. THE System SHALL cache menu data locally for 1 hour to reduce database queries
5. WHEN an admin updates the menu, THE System SHALL invalidate the cache and refresh the display
6. THE System SHALL display menu items grouped by categorie (entrée, plat principal, dessert)
7. THE System SHALL handle missing images gracefully with placeholder images

### Requirement 10: Admin Dashboard Statistics

**User Story:** As an admin, I want to view real-time statistics, so that I can monitor system usage and make informed decisions.

#### Acceptance Criteria

1. WHEN an admin views the dashboard, THE System SHALL calculate and display today's total reservations
2. WHEN an admin views the dashboard, THE System SHALL calculate and display current occupancy rate
3. WHEN an admin views the dashboard, THE System SHALL calculate and display remaining seats across all time slots
4. THE System SHALL update dashboard statistics in real-time using Firestore aggregation queries
5. WHEN displaying statistics, THE System SHALL show data only for the current date by default
6. THE System SHALL provide date range filters for historical statistics
7. THE System SHALL calculate peak usage times and display them graphically

### Requirement 11: Admin Time Slot Management

**User Story:** As an admin, I want to create and manage time slots, so that I can control restaurant capacity and operating hours.

#### Acceptance Criteria

1. WHEN an admin creates a time slot, THE System SHALL validate start_time is before end_time
2. WHEN an admin creates a time slot, THE System SHALL validate max_capacity is a positive integer
3. WHEN an admin creates a time slot, THE System SHALL set current_reservations to 0
4. WHEN an admin updates a time slot capacity, THE System SHALL validate it's not less than current_reservations
5. WHEN an admin deactivates a time slot, THE System SHALL set is_active to false and hide it from students
6. WHEN an admin deletes a time slot with existing reservations, THE System SHALL prevent deletion and show error
7. THE System SHALL allow admins to bulk create time slots for multiple dates

### Requirement 12: Admin Menu Management

**User Story:** As an admin, I want to create and manage daily menus, so that students know what meals are available.

#### Acceptance Criteria

1. WHEN an admin creates a menu item, THE System SHALL validate all required fields (nom, description, prix, categorie)
2. WHEN an admin uploads a menu image, THE System SHALL store it in Firebase Storage and save the URL
3. WHEN an admin updates a menu item, THE System SHALL update the Firestore document immediately
4. WHEN an admin deletes a menu item, THE System SHALL remove it from Firestore and delete the associated image
5. THE System SHALL allow admins to associate menu items with specific dates
6. THE System SHALL allow admins to copy previous menus to new dates
7. THE System SHALL validate prix is a positive number

### Requirement 13: Admin User Management

**User Story:** As an admin, I want to manage user accounts, so that I can create staff accounts, modify roles, and handle account issues.

#### Acceptance Criteria

1. WHEN an admin creates a user, THE System SHALL create both a Firebase Auth account and Firestore document
2. WHEN an admin creates a user, THE System SHALL set custom claims for the specified role
3. WHEN an admin changes a user's role, THE System SHALL update both custom claims and Firestore document
4. WHEN an admin deactivates a user, THE System SHALL disable their Firebase Auth account
5. THE System SHALL prevent admins from deleting their own account
6. THE System SHALL allow admins to reset user passwords
7. WHEN displaying users, THE System SHALL show email, nom, role, created_time, and last_login

### Requirement 14: Audit Logging

**User Story:** As a system administrator, I want comprehensive audit logs, so that I can track all system actions for security and compliance.

#### Acceptance Criteria

1. WHEN any user performs an action, THE System SHALL create an audit log entry
2. THE Audit_Log SHALL include timestamp, user_id, user_role, action_type, resource_id, and result
3. WHEN a reservation is created, modified, or cancelled, THE System SHALL log the action
4. WHEN a QR code is scanned, THE System SHALL log the scan attempt and result
5. WHEN an admin modifies system data, THE System SHALL log the changes with before/after values
6. THE System SHALL store audit logs in a separate Firestore collection with appropriate indexes
7. WHEN an admin views audit logs, THE System SHALL provide filtering by date, user, and action type

### Requirement 15: Real-Time Notifications

**User Story:** As a student, I want to receive notifications about my reservations, so that I don't miss my meal time.

#### Acceptance Criteria

1. WHEN a reservation is confirmed, THE System SHALL send a push notification to the student
2. WHEN a reservation time is 1 hour away, THE System SHALL send a reminder notification
3. WHEN a reservation is cancelled by admin, THE System SHALL send a notification to the student
4. WHEN a payment fails, THE System SHALL send a notification with error details
5. THE System SHALL respect user notification preferences (notifications_enabled field)
6. THE System SHALL use Firebase Cloud Messaging for push notifications
7. THE System SHALL store notification history in Firestore for user reference

### Requirement 16: Error Handling and Resilience

**User Story:** As a developer, I want comprehensive error handling, so that the system degrades gracefully and provides helpful error messages.

#### Acceptance Criteria

1. WHEN a network error occurs, THE System SHALL display a user-friendly error message and retry option
2. WHEN a Firestore query fails, THE System SHALL log the error and display a generic error message
3. WHEN a Cloud Function times out, THE System SHALL return an appropriate HTTP status code and error message
4. THE System SHALL implement exponential backoff for retrying failed operations
5. WHEN critical errors occur, THE System SHALL log them to Firebase Crashlytics
6. THE System SHALL validate all user inputs before sending to the backend
7. WHEN validation fails, THE System SHALL display specific field-level error messages

### Requirement 17: Data Validation and Integrity

**User Story:** As a system architect, I want strict data validation, so that the database maintains integrity and consistency.

#### Acceptance Criteria

1. THE System SHALL enforce Firestore security rules that validate all field types and required fields
2. WHEN creating a reservation, THE System SHALL use Firestore transactions to ensure atomic updates
3. WHEN updating time slot capacity, THE System SHALL use Firestore transactions to prevent race conditions
4. THE System SHALL validate email addresses match a valid format before creating users
5. THE System SHALL validate CIN (national ID) is exactly 8 digits for Tunisian users
6. THE System SHALL prevent negative values for pocket balance, tickets, and prices
7. THE System SHALL enforce referential integrity between reservations and time_slots

### Requirement 18: Performance and Scalability

**User Story:** As a system architect, I want the system to handle peak loads efficiently, so that students can reserve meals during busy periods.

#### Acceptance Criteria

1. WHEN 100 concurrent users browse time slots, THE System SHALL respond within 2 seconds
2. WHEN 50 concurrent users create reservations, THE System SHALL process them without conflicts
3. THE System SHALL use Firestore composite indexes for efficient querying
4. THE System SHALL implement pagination for lists with more than 50 items
5. THE System SHALL cache frequently accessed data (app settings, today's menu) in app state
6. THE System SHALL use Cloud Functions with appropriate memory and timeout configurations
7. WHEN database queries exceed 1 second, THE System SHALL log performance warnings

### Requirement 19: Security and Data Protection

**User Story:** As a security administrator, I want robust security measures, so that user data and system integrity are protected.

#### Acceptance Criteria

1. THE System SHALL enforce HTTPS for all network communications
2. THE System SHALL never store passwords in Firestore (Firebase Auth handles authentication)
3. THE System SHALL implement Firestore security rules that prevent unauthorized data access
4. THE System SHALL validate and sanitize all user inputs to prevent injection attacks
5. THE System SHALL use environment variables for sensitive configuration (API keys, secrets)
6. THE System SHALL implement rate limiting on Cloud Functions to prevent abuse
7. THE System SHALL encrypt QR tokens using industry-standard cryptographic algorithms

### Requirement 20: Multi-Language Support

**User Story:** As a student, I want to use the app in my preferred language, so that I can understand all content clearly.

#### Acceptance Criteria

1. THE System SHALL support French and Arabic languages
2. WHEN a user changes language preference, THE System SHALL update the UI immediately
3. WHEN a user changes language, THE System SHALL store the preference in their user document
4. THE System SHALL load the user's language preference on app startup
5. THE System SHALL translate all UI text, error messages, and notifications
6. THE System SHALL handle right-to-left (RTL) layout for Arabic
7. WHEN displaying dates and times, THE System SHALL format them according to the selected locale

### Requirement 21: Offline Capability

**User Story:** As a student, I want to view my reservations offline, so that I can access my QR code without internet connection.

#### Acceptance Criteria

1. WHEN the app loses network connectivity, THE System SHALL display cached reservation data
2. WHEN offline, THE System SHALL allow viewing of previously loaded QR codes
3. WHEN offline, THE System SHALL prevent actions that require backend communication
4. WHEN connectivity is restored, THE System SHALL sync any pending changes
5. THE System SHALL use Firestore offline persistence for automatic caching
6. WHEN offline, THE System SHALL display a clear indicator of offline status
7. THE System SHALL queue notifications for delivery when connectivity is restored

### Requirement 22: Analytics and Monitoring

**User Story:** As an admin, I want to analyze usage patterns, so that I can optimize restaurant operations.

#### Acceptance Criteria

1. THE System SHALL track daily reservation counts and store them in analytics collection
2. THE System SHALL calculate peak usage times by analyzing reservation timestamps
3. THE System SHALL track no-show rates by comparing reservations to actual usage
4. THE System SHALL calculate average occupancy rates per time slot
5. THE System SHALL provide weekly and monthly trend reports
6. THE System SHALL track payment success and failure rates
7. WHEN generating analytics, THE System SHALL aggregate data efficiently using Cloud Functions

### Requirement 23: Configuration Management

**User Story:** As an admin, I want to configure system settings, so that I can adjust operational parameters without code changes.

#### Acceptance Criteria

1. THE System SHALL store configuration in an app_settings Firestore document
2. THE System SHALL allow admins to modify max_reservations_per_user setting
3. THE System SHALL allow admins to modify default_meal_price setting
4. THE System SHALL allow admins to modify contact information (email, phone)
5. THE System SHALL allow admins to modify welcome messages and announcements
6. WHEN settings are updated, THE System SHALL propagate changes to all clients within 5 seconds
7. THE System SHALL validate setting values before saving (e.g., positive numbers, valid emails)

### Requirement 24: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive testing, so that the system is reliable and bug-free.

#### Acceptance Criteria

1. THE System SHALL have unit tests for all Cloud Functions with >80% code coverage
2. THE System SHALL have integration tests for critical user flows (reservation, payment, QR validation)
3. THE System SHALL have Firestore security rules tests to verify access control
4. THE System SHALL use Firebase Emulator Suite for local testing
5. THE System SHALL have automated tests that run on every code commit
6. THE System SHALL have load tests that simulate 200 concurrent users
7. THE System SHALL have end-to-end tests for each user role (student, staff, admin)
