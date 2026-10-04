import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/customer_import_service.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  final List<RawImportItem> rawItems;

  const ImportPreviewScreen({
    super.key,
    required this.rawItems,
  });

  @override
  ConsumerState<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  bool _isAnalyzing = true;
  ImportAnalysisResult? _analysisResult;
  String? _analysisError;

  // Selected filter tab: 'new', 'existing', 'invalid'
  String _activeTab = 'new';

  // Salesman assignment
  String? _selectedSalesmanId;
  String? _selectedSalesmanName;

  // Progress state
  bool _isImporting = false;
  int _importProcessed = 0;
  int _importTotal = 0;
  BatchImportResult? _importResult;

  // Track retryable failed candidates in case of partial error
  List<ImportCandidate> _failedCandidates = [];

  @override
  void initState() {
    super.initState();
    _analyzeSelection();
  }

  Future<void> _analyzeSelection() async {
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      final importService = ref.read(customerImportServiceProvider);

      // Fetch all active customers to guarantee zero duplicates
      final existingCustomers = await customerRepo.getAllActiveCustomersLightweight();

      final result = importService.analyze(
        rawItems: widget.rawItems,
        existingDatabaseCustomers: existingCustomers,
      );

      // Setup initial salesman assignment based on current user role
      final currentUser = ref.read(currentUserProfileProvider).value;
      String? initialSalesmanId;
      String? initialSalesmanName;

      if (currentUser?.role == UserRole.salesman) {
        initialSalesmanId = currentUser?.uid;
        initialSalesmanName = currentUser?.name;
      }

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _selectedSalesmanId = initialSalesmanId;
          _selectedSalesmanName = initialSalesmanName;
          _isAnalyzing = false;
          // Switch to existing or invalid tab if there are 0 new customers
          if (result.newCount == 0 && result.existingCount > 0) {
            _activeTab = 'existing';
          } else if (result.newCount == 0 && result.invalidCount > 0) {
            _activeTab = 'invalid';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisError = 'Failed to analyze contacts: $e';
        });
      }
    }
  }

  Future<void> _startImport({List<ImportCandidate>? candidatesToRun}) async {
    final toImport = candidatesToRun ?? _analysisResult?.newCustomers ?? [];
    if (toImport.isEmpty) return;

    final currentUser = ref.read(currentUserProfileProvider).value;
    final importService = ref.read(customerImportServiceProvider);

    setState(() {
      _isImporting = true;
      _importProcessed = 0;
      _importTotal = toImport.length;
      _importResult = null;
    });

    try {
      final result = await importService.executeImport(
        candidatesToImport: toImport,
        totalSkippedCount: _analysisResult?.existingCount ?? 0,
        totalInvalidCount: _analysisResult?.invalidCount ?? 0,
        assignedSalesmanId: _selectedSalesmanId,
        assignedSalesmanName: _selectedSalesmanName,
        createdBy: currentUser?.uid ?? 'SYSTEM',
        createdByName: currentUser?.name ?? 'Admin',
        onProgress: (processed, total) {
          if (mounted) {
            setState(() {
              _importProcessed = processed;
              _importTotal = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isImporting = false;
          _importResult = result;
          if (result.failedCount > 0) {
            // Keep track of failed candidates for idempotent retry
            _failedCandidates = toImport.skip(result.importedCount).toList();
          }
        });

        // Invalidate customer stream so list updates immediately
        ref.invalidate(customersStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importResult = BatchImportResult(
            isSuccess: false,
            totalAttempted: toImport.length,
            importedCount: _importProcessed,
            skippedCount: _analysisResult?.existingCount ?? 0,
            invalidCount: _analysisResult?.invalidCount ?? 0,
            failedCount: toImport.length - _importProcessed,
            importBatchId: 'ERROR',
            errors: [e.toString()],
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyPrimary),
          onPressed: _isImporting ? null : () => context.pop(),
        ),
        title: Text(
          'Import Customers',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.navyPrimary,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.navyPrimary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Checking for duplicates in Firestore...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    if (_analysisError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.crimsonDanger, size: 48),
              const SizedBox(height: 12),
              Text(
                _analysisError!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 16),
              AppButton(text: 'Retry', onPressed: _analyzeSelection),
            ],
          ),
        ),
      );
    }

    final result = _analysisResult!;

    return Stack(
      children: [
        Column(
          children: [
            // 1. Summary Cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Selected',
                      count: result.totalSelected,
                      color: AppColors.navyPrimary,
                      backgroundColor: AppColors.primaryFixed.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'New',
                      count: result.newCount,
                      color: AppColors.emeraldSuccess,
                      backgroundColor: AppColors.emeraldLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Existing',
                      count: result.existingCount,
                      color: AppColors.amberSecondary,
                      backgroundColor: AppColors.amberLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Invalid',
                      count: result.invalidCount,
                      color: AppColors.crimsonDanger,
                      backgroundColor: AppColors.crimsonLight,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Salesman Assignment Section
            _buildSalesmanAssignmentSection(),

            // 3. Segmented Tab Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabChip(
                      id: 'new',
                      title: 'New',
                      count: result.newCount,
                      color: AppColors.emeraldSuccess,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabChip(
                      id: 'existing',
                      title: 'Existing',
                      count: result.existingCount,
                      color: AppColors.amberSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabChip(
                      id: 'invalid',
                      title: 'Invalid',
                      count: result.invalidCount,
                      color: AppColors.crimsonDanger,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.hairlineBorder),

            // 4. Item List for active tab
            Expanded(child: _buildListForActiveTab()),
          ],
        ),

        // Import In-Progress or Finished Modal Overlay
        if (_isImporting || _importResult != null) _buildImportOverlay(),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesmanAssignmentSection() {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    final isSalesman = currentUser?.role == UserRole.salesman;

    if (isSalesman) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairlineBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_pin_rounded, color: AppColors.navyPrimary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Salesman',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.onPrimaryContainer),
                  ),
                  Text(
                    currentUser?.name ?? 'Mohammed',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Auto Assigned',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Admin or Manager: Dropdown selection
    final salesmenAsync = ref.watch(salesmenStreamProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: AppColors.navyPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: salesmenAsync.when(
              loading: () => const Text('Loading salesmen...'),
              error: (_, __) => const Text('Failed to load salesmen'),
              data: (salesmen) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedSalesmanId,
                    isExpanded: true,
                    hint: Text(
                      'Assign Salesman (Optional)',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimaryContainer),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Unassigned',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.navyPrimary),
                        ),
                      ),
                      ...salesmen.map((s) => DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(
                              s.name,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.navyPrimary),
                            ),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedSalesmanId = val;
                        if (val == null) {
                          _selectedSalesmanName = null;
                        } else {
                          final match = salesmen.firstWhere((s) => s.id == val);
                          _selectedSalesmanName = match.name;
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String id,
    required String title,
    required int count,
    required Color color,
  }) {
    final isSelected = _activeTab == id;

    return InkWell(
      onTap: () => setState(() => _activeTab = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyPrimary : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.navyPrimary : AppColors.hairlineBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title ($count)',
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.textOnDark : AppColors.navyPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListForActiveTab() {
    final result = _analysisResult!;
    List<ImportCandidate> items;

    if (_activeTab == 'new') {
      items = result.newCustomers;
    } else if (_activeTab == 'existing') {
      items = result.existingCustomers;
    } else {
      items = result.invalidContacts;
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No $_activeTab contacts in selection.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onPrimaryContainer),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairlineBorder),
      itemBuilder: (context, index) {
        final item = items[index];

        if (item.isNew) {
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.emeraldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.emeraldSuccess, size: 20),
            ),
            title: Text(
              item.name,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.navyPrimary,
              ),
            ),
            subtitle: Text(
              PhoneNormalizer.formatDisplay(item.rawPhone),
              style: AppTypography.bodySmall.copyWith(color: AppColors.onPrimaryContainer),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Will Import',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.emeraldSuccess,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        if (item.isExisting) {
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.amberLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.amberSecondary, size: 20),
            ),
            title: Text(
              item.name,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.navyPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PhoneNormalizer.formatDisplay(item.rawPhone),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.onPrimaryContainer),
                ),
                Text(
                  item.rejectionReason ?? 'Existing Customer',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.amberSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: item.existingCustomer != null
                ? TextButton(
                    onPressed: () => context.push('/customers/${item.existingCustomer!.id}'),
                    child: Text(
                      'View',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.navyPrimary),
                    ),
                  )
                : null,
          );
        }

        // Invalid Contact
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.crimsonLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined, color: AppColors.crimsonDanger, size: 20),
          ),
          title: Text(
            item.name,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.navyPrimary,
            ),
          ),
          subtitle: Text(
            item.rejectionReason ?? 'Invalid Contact',
            style: AppTypography.bodySmall.copyWith(color: AppColors.crimsonDanger),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final result = _analysisResult;
    final newCount = result?.newCount ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.hairlineBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Cancel',
              variant: AppButtonVariant.outlined,
              onPressed: _isImporting ? null : () => context.pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              text: newCount > 0
                  ? 'Import $newCount ${newCount == 1 ? "Customer" : "Customers"}'
                  : 'Nothing to Import',
              variant: AppButtonVariant.primary,
              icon: Icons.check_circle_outline_rounded,
              onPressed: (newCount > 0 && !_isImporting && _importResult == null)
                  ? () => _startImport()
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOverlay() {
    final isDone = _importResult != null;
    final result = _importResult;

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Card(
        color: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDone) ...[
                // Loading / In-Progress State
                const CircularProgressIndicator(
                  color: AppColors.navyPrimary,
                  strokeWidth: 4,
                ),
                const SizedBox(height: 20),
                Text(
                  'Importing Customers...',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _importTotal > 0 ? _importProcessed / _importTotal : null,
                  backgroundColor: AppColors.surfaceContainerLow,
                  color: AppColors.navyPrimary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_importProcessed / $_importTotal customers',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please don\'t close the application.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ] else ...[
                // Result State
                if (result!.isSuccess) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.emeraldLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emeraldSuccess,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Import Complete',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.importedCount} customers added successfully.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.navyPrimary),
                    textAlign: TextAlign.center,
                  ),
                  if (result.skippedCount > 0)
                    Text(
                      '${result.skippedCount} customers skipped because they already existed.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onPrimaryContainer),
                      textAlign: TextAlign.center,
                    ),
                  if (result.invalidCount > 0)
                    Text(
                      '${result.invalidCount} invalid contacts skipped.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onPrimaryContainer),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'View Customers',
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        context.go('/customers');
                      },
                    ),
                  ),
                ] else ...[
                  // Partial / Complete Failure State
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.crimsonLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: AppColors.crimsonDanger,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.hasPartialFailure
                        ? 'Import Partially Completed'
                        : 'Import Failed',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Successfully imported: ${result.importedCount}\nFailed: ${result.failedCount}',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.navyPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Close',
                          variant: AppButtonVariant.outlined,
                          onPressed: () => context.go('/customers'),
                        ),
                      ),
                      if (_failedCandidates.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'Retry Failed',
                            variant: AppButtonVariant.primary,
                            onPressed: () => _startImport(candidatesToRun: _failedCandidates),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
