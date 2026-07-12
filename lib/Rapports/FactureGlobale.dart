import 'package:flutter/material.dart' show NetworkImage;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildFactureGlobaleDocument(
  Map<String, dynamic> entreprise,
  Map<String, dynamic> factureData,
) async {
  final pdf = pw.Document();
  final fontBold = await PdfGoogleFonts.robotoBold();
  final fontRegular = await PdfGoogleFonts.robotoRegular();

  dynamic logoImage;
  try {
    final logoUrl = (entreprise['logo_path'] ?? '') as String;
    if (logoUrl.isNotEmpty) {
      logoImage = await flutterImageProvider(NetworkImage(logoUrl));
    }
  } catch (_) {
    logoImage = null;
  }

  final client = (factureData['client'] as Map?)?.cast<String, dynamic>() ?? {};
  final logements = (factureData['logement'] as List?) ?? [];
  final autresServices = (factureData['autres_services'] as List?) ?? [];
  final restaurant = (factureData['restaurant'] as List?) ?? [];
  final totaux = (factureData['totaux'] as Map?)?.cast<String, dynamic>() ?? {};

  final totalLogement =
      (num.tryParse(totaux['totalLogement']?.toString() ?? '0') ?? 0).toDouble();
  final totalServices =
      (num.tryParse(totaux['totalAutresServices']?.toString() ?? '0') ?? 0).toDouble();
  final totalRestaurant =
      (num.tryParse(totaux['totalRestaurant']?.toString() ?? '0') ?? 0).toDouble();
  final totalGeneral = totalLogement + totalServices + totalRestaurant;

  final totalAcompte =
      (num.tryParse(totaux['totalAcompte']?.toString() ?? '0') ?? 0).toDouble();
  const report = 0.0;
  final totalJournalier = totalGeneral; // taxes laissées vides → égal au 1er Total
  final totalCumule = totalJournalier + report;
  final netAPayer = totalCumule - totalAcompte;

  final bleu = PdfColor.fromHex('1F3A93');
  final bleuClair = PdfColor.fromHex('E8F0FF');
  final grisLeger = PdfColor.fromHex('F5F5F5');
  final grisLigne = PdfColor.fromHex('E0E0E0');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context ctx) => [
        // ── EN-TÊTE HÔTEL ────────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                height: 60,
                width: 60,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    entreprise['Denomination'] ?? 'HOTEL BENI-NEW LOOK',
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 14, color: bleu),
                  ),
                  pw.Text(
                    'Bar - Restaurant',
                    style: pw.TextStyle(font: fontBold, fontSize: 9, color: bleu),
                  ),
                  pw.SizedBox(height: 3),
                  if ((entreprise['ID_national'] ?? '').toString().isNotEmpty)
                    pw.Text('N° IDENT: ${entreprise['ID_national']}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                  if ((entreprise['Numero_RCCM'] ?? '').toString().isNotEmpty)
                    pw.Text('RCCM: ${entreprise['Numero_RCCM']}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                  if ((entreprise['Adresse'] ?? '').toString().isNotEmpty)
                    pw.Text(entreprise['Adresse'].toString(),
                        style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                  if ((entreprise['Telephone'] ?? '').toString().isNotEmpty)
                    pw.Text('Tél: ${entreprise['Telephone']}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                  if ((entreprise['Email'] ?? '').toString().isNotEmpty)
                    pw.Text('E-mail: ${entreprise['Email']}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                ],
              ),
            ),
            // Badge FACTURE
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: bleu, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('FACTURE',
                      style: pw.TextStyle(font: fontBold, fontSize: 12, color: bleu)),
                  pw.Text(
                    'N° ${DateTime.now().millisecondsSinceEpoch % 10000}',
                    style: pw.TextStyle(font: fontBold, fontSize: 10, color: bleu),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.5, color: bleu),
        pw.SizedBox(height: 10),

        // ── INFO CLIENT ──────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: bleuClair,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Monsieur / Madame :',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: bleu)),
                    pw.Text(client['client_name']?.toString() ?? '',
                        style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    if ((client['phone_number'] ?? '').toString().isNotEmpty)
                      pw.Text('Tél: ${client['phone_number']}',
                          style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                  ],
                ),
              ),
              if (logements.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Chambre / Espace :',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: bleu)),
                    pw.Text(
                      logements.first['designationEspace']?.toString() ?? '',
                      style: pw.TextStyle(font: fontBold, fontSize: 11),
                    ),
                    pw.Text(
                      '${logements.first['DateArrivee'] ?? ''} → ${logements.first['DateDepart'] ?? ''}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8),
                    ),
                  ],
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),

        // ── TABLEAU LOGEMENT ─────────────────────────────────────────────
        if (logements.isNotEmpty) ...[
          _sectionTitle(fontBold, bleu, 'LOGEMENT'),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: grisLigne, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableHeader(fontBold, bleu, grisLeger,
                  ['Chambre / Espace', 'Arrivée', 'Départ', 'Montant (USD)']),
              for (final l in logements)
                pw.TableRow(children: [
                  _cell(fontRegular, l['designationEspace']?.toString() ?? ''),
                  _cell(fontRegular, l['DateArrivee']?.toString() ?? ''),
                  _cell(fontRegular, l['DateDepart']?.toString() ?? ''),
                  _cellRight(fontBold, _fmt(l['Totalpayer'])),
                ]),
              _totalRow4(fontBold, bleuClair, bleu, 'Sous-total Logement',
                  _fmt(totalLogement)),
            ],
          ),
          pw.SizedBox(height: 12),
        ],

        // ── TABLEAU AUTRES SERVICES ───────────────────────────────────────
        if (autresServices.isNotEmpty) ...[
          _sectionTitle(fontBold, bleu, 'AUTRES SERVICES'),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: grisLigne, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableHeader(fontBold, bleu, grisLeger,
                  ['Service', 'Date', 'Montant (USD)']),
              for (final s in autresServices)
                pw.TableRow(children: [
                  _cell(fontRegular,
                      s['designationSectionAuxi']?.toString() ?? ''),
                  _cell(fontRegular,
                      s['dateFacturation']?.toString().split(' ')[0] ?? ''),
                  _cellRight(fontBold, _fmt(s['MontantPayer'])),
                ]),
              _totalRow3(fontBold, bleuClair, bleu, 'Sous-total Services',
                  _fmt(totalServices)),
            ],
          ),
          pw.SizedBox(height: 12),
        ],

        // ── TABLEAU RESTAURANT / BAR ──────────────────────────────────────
        if (restaurant.isNotEmpty) ...[
          _sectionTitle(fontBold, bleu, 'RESTAURANT / BAR'),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: grisLigne, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableHeader(fontBold, bleu, grisLeger,
                  ['Section', 'Date', 'Montant (USD)']),
              for (final r in restaurant)
                pw.TableRow(children: [
                  _cell(fontRegular, r['nomSection']?.toString() ?? 'Restaurant'),
                  _cell(fontRegular,
                      r['datecommande']?.toString().split(' ')[0] ?? ''),
                  _cellRight(fontBold, _fmt(r['totalFacture'])),
                ]),
              _totalRow3(fontBold, bleuClair, bleu, 'Sous-total Restaurant',
                  _fmt(totalRestaurant)),
            ],
          ),
          pw.SizedBox(height: 14),
        ],

        // ── RÉCAPITULATIF TAXES ───────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: pw.SizedBox()),
            pw.SizedBox(
              width: 220,
              child: pw.Table(
                border: pw.TableBorder.all(color: grisLigne, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  _recapRow(fontRegular, '1er Total', _fmt(totalGeneral)),
                  _recapRow(fontRegular, 'T.V.A  16%', ''),
                  _recapRow(fontRegular, 'Cité    5%', ''),
                  _recapRow(fontRegular, 'F.P.T  5%', ''),
                  _recapRow(fontRegular, 'Service 10%', ''),
                  _totalRow2(fontBold, bleuClair, bleu, 'TOTAL JOURNALIER', _fmt(totalJournalier)),
                  _recapRow(fontRegular, 'Report', _fmt(report)),
                  _recapRow(fontRegular, 'Acompte', _fmt(totalAcompte)),
                  _totalRow2(fontBold, bleuClair, bleu, 'TOTAL CUMULÉ', _fmt(totalCumule)),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('E8F0FF')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('NET À PAYER',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 8,
                                color: bleu)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(_fmt(netAPayer),
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: bleu),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // ── PIED DE PAGE ─────────────────────────────────────────────────
        pw.Container(height: 1, color: bleu),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Document officiel - Conservez avec vos archives',
                style: pw.TextStyle(font: fontRegular, fontSize: 6, color: bleu)),
            pw.Text('Généré le: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(font: fontRegular, fontSize: 6)),
          ],
        ),
        if ((entreprise['compte_bancaire'] ?? '').toString().isNotEmpty)
          pw.Center(
            child: pw.Text(
              'F.B.N / Beni compte N° ${entreprise['compte_bancaire']}',
              style: pw.TextStyle(font: fontRegular, fontSize: 7),
            ),
          ),
      ],
    ),
  );

  return pdf;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(dynamic val) {
  final n = num.tryParse(val?.toString() ?? '0') ?? 0.0;
  return n.toStringAsFixed(2);
}

