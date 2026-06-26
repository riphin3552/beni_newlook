import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RapportEntreesEncaissements extends StatefulWidget {
  final int identreprise;
  const RapportEntreesEncaissements({super.key, required this.identreprise});

  @override
  State<RapportEntreesEncaissements> createState() =>
      _RapportEntreesEncaissementsState();
}

class _RapportEntreesEncaissementsState
    extends State<RapportEntreesEncaissements> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  List<dynamic> _tousLesMouvements = [];
  List<String> _provenances = [];
  String? _provenanceSelectionnee;
  List<dynamic> _resultats = [];

  bool _isLoadingProvenances = true;
  bool _isSearching = false;
  bool _hasSearched = false;

  static const Color _primaryColor = Color(0xFF388E3C);
  static const Color _lightColor = Color(0xFFF1F8E9);

  @override
  void initState() {
    super.initState();
    _chargerMouvements();
  }

  @override
  void dispose() {
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _chargerMouvements() async {
    setState(() => _isLoadingProvenances = true);
    try {
      final response = await http.post(
        Uri.parse(
            'https://riphin-salemanager.com/beni_newlook_API/AfficherMouvementsEntreeCaisse.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entreprise': widget.identreprise}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> all = [];
        if (data is List) {
          all = data;
        } else if (data is Map) {
          if (data['success'] == false) throw Exception(data['message']);
          all = data['data'] ?? [];
        }
        final Set<String> uniques = {};
        for (final m in all) {
          final prov = m['Provenance']?.toString().trim() ?? '';
          if (prov.isNotEmpty) uniques.add(prov);
        }
        final sorted = uniques.toList()..sort();
        setState(() {
          _tousLesMouvements = all;
          _provenances = sorted;
          _isLoadingProvenances = false;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingProvenances = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement: $e')),
        );
      }
    }
  }

  void _rechercherEntrees() {
    if (_dateDebutController.text.isEmpty || _dateFinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une période')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final dateDebut = DateTime.tryParse(_dateDebutController.text);
    final dateFin = DateTime.tryParse(_dateFinController.text);

    final filtered = _tousLesMouvements.where((m) {
      // Filtre par provenance uniquement si sélectionnée
      if (_provenanceSelectionnee != null) {
        final prov = m['Provenance']?.toString().trim() ?? '';
        if (prov != _provenanceSelectionnee) return false;
      }

      final rawDate = m['date_mouvement']?.toString().split(' ')[0] ?? '';
      final date = DateTime.tryParse(rawDate);
      if (date == null || dateDebut == null || dateFin == null) return false;

      return !date.isBefore(dateDebut) &&
          !date.isAfter(dateFin.add(const Duration(days: 1)));
    }).toList();

    setState(() {
      _resultats = filtered;
      _isSearching = false;
    });
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  double get _total => _resultats.fold(
      0.0,
      (sum, d) =>
          sum + (double.tryParse(d['montant']?.toString() ?? '0') ?? 0.0));

  String _fmt(String value) {
    final n = double.tryParse(value) ?? 0.0;
    return n.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }

  Future<pw.Document> _buildPdf() async {
    Map<String, dynamic> ese = {};
    try {
      final resp = await http.post(
        Uri.parse(
            'https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idEse': widget.identreprise}),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        ese = (d is Map && d['data'] != null) ? d['data'] : {};
      }
    } catch (_) {}

    final pdf = pw.Document();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontReg = await PdfGoogleFonts.robotoRegular();

    dynamic logo;
    try {
      final rawPath = ese['logo_path']?.toString() ?? '';
      if (rawPath.isNotEmpty) {
        final logoUrl = rawPath.startsWith('http')
            ? rawPath
            : 'https://riphin-salemanager.com/beni_newlook_API/$rawPath';
        logo = await flutterImageProvider(NetworkImage(logoUrl));
      }
    } catch (_) {
      logo = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontReg, bold: fontBold),
        build: (pw.Context ctx) => [
          // En-tête identique aux autres rapports
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(ese['Denomination'] ?? 'ENTREPRISE',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('RCCM: ${ese['Numero_RCCM'] ?? ''}',
                      style: pw.TextStyle(font: fontReg, fontSize: 9)),
                  pw.Text('ID National: ${ese['ID_national'] ?? ''}',
                      style: pw.TextStyle(font: fontReg, fontSize: 9)),
                  pw.Text("N° Impôt: ${ese['Numero_impot'] ?? ''}",
                      style: pw.TextStyle(font: fontReg, fontSize: 9)),
                  pw.Text('Adresse: ${ese['Adresse'] ?? ''}',
                      style: pw.TextStyle(font: fontReg, fontSize: 9)),
                  pw.Text('Tél: ${ese['Telephone'] ?? ''}',
                      style: pw.TextStyle(font: fontReg, fontSize: 9)),
                  pw.Text('Email: ${ese['Email'] ?? ''}',
                      style: pw.TextStyle(font: fontReg, fontSize: 9)),
                ],
              ),
              if (logo != null)
                pw.Container(
                  height: 60,
                  width: 60,
                  child: pw.Image(logo),
                ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Titre centré
          pw.Center(
            child: pw.Text(
              'RAPPORT ENTRÉES / ENCAISSEMENTS',
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Source: ${_provenanceSelectionnee ?? 'Toutes les provenances'}',
              style: pw.TextStyle(font: fontBold, fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Période : ${_dateDebutController.text}  →  ${_dateFinController.text}',
              style: pw.TextStyle(font: fontReg, fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColor.fromHex('388E3C'), thickness: 1.5),
          pw.SizedBox(height: 10),

          // Tableau
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(72),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FixedColumnWidth(80),
            },
            children: [
              pw.TableRow(
                decoration:
                    pw.BoxDecoration(color: PdfColor.fromHex('388E3C')),
                children: [
                  _pdfCell('#', fontBold, isHeader: true),
                  _pdfCell('Date', fontBold, isHeader: true),
                  _pdfCell('Provenance', fontBold, isHeader: true),
                  _pdfCell('Mode paiement', fontBold, isHeader: true),
                  _pdfCell('Montant', fontBold, isHeader: true),
                ],
              ),
              ..._resultats.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final bg =
                    i.isEven ? PdfColors.white : PdfColor.fromHex('F1F8E9');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _pdfCell('${i + 1}', fontReg),
                    _pdfCell(
                        (d['date_mouvement'] ?? '').toString().split(' ')[0],
                        fontReg),
                    _pdfCell(d['Provenance']?.toString() ?? '-', fontReg),
                    _pdfCell(d['Modepaiement']?.toString() ?? '-', fontReg),
                    _pdfCell(_fmt(d['montant']?.toString() ?? '0'), fontBold),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 12),

          // Total
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('388E3C'),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'TOTAL : ${_fmt(_total.toStringAsFixed(2))} CDF',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 11, color: PdfColors.white),
              ),
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _pdfCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: isHeader ? PdfColors.white : PdfColors.black,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightColor,
      appBar: AppBar(
        title: const Text('Rapport Entrées / Encaissements'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: const [],
      ),
      body: Column(
        children: [
          // ── Panneau de filtres ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Listbox provenances uniques
                _isLoadingProvenances
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              color: _primaryColor, strokeWidth: 2),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _provenanceSelectionnee,
                        decoration: InputDecoration(
                          labelText: 'Source / Provenance',
                          labelStyle:
                              const TextStyle(color: _primaryColor),
                          prefixIcon: const Icon(Icons.input_outlined,
                              color: _primaryColor),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: _primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        hint: const Text(
                            'Sélectionner une source d\'encaissement'),
                        isExpanded: true,
                        items: _provenances
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setState(
                            () => _provenanceSelectionnee = val),
                      ),
                const SizedBox(height: 12),

                // Période + boutons
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        controller: _dateDebutController,
                        label: 'Date début',
                        primaryColor: _primaryColor,
                        onTap: () => _selectDate(_dateDebutController),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateField(
                        controller: _dateFinController,
                        label: 'Date fin',
                        primaryColor: _primaryColor,
                        onTap: () => _selectDate(_dateFinController),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed:
                          (_isLoadingProvenances || _isSearching)
                              ? null
                              : _rechercherEntrees,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('Rechercher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _resultats.isEmpty
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              final pdf = await _buildPdf();
                              if (!mounted) return;
                              navigator.push(MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text(
                                        'Rapport PDF – Entrées / Encaissements'),
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  body: PdfPreview(
                                    build: (format) async => pdf.save(),
                                    allowPrinting: true,
                                    allowSharing: true,
                                  ),
                                ),
                              ));
                            },
                      icon: const Icon(Icons.picture_as_pdf_outlined,
                          size: 20),
                      label: const Text('Rapport PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Contenu ──
          Expanded(
            child: !_hasSearched
                ? _emptyState(
                    Icons.filter_list_outlined,
                    'Sélectionnez une période (la provenance est optionnelle),\npuis cliquez sur Rechercher',
                  )
                : _resultats.isEmpty
                    ? _emptyState(
                        Icons.inbox_outlined,
                        'Aucune entrée trouvée pour cette sélection',
                      )
                    : Column(
                        children: [
                          // Bandeau total
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _provenanceSelectionnee ?? 'Toutes les provenances',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_dateDebutController.text}  →  ${_dateFinController.text}',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_resultats.length} opération(s)',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_fmt(_total.toStringAsFixed(2))} CDF',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Tableau
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor:
                                        WidgetStateProperty.all(
                                            _primaryColor
                                                .withValues(alpha: 0.12)),
                                    headingRowHeight: 50,
                                    // ignore: deprecated_member_use
                                    dataRowHeight: 46,
                                    border: TableBorder(
                                      horizontalInside: BorderSide(
                                          color: Colors.grey[200]!),
                                    ),
                                    columns: const [
                                      DataColumn(
                                          label: Text('#',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: _primaryColor))),
                                      DataColumn(
                                          label: Text('Date',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: _primaryColor))),
                                      DataColumn(
                                          label: Text('Provenance',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: _primaryColor))),
                                      DataColumn(
                                          label: Text('Mode paiement',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: _primaryColor))),
                                      DataColumn(
                                          label: Text('Montant (CDF)',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: _primaryColor))),
                                    ],
                                    rows: _resultats
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final i = entry.key;
                                      final d = entry.value;
                                      return DataRow(
                                        color: WidgetStateProperty.all(
                                          i.isEven
                                              ? Colors.white
                                              : _lightColor,
                                        ),
                                        cells: [
                                          DataCell(Text('${i + 1}')),
                                          DataCell(Text(
                                              (d['date_mouvement'] ?? '')
                                                  .toString()
                                                  .split(' ')[0])),
                                          DataCell(Text(
                                              d['Provenance']
                                                      ?.toString() ??
                                                  '-')),
                                          DataCell(Text(
                                              d['Modepaiement']
                                                      ?.toString() ??
                                                  '-')),
                                          DataCell(Text(
                                            _fmt(d['montant']
                                                    ?.toString() ??
                                                '0'),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: _primaryColor),
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(msg,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color primaryColor;
  final VoidCallback onTap;

  const _DateField({
    required this.controller,
    required this.label,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        prefixIcon:
            Icon(Icons.calendar_today, color: primaryColor, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
