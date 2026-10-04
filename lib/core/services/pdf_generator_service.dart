import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/transactions/models/transaction_model.dart';
import '../../features/payments/models/payment_model.dart';
import '../../features/salesmen/models/salesman_model.dart';
import '../../features/settings/models/business_settings_model.dart';
import '../../features/organizations/models/organization_model.dart';

class PdfGeneratorService {
  PdfGeneratorService._();

  // Color palette matching MPM Connect "Precision Ledger" design system
  static const PdfColor pdfNavy = PdfColor.fromInt(0xFF0F2042);
  static const PdfColor pdfNavyDark = PdfColor.fromInt(0xFF000922);
  static const PdfColor pdfOrange = PdfColor.fromInt(0xFFFD761A);
  static const PdfColor pdfOrangeLight = PdfColor.fromInt(0xFFFFF0E6);
  static const PdfColor pdfOrangeDark = PdfColor.fromInt(0xFF9D4300);
  static const PdfColor pdfEmerald = PdfColor.fromInt(0xFF009C6B);
  static const PdfColor pdfEmeraldLight = PdfColor.fromInt(0xFFE6F7F0);
  static const PdfColor pdfCrimson = PdfColor.fromInt(0xFFBA1A1A);
  static const PdfColor pdfCrimsonLight = PdfColor.fromInt(0xFFFFEBEB);
  static const PdfColor pdfSlate = PdfColor.fromInt(0xFF45464E);
  static const PdfColor pdfSlateLight = PdfColor.fromInt(0xFF75777F);
  static const PdfColor pdfBorder = PdfColor.fromInt(0xFFDCE9FF);
  static const PdfColor pdfSurfaceLow = PdfColor.fromInt(0xFFEFF4FF);
  static const PdfColor pdfSurface = PdfColor.fromInt(0xFFF8F9FF);

  // Default company details as mandated:
  // Malappuram Store
  // Oorakam PO, Karathode, Kerala
  // 676519
  // Mob : 9947245526
  static const String companyName = 'Malappuram Store';
  static const String companyAddress = 'Oorakam PO, Karathode, Kerala';
  static const String companyPin = '676519';
  static const String companyPhone = 'Mob : 9947245526';

  // Cached fonts for Unicode & Indian Rupee symbol rendering
  static pw.Font? _fontRegular;
  static pw.Font? _fontBold;
  static pw.Font? _fontMalayalam;

  static List<pw.Font> get _fallbackFonts => [
    if (_fontMalayalam != null) _fontMalayalam!,
  ];

  static Future<pw.ThemeData> _getDocumentTheme() async {
    if (_fontRegular == null || _fontBold == null) {
      try {
        final regData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
        final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
        _fontRegular = pw.Font.ttf(regData);
        _fontBold = pw.Font.ttf(boldData);
      } catch (_) {
        // Fallback for tests / headless execution
        _fontRegular = pw.Font.helvetica();
        _fontBold = pw.Font.helveticaBold();
      }
    }
    if (_fontMalayalam == null) {
      try {
        final malData = await rootBundle.load('assets/fonts/NotoSansMalayalam.ttf');
        _fontMalayalam = pw.Font.ttf(malData);
      } catch (_) {
        // Ignore in test or headless environment
      }
    }
    return pw.ThemeData.withFont(
      base: _fontRegular,
      bold: _fontBold,
      fontFallback: [
        if (_fontMalayalam != null) _fontMalayalam!,
      ],
    );
  }

