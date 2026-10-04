import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessSettings {
  final String businessName;
  final String phone;
  final String address;
  final String email;
  final String gstNumber;
  final String invoicePrefix;
  final String currencySymbol;
  final String? logoUrl;
  final String organizationId;
  final DateTime updatedAt;

  const BusinessSettings({
    this.businessName = 'Malappuram Store',
    this.phone = '9947245526',
    this.address = 'Oorakam PO, Karathode, Kerala, 676519',
    this.email = 'contact@mpmconnect.com',
    this.gstNumber = '',
    this.invoicePrefix = 'INV-',
    this.currencySymbol = '₹',
    this.logoUrl,
    this.organizationId = 'mpm',
    required this.updatedAt,
  });

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return BusinessSettings(
      businessName: map['businessName'] ?? 'Malappuram Store',
      phone: map['phone'] ?? '9947245526',
      address: map['address'] ?? 'Oorakam PO, Karathode, Kerala, 676519',
      email: map['email'] ?? 'contact@mpmconnect.com',
      gstNumber: map['gstNumber'] ?? '',
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      currencySymbol: map['currencySymbol'] ?? '₹',
      logoUrl: map['logoUrl'],
      organizationId: (map['organizationId'] as String?)?.isNotEmpty == true
          ? map['organizationId'] as String
          : 'mpm',
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'phone': phone,
      'address': address,
      'email': email,
      'gstNumber': gstNumber,
      'invoicePrefix': invoicePrefix,
      'currencySymbol': currencySymbol,
      'logoUrl': logoUrl,
      'organizationId': organizationId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BusinessSettings copyWith({
    String? businessName,
    String? phone,
    String? address,
    String? email,
    String? gstNumber,
    String? invoicePrefix,
    String? currencySymbol,
    String? logoUrl,
    String? organizationId,
    DateTime? updatedAt,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      logoUrl: logoUrl ?? this.logoUrl,
      organizationId: organizationId ?? this.organizationId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
