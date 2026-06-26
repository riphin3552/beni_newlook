import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BridgeStatistiques extends StatefulWidget {
  final int identreprise;
  const BridgeStatistiques({super.key, required this.identreprise});

  @override
  State<BridgeStatistiques> createState() => _BridgeStatistiquesState();
}

class _BridgeStatistiquesState extends State<BridgeStatistiques> {
  int _hoveredIndex = -1;
  late Future<Map<String, dynamic>> _statsFuture;
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialisation des dates sur les 7 derniers jours par défaut
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    _dateFinController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _dateDebutController.text = "${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}";
    
    _statsFuture = fetchRoomStats();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = fetchRoomStats();
    });
  }

  // ── Génération PDF ─────────────────────────────────────────────────────────
  Future<pw.Document> _buildPdf(Map<String, dynamic> stats) async {
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

    final taux = (stats['taux_occupation_reel_pourcent'] as num?)?.toDouble() ?? 0.0;

    PdfColor tauxColor(double p) {
      if (p >= 70) return PdfColors.green700;
      if (p >= 40) return PdfColors.orange700;
      return PdfColors.red700;
    }

    pw.TableRow headerRow(List<String> cols) => pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('0D47A1')),
      children: cols.map((c) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(c, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
      )).toList(),
    );

    pw.TableRow dataRow(String label, String value, bool shaded) => pw.TableRow(
      decoration: pw.BoxDecoration(
          color: shaded ? PdfColor.fromHex('E8EEF9') : PdfColors.white),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(label, style: pw.TextStyle(font: fontReg, fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(value,
              style: pw.TextStyle(font: fontBold, fontSize: 10),
              textAlign: pw.TextAlign.center),
        ),
      ],
    );

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: fontReg, bold: fontBold),
      build: (pw.Context ctx) => [
        // En-tête entreprise
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
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
            ]),
            if (logo != null) pw.Container(height: 60, width: 60, child: pw.Image(logo)),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Container(height: 2, color: PdfColor.fromHex('0D47A1')),
        pw.SizedBox(height: 12),

        // Titre
        pw.Center(child: pw.Text(
          'RAPPORT STATISTIQUE DU RENDEMENT HÉBERGEMENT',
          style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColor.fromHex('0D47A1')),
        )),
        pw.SizedBox(height: 5),
        pw.Center(child: pw.Text(
          'Période : ${_dateDebutController.text}  →  ${_dateFinController.text}',
          style: pw.TextStyle(font: fontReg, fontSize: 9),
        )),
        pw.SizedBox(height: 14),

        // Taux d'occupation
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('E8EEF9'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColor.fromHex('0D47A1'), width: 1.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("TAUX D'OCCUPATION RÉEL",
                  style: pw.TextStyle(font: fontBold, fontSize: 11)),
              pw.Text('${taux.toStringAsFixed(1)} %',
                  style: pw.TextStyle(font: fontBold, fontSize: 22, color: tauxColor(taux))),
            ],
          ),
        ),
        pw.SizedBox(height: 14),

        // Tableau
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            headerRow(['Indicateur', 'Valeur']),
            dataRow('Total chambres / espaces existants',
                stats['total_existantes_jours']?.toString() ?? '0', false),
            dataRow('Chambres / espaces occupés',
                stats['total_occupees_jours']?.toString() ?? '0', true),
            dataRow('Chambres / espaces disponibles',
                stats['total_disponibles_jours']?.toString() ?? '0', false),
            dataRow('En maintenance',
                stats['total_maintenance_jours']?.toString() ?? '0', true),
            dataRow('Bloqués (hors service)',
                stats['total_bloquees_jours']?.toString() ?? '0', false),
            dataRow('Non occupés (disponibles non réservés)',
                stats['total_non_occupees_jours']?.toString() ?? '0', true),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 6),
        pw.Center(child: pw.Text(
          'Généré le : ${DateTime.now().toString().split('.')[0]}',
          style: pw.TextStyle(font: fontReg, fontSize: 7, color: PdfColors.grey600),
        )),
      ],
    ));
    return pdf;
  }

  Future<void> _imprimerStats(Map<String, dynamic> stats) async {
    final navigator = Navigator.of(context);
    final pdf = await _buildPdf(stats);
    if (!mounted) return;
    navigator.push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Rapport PDF – Statistiques Hébergement'),
          backgroundColor: const Color.fromARGB(255, 121, 169, 240),
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

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
      _refreshStats();
    }
  }

  Future<Map<String, dynamic>> fetchRoomStats() async {
    try {
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/StatistiquesOccupationChambre.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "entreprise": widget.identreprise,
          "date_debut": _dateDebutController.text, // Corrected key to match PHP API
          "date_fin": _dateFinController.text,     // Corrected key to match PHP API
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('statistiques_chambres_jours')) {
          return data['statistiques_chambres_jours'];
        }
      }
      // Return default values if API call fails or data is not as expected
      return {
        "total_existantes_jours": 0,
        "total_occupees_jours": 0,
        "total_maintenance_jours": 0,
        "total_bloquees_jours": 0,
        "total_disponibles_jours": 0,
        "total_non_occupees_jours": 0,
        "taux_occupation_reel_pourcent": 0.0
      };
    } catch (e) {
      return {
        "total_existantes_jours": 0,
        "total_occupees_jours": 0,
        "total_maintenance_jours": 0,
        "total_bloquees_jours": 0,
        "total_disponibles_jours": 0,
        "total_non_occupees_jours": 0,
        "taux_occupation_reel_pourcent": 0.0
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D47A1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Chambres'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimer les statistiques',
            onPressed: () async {
              final stats = await _statsFuture;
              await _imprimerStats(stats);
            },
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: primaryColor.withValues(alpha:0.2),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistiques mensuelles d\'occupation',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aperçu en temps réel de l\'état de vos chambres',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Filtres de date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateDebutController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Date Début",
                            prefixIcon: const Icon(Icons.calendar_today, size: 20, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onTap: () => _selectDate(context, _dateDebutController),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dateFinController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Date Fin",
                            prefixIcon: const Icon(Icons.event, size: 20, color: Color.fromARGB(255, 121, 169, 240)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onTap: () => _selectDate(context, _dateFinController),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final stats = snapshot.data ?? {};
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildOccupancyRateHeader(context, stats['taux_occupation_reel_pourcent'] ?? 0),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildSmartCard(
                                context,
                                index: 0,
                                icon: Icons.bedroom_parent_outlined,
                                title: 'Total des chambres',
                                value: stats['total_existantes_jours']?.toString() ?? '0',
                                color: const Color(0xFF0D47A1),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 1,
                                icon: Icons.door_front_door,
                                title: 'Chambres occupées',
                                value: stats['total_occupees_jours']?.toString() ?? '0',
                                color: const Color(0xFF7B1FA2),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 2,
                                icon: Icons.check_circle_outline,
                                title: 'Chambres disponibles',
                                value: stats['total_disponibles_jours']?.toString() ?? '0',
                                color: const Color(0xFF388E3C),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 3,
                                icon: Icons.build_outlined,
                                title: 'Chambres en maintenance',
                                value: stats['total_maintenance_jours']?.toString() ?? '0',
                                color: const Color(0xFFF57C00),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 4,
                                icon: Icons.block_outlined,
                                title: 'Chambres bloquées',
                                value: stats['total_bloquees_jours']?.toString() ?? '0',
                                color: const Color(0xFFD32F2F),
                                onTap: () {},
                              ),
                              _buildSmartCard(
                                context,
                                index: 5,
                                icon: Icons.meeting_room_outlined,
                                title: 'Chambres non occupées',
                                value: stats['total_non_occupees_jours']?.toString() ?? '0',
                                color: const Color(0xFF455A64),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyRateHeader(BuildContext context, dynamic rate) {
    final double percentage = (rate is num) ? rate.toDouble() : 0.0;
    
    Color getProgressColor(double p) {
      if (p >= 70) return Colors.green;
      if (p >= 40) return Colors.orange;
      return Colors.red;
    }

    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha:0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Taux d'occupation réel",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(percentage)),
                ),
              ),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 165,
          height: 165,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha:isHovered ? 0.25 : 0.08),
                blurRadius: isHovered ? 20 : 8,
                offset: Offset(0, isHovered ? 8 : 4),
              ),
            ],
            border: Border.all(
              color: isHovered ? color.withValues(alpha:0.5) : Colors.grey[200]!,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Transform.scale(
            scale: isHovered ? 1.02 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:isHovered ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: isHovered ? 36 : 32,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                            fontSize: 20,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                  if (isHovered) ...[
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}