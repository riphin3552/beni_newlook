import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Page d'aperçu pour les factures logements avec taxes
class FactureLogementsPreviewPage extends StatelessWidget {
  final Map<String, dynamic> entreprise;
  final Map<String, dynamic> facture;

  const FactureLogementsPreviewPage({
    super.key,
    required this.entreprise,
    required this.facture,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aperçu Facture Logement"),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
      ),
      body: PdfPreview(
        build: (format) async {
          final pdf = await buildFactureLogementDocument(entreprise, facture);
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
    Map<String, dynamic> factureLogement,
) async {
  final pdf = await buildFactureLogementDocument(entreprise, factureLogement);
  final docName = 'facture_${factureLogement["IdFacture"] ?? DateTime.now().millisecondsSinceEpoch}';
  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: docName);
}

Future<pw.Document> buildFactureLogementDocument(
    Map<String, dynamic> entreprise,
    Map<String, dynamic> factureLogement,
) async {
  final pdf = pw.Document();

  // Chargement du logo
  final logoImage = await networkImage(entreprise["logo_path"]);

  final espaceChambre = factureLogement["designationEspace"] ?? "";
  final dateArrivee = factureLogement["DateArrivee"] ?? "";
  final dateDepart = factureLogement["DateDepart"] ?? "";
  final montant = num.tryParse(factureLogement["Totalpayer"].toString()) ?? 0.0;

  // Champs supplémentaires (non complétés)
  final tva = 0.0;      // TVA 16%
  final cite = 0.0;     // Cite 5%
  final fpt = 0.0;      // FPT 5%
  final service = 0.0;  // Service 10%

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logoImage, width: 35, height: 35),
            pw.Text(
              entreprise["Denomination"],
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text("RCCM: ${entreprise["Numero_RCCM"]}", style: const pw.TextStyle(fontSize: 8)),
            pw.Text("Adresse: ${entreprise["Adresse"]}", style: const pw.TextStyle(fontSize: 8)),
            pw.Text("Tel: ${entreprise["Telephone"]}", style: const pw.TextStyle(fontSize: 8)),
            pw.Text("Email: ${entreprise["Email"]}", style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 8),

            pw.Text("Facture N° ${factureLogement["IdFacture"] ?? ""}",
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text("Date_facture: ${factureLogement["dateFacturation"] ?? ""}", style: const pw.TextStyle(fontSize: 8)),
            pw.Text("Client: ${factureLogement["client_name"] ?? ""}", style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 8),

            // Tableau logement
            pw.Table(
              border: pw.TableBorder.all(width: 0.3),
              defaultColumnWidth: const pw.FlexColumnWidth(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text("Espace", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text("Arrivée", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text("Départ", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text("Montant", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Center(child: pw.Text(espaceChambre, style: const pw.TextStyle(fontSize: 8))),
                    pw.Center(child: pw.Text("$dateArrivee", style: const pw.TextStyle(fontSize: 8))),
                    pw.Center(child: pw.Text("$dateDepart", style: const pw.TextStyle(fontSize: 8))),
                    pw.Center(child: pw.Text("${montant.toStringAsFixed(2)} \$", style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Tableau taxes + total
            pw.Table(
              border: pw.TableBorder.all(width: 0.3),
              defaultColumnWidth: const pw.FlexColumnWidth(),
              children: [
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("TVA (16%)", style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("$tva \$", style: const pw.TextStyle(fontSize: 8)),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("Cite (5%)", style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("$cite \$", style: const pw.TextStyle(fontSize: 8)),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("FPT (5%)", style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("$fpt \$", style: const pw.TextStyle(fontSize: 8)),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("Service (10%)", style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("$service \$", style: const pw.TextStyle(fontSize: 8)),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("Total TTC", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text("${montant.toStringAsFixed(2)} \$", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                ]),
              ],
            ),
            pw.SizedBox(height: 15),

            pw.Text(
              "Merci pour votre confiance !",
              style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      },
    ),
  );
  return pdf;
}


