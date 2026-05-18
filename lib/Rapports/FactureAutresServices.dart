import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Page d'aperçu pour les factures de services auxiliaires
class FactureAutresServicesPreviewPage extends StatelessWidget {
  final Map<String, dynamic> entreprise;
  final Map<String, dynamic> facture;

  const FactureAutresServicesPreviewPage({
    super.key,
    required this.entreprise,
    required this.facture,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aperçu Facture Service"),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
      ),
      body: PdfPreview(
        build: (format) async {
          final pdf = await buildAutresServicesDocument(entreprise, facture);
          return pdf.save();
        },
        allowPrinting: true,
        allowSharing: true,
        initialPageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
      ),
    );
  }
}

Future<void> generateThermalFacturePDF(
    Map<String, dynamic> entreprise,
    Map<String, dynamic> factureServices,
) async {
  final pdf = await buildAutresServicesDocument(entreprise, factureServices);
  final docName = 'facture_${factureServices["idFacturationAutresServices"] ?? DateTime.now().millisecondsSinceEpoch}';
  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: docName);
}

Future<pw.Document> buildAutresServicesDocument(
    Map<String, dynamic> entreprise,
    Map<String, dynamic> factureServices,
) async {
  final pdf = pw.Document();

  // Chargement optimisé du logo
  final logoImage = await networkImage(entreprise["logo_path"]);

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
  return pdf;
}