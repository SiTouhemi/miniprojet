import 'dart:async';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AppSettingsRecord extends FirestoreRecord {
  AppSettingsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "app_name" field.
  String? _appName;
  String get appName => _appName ?? 'ISET Com Restaurant';
  bool hasAppName() => _appName != null;

  // "welcome_message" field.
  String? _welcomeMessage;
  String get welcomeMessage => _welcomeMessage ?? 'Welcome to our restaurant reservation system';
  bool hasWelcomeMessage() => _welcomeMessage != null;

  // "contact_email" field.
  String? _contactEmail;
  String get contactEmail => _contactEmail ?? 'contact@isetcom.tn';
  bool hasContactEmail() => _contactEmail != null;

  // "contact_phone" field.
  String? _contactPhone;
  String get contactPhone => _contactPhone ?? '+216 XX XXX XXX';
  bool hasContactPhone() => _contactPhone != null;

  // "restaurant_address" field.
  String? _restaurantAddress;
  String get restaurantAddress => _restaurantAddress ?? 'ISET Com Campus';
  bool hasRestaurantAddress() => _restaurantAddress != null;

  // "default_meal_price" field.
  double? _defaultMealPrice;
  double get defaultMealPrice => _defaultMealPrice ?? 0.2;
  bool hasDefaultMealPrice() => _defaultMealPrice != null;

  // "currency" field.
  String? _currency;
  String get currency => _currency ?? 'TND';
  bool hasCurrency() => _currency != null;

  // "subsidy_rate" field.
  double? _subsidyRate;
  double get subsidyRate => _subsidyRate ?? 0.95;
  bool hasSubsidyRate() => _subsidyRate != null;

  // "lunch_start_time" field.
  String? _lunchStartTime;
  String get lunchStartTime => _lunchStartTime ?? '12:00';
  bool hasLunchStartTime() => _lunchStartTime != null;

  // "lunch_end_time" field.
  String? _lunchEndTime;
  String get lunchEndTime => _lunchEndTime ?? '14:00';
  bool hasLunchEndTime() => _lunchEndTime != null;

  // "dinner_start_time" field.
  String? _dinnerStartTime;
  String get dinnerStartTime => _dinnerStartTime ?? '19:00';
  bool hasDinnerStartTime() => _dinnerStartTime != null;

  // "dinner_end_time" field.
  String? _dinnerEndTime;
  String get dinnerEndTime => _dinnerEndTime ?? '21:00';
  bool hasDinnerEndTime() => _dinnerEndTime != null;

  // "max_reservations_per_user" field.
  int? _maxReservationsPerUser;
  int get maxReservationsPerUser => _maxReservationsPerUser ?? 3;
  bool hasMaxReservationsPerUser() => _maxReservationsPerUser != null;

  // "reservation_deadline_hours" field.
  int? _reservationDeadlineHours;
  int get reservationDeadlineHours => _reservationDeadlineHours ?? 2;
  bool hasReservationDeadlineHours() => _reservationDeadlineHours != null;

  // "d17_api_key" field.
  String? _d17ApiKey;
  String get d17ApiKey => _d17ApiKey ?? '';
  bool hasD17ApiKey() => _d17ApiKey != null;

  // "notification_enabled" field.
  bool? _notificationEnabled;
  bool get notificationEnabled => _notificationEnabled ?? true;
  bool hasNotificationEnabled() => _notificationEnabled != null;

  void _initializeFields() {
    _appName = snapshotData['app_name'] as String?;
    _welcomeMessage = snapshotData['welcome_message'] as String?;
    _contactEmail = snapshotData['contact_email'] as String?;
    _contactPhone = snapshotData['contact_phone'] as String?;
    _restaurantAddress = snapshotData['restaurant_address'] as String?;
    _defaultMealPrice = castToType<double>(snapshotData['default_meal_price']);
    _currency = snapshotData['currency'] as String?;
    _subsidyRate = castToType<double>(snapshotData['subsidy_rate']);
    _lunchStartTime = snapshotData['lunch_start_time'] as String?;
    _lunchEndTime = snapshotData['lunch_end_time'] as String?;
    _dinnerStartTime = snapshotData['dinner_start_time'] as String?;
    _dinnerEndTime = snapshotData['dinner_end_time'] as String?;
    _maxReservationsPerUser = castToType<int>(snapshotData['max_reservations_per_user']);
    _reservationDeadlineHours = castToType<int>(snapshotData['reservation_deadline_hours']);
    _d17ApiKey = snapshotData['d17_api_key'] as String?;
    _notificationEnabled = snapshotData['notification_enabled'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('app_settings');

  static Stream<AppSettingsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AppSettingsRecord.fromSnapshot(s));

  static Future<AppSettingsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AppSettingsRecord.fromSnapshot(s));

  static AppSettingsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AppSettingsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AppSettingsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AppSettingsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AppSettingsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AppSettingsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAppSettingsRecordData({
  String? appName,
  String? welcomeMessage,
  String? contactEmail,
  String? contactPhone,
  String? restaurantAddress,
  double? defaultMealPrice,
  int? maxReservationsPerUser,
  int? reservationDeadlineHours,
  String? d17ApiKey,
  bool? notificationEnabled,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'app_name': appName,
      'welcome_message': welcomeMessage,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'restaurant_address': restaurantAddress,
      'default_meal_price': defaultMealPrice,
      'max_reservations_per_user': maxReservationsPerUser,
      'reservation_deadline_hours': reservationDeadlineHours,
      'd17_api_key': d17ApiKey,
      'notification_enabled': notificationEnabled,
    }.withoutNulls,
  );

  return firestoreData;
}