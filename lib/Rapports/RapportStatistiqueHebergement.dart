import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RapportStatistiqueHebergement extends StatefulWidget {
  final int identreprise;
  const RapportStatistiqueHebergement({super.key, required this.identreprise});

  @override
  State<RapportStatistiqueHebergement> createState() =>
      _RapportStatistiqueHebergementState();
}

class _RapportStatistiqueHebergementState
    extends State<RapportStatistiqueHebergement> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController   = TextEditingController();

  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  bool _hasSearched = false;

  static const Color _primaryColor = Color(0xFF0D47A1);
  static const Color _lightColor   = Color(0xFFE8EEF9);

  @override
  void initState() {
    super.initState();
    final now          = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    _dateDebutController.text =
        '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';
    _dateFinController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _chargerStats();
  }

  @override
  void dispose() {
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _chargerStats() async {
    setState(() {
      _isLoading   = true;
      _hasSearched = true;
    });
    try {
      final response = await http.post(
        Uri.parse('https://riphin-salemanager.com/beni_newlook_API/StatistiquesOccupationChambre.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'entreprise': widget.identreprise,
          'date_debut': _dateDebutController.text,
          'date_fin':   _dateFinController.text,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('statistiques_chambres_jours')) {
          setState(() => _stats = data['statistiques_chambres_jours']);
        } else {
          setState(() => _stats = _defaultStats());
        }
      } else {
        setState(() => _stats = _defaultStats());
      }
    } catch (_) {
      setState(() => _stats = _defaultStats());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _defaultStats() => {
        'total_existantes_jours':          0,
        'total_occupees_jours':            0,
        'total_maintenance_jours':         0,
        'total_bloquees_jours':            0,
        'total_disponibles_jours':         0,
        'total_non_occupees_jours':        0,
        'taux_occupation_reel_pourcent':   0.0,
      };

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

  // ── PDF ────────────────────────────────────────────────────────────────────
  Future<pw.Document> _buildPdf() async {
    Map<String, dynamic> ese = {};
    try {
      final resp = await http.post(
        Uri.parse('https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idEse': widget.identreprise}),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        ese = (d is Map && d['data'] != null) ? d['data'] : {};
      }
    } catch (_) {}

    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontReg  = await PdfGoogleFonts.robotoRegular();

    dynamic logo;
    try {
      final rawPath = ese['logo_path']?.toString() ?? '';
      if (rawPath.isNotEmpty) {
        final url = rawPath.startsWith('http')
            ? rawPath
            : 'https://riphin-salemanager.com/beni_newlook_API/$rawPath';
        logo = await flutterImageProvider(NetworkImage(url));
      }
    } catch (_) {}

    final s      = _stats ?? _defaultStats();
    final taux   = (s['taux_occupation_reel_pourcent'] as num?)?.toDouble() ?? 0.0;

    PdfColor tauxColor(double p) {
      if (p >= 70) return PdfColors.green700;
      if (p >= 40) return PdfColors.orange700;
      return PdfColors.red700;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: fontReg, bold: fontBold),
        build: (pw.Context ctx) => [
          // ── En-tête entreprise ────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(ese['Denomination'] ?? 'ENTREPRISE',
                      style: pw.TextStyle(font: fontBold, fontSize: 14)),
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
                ],
              ),
              if (logo != null)
                pw.Container(
                    height: 60, width: 60, child: pw.Image(logo)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(height: 2, color: PdfColor.fromHex('0D47A1')),
          pw.SizedBox(height: 12),

          // ── Titre ─────────────────────────────────────────────────────────
          pw.Center(
            child: pw.Text(
              'RAPPORT STATISTIQUE DU RENDEMENT HÉBERGEMENT',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 14,
                  color: PdfColor.fromHex('0D47A1')),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Période : ${_dateDebutController.text}  →  ${_dateFinController.text}',
              style: pw.TextStyle(font: fontReg, fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Taux d'occupation ─────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('E8EEF9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('0D47A1'), width: 1.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("TAUX D'OCCUPATION RÉEL",
                    style: pw.TextStyle(font: fontBold, fontSize: 11)),
                pw.Text(
                  '${taux.toStringAsFixed(1)} %',
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      color: tauxColor(taux)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Tableau des statistiques ───────────────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              _pdfHeaderRow(fontBold, ['Indicateur', 'Valeur']),
              _pdfRow(fontBold, fontReg, 'Total chambres / espaces existants',
                  s['total_existantes_jours']?.toString() ?? '0', false),
              _pdfRow(fontBold, fontReg, 'Chambres / espaces occupés',
                  s['total_occupees_jours']?.toString() ?? '0', true),
              _pdfRow(fontBold, fontReg, 'Chambres / espaces disponibles',
                  s['total_disponibles_jours']?.toString() ?? '0', false),
              _pdfRow(fontBold, fontReg, 'En maintenance',
                  s['total_maintenance_jours']?.toString() ?? '0', true),
              _pdfRow(fontBold, fontReg, 'Bloqués (hors service)',
                  s['total_bloquees_jours']?.toString() ?? '0', false),
              _pdfRow(fontBold, fontReg, 'Non occupés (disponibles non réservés)',
                  s['total_non_occupees_jours']?.toString() ?? '0', true),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Pied de page ──────────────────────────────────────────────────
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Généré le : ${DateTime.now().toString().split('.')[0]}',
              style: pw.TextStyle(font: fontReg, fontSize: 7, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  pw.TableRow _pdfHeaderRow(pw.Font fontBold, List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('0D47A1')),
      children: headers.map((h) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(h,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
      )).toList(),
    );
  }

  pw.TableRow _pdfRow(pw.Font bold, pw.Font reg, String label, String value, bool shaded) {
    final bg = shaded ? PdfColor.fromHex('E8EEF9') : PdfColors.white;
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(label, style: pw.TextStyle(font: reg, fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(value,
              style: pw.TextStyle(font: bold, fontSize: 10),
              textAlign: pw.TextAlign.center),
        ),
      ],
    );
  }

  Future<void> _afficherPdf() async {
    if (_stats == null) return;
    final navigator = Navigator.of(context);
    final pdf = await _buildPdf();
    if (!mounted) return;
    navigator.push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Rapport PDF – Statistiques Hébergement'),
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
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightColor,
      appBar: AppBar(
        title: const Text('Statistiques Hébergement'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Filtres ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _DateField(
                    controller: _dateDebutController,
                    label: 'Date début',
                    primaryColor: _primaryColor,
                    onTap: () => _selectDate(_dateDebutController),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    controller: _dateFinController,
                    label: 'Date fin',
                    primaryColor: _primaryColor,
                    onTap: () => _selectDate(_dateFinController),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _chargerStats,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Afficher'),
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
                  onPressed:
                      (_stats == null || _isLoading) ? null : _afficherPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
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
          ),
          const Divider(height: 1),

          // ── Contenu ───────────────────────────────────────────────────────
          Expanded(
            child: !_hasSearched
                ? _emptyState(Icons.filter_list_outlined,
                    'Sélectionnez une période puis cliquez sur Afficher')
                : _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _primaryColor))
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final s    = _stats ?? _defaultStats();
    final taux = (s['taux_occupation_reel_pourcent'] as num?)?.toDouble() ?? 0.0;

    Color tauxColor(double p) {
      if (p >= 70) return Colors.green;
      if (p >= 40) return Colors.orange;
      return Colors.red;
    }

    final rows = [
      {'label': 'Total chambres / espaces existants',     'value': s['total_existantes_jours'],   'color': _primaryColor},
      {'label': 'Chambres / espaces occupés',             'value': s['total_occupees_jours'],     'color': const Color(0xFF7B1FA2)},
      {'label': 'Chambres / espaces disponibles',         'value': s['total_disponibles_jours'],  'color': const Color(0xFF388E3C)},
      {'label': 'En maintenance',                         'value': s['total_maintenance_jours'],  'color': const Color(0xFFF57C00)},
      {'label': 'Bloqués (hors service)',                 'value': s['total_bloquees_jours'],     'color': const Color(0xFFD32F2F)},
      {'label': 'Non occupés (disponibles non réservés)', 'value': s['total_non_occupees_jours'], 'color': const Color(0xFF455A64)},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Bandeau taux ─────────────────────────────────────────────────
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 90,
                    width: 90,
                    child: CircularProgressIndicator(
                      value: taux / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(tauxColor(taux)),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Taux d'occupation réel",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey)),
                      Text(
                        '${taux.toStringAsFixed(1)} %',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: tauxColor(taux)),
                      ),
                      Text(
                        '${_dateDebutController.text}  →  ${_dateFinController.text}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tableau des statistiques ──────────────────────────────────────
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  _primaryColor.withValues(alpha: 0.12)),
              headingRowHeight: 52,
              // ignore: deprecated_member_use
              dataRowHeight: 50,
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: Colors.grey[200]!),
              ),
              columns: const [
                DataColumn(
                  label: Text('Indicateur',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                ),
                DataColumn(
                  label: Text('Valeur',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                ),
              ],
              rows: rows.asMap().entries.map((e) {
                final i    = e.key;
                final row  = e.value;
                final col  = row['color'] as Color;
                final val  = row['value']?.toString() ?? '0';
                return DataRow(
                  color: WidgetStateProperty.all(
                      i.isEven ? Colors.white : _lightColor),
                  cells: [
                    DataCell(Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(row['label'] as String,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    )),
                    DataCell(
                      Text(val,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: col)),
                    ),
                  ],
                );
              }).toList(),
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

// ── Widget date field réutilisable ────────────────────────────────────────────
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
