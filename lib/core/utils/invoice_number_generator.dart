import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/organizations/models/organization_model.dart';

/// Atomic sequential invoice number generator
/// Uses Firestore transaction on settings/counters to guarantee unique sequential numbers:
/// INV-000001, INV-000002, etc.
class InvoiceNumberGenerator {
  InvoiceNumberGenerator._();

  static const String _counterField = 'lastInvoiceNumber';

  static String _getCounterDocPath(Organization? org) {
    if (org == null) {
      return 'settings/counters';
    }
    return 'organizations/${org.id}/settings/counters';
  }

  /// Generates the next sequential invoice number within a Firestore Transaction
  static Future<String> getNextInvoiceNumberWithTransaction(
    FirebaseFirestore firestore,
    Transaction transaction, {
    String prefix = 'INV-',
    Organization? org,
  }) async {
    final counterRef = firestore.doc(_getCounterDocPath(org));
    final counterSnapshot = await transaction.get(counterRef);

    int currentCounter = 0;
    if (counterSnapshot.exists && counterSnapshot.data() != null) {
      currentCounter = (counterSnapshot.data()![_counterField] as num?)?.toInt() ?? 0;
    }

    final nextCounter = currentCounter + 1;
    transaction.set(
      counterRef,
      {
        _counterField: nextCounter,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Format with 6 digits padding: e.g. INV-000001
    final paddedNumber = nextCounter.toString().padLeft(6, '0');
    return '$prefix$paddedNumber';
  }

  /// Previews the next sequential invoice number without incrementing
  static Future<String> previewNextInvoiceNumber(
    FirebaseFirestore firestore, {
    String prefix = 'INV-',
    Organization? org,
  }) async {
    final counterRef = firestore.doc(_getCounterDocPath(org));
    final snapshot = await counterRef.get();
    int currentCounter = 0;
    if (snapshot.exists && snapshot.data() != null) {
      currentCounter = (snapshot.data()![_counterField] as num?)?.toInt() ?? 0;
    }
    final nextCounter = currentCounter + 1;
    final paddedNumber = nextCounter.toString().padLeft(6, '0');
    return '$prefix$paddedNumber';
  }

  /// Formats any integer to an invoice string
  static String format(int sequence, {String prefix = 'INV-'}) {
    return '$prefix${sequence.toString().padLeft(6, '0')}';
  }
}
