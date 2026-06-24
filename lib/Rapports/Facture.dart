import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

const Color _primaryColor = Color.fromARGB(255, 121, 169, 240);
const Color _lightGrey = Color.fromARGB(255, 245, 248, 255);

class FacturePreviewPage extends StatelessWidget {
  final Map<String, dynamic> entreprise;
  final Map<String, dynamic> facture;

  const FacturePreviewPage({
    super.key,
    required this.entreprise,
    required this.facture,
  });

  @override
  Widget build(BuildContext context) {
    final details = (facture["detailsProduits"] ?? []) as List<dynamic>;
    final totalTTC = details.fold(
      0.0,
      (sum, d) => sum + (num.tryParse(d["totalPayer"].toString()) ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prévisualisation Facture"),
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 2,
      ),
      backgroundColor: _lightGrey,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Facture N° ${facture['IdFacture'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Client: ${facture['client_name'] ?? 'N/A'}",
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              border: Border.all(color: _primaryColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Montant Total TTC",
                                  style: TextStyle(fontSize: 11, color: _primaryColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${totalTTC.toStringAsFixed(2)} USD",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildInfoField(
                              "Date Commande",
                              facture['datecommande']?.toString().split(' ')[0] ?? 'N/A',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoField(
                              "Statut",
                              facture['statutcommande']?.toString() ?? 'Facturée',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Produits (${details.length})",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: details.length,
                        itemBuilder: (context, index) {
                          final item = details[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['designationProduit']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                Text(
                                  'Qté: ${item['Quantite']}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  '${item['totalPayer']} USD',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Prévisualisation PDF",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        height: 600,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: PdfPreview(
                            build: (format) async {
                              final pdf = await buildFactureDocument(entreprise, facture);
                              return pdf.save();
                            },
                            allowPrinting: true,
                            allowSharing: true,
                            pdfFileName: "facture_${facture['IdFacture']}.pdf",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

Future<void> generateThermalFacturePDF(
    Map<String, dynamic> entreprise,
    Map<String, dynamic> facture,
) async {
  final pdf = await buildFactureDocument(entreprise, facture);
  final docName = 'facture_${facture["IdFacture"] ?? DateTime.now().millisecondsSinceEpoch}';
  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: docName);
}

Future<pw.Document> buildFactureDocument(
    Map<String, dynamic> entreprise,
    Map<String, dynamic> facture,
) async {
  final pdf = pw.Document();
  final fontBold = await PdfGoogleFonts.robotoBold();

  dynamic logoImage;
  try {
    final logoUrl = (entreprise["logo_path"] ?? '') as String;
    if (logoUrl.isNotEmpty) logoImage = await flutterImageProvider(NetworkImage(logoUrl));
  } catch (e) {
    logoImage = null;
  }

  final details = (facture["detailsProduits"] ?? []) as List<dynamic>;
  final totalTTC = details.fold(
    0.0,
    (sum, d) => sum + (num.tryParse(d["totalPayer"].toString()) ?? 0),
  );
  final dateFacturation = facture["datecommande"]?.toString().split(' ')[0] ?? "";
  final numRefSolide = "FAC/${facture['IdFacture']}/$dateFacturation";

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
      margin: const pw.EdgeInsets.all(8),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null)
              pw.Container(
                height: 40,
                width: 40,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('1F3A93'), width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            pw.SizedBox(height: 6),
            pw.Text(
              entreprise['Denomination'] ?? 'ENTREPRISE',
              style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('1F3A93')),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 3),
            pw.Text("RCCM: ${entreprise['Numero_RCCM'] ?? ''}", style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
            pw.Text("ID Nat: ${entreprise['ID_national'] ?? ''}", style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
            pw.Text("N° Impôt: ${entreprise['Numero_impot'] ?? ''}", style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
            pw.Text("Adr: ${entreprise['Adresse'] ?? ''}", style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
            pw.Text("Tel: ${entreprise['Telephone'] ?? ''}", style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
            pw.Text("Email: ${entreprise['Email'] ?? ''}", style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 6),

            pw.Container(height: 1, color: PdfColor.fromHex('1F3A93')),
            pw.SizedBox(height: 6),

            pw.Text(
              'FACTURE VENTE',
              style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColor.fromHex('1F3A93')),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E8F0FF'),
                border: pw.Border.all(color: PdfColor.fromHex('1F3A93'), width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('TOTAL TTC:', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                  pw.Text(
                    '${totalTTC.toStringAsFixed(2)} USD',
                    style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColor.fromHex('1F3A93')),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('D0D0D0'), width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildThermalInfoLine("N° Fact:", facture['IdFacture']?.toString() ?? 'N/A'),
                  _buildThermalInfoLine("Date:", dateFacturation),
                  _buildThermalInfoLine("Client:", facture['client_name']?.toString() ?? 'N/A'),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('D0D0D0'), width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('E0E0E0'), width: 0.3),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('F5F5F5')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('ARTICLE', style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColor.fromHex('1F3A93'))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('QTÉ', style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColor.fromHex('1F3A93')), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColor.fromHex('1F3A93')), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  ...details.map((item) => pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(item['designationProduit']?.toString() ?? '', style: const pw.TextStyle(fontSize: 7), maxLines: 2, overflow: pw.TextOverflow.clip),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(item['Quantite']?.toString() ?? '', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('${item['totalPayer']}', style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
                    ),
                  ])),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('E8F0FF')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('1F3A93')),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('1F3A93'))),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          '${totalTTC.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('1F3A93')),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),

            pw.Container(height: 1, color: PdfColor.fromHex('1F3A93')),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Une marchandise vendue ne peut ni être',
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Center(
              child: pw.Text(
                'remise ni échangée',
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'Généré le: ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf;
}

pw.Widget _buildThermalInfoLine(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 35,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 7), maxLines: 2, overflow: pw.TextOverflow.clip),
        ),
      ],
    ),
  );
}

Future<void> showFacturePreviewDialog(
  BuildContext context,
  Map<String, dynamic> entreprise,
  Map<String, dynamic> facture,
) async {
  final pdf = await buildFactureDocument(entreprise, facture);
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Prévisualisation Facture'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: PdfPreview(
          build: (format) => pdf.save(),
          allowPrinting: true,
          allowSharing: true,
          pdfFileName: "facture_${facture['IdFacture']}.pdf",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}