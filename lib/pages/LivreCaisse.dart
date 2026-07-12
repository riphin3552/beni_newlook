import 'dart:convert';
import 'package:beni_newlook/api_config.dart';
import 'package:beni_newlook/session_utilisateur.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color _primaryLivre = Color(0xFFF57C00);
const Color _lightLivre = Color(0xFFFFF8F0);

class LivreCaisse extends StatefulWidget {
  final int identreprise;
  final int idUtilisateur;

  const LivreCaisse({
    super.key,
    required this.identreprise,
    required this.idUtilisateur,
  });

  @override
  State<LivreCaisse> createState() => _LivreCaisseState();
}

class _LivreCaisseState extends State<LivreCaisse> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  List<dynamic> _mouvements = [];
  double _soldeInitial = 0;
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryLivre),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _fetchLivreCaisse() async {
    if (_dateDebutController.text.isEmpty || _dateFinController.text.isEmpty) {
      _showDialog('Attention', 'Veuillez sélectionner les deux dates.');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/LivreCaisse.php'),
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _soldeInitial = double.tryParse(data['solde_initial']?.toString() ?? '0') ?? 0;
          _mouvements = data is List ? data : (data['data'] ?? []);
        });
      } else {
        _showDialog('Erreur', 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _showDialog('Erreur', 'Erreur de connexion: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchEntrepriseInfos() async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/AfficherInfos_Ese.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idEse': widget.identreprise}),
    );
    return jsonDecode(response.body)['data'];
  }

  void _showDialog(String titre, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildLignes() {
    double solde = _soldeInitial;
    return _mouvements.map((mvt) {
      final montant = double.tryParse(mvt['montant']?.toString() ?? '0') ?? 0;
      final isEntree = mvt['type_mouvement']?.toString() == 'Entrée Caisse';
      final entree = isEntree ? montant : 0.0;
      final sortie = isEntree ? 0.0 : montant;
      solde += entree - sortie;
      return {
        'date': (mvt['date_mouvement'] ?? '').toString().split(' ')[0],
        'libelle': mvt['descriptionMvt'] ?? '',
        'reference': mvt['reference_externe'] ?? '',
        'entree': entree,
        'sortie': sortie,
        'solde': solde,
      };
    }).toList();
  }

  Future<void> _genererPDF() async {
    if (_mouvements.isEmpty) {
      _showDialog('Attention', 'Aucune donnée à imprimer.');
      return;
    }

    final entreprise = await _fetchEntrepriseInfos();
    final lignes = _buildLignes();
    final totalEntrees = lignes.fold(0.0, (s, l) => s + (l['entree'] as double));
    final totalSorties = lignes.fold(0.0, (s, l) => s + (l['sortie'] as double));
    final soldeFinal = totalEntrees - totalSorties;

    final pdf = pw.Document();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontNormal = await PdfGoogleFonts.robotoRegular();

    dynamic logoImage;
    try {
      final rawLogoPath = entreprise['logo_path']?.toString() ?? '';
    if (rawLogoPath.isNotEmpty) {
      final logoUrl = rawLogoPath.startsWith('http') ? rawLogoPath : '$apiBaseUrl/$rawLogoPath';
      logoImage = await flutterImageProvider(NetworkImage(logoUrl));
    }
    } catch (_) {
      logoImage = null;
    }

    final orange = PdfColor.fromHex('F57C00');
    const colWidths = [60.0, 130.0, 70.0, 65.0, 65.0, 65.0];

    pw.Widget cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            font: bold ? fontBold : fontNormal,
            fontSize: 8,
            color: color,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return [
            // En-tête entreprise
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entreprise['Denomination'] ?? 'ENTREPRISE',
                      style: pw.TextStyle(font: fontBold, fontSize: 14, color: orange),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text('RCCM: ${entreprise['Numero_RCCM'] ?? ''}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                    pw.Text('ID National: ${entreprise['ID_national'] ?? ''}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                    pw.Text('N° Impôt: ${entreprise['Numero_impot'] ?? ''}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                    pw.Text('Adresse: ${entreprise['Adresse'] ?? ''}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                    pw.Text('Téléphone: ${entreprise['Telephone'] ?? ''}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                    pw.Text('Email: ${entreprise['Email'] ?? ''}', style: pw.TextStyle(font: fontNormal, fontSize: 8)),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    height: 60,
                    width: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: orange, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 2, color: orange),
            pw.SizedBox(height: 10),

            // Titre
            pw.Center(
              child: pw.Text(
                'LIVRE DE CAISSE',
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: orange),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Du ${_dateDebutController.text} au ${_dateFinController.text}',
                style: pw.TextStyle(font: fontNormal, fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 14),

            // Tableau
            pw.Table(
              columnWidths: {
                0: pw.FixedColumnWidth(colWidths[0]),
                1: pw.FixedColumnWidth(colWidths[1]),
                2: pw.FixedColumnWidth(colWidths[2]),
                3: pw.FixedColumnWidth(colWidths[3]),
                4: pw.FixedColumnWidth(colWidths[4]),
                5: pw.FixedColumnWidth(colWidths[5]),
              },
              border: pw.TableBorder.all(color: PdfColor.fromHex('E0E0E0'), width: 0.5),
              children: [
                // En-tête colonnes
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: orange),
                  children: [
                    cell('DATE', bold: true, color: PdfColors.white),
                    cell('LIBELLÉ / MOTIF', bold: true, color: PdfColors.white),
                    cell('RÉF. PIÈCE', bold: true, color: PdfColors.white),
                    cell('ENTRÉES', bold: true, align: pw.TextAlign.right, color: PdfColors.white),
                    cell('SORTIES', bold: true, align: pw.TextAlign.right, color: PdfColors.white),
                    cell('SOLDE', bold: true, align: pw.TextAlign.right, color: PdfColors.white),
                  ],
                ),
                // Solde initial
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('E3F2FD')),
                  children: [
                    cell(_dateDebutController.text, bold: true),
                    cell('SOLDE INITIAL', bold: true, color: PdfColor.fromHex('1565C0')),
                    cell(''),
                    cell(''),
                    cell(''),
                    cell(_soldeInitial.toStringAsFixed(2), bold: true, align: pw.TextAlign.right, color: PdfColor.fromHex('1565C0')),
                  ],
                ),
                // Lignes de données
                ...lignes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final l = entry.value;
                  final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('FFF8F0');
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      cell(l['date']),
                      cell(l['libelle']),
                      cell(l['reference']),
                      cell(l['entree'] > 0 ? l['entree'].toStringAsFixed(2) : '', align: pw.TextAlign.right),
                      cell(l['sortie'] > 0 ? l['sortie'].toStringAsFixed(2) : '', align: pw.TextAlign.right),
                      cell(l['solde'].toStringAsFixed(2), bold: true, align: pw.TextAlign.right),
                    ],
                  );
                }),

                // Ligne vide séparatrice
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: List.generate(6, (_) => cell('')),
                ),

                // Ligne totaux
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('FFF3E0')),
                  children: [
                    cell('', bold: true),
                    cell('TOTAUX', bold: true, color: orange),
                    cell('', bold: true),
                    cell(totalEntrees.toStringAsFixed(2), bold: true, align: pw.TextAlign.right, color: PdfColor.fromHex('2E7D32')),
                    cell(totalSorties.toStringAsFixed(2), bold: true, align: pw.TextAlign.right, color: PdfColor.fromHex('C62828')),
                    cell(soldeFinal.toStringAsFixed(2), bold: true, align: pw.TextAlign.right, color: orange),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Récapitulatif
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: orange, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(children: [
                        pw.Text('Total Entrées  : ', style: pw.TextStyle(font: fontNormal, fontSize: 9)),
                        pw.Text('${totalEntrees.toStringAsFixed(2)} USD', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('2E7D32'))),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Text('Total Sorties  : ', style: pw.TextStyle(font: fontNormal, fontSize: 9)),
                        pw.Text('${totalSorties.toStringAsFixed(2)} USD', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('C62828'))),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Divider(color: orange),
                      pw.Row(children: [
                        pw.Text('Solde Final    : ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        pw.Text('${soldeFinal.toStringAsFixed(2)} USD', style: pw.TextStyle(font: fontBold, fontSize: 10, color: orange)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Pied de page
            pw.Divider(color: PdfColor.fromHex('E0E0E0')),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Généré le: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(font: fontNormal, fontSize: 7, color: PdfColor.fromHex('9E9E9E')),
              ),
            ),
          ];
        },
      ),
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Livre de Caisse'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: PdfPreview(
            build: (format) => pdf.save(),
            allowPrinting: true,
            allowSharing: false,
            pdfFileName: 'livre_caisse_${_dateDebutController.text}_${_dateFinController.text}.pdf',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildLignesFiltrees() {
    final lignes = _buildLignes();
    return lignes;
  }

  @override
  Widget build(BuildContext context) {
    final lignes = _buildLignesFiltrees();
    final totalEntrees = lignes.fold(0.0, (s, l) => s + (l['entree'] as double));
    final totalSorties = lignes.fold(0.0, (s, l) => s + (l['sortie'] as double));
    final soldeFinal = totalEntrees - totalSorties;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livre de Caisse'),
        backgroundColor: _primaryLivre,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Carte filtre dates
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.date_range, color: _primaryLivre),
                          SizedBox(width: 10),
                          Text(
                            'Sélectionner la période',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primaryLivre),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dateDebutController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Date début',
                                labelStyle: const TextStyle(color: _primaryLivre),
                                prefixIcon: const Icon(Icons.calendar_today, color: _primaryLivre),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: _primaryLivre, width: 2),
                                ),
                              ),
                              onTap: () => _selectDate(_dateDebutController),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _dateFinController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Date fin',
                                labelStyle: const TextStyle(color: _primaryLivre),
                                prefixIcon: const Icon(Icons.event, color: _primaryLivre),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: _primaryLivre, width: 2),
                                ),
                              ),
                              onTap: () => _selectDate(_dateFinController),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _fetchLivreCaisse,
                            icon: _isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.search),
                            label: const Text('Générer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryLivre,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Résultats
              if (_hasSearched && !_isLoading) ...[
                if (lignes.isEmpty)
                  const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Aucun mouvement pour cette période', style: TextStyle(color: Colors.grey))),
                    ),
                  )
                else ...[
                  // Résumé rapide
                  Row(
                    children: [
                      _buildSummaryCard('Total Entrées', totalEntrees, const Color(0xFF2E7D32), Icons.arrow_downward),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Total Sorties', totalSorties, const Color(0xFFC62828), Icons.arrow_upward),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Solde Final', soldeFinal, _primaryLivre, Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bouton imprimer
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _genererPDF,
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer le rapport'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryLivre,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tableau
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(_primaryLivre.withValues(alpha: 0.12)),
                              headingRowHeight: 50,
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryLivre))),
                                DataColumn(label: Text('Libellé / Motif', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryLivre))),
                                DataColumn(label: Text('Réf. Pièce', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryLivre))),
                                DataColumn(label: Text('Entrées', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                                DataColumn(label: Text('Sorties', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828)))),
                                DataColumn(label: Text('Solde', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryLivre))),
                              ],
                              rows: [
                                // Ligne solde initial
                                DataRow(
                                  color: WidgetStateProperty.all(const Color(0xFFE3F2FD)),
                                  cells: [
                                    DataCell(Text(_dateDebutController.text, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    const DataCell(Text('SOLDE INITIAL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)))),
                                    const DataCell(Text('')),
                                    const DataCell(Text('')),
                                    const DataCell(Text('')),
                                    DataCell(Text(
                                      '${_soldeInitial.toStringAsFixed(2)} \$',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                    )),
                                  ],
                                ),
                                ...lignes.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final l = entry.value;
                                  return DataRow(
                                    color: WidgetStateProperty.all(i.isEven ? Colors.white : _lightLivre),
                                    cells: [
                                      DataCell(Text(l['date'])),
                                      DataCell(SizedBox(
                                        width: 160,
                                        child: Text(l['libelle'], overflow: TextOverflow.ellipsis),
                                      )),
                                      DataCell(Text(l['reference'])),
                                      DataCell(Text(
                                        l['entree'] > 0 ? '${(l['entree'] as double).toStringAsFixed(2)} \$' : '',
                                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                                      )),
                                      DataCell(Text(
                                        l['sortie'] > 0 ? '${(l['sortie'] as double).toStringAsFixed(2)} \$' : '',
                                        style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                                      )),
                                      DataCell(Text(
                                        '${(l['solde'] as double).toStringAsFixed(2)} \$',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryLivre),
                                      )),
                                    ],
                                  );
                                }),
                                // Ligne totaux
                                DataRow(
                                  color: WidgetStateProperty.all(const Color(0xFFFFF3E0)),
                                  cells: [
                                    const DataCell(Text('')),
                                    const DataCell(Text('TOTAUX', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryLivre))),
                                    const DataCell(Text('')),
                                    DataCell(Text(
                                      '${totalEntrees.toStringAsFixed(2)} \$',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                    )),
                                    DataCell(Text(
                                      '${totalSorties.toStringAsFixed(2)} \$',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                                    )),
                                    DataCell(Text(
                                      '${soldeFinal.toStringAsFixed(2)} \$',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryLivre),
                                    )),
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
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(
                    '${value.toStringAsFixed(2)} \$',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
