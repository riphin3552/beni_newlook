import 'dart:convert';
import 'package:beni_newlook/api_config.dart';
import 'package:beni_newlook/session_utilisateur.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FicheDeStock extends StatefulWidget {
  final int identreprise;
  const FicheDeStock({super.key, required this.identreprise});

  @override
  State<FicheDeStock> createState() => _FicheDeStockState();
}

class _FicheDeStockState extends State<FicheDeStock> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  Map<String, List<dynamic>> _parSection = {};
  bool _isLoading = false;
  bool _hasSearched = false;

  static const Color _primaryColor = Color(0xFF1565C0);

  @override
  void dispose() {
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        ctrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _charger() async {
    if (_dateDebutController.text.isEmpty || _dateFinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une période')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _parSection = {};
    });

    try {
      final resp = await http.post(
        Uri.parse('$apiBaseUrl/FicheDeStock.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': SessionUtilisateur.token,
        },
        body: jsonEncode({
          'entreprise': widget.identreprise,
          'date_debut': _dateDebutController.text,
          'date_fin': _dateFinController.text,
        }),
      );

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body);
        List<dynamic> rows = [];
        if (raw is Map && raw['success'] == true) {
          rows = raw['data'] ?? [];
        } else if (raw is List) {
          rows = raw;
        } else {
          throw Exception(raw['message'] ?? 'Erreur inconnue');
        }

        final Map<String, List<dynamic>> grouped = {};
        for (final row in rows) {
          final sec = row['descptionSection']?.toString() ?? 'Sans section';
          grouped.putIfAbsent(sec, () => []).add(row);
        }
        setState(() {
          _parSection = grouped;
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur HTTP ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  String _fmt(dynamic v) {
    final n = _d(v);
    final parts = n.toStringAsFixed(2).split('.');
    final intPart =
        parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$intPart,${parts[1]}';
  }

  // ─── PDF ────────────────────────────────────────────────────────────────────

  Future<pw.Document> _buildPdf() async {
    Map<String, dynamic> ese = {};
    try {
      final r = await http.post(
        Uri.parse(
            '$apiBaseUrl/AfficherInfos_Ese.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idEse': widget.identreprise}),
      );
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        ese = (d is Map && d['data'] != null) ? Map<String, dynamic>.from(d['data']) : {};
      }
    } catch (_) {}

    dynamic logo;
    try {
      final rawPath = ese['logo_path']?.toString() ?? '';
      if (rawPath.isNotEmpty) {
        final url = rawPath.startsWith('http')
            ? rawPath
            : '$apiBaseUrl/$rawPath';
        logo = await flutterImageProvider(NetworkImage(url));
      }
    } catch (_) {}

    final pdf = pw.Document();
    final sections = _parSection.entries.toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) {
          final List<pw.Widget> widgets = [];

          // En-tête entreprise
          widgets.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(ese['Denomination']?.toString() ?? '',
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text('RCCM: ${ese['Numero_RCCM'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('ID National: ${ese['ID_national'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('N° Impôt: ${ese['Numero_impot'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Adresse: ${ese['Adresse'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Tél: ${ese['Telephone'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (logo != null)
                pw.Container(
                    height: 55, width: 55, child: pw.Image(logo)),
            ],
          ));

          widgets.add(pw.SizedBox(height: 12));
          widgets.add(pw.Center(
            child: pw.Text(
              'FICHE DE STOCK',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
          ));
          widgets.add(pw.Center(
            child: pw.Text(
              'Période : ${_dateDebutController.text}  au  ${_dateFinController.text}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ));
          widgets.add(pw.SizedBox(height: 10));

          final boldHeader =
              pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold);
          const cellStyle = pw.TextStyle(fontSize: 7);
          final headerDeco =
              pw.BoxDecoration(color: PdfColors.blueGrey100);
          final sectionDeco =
              pw.BoxDecoration(color: PdfColors.blue50);
          for (final entry in sections) {
            final sectionName = entry.key;
            final items = entry.value;

            // Totaux section
            double totStockInitQte = 0, totStockInitVal = 0;
            double totEntreeQte = 0, totEntreeVal = 0;
            double totSortieQte = 0, totSortieVal = 0;
            double totStockFinQte = 0, totStockFinVal = 0;
            for (final r in items) {
              totStockInitQte += _d(r['stock_initial']);
              totStockInitVal += _d(r['valeur_stock_initial']);
              totEntreeQte    += _d(r['qte_entree']);
              totEntreeVal    += _d(r['valeur_entree']);
              totSortieQte    += _d(r['qte_sortie_totale']);
              totSortieVal    += _d(r['valeur_sortie']);
              totStockFinQte  += _d(r['stock_final']);
              totStockFinVal  += _d(r['valeur_stock_final']);
            }

            // Section header
            widgets.add(pw.Container(
              decoration: sectionDeco,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: pw.Text(
                'Section : $sectionName',
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ));

            // Table
            widgets.add(
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: [
                  'Stock',
                  'Produit',
                  'Unité',
                  'Stk Init\n(Qté)',
                  'Val Init\n(FC)',
                  'Qté\nEntrée',
                  'Val\nEntrée (FC)',
                  'Qté\nSortie',
                  'Val\nSortie (FC)',
                  'Stk Final\n(Qté)',
                  'Val Final\n(FC)',
                ],
                data: [
                  ...items.map((r) => [
                        r['designationStock']?.toString() ?? '',
                        r['designationProduit']?.toString() ?? '',
                        r['uniteMesure']?.toString() ?? '',
                        _fmt(r['stock_initial']),
                        _fmt(r['valeur_stock_initial']),
                        _fmt(r['qte_entree']),
                        _fmt(r['valeur_entree']),
                        _fmt(r['qte_sortie_totale']),
                        _fmt(r['valeur_sortie']),
                        _fmt(r['stock_final']),
                        _fmt(r['valeur_stock_final']),
                      ]),
                  // Ligne total section
                  [
                    'TOTAL SECTION',
                    '',
                    '',
                    _fmt(totStockInitQte),
                    _fmt(totStockInitVal),
                    _fmt(totEntreeQte),
                    _fmt(totEntreeVal),
                    _fmt(totSortieQte),
                    _fmt(totSortieVal),
                    _fmt(totStockFinQte),
                    _fmt(totStockFinVal),
                  ],
                ],
                headerStyle: boldHeader,
                cellStyle: cellStyle,
                headerDecoration: headerDeco,
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                cellAlignment: pw.Alignment.centerRight,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(2.2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(1.5),
                  7: const pw.FlexColumnWidth(1.2),
                  8: const pw.FlexColumnWidth(1.5),
                  9: const pw.FlexColumnWidth(1.2),
                  10: const pw.FlexColumnWidth(1.5),
                },
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          }

          // Grand total global
          double gStockInitQte = 0, gStockInitVal = 0;
          double gEntreeQte = 0, gEntreeVal = 0;
          double gSortieQte = 0, gSortieVal = 0;
          double gStockFinQte = 0, gStockFinVal = 0;
          for (final rows in _parSection.values) {
            for (final r in rows) {
              gStockInitQte += _d(r['stock_initial']);
              gStockInitVal += _d(r['valeur_stock_initial']);
              gEntreeQte    += _d(r['qte_entree']);
              gEntreeVal    += _d(r['valeur_entree']);
              gSortieQte    += _d(r['qte_sortie_totale']);
              gSortieVal    += _d(r['valeur_sortie']);
              gStockFinQte  += _d(r['stock_final']);
              gStockFinVal  += _d(r['valeur_stock_final']);
            }
          }

          widgets.add(pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.blue900),
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Row(children: [
              pw.Expanded(
                child: pw.Text(
                  'TOTAL GÉNÉRAL',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white),
                ),
              ),
              _pdfTotalCell('Stk Init\n${_fmt(gStockInitQte)}\n${_fmt(gStockInitVal)} FC'),
              _pdfTotalCell('Entrées\n${_fmt(gEntreeQte)}\n${_fmt(gEntreeVal)} FC'),
              _pdfTotalCell('Sorties\n${_fmt(gSortieQte)}\n${_fmt(gSortieVal)} FC'),
              _pdfTotalCell('Stk Final\n${_fmt(gStockFinQte)}\n${_fmt(gStockFinVal)} FC'),
            ]),
          ));

          return widgets;
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfTotalCell(String text) => pw.Expanded(
        child: pw.Text(
          text,
          style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white),
          textAlign: pw.TextAlign.right,
        ),
      );

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Fiche de Stock',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_parSection.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              tooltip: 'Générer PDF',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _PdfPreview(buildDoc: _buildPdf),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltres(),
          Expanded(child: _buildCorps()),
        ],
      ),
    );
  }

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _dateField('Date début', _dateDebutController)),
          const SizedBox(width: 12),
          Expanded(child: _dateField('Date fin', _dateFinController)),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.search),
            label: const Text('Rechercher'),
            onPressed: _isLoading ? null : _charger,
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onTap: () => _selectDate(ctrl),
    );
  }

  Widget _buildCorps() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return _placeholder(
          Icons.inventory_2_outlined,
          'Sélectionnez une période et cliquez sur Rechercher');
    }
    if (_parSection.isEmpty) {
      return _placeholder(Icons.inbox_outlined, 'Aucune donnée pour cette période');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _parSection.length,
      itemBuilder: (_, i) {
        final entry = _parSection.entries.elementAt(i);
        return _SectionCard(
          sectionName: entry.key,
          rows: entry.value,
          fmt: _fmt,
          d: _d,
          primaryColor: _primaryColor,
        );
      },
    );
  }

  Widget _placeholder(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[350]),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String sectionName;
  final List<dynamic> rows;
  final String Function(dynamic) fmt;
  final double Function(dynamic) d;
  final Color primaryColor;

  const _SectionCard({
    required this.sectionName,
    required this.rows,
    required this.fmt,
    required this.d,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    double totSIQ = 0, totSIV = 0;
    double totEQ = 0, totEV = 0;
    double totSoQ = 0, totSoV = 0;
    double totSFQ = 0, totSFV = 0;
    for (final r in rows) {
      totSIQ  += d(r['stock_initial']);
      totSIV  += d(r['valeur_stock_initial']);
      totEQ   += d(r['qte_entree']);
      totEV   += d(r['valeur_entree']);
      totSoQ  += d(r['qte_sortie_totale']);
      totSoV  += d(r['valeur_sortie']);
      totSFQ  += d(r['stock_final']);
      totSFV  += d(r['valeur_stock_final']);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Container(
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: primaryColor.withOpacity(0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.category_outlined, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  sectionName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                Text('${rows.length} article(s)',
                    style:
                        TextStyle(color: primaryColor, fontSize: 12)),
              ],
            ),
          ),

          // Scrollable table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  // ignore: deprecated_member_use
                  primaryColor.withOpacity(0.06)),
              columnSpacing: 16,
              headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              dataTextStyle:
                  const TextStyle(fontSize: 12),
              columns: const [
                DataColumn(label: Text('Stock')),
                DataColumn(label: Text('Produit')),
                DataColumn(label: Text('Unité')),
                DataColumn(label: Text('Stk Init\n(Qté)'), numeric: true),
                DataColumn(label: Text('Val. Init\n(FC)'), numeric: true),
                DataColumn(label: Text('Qté\nEntrée'), numeric: true),
                DataColumn(label: Text('Val.\nEntrée (FC)'), numeric: true),
                DataColumn(label: Text('Qté\nSortie'), numeric: true),
                DataColumn(label: Text('Val.\nSortie (FC)'), numeric: true),
                DataColumn(label: Text('Stk Final\n(Qté)'), numeric: true),
                DataColumn(label: Text('Val. Final\n(FC)'), numeric: true),
              ],
              rows: [
                ...rows.map(
                  (r) => DataRow(cells: [
                    DataCell(Text(r['designationStock']?.toString() ?? '')),
                    DataCell(Text(r['designationProduit']?.toString() ?? '')),
                    DataCell(Text(r['uniteMesure']?.toString() ?? '')),
                    DataCell(Text(fmt(r['stock_initial']))),
                    DataCell(Text(fmt(r['valeur_stock_initial']))),
                    DataCell(Text(fmt(r['qte_entree']))),
                    DataCell(Text(fmt(r['valeur_entree']))),
                    DataCell(Text(fmt(r['qte_sortie_totale']))),
                    DataCell(Text(fmt(r['valeur_sortie']))),
                    DataCell(Text(fmt(r['stock_final']))),
                    DataCell(Text(fmt(r['valeur_stock_final']))),
                  ]),
                ),
              ],
            ),
          ),

          // Total section
          Container(
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: primaryColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('TOTAL : ',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                  _totChip('Stk Init', fmt(totSIQ), fmt(totSIV),
                      Colors.blueGrey),
                  _totChip('Entrées', fmt(totEQ), fmt(totEV),
                      Colors.green.shade700),
                  _totChip('Sorties', fmt(totSoQ), fmt(totSoV),
                      Colors.red.shade700),
                  _totChip('Stk Final', fmt(totSFQ), fmt(totSFV),
                      Colors.blue.shade800),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totChip(String label, String qty, String val, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
          Text(qty,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text('$val FC',
              style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

// ─── PDF Preview Page ─────────────────────────────────────────────────────────

class _PdfPreview extends StatelessWidget {
  final Future<pw.Document> Function() buildDoc;
  const _PdfPreview({required this.buildDoc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu PDF',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<pw.Document>(
        future: buildDoc(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erreur: ${snap.error}'));
          }
          return PdfPreview(
            build: (fmt) async => snap.data!.save(),
            allowPrinting: true,
            allowSharing: true,
          );
        },
      ),
    );
  }
}