  // ==========================================
  // SHARED STAT CARD BUILDER (STITCH PRECISION LEDGER)
  // ==========================================
  static pw.Widget _buildStatCard({
    required String label,
    required String value,
    String? subtitle,
    bool isHero = false,
    bool isHighlight = false,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    PdfColor bgColor = pdfSurfaceLow;
    PdfColor borderColor = pdfBorder;
    PdfColor labelColor = pdfSlate;
    PdfColor valueColor = pdfNavyDark;
    PdfColor subColor = pdfSlateLight;

    if (isHero) {
      bgColor = pdfNavy;
      borderColor = pdfNavyDark;
      labelColor = pdfOrange;
      valueColor = PdfColors.white;
      subColor = PdfColors.grey300;
    } else if (isHighlight) {
      bgColor = pdfOrangeLight;
      borderColor = pdfOrange;
      labelColor = pdfOrangeDark;
      valueColor = pdfOrangeDark;
      subColor = pdfOrangeDark;
    } else if (isSuccess) {
      bgColor = pdfEmeraldLight;
      borderColor = pdfEmerald;
      labelColor = pdfEmerald;
      valueColor = pdfEmerald;
      subColor = pdfEmerald;
    } else if (isWarning) {
      bgColor = pdfCrimsonLight;
      borderColor = pdfCrimson;
      labelColor = pdfCrimson;
      valueColor = pdfCrimson;
      subColor = pdfCrimson;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              color: labelColor,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              fontFallback: _fallbackFonts,
            ),
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(color: subColor, fontSize: 7.5, fontFallback: _fallbackFonts),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SHARED HEADER BUILDER
  // ==========================================
  static pw.Widget _buildHeader(
    String title, {
    String? docNumber,
    String? subtitle,
    String? statusPill,
    PdfColor? statusColor,
    PdfColor? statusBgColor,
    Organization? organization,
  }) {
    final isTest = organization?.isTest == true;
    final displayCompanyName = isTest ? '${organization?.name ?? "MPM Test"} (TEST)' : companyName;
    final displayAddress = isTest ? 'Test Environment - Isolated Tenant' : companyAddress;
    final displayPin = isTest ? 'TEST-ORG' : companyPin;
    final displayPhone = isTest ? 'Demo / Training Only' : companyPhone;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (isTest) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            margin: const pw.EdgeInsets.only(bottom: 6),
            decoration: pw.BoxDecoration(
              color: pdfOrangeLight,
              borderRadius: pw.BorderRadius.circular(3),
              border: pw.Border.all(color: pdfOrange, width: 0.8),
            ),
            child: pw.Center(
              child: pw.Text(
                '*** TEST ENVIRONMENT - DEMO & TRAINING ONLY - NOT A LEGAL DOCUMENT ***',
                style: pw.TextStyle(
                  color: pdfOrangeDark,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        // Top Two-Tone Accent Line
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Container(height: 3, color: isTest ? pdfOrange : pdfNavy),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Container(height: 3, color: isTest ? pdfNavy : pdfOrange),
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Company Details & Document Badge Row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Clean Company Identity
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  displayCompanyName,
                  style: pw.TextStyle(
                    color: isTest ? pdfOrangeDark : pdfNavyDark,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  displayAddress,
                  style: const pw.TextStyle(
                    color: pdfSlate,
                    fontSize: 9,
                  ),
                ),
                pw.Text(
                  displayPin,
                  style: const pw.TextStyle(
                    color: pdfSlate,
                    fontSize: 9,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  displayPhone,
                  style: pw.TextStyle(
                    color: isTest ? pdfOrangeDark : pdfNavyDark,
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Right: Document Identification & Status Badge
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: isTest ? pdfOrange : pdfNavy,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    title.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (docNumber != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    docNumber,
                    style: pw.TextStyle(
                      color: pdfNavyDark,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
                if (subtitle != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      color: pdfSlateLight,
                      fontSize: 8.5,
                    ),
                  ),
                ],
                if (statusPill != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: pw.BoxDecoration(
                      color: statusBgColor ?? pdfEmeraldLight,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: statusColor ?? pdfEmerald, width: 0.8),
                    ),
                    child: pw.Text(
                      statusPill.toUpperCase(),
                      style: pw.TextStyle(
                        color: statusColor ?? pdfEmerald,
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(height: 0.8, color: pdfBorder),
        pw.SizedBox(height: 14),
      ],
    );
  }

  // ==========================================
  // SHARED FOOTER BUILDER
  // ==========================================
  static pw.Widget _buildFooter(pw.Context context, {Organization? organization}) {
    final isTest = organization?.isTest == true;
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: pdfBorder, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isTest
                ? 'MPM TEST ENVIRONMENT | NOT FOR LEGAL/COMMERCIAL USE'
                : '$companyName | $companyAddress (Mob: 9947245526)',
            style: pw.TextStyle(color: isTest ? pdfOrangeDark : pdfSlateLight, fontSize: 8),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount} | ${isTest ? "TEST DOC" : "Computer generated document"}',
            style: pw.TextStyle(color: isTest ? pdfOrangeDark : pdfSlateLight, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. INDIVIDUAL TRANSACTION / INVOICE PDF
  // ==========================================
  static Future<Uint8List> generateTransactionInvoice({
    required InvoiceTransaction transaction,
    Customer? customer,
    BusinessSettings? settings,
    Organization? organization,
  }) async {
    final theme = await _getDocumentTheme();
    final pdf = pw.Document(theme: theme);

    final status = transaction.paymentStatus.toUpperCase();
    PdfColor statusColor = pdfEmerald;
    PdfColor statusBgColor = pdfEmeraldLight;
    if (status == 'UNPAID') {
      statusColor = pdfCrimson;
      statusBgColor = pdfCrimsonLight;
    } else if (status == 'PARTIAL') {
      statusColor = pdfOrange;
      statusBgColor = pdfOrangeLight;
    }

    final phone = (customer?.phone.isNotEmpty == true) ? customer!.phone : '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(
              'Invoice',
              docNumber: 'Invoice No: ${transaction.invoiceNumber}',
              subtitle: 'Date: ${DateFormatter.formatDate(transaction.invoiceDate)}',
              statusPill: transaction.paymentStatus,
              statusColor: statusColor,
              statusBgColor: statusBgColor,
              organization: organization,
            ),

            // Billed To Customer Card (Clean, focused)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: pdfSurfaceLow,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: pdfBorder, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO / CUSTOMER',
                        style: pw.TextStyle(
                          color: pdfSlateLight,
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        transaction.customerName,
                        style: pw.TextStyle(
                          color: pdfNavyDark,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Mobile: $phone',
                          style: const pw.TextStyle(color: pdfSlate, fontSize: 9),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (customer?.customerCode.isNotEmpty == true) ...[
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: pdfNavy,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(
                            customer!.customerCode,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      pw.Text(
                        'Payment Method: ${transaction.paymentMethod}',
                        style: const pw.TextStyle(color: pdfSlate, fontSize: 8.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 4-Card Stats Ribbon Breakdown (Stitch Design)
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildStatCard(
                    label: 'Previous Balance',
                    value: CurrencyFormatter.format(transaction.previousBalance),
                    subtitle: 'Due Prior',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildStatCard(
                    label: '(+) New Invoice',
                    value: CurrencyFormatter.format(transaction.invoiceAmount),
                    subtitle: 'Invoice Amount',
                    isHero: true,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildStatCard(
                    label: '(-) Paid Today',
                    value: CurrencyFormatter.format(transaction.paymentReceived),
                    subtitle: 'Cash / UPI Received',
                    isSuccess: true,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildStatCard(
                    label: 'New Balance',
                    value: CurrencyFormatter.format(transaction.newBalance),
                    subtitle: 'Customer Ledger Due',
                    isHighlight: transaction.newBalance > 0,
                    isSuccess: transaction.newBalance <= 0,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Itemized Invoice Particulars (Stitch Design)
            _buildSectionTitle('Invoice Particulars', badge: '1 Item'),

            pw.TableHelper.fromTextArray(
              headers: ['SL', 'PARTICULARS / DESCRIPTION', 'PAYMENT METHOD', 'AMOUNT'],
              headerStyle: pw.TextStyle(
                color: pdfSlate,
                fontWeight: pw.FontWeight.bold,
                fontSize: 7.5,
                letterSpacing: 0.5,
                fontFallback: _fallbackFonts,
              ),
              headerDecoration: pw.BoxDecoration(
                color: pdfSurfaceLow,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(
                fontSize: 8.5,
                color: pdfNavyDark,
                fontFallback: _fallbackFonts,
              ),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
              headerAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
              border: null,
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              data: [
                [
                  '01',
                  'Sales Invoice - #${transaction.invoiceNumber}',
                  transaction.paymentMethod,
                  CurrencyFormatter.format(transaction.invoiceAmount),
                ],
              ],
            ),

            _buildSubtotalsBar({
              'INVOICE AMOUNT': CurrencyFormatter.format(transaction.invoiceAmount),
              'PAID TODAY': CurrencyFormatter.format(transaction.paymentReceived),
              'NET BALANCE DUE': CurrencyFormatter.format(transaction.newBalance),
            }),

            if (transaction.notes.trim().isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: pdfSurfaceLow,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: pdfBorder, width: 0.6),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Note: ',
                      style: pw.TextStyle(
                        color: pdfNavyDark,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        fontFallback: _fallbackFonts,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        transaction.notes.trim(),
                        style: pw.TextStyle(color: pdfSlate, fontSize: 8.5, fontFallback: _fallbackFonts),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            pw.Spacer(),

            _buildSignatureBlock(organization: organization),

            _buildFooter(context, organization: organization),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // SHARED SECTION TITLE (STITCH DESIGN)
  // ==========================================
  static pw.Widget _buildSectionTitle(String title, {String? badge, String? trailingText}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: pdfNavyDark,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: _fallbackFonts,
                ),
              ),
              if (badge != null) ...[
                pw.SizedBox(width: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: pdfSurfaceLow,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: pdfBorder, width: 0.6),
                  ),
                  child: pw.Text(
                    badge,
                    style: pw.TextStyle(
                      color: pdfSlate,
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      fontFallback: _fallbackFonts,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (trailingText != null)
            pw.Text(
              trailingText,
              style: pw.TextStyle(color: pdfSlateLight, fontSize: 8, fontFallback: _fallbackFonts),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED SUBTOTALS BAR (STITCH DESIGN)
  // ==========================================
  static pw.Widget _buildSubtotalsBar(Map<String, String> items) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: pdfNavy,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: items.entries.map((entry) {
          return pw.Row(
            children: [
              pw.Text(
                '${entry.key}: ',
                style: pw.TextStyle(
                  color: PdfColors.grey300,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                entry.value,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // SHARED SIGNATURE BLOCK (STITCH DESIGN)
  // ==========================================
  static pw.Widget _buildSignatureBlock({Organization? organization}) {
    final isTest = organization?.isTest == true;
    final signatoryName = isTest ? '${organization?.name ?? "MPM Test"} (TEST)' : companyName;
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 130, height: 0.8, color: pdfSlateLight),
              pw.SizedBox(height: 4),
              pw.Text(
                'Customer Signature',
                style: pw.TextStyle(fontSize: 8, color: pdfSlate, fontFallback: _fallbackFonts),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(width: 130, height: 0.8, color: pdfSlateLight),
              pw.SizedBox(height: 4),
              pw.Text(
                'For $signatoryName',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: isTest ? pdfOrangeDark : pdfNavyDark,
                  fontFallback: _fallbackFonts,
                ),
              ),
              pw.Text(
                'Authorised Signatory',
                style: pw.TextStyle(fontSize: 7.5, color: pdfSlate, fontFallback: _fallbackFonts),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. CUSTOMER STATEMENT PDF
  // ==========================================
  static Future<Uint8List> generateCustomerStatement({
    required Customer customer,
    required List<InvoiceTransaction> transactions,
    required List<PaymentRecord> payments,
    DateTime? startDate,
    DateTime? endDate,
    BusinessSettings? settings,
    Organization? organization,
  }) async {
    final theme = await _getDocumentTheme();
    final pdf = pw.Document(theme: theme);

    final dateRangeText = 'Period: ${startDate != null ? DateFormatter.formatDate(startDate) : "All Time"} to ${endDate != null ? DateFormatter.formatDate(endDate) : DateFormatter.formatDate(DateTime.now())}';

    // Combine transactions and payments chronologically
    final List<Map<String, dynamic>> ledgerEntries = [];
    for (final tx in transactions) {
      ledgerEntries.add({
        'date': tx.invoiceDate,
        'reference': tx.invoiceNumber,
        'type': 'Invoice',
        'invoiceAmount': tx.invoiceAmount,
        'paymentAmount': 0.0,
      });
    }
    for (final pm in payments) {
      ledgerEntries.add({
        'date': pm.paymentDate,
        'reference': 'PMT-${pm.id.length >= 6 ? pm.id.substring(0, 6).toUpperCase() : pm.id.toUpperCase()}',
        'type': 'Payment (${pm.paymentMethod})',
        'invoiceAmount': 0.0,
        'paymentAmount': pm.amount,
      });
    }
    ledgerEntries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Build ledger rows with running balance and subtotals (Stitch Precision Ledger)
    double runningBalance = 0.0;
    double totalDebits = 0.0;
    double totalCredits = 0.0;
    final List<List<String>> tableData = [];

    for (final e in ledgerEntries) {
      final inv = e['invoiceAmount'] as double;
      final pmt = e['paymentAmount'] as double;
      runningBalance += inv;
      runningBalance -= pmt;
      totalDebits += inv;
      totalCredits += pmt;

      tableData.add([
        DateFormatter.formatDate(e['date'] as DateTime),
        e['reference'].toString(),
        e['type'].toString(),
        inv > 0 ? CurrencyFormatter.format(inv) : '-',
        pmt > 0 ? CurrencyFormatter.format(pmt) : '-',
        CurrencyFormatter.format(runningBalance),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(
          'Customer Statement',
          subtitle: dateRangeText,
          statusPill: customer.balance > 0 ? 'DUE: ${CurrencyFormatter.format(customer.balance)}' : 'SETTLED',
          statusColor: customer.balance > 0 ? pdfCrimson : pdfEmerald,
          statusBgColor: customer.balance > 0 ? pdfCrimsonLight : pdfEmeraldLight,
          organization: organization,
        ),
        footer: (context) => _buildFooter(context, organization: organization),
        build: (context) => [
          // Customer Account Header Box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: pdfBorder, width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ACCOUNT DETAILS',
                      style: pw.TextStyle(
                        color: pdfSlateLight,
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      customer.name,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: pdfNavyDark,
                        fontFallback: _fallbackFonts,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Code: ${customer.customerCode}${customer.phone.isNotEmpty ? " | Mob: ${customer.phone}" : ""}',
                      style: pw.TextStyle(fontSize: 8.5, color: pdfSlate, fontFallback: _fallbackFonts),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'OUTSTANDING BALANCE',
                      style: pw.TextStyle(
                        color: customer.balance > 0 ? pdfCrimson : pdfEmerald,
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      CurrencyFormatter.format(customer.balance),
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: customer.balance > 0 ? pdfCrimson : pdfEmerald,
                        fontFallback: _fallbackFonts,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Total Due to Malappuram Store',
                      style: const pw.TextStyle(fontSize: 8, color: pdfSlate),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // 4-Card Stats Grid (Matching Stitch Customer Statement)
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Invoiced',
                  value: CurrencyFormatter.format(customer.totalInvoiced),
                  subtitle: '${transactions.length} Recorded Invoices',
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Paid',
                  value: CurrencyFormatter.format(customer.totalPaid),
                  subtitle: '${payments.length} Payments Received',
                  isSuccess: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Amount to Get',
                  value: CurrencyFormatter.format(customer.balance),
                  subtitle: 'Immediate Receivable',
                  isHighlight: customer.balance > 0,
                  isSuccess: customer.balance <= 0,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Account Status',
                  value: customer.balance > 0 ? 'DUE ACTIVE' : 'ALL SETTLED',
                  subtitle: customer.balance > 0 ? 'Payment Pending' : 'Zero Outstanding',
                  isWarning: customer.balance > 0,
                  isSuccess: customer.balance <= 0,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          _buildSectionTitle(
            'Statement Ledger Table',
            badge: '${transactions.length + payments.length} Entries',
            trailingText: 'Statement Cycle',
          ),

          // Professional Ledger Table (Stitch 6-Column Layout with Running Balance)
          pw.TableHelper.fromTextArray(
            headers: ['DATE', 'REFERENCE', 'DESCRIPTION', 'INVOICE (+)', 'PAYMENT (−)', 'BALANCE'],
            headerStyle: pw.TextStyle(
              color: pdfSlate,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7.5,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(
              fontSize: 8.5,
              color: pdfNavyDark,
              fontFallback: _fallbackFonts,
            ),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            border: null,
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            data: tableData.isNotEmpty
                ? tableData
                : [
                    ['-', '-', 'No transactions recorded in this cycle', '-', '-', '-']
                  ],
          ),

          _buildSubtotalsBar({
            'CYCLE SUBTOTALS': '${transactions.length + payments.length} Entries',
            'Debits (+)': CurrencyFormatter.format(totalDebits),
            'Credits (−)': CurrencyFormatter.format(totalCredits),
          }),

          // High-Impact Closing Reconciliation Card (Stitch Design)
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: pdfNavy,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FINAL STATEMENT RECONCILIATION',
                      style: pw.TextStyle(
                        color: pdfOrange,
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'CLOSING BALANCE: ',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(customer.balance),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            fontFallback: _fallbackFonts,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      customer.balance > 0
                          ? 'Settlement pending. Please clear outstanding balance.'
                          : 'Account is settled with zero outstanding balance.',
                      style: const pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: customer.balance > 0 ? pdfOrange : pdfEmerald,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    customer.balance > 0 ? 'PAYMENT PENDING' : 'ACCOUNT SETTLED',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildSignatureBlock(organization: organization),
        ],
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // 3. ALL TRANSACTIONS REPORT PDF
  // ==========================================
  static Future<Uint8List> generateAllTransactionsReport({
    required List<InvoiceTransaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
    BusinessSettings? settings,
    Organization? organization,
  }) async {
    final theme = await _getDocumentTheme();
    final pdf = pw.Document(theme: theme);

    final totalInvoice = transactions.fold(0.0, (sum, t) => sum + t.invoiceAmount);
    final totalPaid = transactions.fold(0.0, (sum, t) => sum + t.paymentReceived);
    final totalBalance = transactions.fold(0.0, (sum, t) => sum + t.newBalance);
    final clearanceRate = totalInvoice > 0 ? (totalPaid / totalInvoice) * 100 : 100.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(
          'Transactions Ledger Report',
          subtitle: 'Records: ${transactions.length} | Invoiced: ${CurrencyFormatter.format(totalInvoice)} | Paid: ${CurrencyFormatter.format(totalPaid)}',
          organization: organization,
        ),
        footer: (context) => _buildFooter(context, organization: organization),
        build: (context) => [
          // 4-Card Stats Grid (Matching Stitch Landscape)
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Sales / Billed',
                  value: CurrencyFormatter.format(totalInvoice),
                  subtitle: '${transactions.length} Total Invoices',
                  isHero: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Collections',
                  value: CurrencyFormatter.format(totalPaid),
                  subtitle: 'Immediate Cash/UPI',
                  isSuccess: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Net Outstanding',
                  value: CurrencyFormatter.format(totalBalance),
                  subtitle: 'Active Ledger Due',
                  isHighlight: totalBalance > 0,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Clearance Rate',
                  value: '${clearanceRate.toStringAsFixed(1)}%',
                  subtitle: 'Collection Ratio',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          _buildSectionTitle(
            'Itemized Ledger Entries',
            badge: '${transactions.length} Records',
            trailingText: 'Sorted Chronologically',
          ),

          // Ledger Table (Stitch Design)
          pw.TableHelper.fromTextArray(
            headers: ['DATE', 'INVOICE #', 'CUSTOMER NAME', 'INVOICE AMT', 'PAID AMT', 'BALANCE', 'STATUS'],
            headerStyle: pw.TextStyle(
              color: pdfSlate,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 8, color: pdfNavyDark, fontFallback: _fallbackFonts),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.center,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.center,
            },
            border: null,
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            data: transactions.map((t) {
              return [
                DateFormatter.formatDate(t.invoiceDate),
                t.invoiceNumber,
                t.customerName,
                CurrencyFormatter.format(t.invoiceAmount),
                CurrencyFormatter.format(t.paymentReceived),
                CurrencyFormatter.format(t.newBalance),
                t.paymentStatus.toUpperCase(),
              ];
            }).toList(),
          ),

          _buildSubtotalsBar({
            'PAGE SUBTOTALS': '${transactions.length} Records',
            'Total Invoiced': CurrencyFormatter.format(totalInvoice),
            'Total Paid': CurrencyFormatter.format(totalPaid),
            'Net Outstanding': CurrencyFormatter.format(totalBalance),
          }),

          _buildSignatureBlock(organization: organization),
        ],
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // 4. CUSTOMER OUTSTANDING REPORT PDF
  // ==========================================
  static Future<Uint8List> generateOutstandingReport({
    required List<Customer> customers,
    BusinessSettings? settings,
    Organization? organization,
  }) async {
    final theme = await _getDocumentTheme();
    final pdf = pw.Document(theme: theme);

    final outstandingList = customers.where((c) => c.balance > 0).toList();
    outstandingList.sort((a, b) => b.balance.compareTo(a.balance));

    final totalOutstanding = outstandingList.fold(0.0, (sum, c) => sum + c.balance);
    final totalInvoicedAll = outstandingList.fold(0.0, (sum, c) => sum + c.totalInvoiced);
    final totalPaidAll = outstandingList.fold(0.0, (sum, c) => sum + c.totalPaid);
    final highestDue = outstandingList.isNotEmpty ? outstandingList.first.balance : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(
          'Outstanding Balance Report',
          subtitle: 'Total Due: ${CurrencyFormatter.format(totalOutstanding)} across ${outstandingList.length} accounts',
          statusPill: '${outstandingList.length} ACCOUNTS',
          statusColor: pdfCrimson,
          statusBgColor: pdfCrimsonLight,
          organization: organization,
        ),
        footer: (context) => _buildFooter(context, organization: organization),
        build: (context) => [
          // 3-Card Stats Grid (Matching Stitch Outstanding Customers)
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Outstanding Due',
                  value: CurrencyFormatter.format(totalOutstanding),
                  subtitle: 'Across ${outstandingList.length} Active Accounts',
                  isHero: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Accounts With Due',
                  value: '${outstandingList.length} Ledgers',
                  subtitle: 'Require Follow-up',
                  isWarning: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Highest Single Due',
                  value: CurrencyFormatter.format(highestDue),
                  subtitle: outstandingList.isNotEmpty ? outstandingList.first.name : '-',
                  isHighlight: true,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          _buildSectionTitle(
            'Outstanding Customers Ledger',
            badge: '${outstandingList.length} Accounts',
            trailingText: 'Sorted by Due (Desc)',
          ),

          // Table: Code, Customer Name, Mobile, Invoiced, Paid, Outstanding Due
          pw.TableHelper.fromTextArray(
            headers: ['CODE', 'CUSTOMER NAME', 'MOBILE', 'TOTAL INVOICED', 'TOTAL PAID', 'OUTSTANDING DUE'],
            headerStyle: pw.TextStyle(
              color: pdfSlate,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7.5,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(
              fontSize: 8.5,
              color: pdfNavyDark,
              fontFallback: _fallbackFonts,
            ),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            border: null,
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            data: outstandingList.isNotEmpty
                ? outstandingList.map((c) {
                    return [
                      c.customerCode.isNotEmpty ? c.customerCode : '-',
                      c.name,
                      c.phone.isNotEmpty ? c.phone : '-',
                      CurrencyFormatter.format(c.totalInvoiced),
                      CurrencyFormatter.format(c.totalPaid),
                      CurrencyFormatter.format(c.balance),
                    ];
                  }).toList()
                : [
                    ['-', 'All customer accounts settled', '-', '₹0.00', '₹0.00', '₹0.00']
                  ],
          ),

          _buildSubtotalsBar({
            'TOTAL OUTSTANDING': CurrencyFormatter.format(totalOutstanding),
            'Accounts': '${outstandingList.length}',
            'Total Invoiced': CurrencyFormatter.format(totalInvoicedAll),
            'Total Paid': CurrencyFormatter.format(totalPaidAll),
          }),

          _buildSignatureBlock(organization: organization),
        ],
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // 5. SALESMAN REPORT PDF
  // ==========================================
  static Future<Uint8List> generateSalesmanReport({
    required List<Salesman> salesmen,
    BusinessSettings? settings,
    Organization? organization,
  }) async {
    final theme = await _getDocumentTheme();
    final pdf = pw.Document(theme: theme);

    final totalSales = salesmen.fold(0.0, (sum, s) => sum + s.totalSales);
    final totalCollected = salesmen.fold(0.0, (sum, s) => sum + s.totalCollected);
    final totalOutstanding = salesmen.fold(0.0, (sum, s) => sum + s.outstandingBalance);
    final totalTxCount = salesmen.fold(0, (sum, s) => sum + s.transactionCount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(
          'Salesman Performance Report',
          subtitle: 'Active Staff Records: ${salesmen.length}',
          organization: organization,
        ),
        footer: (context) => _buildFooter(context, organization: organization),
        build: (context) => [
          // 4-Card Stats Grid (Matching Stitch Salesman Performance)
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Sales Generated',
                  value: CurrencyFormatter.format(totalSales),
                  subtitle: 'Gross Generated Value',
                  isHero: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Collections',
                  value: CurrencyFormatter.format(totalCollected),
                  subtitle: 'Recovered Inflow',
                  isSuccess: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Pending Due',
                  value: CurrencyFormatter.format(totalOutstanding),
                  subtitle: 'Unsettled Balance',
                  isHighlight: totalOutstanding > 0,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Team Activity',
                  value: '${salesmen.length} Reps',
                  subtitle: '$totalTxCount Total Invoices',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          _buildSectionTitle(
            'Salesman Performance Ledger',
            badge: '${salesmen.length} Field Reps',
            trailingText: 'Ranked by Total Sales Volume',
          ),

          // Table (Stitch Design)
          pw.TableHelper.fromTextArray(
            headers: ['SALESMAN', 'MOBILE', 'TOTAL SALES', 'COLLECTED', 'OUTSTANDING', 'TX COUNT'],
            headerStyle: pw.TextStyle(
              color: pdfSlate,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7.5,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 8.5, color: pdfNavyDark, fontFallback: _fallbackFonts),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            border: null,
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            data: salesmen.map((s) {
              return [
                s.name,
                s.phone.isNotEmpty ? s.phone : '-',
                CurrencyFormatter.format(s.totalSales),
                CurrencyFormatter.format(s.totalCollected),
                CurrencyFormatter.format(s.outstandingBalance),
                s.transactionCount.toString(),
              ];
            }).toList(),
          ),

          _buildSubtotalsBar({
            'CUMULATIVE TOTALS': '${salesmen.length} Reps',
            'Total Sales': CurrencyFormatter.format(totalSales),
            'Collected': CurrencyFormatter.format(totalCollected),
            'Outstanding': CurrencyFormatter.format(totalOutstanding),
          }),

          _buildSignatureBlock(organization: organization),
        ],
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // 6. DAILY SALES REPORT PDF
  // ==========================================
  static Future<Uint8List> generateDailySalesReport({
    required DateTime reportDate,
    required List<InvoiceTransaction> transactions,
    required List<PaymentRecord> payments,
    BusinessSettings? settings,
    Organization? organization,
  }) async {
    final theme = await _getDocumentTheme();
    final pdf = pw.Document(theme: theme);

    final totalSales = transactions.fold(0.0, (sum, t) => sum + t.invoiceAmount);
    final totalCollections = payments.fold(0.0, (sum, p) => sum + p.amount);
    final netDaily = totalSales - totalCollections;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(
          'Daily Sales & Collections',
          subtitle: 'Date: ${DateFormatter.formatDate(reportDate)} | Invoiced: ${CurrencyFormatter.format(totalSales)} | Collected: ${CurrencyFormatter.format(totalCollections)}',
          organization: organization,
        ),
        footer: (context) => _buildFooter(context, organization: organization),
        build: (context) => [
          // 3-Card Stats Grid (Matching Stitch Daily Sales)
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Today Gross Sales',
                  value: CurrencyFormatter.format(totalSales),
                  subtitle: '${transactions.length} Invoices Generated',
                  isHero: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Today Collections',
                  value: CurrencyFormatter.format(totalCollections),
                  subtitle: '${payments.length} Receipts Collected',
                  isSuccess: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Net Daily Change',
                  value: CurrencyFormatter.format(netDaily),
                  subtitle: netDaily > 0 ? 'Credit Extended' : 'Net Liquidation',
                  isHighlight: netDaily > 0,
                  isSuccess: netDaily <= 0,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          _buildSectionTitle(
            'Daily Transaction Register',
            badge: '${transactions.length} Invoices',
          ),

          pw.TableHelper.fromTextArray(
            headers: ['INVOICE NO', 'CUSTOMER', 'AMOUNT', 'PAID DOWN', 'BALANCE'],
            headerStyle: pw.TextStyle(
              color: pdfSlate,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7.5,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 8, color: pdfNavyDark, fontFallback: _fallbackFonts),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            border: null,
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            data: transactions.map((t) => [
              t.invoiceNumber,
              t.customerName,
              CurrencyFormatter.format(t.invoiceAmount),
              CurrencyFormatter.format(t.paymentReceived),
              CurrencyFormatter.format(t.newBalance),
            ]).toList(),
          ),
          pw.SizedBox(height: 16),

          _buildSectionTitle(
            'Collections Received Today',
            badge: '${payments.length} Receipts',
          ),

          pw.TableHelper.fromTextArray(
            headers: ['TIME / DATE', 'CUSTOMER', 'AMOUNT', 'METHOD'],
            headerStyle: pw.TextStyle(
              color: pdfSlate,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7.5,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 8, color: pdfNavyDark, fontFallback: _fallbackFonts),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
            },
            border: null,
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            data: payments.map((p) => [
              DateFormatter.formatDate(p.paymentDate),
              p.customerName,
              CurrencyFormatter.format(p.amount),
              p.paymentMethod,
            ]).toList(),
          ),

          _buildSubtotalsBar({
            'TOTAL DAY AGGREGATE': DateFormatter.formatDate(reportDate),
            'Invoiced': CurrencyFormatter.format(totalSales),
            'Collected': CurrencyFormatter.format(totalCollections),
          }),

          _buildSignatureBlock(organization: organization),
        ],
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // 7. PAYMENT COLLECTION REPORT PDF
  // ==========================================
  static Future<Uint8List> generatePaymentCollectionReport({
    required List<PaymentRecord> payments,
    DateTime? startDate,
    DateTime? endDate,
    BusinessSettings? settings,
    Organization? organization,
  }) async {
    final theme = await _getDocumentTheme();
    final pdf = pw.Document(theme: theme);

    final totalCollected = payments.fold(0.0, (sum, p) => sum + p.amount);
    final cashTotal = payments.where((p) => p.paymentMethod.toLowerCase() == 'cash').fold(0.0, (sum, p) => sum + p.amount);
    final digitalTotal = totalCollected - cashTotal;
    final cashCount = payments.where((p) => p.paymentMethod.toLowerCase() == 'cash').length;
    final digitalCount = payments.length - cashCount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(
          'Payment Collection Report',
          subtitle: 'Total Collections: ${CurrencyFormatter.format(totalCollected)} across ${payments.length} receipts',
          organization: organization,
        ),
        footer: (context) => _buildFooter(context, organization: organization),
        build: (context) => [
          // 4-Card Stats Grid (Matching Stitch Payment Collection)
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Collected',
                  value: CurrencyFormatter.format(totalCollected),
                  subtitle: '${payments.length} Receipts Processed',
                  isHero: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Cash Receipts',
                  value: CurrencyFormatter.format(cashTotal),
                  subtitle: '$cashCount Cash Payments',
                  isSuccess: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Digital / Bank',
                  value: CurrencyFormatter.format(digitalTotal),
                  subtitle: '$digitalCount Online Transfers',
                  isHighlight: true,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildStatCard(
                  label: 'Total Receipts',
                  value: '${payments.length}',
                  subtitle: 'Verified Ledger Entries',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          _buildSectionTitle(
            'Detailed Collection Ledger',
            badge: '${payments.length} Entries',
            trailingText: 'Currency: INR (\u20b9)',
          ),

          // Table (Stitch Design)
          pw.TableHelper.fromTextArray(
            headers: ['DATE', 'CUSTOMER', 'AMOUNT', 'METHOD', 'NOTES / REF'],
            headerStyle: pw.TextStyle(
              color: pdfSlate,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7.5,
              letterSpacing: 0.5,
              fontFallback: _fallbackFonts,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 8.5, color: pdfNavyDark, fontFallback: _fallbackFonts),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
            },
            border: null,
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(
              color: pdfSurfaceLow,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            data: payments.map((p) {
              return [
                DateFormatter.formatDate(p.paymentDate),
                p.customerName,
                CurrencyFormatter.format(p.amount),
                p.paymentMethod,
                p.notes.isNotEmpty ? p.notes : '-',
              ];
            }).toList(),
          ),

          _buildSubtotalsBar({
            'LEDGER SUBTOTAL': '${payments.length} Receipts',
            'Cash': CurrencyFormatter.format(cashTotal),
            'Digital': CurrencyFormatter.format(digitalTotal),
            'Total': CurrencyFormatter.format(totalCollected),
          }),

          _buildSignatureBlock(organization: organization),
        ],
      ),
    );

    return pdf.save();
  }
}
