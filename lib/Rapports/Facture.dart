import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'dart:convert';

Future<void> generateThermalFacturePDF(
    Map<String, dynamic> entreprise,
    Map<String, dynamic> facture,
) async {
  final pdf = pw.Document();

  // Charger le logo
  final logoResponse = await http.get(Uri.parse(entreprise["logo_path"]));
  final logoImage = pw.MemoryImage(logoResponse.bodyBytes);

  final details = (facture["detailsProduits"] ?? []) as List<dynamic>;
  print("objects details: $details"); // Debug: afficher les détails de la facture
  final totalTTC = details.fold(
    0.0,
    (sum, d) => sum + (num.tryParse(d["totalPayer"].toString()) ?? 0),
  );

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

            pw.Text("Facture N° ${facture["IdFacture"]  ??""}",
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text("Date: ${facture["datecommande"]  ??""}"),
            pw.Text("Client: ${facture["client_name"]  ??""}"),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Text("Produit", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Qté", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("PU", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Total", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                ...details.map((item) => pw.TableRow(
                  children: [
                    pw.Text(item["designationProduit"], style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(item["Quantite"].toString(), style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(item["prixUnitiare"].toString(), style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(item["totalPayer"].toString(), style: const pw.TextStyle(fontSize: 10)),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 10),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Total TTC: $totalTTC",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),

            pw.Center(
              child: pw.Text(
                "Une marchandise vendue ne peut ni être remise ni échangée",
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