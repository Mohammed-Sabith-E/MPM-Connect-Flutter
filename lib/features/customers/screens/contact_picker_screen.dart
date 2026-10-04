import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/customer_import_service.dart';
import '../widgets/select_phone_dialog.dart';

class ContactPickerScreen extends StatefulWidget {
  final bool isMultiSelect;

  const ContactPickerScreen({
    super.key,
    this.isMultiSelect = true,
  });

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final _searchController = TextEditingController();
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Multi-select tracking: contact.id -> selected primary phone number
  final Map<String, String> _selectedContactPhones = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch contacts with properties for fast, memory-efficient loading of large lists
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      // Filter out contacts without any display name and phone number
      final validContacts = contacts.where((c) {
        final hasName = c.displayName.trim().isNotEmpty;
        final hasPhone = c.phones.isNotEmpty;
        return hasName || hasPhone;
      }).toList();

      if (mounted) {
        setState(() {
          _allContacts = validContacts;
          _filteredContacts = validContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load contacts: $e';
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) {
      setState(() => _filteredContacts = _allContacts);
      return;
    }

    final queryNorm = PhoneNormalizer.normalize(cleanQuery);
    setState(() {
      _filteredContacts = _allContacts.where((c) {
        final nameMatch = c.displayName.toLowerCase().contains(cleanQuery);
        final phoneMatch = c.phones.any((p) {
          final pNorm = PhoneNormalizer.normalize(p.number);
          return p.number.contains(cleanQuery) ||
              (queryNorm.isNotEmpty && pNorm.contains(queryNorm));
        });
        return nameMatch || phoneMatch;
      }).toList();
    });
  }

  void _selectAll() {
    setState(() {
      for (final contact in _filteredContacts) {
        if (contact.phones.isNotEmpty) {
          _selectedContactPhones[contact.id] = contact.phones.first.number;
        } else {
          _selectedContactPhones[contact.id] = '';
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedContactPhones.clear();
    });
  }

  Future<void> _handleContactTap(Contact contact) async {
    final phones = contact.phones.map((p) => p.number.trim()).where((p) => p.isNotEmpty).toList();

    if (!widget.isMultiSelect) {
      // Single select mode
      String selectedPhone = '';
      if (phones.length > 1) {
        final chosen = await SelectPhoneDialog.show(
          context,
          contactName: contact.displayName,
          phoneNumbers: phones,
        );
        if (chosen == null) return; // User cancelled
        selectedPhone = chosen;
      } else if (phones.isNotEmpty) {
        selectedPhone = phones.first;
      }

      if (!mounted) return;
      context.pushReplacement(
        '/customers/add',
        extra: {
          'initialName': contact.displayName,
          'initialPhone': selectedPhone,
        },
      );
      return;
    }

    // Multi-select mode
    setState(() {
      if (_selectedContactPhones.containsKey(contact.id)) {
        _selectedContactPhones.remove(contact.id);
      } else {
        _selectedContactPhones[contact.id] = phones.isNotEmpty ? phones.first : '';
      }
    });
  }

  Future<void> _disambiguatePhone(Contact contact) async {
    final phones = contact.phones.map((p) => p.number.trim()).where((p) => p.isNotEmpty).toList();
    if (phones.length <= 1) return;

    final currentlySelected = _selectedContactPhones[contact.id];
    final chosen = await SelectPhoneDialog.show(
      context,
      contactName: contact.displayName,
      phoneNumbers: phones,
      currentlySelected: currentlySelected,
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedContactPhones[contact.id] = chosen;
      });
    }
  }

  void _proceedToPreview() {
    if (_selectedContactPhones.isEmpty) return;

    final selectedItems = <RawImportItem>[];
    for (final contact in _allContacts) {
      if (_selectedContactPhones.containsKey(contact.id)) {
        final chosenPhone = _selectedContactPhones[contact.id]!;
        final allPhones = contact.phones.map((p) => p.number).toList();
        selectedItems.add(RawImportItem(
          name: contact.displayName,
          phone: chosenPhone,
          allPhoneNumbers: allPhones,
        ));
      }
    }

    context.push('/customers/import-preview', extra: selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedContactPhones.length;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isMultiSelect ? 'Select Contacts' : 'Search Contacts',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.navyPrimary,
          ),
        ),
        actions: widget.isMultiSelect
            ? [
                if (_filteredContacts.isNotEmpty)
                  TextButton(
                    onPressed: selectedCount == _filteredContacts.length
                        ? _deselectAll
                        : _selectAll,
                    child: Text(
                      selectedCount == _filteredContacts.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairlineBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.navyPrimary),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.onPrimaryContainer,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          color: AppColors.onPrimaryContainer,
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: widget.isMultiSelect ? _buildBottomBar(selectedCount) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
              'Loading contacts from phone...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.crimsonDanger, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Retry',
                onPressed: _loadDeviceContacts,
              ),
            ],
          ),
        ),
      );
    }

    if (_allContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contact_phone_outlined, size: 56, color: AppColors.onPrimaryContainer),
            const SizedBox(height: 16),
            Text(
              'No contacts found on device',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.navyPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.onPrimaryContainer),
            const SizedBox(height: 12),
            Text(
              'No contacts matching "${_searchController.text}"',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = _selectedContactPhones.containsKey(contact.id);
        final phones = contact.phones.map((p) => p.number.trim()).where((p) => p.isNotEmpty).toList();
        final selectedPhone = _selectedContactPhones[contact.id] ?? (phones.isNotEmpty ? phones.first : '');
        final hasMultiplePhones = phones.length > 1;

        return InkWell(
          onTap: () => _handleContactTap(contact),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryFixed.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: const Border(
                bottom: BorderSide(color: AppColors.hairlineBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Selection Checkbox (multi-select)
                if (widget.isMultiSelect) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: AppColors.navyPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (_) => _handleContactTap(contact),
                  ),
                  const SizedBox(width: 8),
                ],

                // Avatar with Initials
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected ? AppColors.navyPrimary : AppColors.surfaceContainerLow,
                  child: Text(
                    _getInitials(contact.displayName),
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected ? AppColors.textOnDark : AppColors.navyPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name and Phone Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName.isNotEmpty ? contact.displayName : 'Unknown Contact',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedPhone.isNotEmpty
                                  ? PhoneNormalizer.formatDisplay(selectedPhone)
                                  : 'No phone number',
                              style: AppTypography.bodySmall.copyWith(
                                color: selectedPhone.isNotEmpty
                                    ? AppColors.onPrimaryContainer
                                    : AppColors.crimsonDanger,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasMultiplePhones && widget.isMultiSelect && isSelected)
                            InkWell(
                              onTap: () => _disambiguatePhone(contact),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.hairlineBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${phones.length} nos',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.navyPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: 16,
                                      color: AppColors.navyPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!widget.isMultiSelect)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.onPrimaryContainer,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(int selectedCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.hairlineBorder)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(15, 43, 72, 0.08),
            offset: Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: AppButton(
        text: selectedCount == 0
            ? 'Select Contacts to Import'
            : 'Import $selectedCount ${selectedCount == 1 ? "Customer" : "Customers"}',
        variant: AppButtonVariant.primary,
        icon: Icons.download_rounded,
        onPressed: selectedCount > 0 ? _proceedToPreview : null,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
