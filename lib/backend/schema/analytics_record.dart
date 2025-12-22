import 'dart:async';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AnalyticsRecord extends FirestoreRecord {
  AnalyticsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "total_reservations" field.
  int? _totalReservations;
  int get totalReservations => _totalReservations ?? 0;
  bool hasTotalReservations() => _totalReservations != null;

  // "total_revenue" field.
  double? _totalRevenue;
  double get totalRevenue => _totalRevenue ?? 0.0;
  bool hasTotalRevenue() => _totalRevenue != null;

  // "peak_hour" field.
  String? _peakHour;
  String get peakHour => _peakHour ?? '';
  bool hasPeakHour() => _peakHour != null;

  // "most_popular_meal" field.
  String? _mostPopularMeal;
  String get mostPopularMeal => _mostPopularMeal ?? '';
  bool hasMostPopularMeal() => _mostPopularMeal != null;

  // "cancellation_rate" field.
  double? _cancellationRate;
  double get cancellationRate => _cancellationRate ?? 0.0;
  bool hasCancellationRate() => _cancellationRate != null;

  // "average_occupancy" field.
  double? _averageOccupancy;
  double get averageOccupancy => _averageOccupancy ?? 0.0;
  bool hasAverageOccupancy() => _averageOccupancy != null;

  void _initializeFields() {
    _date = snapshotData['date'] as DateTime?;
    _totalReservations = castToType<int>(snapshotData['total_reservations']);
    _totalRevenue = castToType<double>(snapshotData['total_revenue']);
    _peakHour = snapshotData['peak_hour'] as String?;
    _mostPopularMeal = snapshotData['most_popular_meal'] as String?;
    _cancellationRate = castToType<double>(snapshotData['cancellation_rate']);
    _averageOccupancy = castToType<double>(snapshotData['average_occupancy']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('analytics');

  static Stream<AnalyticsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AnalyticsRecord.fromSnapshot(s));

  static Future<AnalyticsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AnalyticsRecord.fromSnapshot(s));

  static AnalyticsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AnalyticsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AnalyticsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AnalyticsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AnalyticsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AnalyticsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}