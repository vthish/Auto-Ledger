import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndPrintReceipt(Map<String, dynamic> fine) async {
    final pdf = pw.Document();

    final totalAmount = fine['amount'] ?? 0.0;
    final fineId = fine['id'] ?? 'N/A';
    final issueDate = fine['date'] ?? DateTime.now().toIso8601String();
    final officer = fine['officer'] ?? 'Unknown Officer';
    final offenses = fine['offenses'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'AUTO-LEDGER',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Payment Receipt',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt ID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('#${fineId.substring(0, 8).toUpperCase()}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatDate(issueDate)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('OFFICER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(officer),
              pw.SizedBox(height: 20),
              pw.Text('OFFENSES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...offenses.map((o) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${o['code']} - ${o['name']}'),
                    pw.Text('+${o['points']} pts'),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL AMOUNT',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                  pw.Text(
                    'Rs. ${totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.green700),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Thank you for paying your traffic fine.',
                  style: pw.TextStyle(color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '---';
    }
  }
}