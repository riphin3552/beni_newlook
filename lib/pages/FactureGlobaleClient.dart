import 'dart:convert';
import 'package:beni_newlook/Rapports/FactureGlobale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

class FactureGlobaleClientPage extends StatefulWidget {
  final int idEntreprise;
  const FactureGlobaleClientPage({super.key, required this.idEntreprise});

  @override
  State<FactureGlobaleClientPage> createState() =>
      _FactureGlobaleClientPageState();
}

class _FactureGlobaleClientPageState extends State<FactureGlobaleClientPage> {
  static const _baseUrl = 'https://riphin-salemanager.com/beni_newlook_API/';
  static const _primary = Color(0xFF0D47A1);
  static const _accent = Color.fromARGB(255, 121, 169, 240);
  static const _green = Color(0xFF388E3C);
  static const _orange = Color(0xFFF57C00);
  static const _purple = Color(0xFF7B1FA2);

  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinController = TextEditingController();

  int? _selectedClientId;
  Map<String, dynamic>? _factureData;
  Map<String, dynamic>? _entreprise;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerEntreprise();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _chargerEntreprise() async {
    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}AfficherInfos_Ese.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idEse': widget.idEntreprise}),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d['data'] != null) {
          setState(() => _entreprise = Map<String, dynamic>.from(d['data']));
        }
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _rechercherClients(String pattern) async {
    if (pattern.length < 2) return [];
    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}FetchANDaddClient.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'client': pattern, 'entreprise': widget.idEntreprise}),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d['client'] != null) {
          return [
            {
              'client_id': d['client']['id'],
              'client_name': d['client']['client_name'],
              'phone_number': d['client']['phone_number'] ?? '',
            }
          ];
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _chargerFactureGlobale() async {
    if (_selectedClientId == null) {
      _snack('Veuillez sélectionner un client', Colors.orange);
      return;
    }
    if (_dateDebutController.text.isEmpty || _dateFinController.text.isEmpty) {
      _snack('Veuillez sélectionner les deux dates', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _factureData = null;
    });

    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}FactureGlobaleClient.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'entreprise': widget.idEntreprise,
          'client_id': _selectedClientId,
          'date1': _dateDebutController.text,
          'date2': _dateFinController.text,
        }),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d['success'] == true) {
          setState(() => _factureData = Map<String, dynamic>.from(d));
        } else {
          _snack(d['message'] ?? 'Aucune donnée trouvée pour ce client', Colors.orange);
        }
      } else {
        _snack('Erreur serveur: ${resp.statusCode}', Colors.red);
      }
    } catch (e) {
      _snack('Erreur réseau: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _imprimer() {
    if (_factureData == null || _entreprise == null) {
      _snack('Données non chargées', Colors.orange);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FactureGlobalePreviewPage(
          entreprise: _entreprise!,
          factureData: _factureData!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture Globale Client',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: _primary,
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      backgroundColor: const Color(0xFFF5F8FF),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Formulaire de recherche ────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.manage_search_rounded, color: _accent),
                      const SizedBox(width: 8),
                      Text(
                        'Sélection client & période',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    TypeAheadField<Map<String, dynamic>>(
                      controller: _clientController,
                      suggestionsCallback: _rechercherClients,
                      builder: (context, controller, focusNode) => TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Rechercher un client hébergé',
                          prefixIcon: const Icon(Icons.person_search, color: _accent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _accent, width: 2)),
                        ),
                      ),
                      itemBuilder: (context, s) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _accent.withValues(alpha: 0.15),
                          child: Text(
                            (s['client_name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(s['client_name']?.toString() ?? ''),
                        subtitle: Text(s['phone_number']?.toString() ?? ''),
                      ),
                      onSelected: (s) {
                        setState(() {
                          _selectedClientId = int.tryParse(s['client_id'].toString());
                          _clientController.text = s['client_name']?.toString() ?? '';
                          _factureData = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateDebutController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date Début',
                            prefixIcon: const Icon(Icons.calendar_today, color: _accent),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          onTap: () => _selectDate(_dateDebutController),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _dateFinController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date Fin',
                            prefixIcon: const Icon(Icons.event, color: _accent),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                          onTap: () => _selectDate(_dateFinController),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _chargerFactureGlobale,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.search_rounded),
                          label: Text(_isLoading ? 'Chargement...' : 'Afficher la Facture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      if (_factureData != null) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _imprimer,
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Imprimer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(150, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_factureData != null) _buildResume(),
          ],
        ),
      ),
    );
  }

  Widget _buildResume() {
    final client = (_factureData!['client'] as Map?)?.cast<String, dynamic>() ?? {};
    final logements = (_factureData!['logement'] as List?) ?? [];
    final autresServices = (_factureData!['autres_services'] as List?) ?? [];
    final restaurant = (_factureData!['restaurant'] as List?) ?? [];
    final totaux = (_factureData!['totaux'] as Map?)?.cast<String, dynamic>() ?? {};

    final totalGen = (num.tryParse(totaux['totalGeneral']?.toString() ?? '0') ?? 0).toDouble();
    final totalAcompte = (num.tryParse(totaux['totalAcompte']?.toString() ?? '0') ?? 0).toDouble();
    final totalReste = (num.tryParse(totaux['totalReste']?.toString() ?? '0') ?? 0).toDouble();

    return Expanded(
      child: SingleChildScrollView(
        child: Column(children: [
          // Client
          _sectionCard(
            'Informations Client',
            Icons.person_rounded,
            _primary,
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoRow(Icons.badge_rounded, client['client_name']?.toString() ?? ''),
              if ((client['phone_number'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.phone, client['phone_number'].toString()),
              if ((client['client_adress'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.location_on_rounded, client['client_adress'].toString()),
            ]),
          ),
          const SizedBox(height: 12),

          // Logement
          if (logements.isNotEmpty) ...[
            _sectionCard(
              'Logement  •  ${logements.length} facture(s)',
              Icons.bedroom_parent_rounded,
              _green,
              Column(children: [
                for (final l in logements) ...[
                  Row(children: [
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l['designationEspace']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          '${l['DateArrivee'] ?? ''} → ${l['DateDepart'] ?? ''}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ])),
                    Text('${l['Totalpayer']} \$',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _green)),
                  ]),
                  const Divider(height: 12),
                ],
                _sousTotalRow('Sous-total Logement',
                    '${totaux['totalLogement']} \$', _green),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Autres services
          if (autresServices.isNotEmpty) ...[
            _sectionCard(
              'Autres Services  •  ${autresServices.length} facture(s)',
              Icons.miscellaneous_services_rounded,
              _orange,
              Column(children: [
                for (final s in autresServices) ...[
                  Row(children: [
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['designationSectionAuxi']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          s['dateFacturation']?.toString().split(' ')[0] ?? '',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ])),
                    Text('${s['MontantPayer']} \$',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _orange)),
                  ]),
                  const Divider(height: 12),
                ],
                _sousTotalRow('Sous-total Services',
                    '${totaux['totalAutresServices']} \$', _orange),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Restaurant / Bar
          if (restaurant.isNotEmpty) ...[
            _sectionCard(
              'Restaurant / Bar  •  ${restaurant.length} facture(s)',
              Icons.restaurant_menu_rounded,
              _purple,
              Column(children: [
                for (final r in restaurant) ...[
                  Row(children: [
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r['nomSection']?.toString() ?? 'Restaurant/Bar',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          r['datecommande']?.toString().split(' ')[0] ?? '',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ])),
                    Text('${r['totalFacture']} \$',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _purple)),
                  ]),
                  const Divider(height: 12),
                ],
                _sousTotalRow('Sous-total Restaurant',
                    '${totaux['totalRestaurant']} \$', _purple),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Grand total
          Card(
            elevation: 5,
            color: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('TOTAL GÉNÉRAL',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15)),
                  Text('${totalGen.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20)),
                ]),
                const Divider(color: Colors.white24, height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Acompte versé',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('${totalAcompte.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Reste à payer',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '${totalReste.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      color: totalReste > 0 ? Colors.orangeAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Color color, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          content,
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
            child:
                Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _sousTotalRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 14)),
    ]);
  }
}

// ── Page de prévisualisation PDF ──────────────────────────────────────────────
class FactureGlobalePreviewPage extends StatelessWidget {
  final Map<String, dynamic> entreprise;
  final Map<String, dynamic> factureData;

  const FactureGlobalePreviewPage(
      {super.key, required this.entreprise, required this.factureData});

  @override
  Widget build(BuildContext context) {
    const accent = Color.fromARGB(255, 121, 169, 240);
    const primary = Color(0xFF0D47A1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prévisualisation Facture Globale',
            style: TextStyle(color: Colors.white)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 3,
      ),
      backgroundColor: const Color(0xFFF5F8FF),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Prévisualisation PDF',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                height: MediaQuery.of(context).size.height - 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: PdfPreview(
                    build: (format) async {
                      final pdf = await buildFactureGlobaleDocument(
                          entreprise, factureData);
                      return pdf.save();
                    },
                    allowPrinting: true,
                    allowSharing: true,
                    pdfFileName:
                        'facture_globale_${factureData['client']?['client_name'] ?? 'client'}.pdf',
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
