import 'package:flutter_test/flutter_test.dart';
import 'package:mpm_connect/features/customers/models/customer_model.dart';
import 'package:mpm_connect/features/customers/repositories/customer_repository.dart';
import 'package:mpm_connect/features/customers/services/customer_import_service.dart';

// Fake customer repository for unit testing the import service
class FakeCustomerRepository extends Fake implements CustomerRepository {
  @override
  Future<BatchImportResult> batchCreateCustomers({
    required String importBatchId,
    required List<ImportCandidate> candidates,
    required int totalSkippedCount,
    required int totalInvalidCount,
    String? assignedSalesmanId,
    String? assignedSalesmanName,
    required String createdBy,
    required String createdByName,
    void Function(int processed, int total)? onProgress,
  }) async {
    return BatchImportResult(
      isSuccess: true,
      totalAttempted: candidates.length,
      importedCount: candidates.length,
      skippedCount: totalSkippedCount,
      invalidCount: totalInvalidCount,
      failedCount: 0,
      importBatchId: importBatchId,
    );
  }
}

void main() {
  group('CustomerImportService Analysis & Duplicate Detection Tests', () {
    late CustomerImportService importService;
    late List<Customer> existingCustomers;

    setUp(() {
      importService = CustomerImportService(customerRepository: FakeCustomerRepository());
      existingCustomers = [
        Customer(
          id: 'cust-1',
          customerCode: 'CUST-0001',
          name: 'Faisal Existing',
          phone: '9999911111',
          normalizedPhone: '919999911111',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        Customer(
          id: 'cust-2',
          customerCode: 'CUST-0002',
          name: 'Anwar Existing',
          phone: '+91 98470 45678',
          normalizedPhone: '919847045678',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
    });

    test('Categorizes new, existing, and invalid contacts correctly', () {
      final rawItems = [
        // 1. Genuinely new customer
        const RawImportItem(name: 'Abdul Rahman', phone: '+91 98765 12345'),
        // 2. Already existing (matches 919999911111 in format 09999911111)
        const RawImportItem(name: 'Faisal Duplicate', phone: '09999911111'),
        // 3. Invalid: no phone number
        const RawImportItem(name: 'Invalid No Phone', phone: ''),
        // 4. Invalid: too short
        const RawImportItem(name: 'Invalid Short', phone: '12345'),
        // 5. Another new customer
        const RawImportItem(name: 'Shihab New', phone: '9876522222'),
      ];

      final result = importService.analyze(
        rawItems: rawItems,
        existingDatabaseCustomers: existingCustomers,
      );

      expect(result.totalSelected, 5);
      expect(result.newCount, 2);
      expect(result.existingCount, 1);
      expect(result.invalidCount, 2);

      // Verify new customers
      expect(result.newCustomers[0].name, 'Abdul Rahman');
      expect(result.newCustomers[0].normalizedPhone, '919876512345');
      expect(result.newCustomers[1].name, 'Shihab New');

      // Verify existing customer detection
      expect(result.existingCustomers[0].name, 'Faisal Duplicate');
      expect(result.existingCustomers[0].existingCustomer?.customerCode, 'CUST-0001');

      // Verify invalid customers
      expect(result.invalidContacts[0].rejectionReason, contains('No phone number'));
      expect(result.invalidContacts[1].rejectionReason, contains('too short'));
    });

    test('Detects intra-batch duplicates (same number in one selection)', () {
      final rawItems = [
        const RawImportItem(name: 'Duplicate 1', phone: '9876512345'),
        const RawImportItem(name: 'Duplicate 2', phone: '+91 98765 12345'), // Same normalized number
      ];

      final result = importService.analyze(
        rawItems: rawItems,
        existingDatabaseCustomers: existingCustomers,
      );

      expect(result.newCount, 1);
      expect(result.existingCount, 1);
      expect(result.existingCustomers[0].rejectionReason, contains('current selection'));
    });

    test('Executes import calling repository batch create', () async {
      final rawItems = [
        const RawImportItem(name: 'Abdul Rahman', phone: '+91 98765 12345'),
      ];

      final analysis = importService.analyze(
        rawItems: rawItems,
        existingDatabaseCustomers: existingCustomers,
      );

      final batchResult = await importService.executeImport(
        candidatesToImport: analysis.newCustomers,
        totalSkippedCount: analysis.existingCount,
        totalInvalidCount: analysis.invalidCount,
        createdBy: 'user-1',
        createdByName: 'Sabith',
      );

      expect(batchResult.isSuccess, isTrue);
      expect(batchResult.importedCount, 1);
      expect(batchResult.importBatchId.startsWith('BATCH-'), isTrue);
    });
  });
}
