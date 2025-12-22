import 'dart:async';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PlatRecord extends FirestoreRecord {
  PlatRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "nom" field.
  String? _nom;
  String get nom => _nom ?? '';
  bool hasNom() => _nom != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "ingredients" field.
  String? _ingredients;
  String get ingredients => _ingredients ?? '';
  bool hasIngredients() => _ingredients != null;

  // "prix" field.
  double? _prix;
  double get prix => _prix ?? 0.0;
  bool hasPrix() => _prix != null;

  // "categorie" field.
  String? _categorie;
  String get categorie => _categorie ?? '';
  bool hasCategorie() => _categorie != null;

  // "image" field.
  String? _image;
  String get image => _image ?? '';
  bool hasImage() => _image != null;

  void _initializeFields() {
    _nom = snapshotData['nom'] as String?;
    _description = snapshotData['description'] as String?;
    _ingredients = snapshotData['ingredients'] as String?;
    _prix = castToType<double>(snapshotData['prix']);
    _categorie = snapshotData['categorie'] as String?;
    _image = snapshotData['image'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('plat');

  static Stream<PlatRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PlatRecord.fromSnapshot(s));

  static Future<PlatRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PlatRecord.fromSnapshot(s));

  static PlatRecord fromSnapshot(DocumentSnapshot snapshot) => PlatRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PlatRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PlatRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PlatRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PlatRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPlatRecordData({
  String? nom,
  String? description,
  String? ingredients,
  double? prix,
  String? categorie,
  String? image,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'nom': nom,
      'description': description,
      'ingredients': ingredients,
      'prix': prix,
      'categorie': categorie,
      'image': image,
    }.withoutNulls,
  );

  return firestoreData;
}

class PlatRecordDocumentEquality implements Equality<PlatRecord> {
  const PlatRecordDocumentEquality();

  @override
  bool equals(PlatRecord? e1, PlatRecord? e2) {
    return e1?.nom == e2?.nom &&
        e1?.description == e2?.description &&
        e1?.ingredients == e2?.ingredients &&
        e1?.prix == e2?.prix &&
        e1?.categorie == e2?.categorie &&
        e1?.image == e2?.image;
  }

  @override
  int hash(PlatRecord? e) => const ListEquality().hash([
        e?.nom,
        e?.description,
        e?.ingredients,
        e?.prix,
        e?.categorie,
        e?.image
      ]);

  @override
  bool isValidKey(Object? o) => o is PlatRecord;
}
