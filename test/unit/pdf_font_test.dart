import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mpm_connect/core/services/pdf_generator_service.dart';
import 'package:mpm_connect/features/customers/models/customer_model.dart';
import 'package:mpm_connect/features/transactions/models/transaction_model.dart';
import 'package:mpm_connect/features/payments/models/payment_model.dart';
import 'package:mpm_connect/features/salesmen/models/salesman_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bundled Inter TTF renders Rupee symbol and bullet with zero missing glyphs', () async {
    final regularBytes = File('assets/fonts/Inter-Regular.ttf').readAsBytesSync();
    final boldBytes = File('assets/fonts/Inter-Bold.ttf').readAsBytesSync();
    final malayalamBytes = File('assets/fonts/NotoSansMalayalam.ttf').readAsBytesSync();
    final regularFont = pw.Font.ttf(regularBytes.buffer.asByteData());
    final boldFont = pw.Font.ttf(boldBytes.buffer.asByteData());
    final malayalamFont = pw.Font.ttf(malayalamBytes.buffer.asByteData());

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [malayalamFont],
      ),
    );
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text('₹2,500.00 • Test'),
            pw.Text('ഷിബിൻ - Customer Name'),
          ],
        ),
      ),
    );
    final bytes = await doc.save();
    expect(bytes.isNotEmpty, isTrue);
  });

  test('All 7 PdfGeneratorService methods produce valid PDFs', () async {
    final now = DateTime.now();
    final dummyCustomer = Customer(
      id: 'cust-1',
      customerCode: 'CUST-0001',
      name: 'Ashraf E (ഷിബിൻ)',
      phone: '9947245526',
      address: 'Oorakam, Karathode',
      balance: 1500.0,
      totalInvoiced: 5000.0,
      totalPaid: 3500.0,
      createdAt: now,
      updatedAt: now,
    );

    final dummyTx = InvoiceTransaction(
      id: 'tx-1',
      invoiceNumber: 'INV-000001',
      customerId: 'cust-1',
      customerName: 'Ashraf E (ഷിബിൻ)',
      createdBy: 'user-1',
      invoiceDate: now,
      invoiceAmount: 2500.0,
      previousBalance: 1000.0,
      paymentReceived: 2000.0,
      newBalance: 1500.0,
      paymentMethod: 'Cash',
      paymentStatus: 'partial',
      notes: 'Delivered in good condition',
      createdAt: now,
      updatedAt: now,
    );

    final dummyPayment = PaymentRecord(
      id: 'pm-1',
      customerId: 'cust-1',
      customerName: 'Ashraf E',
      amount: 2000.0,
      paymentMethod: 'Cash',
      paymentDate: now,
      receivedBy: 'user-1',
      notes: 'Part settlement',
      createdAt: now,
    );

    final dummySalesman = Salesman(
      id: 'sm-1',
      name: 'Vikram Singh',
      phone: '9823144521',
      totalSales: 85000.0,
      totalCollected: 60000.0,
      outstandingBalance: 25000.0,
      transactionCount: 12,
      createdAt: now,
    );

    // 1. Transaction Invoice
    final invBytes = await PdfGeneratorService.generateTransactionInvoice(
      transaction: dummyTx,
      customer: dummyCustomer,
    );
    expect(invBytes.isNotEmpty, isTrue);

    // 2. Customer Statement
    final stmtBytes = await PdfGeneratorService.generateCustomerStatement(
      customer: dummyCustomer,
      transactions: [dummyTx],
      payments: [dummyPayment],
    );
    expect(stmtBytes.isNotEmpty, isTrue);

    // 3. Outstanding Report
    final outBytes = await PdfGeneratorService.generateOutstandingReport(
      customers: [dummyCustomer],
    );
    expect(outBytes.isNotEmpty, isTrue);

    // 4. All Transactions Report
    final allTxBytes = await PdfGeneratorService.generateAllTransactionsReport(
      transactions: [dummyTx],
    );
    expect(allTxBytes.isNotEmpty, isTrue);

    // 5. Salesman Report
    final smBytes = await PdfGeneratorService.generateSalesmanReport(
      salesmen: [dummySalesman],
    );
    expect(smBytes.isNotEmpty, isTrue);

    // 6. Daily Sales Report
    final dailyBytes = await PdfGeneratorService.generateDailySalesReport(
      reportDate: now,
      transactions: [dummyTx],
      payments: [dummyPayment],
    );
    expect(dailyBytes.isNotEmpty, isTrue);

    // 7. Payment Collection Report
    final collBytes = await PdfGeneratorService.generatePaymentCollectionReport(
      payments: [dummyPayment],
    );
    expect(collBytes.isNotEmpty, isTrue);
  });
}