pw.Widget _sectionTitle(pw.Font fontBold, PdfColor bleu, String title) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: pw.BoxDecoration(color: bleu),
    child: pw.Text(title,
        style: pw.TextStyle(
            font: fontBold, fontSize: 9, color: PdfColors.white)),
  );
}

pw.TableRow _tableHeader(
    pw.Font fontBold, PdfColor bleu, PdfColor bg, List<String> cols) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: bg),
    children: cols
        .map((c) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(c,
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 8, color: bleu)),
            ))
        .toList(),
  );
}

pw.Widget _cell(pw.Font font, String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8)),
  );
}

pw.Widget _cellRight(pw.Font font, String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(text,
        style: pw.TextStyle(font: font, fontSize: 8),
        textAlign: pw.TextAlign.right),
  );
}

// Total row for 2-column tables (recap)
pw.TableRow _totalRow2(pw.Font fontBold, PdfColor bg, PdfColor color,
    String label, String value) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: bg),
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(label,
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: color)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: color),
            textAlign: pw.TextAlign.right),
      ),
    ],
  );
}

// Total row for 3-column tables (services, restaurant)
pw.TableRow _totalRow3(pw.Font fontBold, PdfColor bg, PdfColor color,
    String label, String value) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: bg),
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(label,
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: color)),
      ),
      pw.SizedBox(),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: color),
            textAlign: pw.TextAlign.right),
      ),
    ],
  );
}

// Total row for 4-column tables (logement)
pw.TableRow _totalRow4(pw.Font fontBold, PdfColor bg, PdfColor color,
    String label, String value) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: bg),
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(label,
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: color)),
      ),
      pw.SizedBox(),
      pw.SizedBox(),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: color),
            textAlign: pw.TextAlign.right),
      ),
    ],
  );
}

pw.TableRow _recapRow(pw.Font font, String label, String value) {
  return pw.TableRow(children: [
    pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8)),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(value,
          style: pw.TextStyle(font: font, fontSize: 8),
          textAlign: pw.TextAlign.right),
    ),
  ]);
}
