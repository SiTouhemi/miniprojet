import 'dart:async';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DailyMenuRecord extends FirestoreRecord {
  DailyMenuRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "meal_type" field.
  String? _mealType;
  String get mealType => _mealType ?? 'lunch';
  bool hasMealType() => _mealType != null;

  // "main_dish" field.
  String? _mainDish;
  String get mainDish => _mainDish ?? '';
  bool hasMainDish() => _mainDish != null;

  // "accompaniments" field.
  List<String>? _accompaniments;
  List<String> get accompaniments => _accompaniments ?? const [];
  bool hasAccompaniments() => _accompaniments != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.2;
  bool hasPrice() => _price != null;

  // "available" field.
  bool? _available;
  bool get available => _available ?? true;
  bool hasAvailable() => _available != null;

  // "image_url" field.
  String? _imageUrl;
  String get imageUrl => _imageUrl ?? '';
  bool hasImageUrl() => _imageUrl != null;

  // "created_by" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  void _initializeFields() {
    _date = snapshotData['date'] as DateTime?;
    _mealType = snapshotData['meal_type'] as String?;
    _mainDish = snapshotData['main_dish'] as String?;
    _accompaniments = getDataList(snapshotData['accompaniments']);
    _description = snapshotData['description'] as String?;
    _price = castToType<double>(snapshotData['price']);
    _available = snapshotData['available'] as bool?;
    _imageUrl = snapshotData['image_url'] as String?;
    _createdBy = snapshotData['created_by'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('daily_menu');

  static Stream<DailyMenuRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DailyMenuRecord.fromSnapshot(s));

  static Future<DailyMenuRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DailyMenuRecord.fromSnapshot(s));

  static DailyMenuRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DailyMenuRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DailyMenuRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DailyMenuRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DailyMenuRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DailyMenuRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDailyMenuRecordData({
  DateTime? date,
  String? mealType,
  String? mainDish,
  String? description,
  double? price,
  bool? available,
  String? imageUrl,
  String? createdBy,
  DateTime? createdAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'date': date,
      'meal_type': mealType,
      'main_dish': mainDish,
      'description': description,
      'price': price,
      'available': available,
      'image_url': imageUrl,
      'created_by': createdBy,
      'created_at': createdAt,
    }.withoutNulls,
  );

  return firestoreData;
}

class DailyMenuRecordDocumentEquality implements Equality<DailyMenuRecord> {
  const DailyMenuRecordDocumentEquality();

  @override
  bool equals(DailyMenuRecord? e1, DailyMenuRecord? e2) {
    const listEquality = ListEquality();
    return e1?.date == e2?.date &&
        e1?.mealType == e2?.mealType &&
        e1?.mainDish == e2?.mainDish &&
        listEquality.equals(e1?.accompaniments, e2?.accompaniments) &&
        e1?.description == e2?.description &&
        e1?.price == e2?.price &&
        e1?.available == e2?.available &&
        e1?.imageUrl == e2?.imageUrl &&
        e1?.createdBy == e2?.createdBy &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(DailyMenuRecord? e) => const ListEquality().hash([
        e?.date,
        e?.mealType,
        e?.mainDish,
        e?.accompaniments,
        e?.description,
        e?.price,
        e?.available,
        e?.imageUrl,
        e?.createdBy,
        e?.createdAt
      ]);

  @override
  bool isValidKey(Object? o) => o is DailyMenuRecord;
}