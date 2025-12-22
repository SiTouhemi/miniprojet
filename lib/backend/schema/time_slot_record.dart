import 'dart:async';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TimeSlotRecord extends FirestoreRecord {
  TimeSlotRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "start_time" field.
  DateTime? _startTime;
  DateTime? get startTime => _startTime;
  bool hasStartTime() => _startTime != null;

  // "end_time" field.
  DateTime? _endTime;
  DateTime? get endTime => _endTime;
  bool hasEndTime() => _endTime != null;

  // "max_capacity" field.
  int? _maxCapacity;
  int get maxCapacity => _maxCapacity ?? 50;
  bool hasMaxCapacity() => _maxCapacity != null;

  // "current_reservations" field.
  int? _currentReservations;
  int get currentReservations => _currentReservations ?? 0;
  bool hasCurrentReservations() => _currentReservations != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  bool hasPrice() => _price != null;

  // "is_active" field.
  bool? _isActive;
  bool get isActive => _isActive ?? true;
  bool hasIsActive() => _isActive != null;

  // "meal_type" field.
  String? _mealType;
  String get mealType => _mealType ?? 'dinner';
  bool hasMealType() => _mealType != null;

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  void _initializeFields() {
    _startTime = snapshotData['start_time'] as DateTime?;
    _endTime = snapshotData['end_time'] as DateTime?;
    _maxCapacity = castToType<int>(snapshotData['max_capacity']);
    _currentReservations = castToType<int>(snapshotData['current_reservations']);
    _price = castToType<double>(snapshotData['price']);
    _isActive = snapshotData['is_active'] as bool?;
    _mealType = snapshotData['meal_type'] as String?;
    _date = snapshotData['date'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('time_slots');

  static Stream<TimeSlotRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TimeSlotRecord.fromSnapshot(s));

  static Future<TimeSlotRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TimeSlotRecord.fromSnapshot(s));

  static TimeSlotRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TimeSlotRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TimeSlotRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TimeSlotRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TimeSlotRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TimeSlotRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTimeSlotRecordData({
  DateTime? startTime,
  DateTime? endTime,
  int? maxCapacity,
  int? currentReservations,
  double? price,
  bool? isActive,
  String? mealType,
  DateTime? date,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'start_time': startTime,
      'end_time': endTime,
      'max_capacity': maxCapacity,
      'current_reservations': currentReservations,
      'price': price,
      'is_active': isActive,
      'meal_type': mealType,
      'date': date,
    }.withoutNulls,
  );

  return firestoreData;
}

class TimeSlotRecordDocumentEquality implements Equality<TimeSlotRecord> {
  const TimeSlotRecordDocumentEquality();

  @override
  bool equals(TimeSlotRecord? e1, TimeSlotRecord? e2) {
    return e1?.startTime == e2?.startTime &&
        e1?.endTime == e2?.endTime &&
        e1?.maxCapacity == e2?.maxCapacity &&
        e1?.currentReservations == e2?.currentReservations &&
        e1?.price == e2?.price &&
        e1?.isActive == e2?.isActive &&
        e1?.mealType == e2?.mealType &&
        e1?.date == e2?.date;
  }

  @override
  int hash(TimeSlotRecord? e) => const ListEquality().hash([
        e?.startTime,
        e?.endTime,
        e?.maxCapacity,
        e?.currentReservations,
        e?.price,
        e?.isActive,
        e?.mealType,
        e?.date
      ]);

  @override
  bool isValidKey(Object? o) => o is TimeSlotRecord;
}