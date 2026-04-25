import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'dart:convert';

Future<void> generateThermalFacturePDF(
    Map<String, dynamic> entreprise,
    Map<String, dynamic> factureServices,
) async {
  final pdf = pw.Document();

  // Charger le logo
  final logoResponse = await http.get(Uri.parse(entreprise["logo_path"]));
  final logoImage = pw.MemoryImage(logoResponse.bodyBytes);

  final montant = num.tryParse(factureServices["MontantPayer"].toString()) ?? 0.0;
  final designation = factureServices["designationSectionAuxi"] ?? "";

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Image(logoImage, width: 40, height: 40)),
            pw.Center(
              child: pw.Text(
                entreprise["Denomination"],
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(child: pw.Text("RCCM: ${entreprise["Numero_RCCM"]}")),
            pw.Center(child: pw.Text("Adresse: ${entreprise["Adresse"]}")),
            pw.Center(child: pw.Text("Tel: ${entreprise["Telephone"]}")),
            pw.Center(child: pw.Text("Email: ${entreprise["Email"]}")),
            pw.SizedBox(height: 10),

            pw.Text("Facture N° ${factureServices["idFacturationAutresServices"]  ??""}",
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text("Date: ${factureServices["dateFacturation"]  ??""}"),
            pw.Text("Client: ${factureServices["client_name"]  ??""}"),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Text("Service", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Montant", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Text(designation, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("${montant.toStringAsFixed(2)} \$", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total TTC", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text("${montant.toStringAsFixed(2)} \$", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Center(
              child: pw.Text(
                "Merci de votre confiance !",
                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        );
      },
    ),
  );

  // ✅ Aperçu avant impression
  await Printing.sharePdf(bytes: await pdf.save(), filename: 'facture.pdf');
}