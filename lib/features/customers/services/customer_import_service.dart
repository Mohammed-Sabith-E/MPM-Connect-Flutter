import 'package:uuid/uuid.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

/// Status of an import candidate after duplicate detection and validation
enum ImportCandidateStatus {
  newCustomer,
  alreadyExisting,
  invalid,
}

/// A normalized candidate ready for preview and batch import
class ImportCandidate {
  final String id;
  final String name;
  final String rawPhone;
  final String normalizedPhone;
  final ImportCandidateStatus status;
  final String? rejectionReason;
  final Customer? existingCustomer;

  const ImportCandidate({
    required this.id,
    required this.name,
    required this.rawPhone,
    required this.normalizedPhone,
    required this.status,
    this.rejectionReason,
    this.existingCustomer,
  });

  bool get isNew => status == ImportCandidateStatus.newCustomer;
  bool get isExisting => status == ImportCandidateStatus.alreadyExisting;
  bool get isInvalid => status == ImportCandidateStatus.invalid;
}

/// Raw input item from any source (Phone contacts, CSV, Excel, API)
class RawImportItem {
  final String name;
  final String phone;
  final List<String> allPhoneNumbers;

  const RawImportItem({
    required this.name,
    required this.phone,
    this.allPhoneNumbers = const [],
  });
}

/// Result of analyzing and categorizing import candidates
class ImportAnalysisResult {
  final List<ImportCandidate> candidates;

  const ImportAnalysisResult({required this.candidates});

  int get totalSelected => candidates.length;

  List<ImportCandidate> get newCustomers =>
      candidates.where((c) => c.status == ImportCandidateStatus.newCustomer).toList();

  List<ImportCandidate> get existingCustomers =>
      candidates.where((c) => c.status == ImportCandidateStatus.alreadyExisting).toList();

  List<ImportCandidate> get invalidContacts =>
      candidates.where((c) => c.status == ImportCandidateStatus.invalid).toList();

  int get newCount => newCustomers.length;
  int get existingCount => existingCustomers.length;
  int get invalidCount => invalidContacts.length;
}

/// Final outcome of a batch import operation
class BatchImportResult {
  final bool isSuccess;
  final int totalAttempted;
  final int importedCount;
  final int skippedCount;
  final int invalidCount;
  final int failedCount;
  final String importBatchId;
  final List<String> errors;

  const BatchImportResult({
    required this.isSuccess,
    required this.totalAttempted,
    required this.importedCount,
    required this.skippedCount,
    required this.invalidCount,
    required this.failedCount,
    required this.importBatchId,
    this.errors = const [],
  });

  bool get hasPartialFailure => importedCount > 0 && failedCount > 0;
  bool get hasCompleteFailure => importedCount == 0 && failedCount > 0;
}

/// Decoupled service for analyzing, duplicate-checking, and importing customers.
/// Architecture supports Phone Contacts, CSV, Excel, and API imports uniformly.
class CustomerImportService {
  final CustomerRepository _customerRepository;

  CustomerImportService({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository;

  /// Analyzes raw candidates against the existing Firestore customer database.
  /// Categorizes every item into New, Already Existing, or Invalid.
  ImportAnalysisResult analyze({
    required List<RawImportItem> rawItems,
    required List<Customer> existingDatabaseCustomers,
  }) {
    // 1. Build an index of existing customers by normalized phone number
    final Map<String, Customer> existingPhoneMap = {};
    for (final customer in existingDatabaseCustomers) {
      final norm = customer.normalizedPhone ?? PhoneNormalizer.normalize(customer.phone);
      if (norm.isNotEmpty) {
        existingPhoneMap[norm] = customer;
      }
    }

    final List<ImportCandidate> analyzed = [];
    final Set<String> seenInThisBatch = {};

    for (int i = 0; i < rawItems.length; i++) {
      final item = rawItems[i];
      final candidateId = 'candidate-$i-${const Uuid().v4().substring(0, 8)}';
      final cleanName = item.name.trim().isEmpty ? 'Unknown Contact' : item.name.trim();
      final rawPhone = item.phone.trim();

      // Check validation
      final validationError = PhoneNormalizer.getValidationError(rawPhone);
      if (validationError != null) {
        analyzed.add(ImportCandidate(
          id: candidateId,
          name: cleanName,
          rawPhone: rawPhone,
          normalizedPhone: PhoneNormalizer.normalize(rawPhone),
          status: ImportCandidateStatus.invalid,
          rejectionReason: validationError,
        ));
        continue;
      }

      final normalizedPhone = PhoneNormalizer.normalize(rawPhone);

      // Check for duplicate against existing database customers
      if (existingPhoneMap.containsKey(normalizedPhone)) {
        final existingCust = existingPhoneMap[normalizedPhone]!;
        analyzed.add(ImportCandidate(
          id: candidateId,
          name: cleanName,
          rawPhone: rawPhone,
          normalizedPhone: normalizedPhone,
          status: ImportCandidateStatus.alreadyExisting,
          rejectionReason: 'Customer already exists (${existingCust.customerCode})',
          existingCustomer: existingCust,
        ));
        continue;
      }

      // Check for intra-batch duplicates (same number picked twice in selection)
      if (seenInThisBatch.contains(normalizedPhone)) {
        analyzed.add(ImportCandidate(
          id: candidateId,
          name: cleanName,
          rawPhone: rawPhone,
          normalizedPhone: normalizedPhone,
          status: ImportCandidateStatus.alreadyExisting,
          rejectionReason: 'Duplicate number within current selection',
        ));
        continue;
      }

      // Genuinely new customer
      seenInThisBatch.add(normalizedPhone);
      analyzed.add(ImportCandidate(
        id: candidateId,
        name: cleanName,
        rawPhone: rawPhone,
        normalizedPhone: normalizedPhone,
        status: ImportCandidateStatus.newCustomer,
      ));
    }

    return ImportAnalysisResult(candidates: analyzed);
  }

  /// Executes the batch import for confirmed new customers with progress callbacks.
  Future<BatchImportResult> executeImport({
    required List<ImportCandidate> candidatesToImport,
    required int totalSkippedCount,
    required int totalInvalidCount,
    String? assignedSalesmanId,
    String? assignedSalesmanName,
    required String createdBy,
    required String createdByName,
    void Function(int processed, int total)? onProgress,
  }) async {
    final importBatchId = 'BATCH-${DateTime.now().millisecondsSinceEpoch}';

    return await _customerRepository.batchCreateCustomers(
      importBatchId: importBatchId,
      candidates: candidatesToImport,
      totalSkippedCount: totalSkippedCount,
      totalInvalidCount: totalInvalidCount,
      assignedSalesmanId: assignedSalesmanId,
      assignedSalesmanName: assignedSalesmanName,
      createdBy: createdBy,
      createdByName: createdByName,
      onProgress: onProgress,
    );
  }
}
