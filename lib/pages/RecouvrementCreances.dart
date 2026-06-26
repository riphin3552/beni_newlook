import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RecouvrementCreances extends StatefulWidget {
  final int identreprise;
  const RecouvrementCreances({super.key, required this.identreprise});

  @override
  State<RecouvrementCreances> createState() => _RecouvrementCreancesState();
}

class _RecouvrementCreancesState extends State<RecouvrementCreances> {
  static const _primaryColor  = Color(0xFF1976D2);
  static const _successColor  = Color(0xFF388E3C);
  static const _dangerColor   = Color(0xFFD32F2F);
  static const _baseUrl = 'https://riphin-salemanager.com/beni_newlook_API/';

  // ── Créances ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _clients  = [];
  List<Map<String, dynamic>> _filtered = [];
  bool   _loading = true;
  String _search  = '';

  // ── Historique encaissements ───────────────────────────────────────────────
  List<Map<String, dynamic>> _historique        = [];
  bool                       _loadingHistorique = true;

  @override
  void initState() {
    super.initState();
    _charger();
    _chargerHistorique();
  }

  // ── Chargement créances ────────────────────────────────────────────────────
  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}AfficherClientsSolde.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entreprise': widget.identreprise}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          setState(() {
            _clients = data.cast<Map<String, dynamic>>();
            _appliquerRecherche();
          });
        }
      }
    } catch (e) {
      _showSnack('Erreur réseau : $e', Colors.red);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Chargement historique encaissements ────────────────────────────────────
  Future<void> _chargerHistorique() async {
    setState(() => _loadingHistorique = true);
    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}AfficherEncaissementsCreances.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entreprise': widget.identreprise}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          setState(() => _historique = data.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {
    } finally {
      setState(() => _loadingHistorique = false);
    }
  }

  void _appliquerRecherche() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_clients)
        : _clients
            .where((c) =>
                (c['client_name'] ?? '').toString().toLowerCase().contains(q))
            .toList();
  }

  double get _totalDette =>
      _filtered.fold(0.0, (s, c) => s + (double.tryParse(c['Solde'].toString()) ?? 0.0));

  double get _totalEncaisse =>
      _historique.fold(0.0, (s, h) => s + (double.tryParse(h['Montpayer'].toString()) ?? 0.0));

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Dialogue encaissement ──────────────────────────────────────────────────
  Future<void> _dialogEncaisser(Map<String, dynamic> client) async {
    final montantCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    final solde       = double.tryParse(client['Solde'].toString()) ?? 0.0;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.payments_outlined, color: _primaryColor),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Encaisser – ${client['client_name']}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Solde actuel',
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    Text('${solde.toStringAsFixed(2)} FC',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dangerColor)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: montantCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Montant encaissé',
                  hintText: 'Ex: ${solde.toStringAsFixed(0)}',
                  prefixIcon: const Icon(Icons.attach_money, color: _primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  final m = double.tryParse(v.trim());
                  if (m == null || m <= 0) return 'Montant invalide';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Encaisser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              await _encaisser(
                clientId:   client['client_id'],
                montant:    double.parse(montantCtrl.text.trim()),
                nomClient:  client['client_name'],
                soldeAvant: solde,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _encaisser({
    required dynamic clientId,
    required double  montant,
    required String  nomClient,
    required double  soldeAvant,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}EncaisserCreance.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id':  clientId,
          'montant':    montant,
          'entreprise': widget.identreprise,
        }),
      );
      final body = jsonDecode(resp.body);
      if (body['success'] == true) {
        _showSnack('Paiement de $nomClient enregistré', Colors.green);
        await Future.wait([_charger(), _chargerHistorique()]);
      } else {
        _showSnack(body['error'] ?? body['message'] ?? 'Erreur', Colors.red);
      }
    } catch (e) {
      _showSnack('Erreur réseau : $e', Colors.red);
    }
  }

  // ── Génération reçu PDF ────────────────────────────────────────────────────
  Future<void> _genererRecu(Map<String, dynamic> h) async {
    // Récupérer les infos entreprise
    Map<String, dynamic> ese = {};
    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}AfficherInfos_Ese.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idEse': widget.identreprise}),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        ese = (d is Map && d['data'] != null) ? Map<String, dynamic>.from(d['data']) : {};
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
            : '$_baseUrl$rawPath';
        logo = await flutterImageProvider(NetworkImage(url));
      }
    } catch (_) {}

    final montant  = double.tryParse(h['Montpayer'].toString()) ?? 0.0;
    final date     = (h['DatePaiement'] ?? '').toString();
    final dateAff  = date.length >= 16 ? date.substring(0, 16) : date;
    final numRecu  = h['IdEncaissementCreance']?.toString() ?? '-';
    final client   = h['client_name'] ?? '';

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont(base: fontReg, bold: fontBold),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(ese['Denomination'] ?? 'ENTREPRISE',
                    style: pw.TextStyle(font: fontBold, fontSize: 13)),
                pw.SizedBox(height: 3),
                pw.Text('RCCM : ${ese['Numero_RCCM'] ?? ''}',
                    style: pw.TextStyle(font: fontReg, fontSize: 8)),
                pw.Text('ID Nat. : ${ese['ID_national'] ?? ''}',
                    style: pw.TextStyle(font: fontReg, fontSize: 8)),
                pw.Text("N° Impôt : ${ese['Numero_impot'] ?? ''}",
                    style: pw.TextStyle(font: fontReg, fontSize: 8)),
                pw.Text('Tél : ${ese['Telephone'] ?? ''}',
                    style: pw.TextStyle(font: fontReg, fontSize: 8)),
                pw.Text('Adresse : ${ese['Adresse'] ?? ''}',
                    style: pw.TextStyle(font: fontReg, fontSize: 8)),
              ]),
              if (logo != null)
                pw.Container(height: 55, width: 55, child: pw.Image(logo)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 1.5, color: PdfColor.fromHex('1976D2')),
          pw.SizedBox(height: 10),

          // Titre
          pw.Center(
            child: pw.Column(children: [
              pw.Text('REÇU DE PAIEMENT',
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: PdfColor.fromHex('1976D2'))),
              pw.SizedBox(height: 4),
              pw.Text('N° $numRecu',
                  style: pw.TextStyle(font: fontReg, fontSize: 9,
                      color: PdfColors.grey600)),
            ]),
          ),
          pw.SizedBox(height: 16),

          // Bloc infos
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('E3F2FD'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _recuLigne(fontBold, fontReg, 'Client',          client),
                pw.SizedBox(height: 6),
                _recuLigne(fontBold, fontReg, 'Date de paiement', dateAff),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('MONTANT ENCAISSÉ',
                        style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    pw.Text('${montant.toStringAsFixed(2)} FC',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 16,
                            color: PdfColor.fromHex('388E3C'))),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Message
          pw.Center(
            child: pw.Text(
              'Nous vous remercions pour votre règlement.',
              style: pw.TextStyle(
                  font: fontReg, fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Spacer(),

          // Signature
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Signature client',
                    style: pw.TextStyle(font: fontBold, fontSize: 9)),
                pw.SizedBox(height: 28),
                pw.Container(width: 100, height: 0.5,
                    color: PdfColors.grey600),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Signature caissier',
                    style: pw.TextStyle(font: fontBold, fontSize: 9)),
                pw.SizedBox(height: 28),
                pw.Container(width: 100, height: 0.5,
                    color: PdfColors.grey600),
              ]),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.Center(
            child: pw.Text(
              'Généré le : ${DateTime.now().toString().split('.')[0]}',
              style: pw.TextStyle(font: fontReg, fontSize: 7,
                  color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    ));

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Reçu de paiement'),
          backgroundColor: const Color.fromARGB(255, 121, 169, 240),
          foregroundColor: Colors.white,
        ),
        body: PdfPreview(
          build: (fmt) async => pdf.save(),
          allowPrinting: true,
          allowSharing: true,
        ),
      ),
    ));
  }

  pw.Widget _recuLigne(pw.Font bold, pw.Font reg, String label, String value) =>
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text('$label :',
                style: pw.TextStyle(font: bold, fontSize: 9)),
          ),
          pw.Flexible(
            child: pw.Text(value,
                style: pw.TextStyle(font: reg, fontSize: 9)),
          ),
        ],
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      appBar: AppBar(
        title: const Text('Recouvrement des créances'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => Future.wait([_charger(), _chargerHistorique()]),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bandeau stats ────────────────────────────────────────────────
            Row(
              children: [
                _statCard(
                  icon: Icons.people_outline,
                  label: 'Clients concernés',
                  value: _filtered.length.toString(),
                  color: _primaryColor,
                ),
                const SizedBox(width: 12),
                _statCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total créances',
                  value: '${_totalDette.toStringAsFixed(2)} FC',
                  color: _dangerColor,
                ),
                const SizedBox(width: 12),
                _statCard(
                  icon: Icons.savings_outlined,
                  label: 'Total encaissé',
                  value: '${_totalEncaisse.toStringAsFixed(2)} FC',
                  color: _successColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Deux panneaux côte à côte ────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Panneau gauche : créances en cours ────────────────────
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _panelHeader(
                          icon: Icons.warning_amber_rounded,
                          title: 'Créances en cours',
                          color: _dangerColor,
                        ),
                        const SizedBox(height: 10),
                        // Recherche
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher un client…',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.search,
                                color: _primaryColor, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _primaryColor, width: 1.5),
                            ),
                          ),
                          onChanged: (v) => setState(() {
                            _search = v;
                            _appliquerRecherche();
                          }),
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: _tableCreances()),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── Panneau droit : historique encaissements ───────────────
                  Expanded(
                    flex: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _panelHeader(
                          icon: Icons.history,
                          title: 'Encaissements effectués',
                          color: _successColor,
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: _tableHistorique()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tableau créances ───────────────────────────────────────────────────────
  Widget _tableCreances() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 52, color: Colors.green[300]),
            const SizedBox(height: 10),
            Text(
              _search.isEmpty ? 'Aucune créance en cours' : 'Aucun résultat',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(const Color(0xFFFFEBEE)),
            dataRowColor:
                WidgetStateProperty.resolveWith((_) => Colors.white),
            columnSpacing: 14,
            headingRowHeight: 40,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 44,
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              DataColumn(label: Text('Client',  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              DataColumn(label: Text('Solde FC', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              DataColumn(label: Text('Action',  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            ],
            rows: List.generate(_filtered.length, (i) {
              final c     = _filtered[i];
              final solde = double.tryParse(c['Solde'].toString()) ?? 0.0;
              return DataRow(cells: [
                DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                DataCell(Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: _primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        (c['client_name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _primaryColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(c['client_name'] ?? '',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                )),
                DataCell(Text(
                  solde.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: solde > 0 ? _dangerColor : _successColor,
                  ),
                )),
                DataCell(
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 13),
                    label: const Text('Encaisser', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    onPressed: () => _dialogEncaisser(c),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  // ── Tableau historique ─────────────────────────────────────────────────────
  Widget _tableHistorique() {
    if (_loadingHistorique) return const Center(child: CircularProgressIndicator());
    if (_historique.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Aucun encaissement enregistré',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(const Color(0xFFE8F5E9)),
            dataRowColor:
                WidgetStateProperty.resolveWith((_) => Colors.white),
            columnSpacing: 14,
            headingRowHeight: 40,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 48,
            columns: const [
              DataColumn(label: Text('#',       style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              DataColumn(label: Text('Client',  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              DataColumn(label: Text('Date',    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              DataColumn(label: Text('Reçu',   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            ],
            rows: List.generate(_historique.length, (i) {
              final h       = _historique[i];
              final montant = double.tryParse(h['Montpayer'].toString()) ?? 0.0;
              final date    = (h['DatePaiement'] ?? '').toString();
              final dateAff = date.length >= 16 ? date.substring(0, 16) : date;
              return DataRow(
                color: WidgetStateProperty.resolveWith(
                    (_) => i.isEven ? Colors.white : const Color(0xFFF9FBE7)),
                cells: [
                  DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                  DataCell(Flexible(
                    child: Text(h['client_name'] ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(Text(
                    '${montant.toStringAsFixed(2)} FC',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _successColor),
                  )),
                  DataCell(Text(dateAff,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
                  DataCell(
                    Tooltip(
                      message: 'Générer le reçu',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _genererRecu(h),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _successColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_outlined,
                              size: 18, color: _successColor),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────
  Widget _panelHeader({required IconData icon, required String title, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String   label,
    required String   value,
    required Color    color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
