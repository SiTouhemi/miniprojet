import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserRecord extends FirestoreRecord {
  UserRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "nom" field.
  String? _nom;
  String get nom => _nom ?? '';
  bool hasNom() => _nom != null;

  // "cin" field.
  int? _cin;
  int get cin => _cin ?? 0;
  bool hasCin() => _cin != null;

  // "motdepasse" field.
  String? _motdepasse;
  String get motdepasse => _motdepasse ?? '';
  bool hasMotdepasse() => _motdepasse != null;

  // "classe" field.
  String? _classe;
  String get classe => _classe ?? '';
  bool hasClasse() => _classe != null;

  // "pocket" field.
  double? _pocket;
  double get pocket => _pocket ?? 0.0;
  bool hasPocket() => _pocket != null;

  // "tickets" field.
  int? _tickets;
  int get tickets => _tickets ?? 0;
  bool hasTickets() => _tickets != null;

  // "role" field.
  String? _role;
  String get role => _role ?? 'student';
  bool hasRole() => _role != null;

  // "language" field.
  String? _language;
  String get language => _language ?? 'en';
  bool hasLanguage() => _language != null;

  // "notifications_enabled" field.
  bool? _notificationsEnabled;
  bool get notificationsEnabled => _notificationsEnabled ?? true;
  bool hasNotificationsEnabled() => _notificationsEnabled != null;

  // "last_login" field.
  DateTime? _lastLogin;
  DateTime? get lastLogin => _lastLogin;
  bool hasLastLogin() => _lastLogin != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _nom = snapshotData['nom'] as String?;
    _cin = castToType<int>(snapshotData['cin']);
    _motdepasse = snapshotData['motdepasse'] as String?;
    _classe = snapshotData['classe'] as String?;
    _pocket = castToType<double>(snapshotData['pocket']);
    _tickets = castToType<int>(snapshotData['tickets']);
    _role = snapshotData['role'] as String?;
    _language = snapshotData['language'] as String?;
    _notificationsEnabled = snapshotData['notifications_enabled'] as bool?;
    _lastLogin = snapshotData['last_login'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user');

  static Stream<UserRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserRecord.fromSnapshot(s));

  static Future<UserRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserRecord.fromSnapshot(s));

  static UserRecord fromSnapshot(DocumentSnapshot snapshot) => UserRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUserRecordData({
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
  String? nom,
  int? cin,
  String? motdepasse,
  String? classe,
  double? pocket,
  int? tickets,
  String? role,
  String? language,
  bool? notificationsEnabled,
  DateTime? lastLogin,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'nom': nom,
      'cin': cin,
      'motdepasse': motdepasse,
      'classe': classe,
      'pocket': pocket,
      'tickets': tickets,
      'role': role,
      'language': language,
      'notifications_enabled': notificationsEnabled,
      'last_login': lastLogin,
    }.withoutNulls,
  );

  return firestoreData;
}

class UserRecordDocumentEquality implements Equality<UserRecord> {
  const UserRecordDocumentEquality();

  @override
  bool equals(UserRecord? e1, UserRecord? e2) {
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.nom == e2?.nom &&
        e1?.cin == e2?.cin &&
        e1?.motdepasse == e2?.motdepasse &&
        e1?.classe == e2?.classe &&
        e1?.pocket == e2?.pocket &&
        e1?.tickets == e2?.tickets;
  }

  @override
  int hash(UserRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber,
        e?.nom,
        e?.cin,
        e?.motdepasse,
        e?.classe,
        e?.pocket,
        e?.tickets
      ]);

  @override
  bool isValidKey(Object? o) => o is UserRecord;
}
