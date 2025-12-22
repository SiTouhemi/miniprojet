import 'dart:async';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ReservationRecord extends FirestoreRecord {
  ReservationRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "prix" field.
  int? _prix;
  int get prix => _prix ?? 0;
  bool hasPrix() => _prix != null;

  // "total" field.
  int? _total;
  int get total => _total ?? 0;
  bool hasTotal() => _total != null;

  // "creneaux" field.
  DateTime? _creneaux;
  DateTime? get creneaux => _creneaux;
  bool hasCreneaux() => _creneaux != null;

  // "user_id" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "status" field.
  String? _status;
  String get status => _status ?? 'pending';
  bool hasStatus() => _status != null;

  // "qr_code" field.
  String? _qrCode;
  String get qrCode => _qrCode ?? '';
  bool hasQrCode() => _qrCode != null;

  // "payment_id" field.
  String? _paymentId;
  String get paymentId => _paymentId ?? '';
  bool hasPaymentId() => _paymentId != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "used_at" field.
  DateTime? _usedAt;
  DateTime? get usedAt => _usedAt;
  bool hasUsedAt() => _usedAt != null;

  // "capacity" field.
  int? _capacity;
  int get capacity => _capacity ?? 1;
  bool hasCapacity() => _capacity != null;

  void _initializeFields() {
    _type = snapshotData['type'] as String?;
    _prix = castToType<int>(snapshotData['prix']);
    _total = castToType<int>(snapshotData['total']);
    _creneaux = snapshotData['creneaux'] as DateTime?;
    _userId = snapshotData['user_id'] as String?;
    _status = snapshotData['status'] as String?;
    _qrCode = snapshotData['qr_code'] as String?;
    _paymentId = snapshotData['payment_id'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _usedAt = snapshotData['used_at'] as DateTime?;
    _capacity = castToType<int>(snapshotData['capacity']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('reservation');

  static Stream<ReservationRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ReservationRecord.fromSnapshot(s));

  static Future<ReservationRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ReservationRecord.fromSnapshot(s));

  static ReservationRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ReservationRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ReservationRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ReservationRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ReservationRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ReservationRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createReservationRecordData({
  String? type,
  int? prix,
  int? total,
  DateTime? creneaux,
  String? userId,
  String? status,
  String? qrCode,
  String? paymentId,
  DateTime? createdAt,
  DateTime? usedAt,
  int? capacity,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'type': type,
      'prix': prix,
      'total': total,
      'creneaux': creneaux,
      'user_id': userId,
      'status': status,
      'qr_code': qrCode,
      'payment_id': paymentId,
      'created_at': createdAt,
      'used_at': usedAt,
      'capacity': capacity,
    }.withoutNulls,
  );

  return firestoreData;
}

class ReservationRecordDocumentEquality implements Equality<ReservationRecord> {
  const ReservationRecordDocumentEquality();

  @override
  bool equals(ReservationRecord? e1, ReservationRecord? e2) {
    return e1?.type == e2?.type &&
        e1?.prix == e2?.prix &&
        e1?.total == e2?.total &&
        e1?.creneaux == e2?.creneaux;
  }

  @override
  int hash(ReservationRecord? e) =>
      const ListEquality().hash([e?.type, e?.prix, e?.total, e?.creneaux]);

  @override
  bool isValidKey(Object? o) => o is ReservationRecord;
}
