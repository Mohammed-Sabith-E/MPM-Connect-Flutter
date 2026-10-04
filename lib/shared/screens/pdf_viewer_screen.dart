import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() pdfGenerator;
  final String filename;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfGenerator,
    this.filename = 'mpm_document.pdf',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Document',
            onPressed: () async {
              final bytes = await pdfGenerator();
              await Printing.sharePdf(bytes: bytes, filename: filename);
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: () async {
              final bytes = await pdfGenerator();
              await Printing.layoutPdf(onLayout: (_) => bytes, name: filename);
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: const Border(top: BorderSide(color: AppColors.hairlineBorder)),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyContainer,
                    side: const BorderSide(color: AppColors.hairlineBorder),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final bytes = await pdfGenerator();
                    await Printing.layoutPdf(onLayout: (_) => bytes, name: filename);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share PDF / WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amberContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final bytes = await pdfGenerator();
                    await Printing.sharePdf(bytes: bytes, filename: filename);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: PdfPreview(
        build: (format) => pdfGenerator(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        dynamicLayout: false,
        pdfFileName: filename,
        previewPageMargin: const EdgeInsets.all(16),
        actions: const [], // We use our styled App Bar & bottom actions
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: AppColors.navyPrimary),
        ),
      ),
    );
  }
}
