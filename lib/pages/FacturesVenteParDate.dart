import 'dart:convert';
import 'package:beni_newlook/Rapports/Facture.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class FacturesVenteParDate extends StatefulWidget {
  final int idEntreprise;
  const FacturesVenteParDate({super.key, required this.idEntreprise});

  @override
  State<FacturesVenteParDate> createState() => _FacturesVenteParDateState();
}

class _FacturesVenteParDateState extends State<FacturesVenteParDate> {
  static const _primary  = Color(0xFF0D47A1);
  static const _accent   = Color(0xFF1976D2);
  static const _green    = Color(0xFF388E3C);
  static const _orange   = Color(0xFFF57C00);
  static const _red      = Color(0xFFD32F2F);
  static const _bgLight  = Color(0xFFF5F8FF);
  static const _baseUrl  = 'https://riphin-salemanager.com/beni_newlook_API/';

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _factures = [];
  double _totalJournee = 0;
  bool _loading = false;
  Map<String, dynamic>? _entreprise;

  // Sections
  List<Map<String, dynamic>> _sections = [];
  int? _selectedSectionId; // null = toutes

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      _chargerSections();
      _charger();
      _chargerEntreprise();
    });
  }

  Future<void> _chargerSections() async {
    try {
      final resp = await http.post(
        Uri.parse('${_baseUrl}AfficherSectionsPrincipales.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entreprise': widget.idEntreprise}),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d is List) {
          setState(() => _sections = List<Map<String, dynamic>>.from(d));
        }
      }
    } catch (_) {}
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

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final body = <String, dynamic>{
        'entreprise': widget.idEntreprise,
        'date': dateStr,
      };
      if (_selectedSectionId != null) {
        body['idSection'] = _selectedSectionId;
      }

      final resp = await http.post(
        Uri.parse('${_baseUrl}AfficherFacturesVente_parDate.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d['success'] == true) {
          setState(() {
            _factures     = List<Map<String, dynamic>>.from(d['data']);
            _totalJournee = (d['totalJournee'] as num).toDouble();
          });
        } else {
          _snack(d['message'] ?? 'Erreur serveur', Colors.red);
        }
      }
    } catch (e) {
      _snack('Erreur réseau : $e', Colors.red);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _charger();
    }
  }

  void _imprimer(Map<String, dynamic> facture) {
    if (_entreprise == null) {
      _snack('Informations entreprise non chargées', Colors.orange);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacturePreviewPage(
          entreprise: _entreprise!,
          facture: facture,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateAff = DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate);

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text('Factures de vente',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: _charger,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Barre de filtres ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // Date
                const Icon(Icons.calendar_today_outlined,
                    color: _accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  dateAff,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _primary),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _choisirDate,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 15),
                  label: const Text('Changer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 20),

                // Filtre section — prend tout l'espace restant
                const Icon(Icons.store_outlined, color: _accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedSectionId,
                    decoration: InputDecoration(
                      labelText: 'Section',
                      labelStyle:
                          const TextStyle(fontSize: 12, color: _accent),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _accent)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: _accent.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: _accent, width: 2)),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Toutes les sections',
                            style: TextStyle(fontSize: 13)),
                      ),
                      ..._sections.map((s) => DropdownMenuItem<int?>(
                            value: int.tryParse(s['idSection'].toString()),
                            child: Text(
                              s['descptionSection'] ?? '',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedSectionId = val);
                      _charger();
                    },
                  ),
                ),
                const SizedBox(width: 20),

                // Badges récapitulatifs
                _statBadge(
                  '${_factures.length} facture(s)',
                  Icons.receipt_long_outlined,
                  _accent,
                ),
                const SizedBox(width: 12),
                _statBadge(
                  '${_totalJournee.toStringAsFixed(2)} CDF',
                  Icons.account_balance_wallet_outlined,
                  _green,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Tableau des factures ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary))
                : _factures.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 72, color: Colors.grey[300]),
                            const SizedBox(height: 14),
                            Text(
                              'Aucune facture pour le $dateAff'
                              '${_selectedSectionId != null ? " (section filtrée)" : ""}',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // En-tête colonnes
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: _ColHeader('#')),
                Expanded(flex: 3, child: _ColHeader('Client')),
                Expanded(flex: 2, child: _ColHeader('Section')),
                Expanded(flex: 2, child: _ColHeader('Total')),
                Expanded(flex: 2, child: _ColHeader('Acompte')),
                Expanded(flex: 2, child: _ColHeader('Reste/Dette')),
                Expanded(flex: 2, child: _ColHeader('Statut')),
                SizedBox(width: 100, child: _ColHeader('Impression')),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lignes
          Expanded(
            child: ListView.separated(
              itemCount: _factures.length,
              separatorBuilder: (context, i) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final f        = _factures[i];
                final total    = (f['totalFacture'] as num).toDouble();
                final accompte = (f['Accompte'] as num).toDouble();
                final reste    = (f['RestApayer'] as num).toDouble();
                final statut   = f['statutcommande']?.toString() ?? '';
                final section  = f['nomSection']?.toString() ?? '—';

                return Container(
                  color: i.isEven ? Colors.white : _bgLight,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('${f['IdFacture']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                fontSize: 12)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  _accent.withValues(alpha: 0.12),
                              child: Text(
                                (f['client_name'] ?? '?')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _accent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(f['client_name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(section,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('${total.toStringAsFixed(2)} CDF',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('${accompte.toStringAsFixed(2)} CDF',
                            style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${reste.toStringAsFixed(2)} CDF',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: reste > 0 ? _red : _green,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(statut,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _accent,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton.icon(
                          onPressed: () => _imprimer(f),
                          icon: const Icon(Icons.print_outlined, size: 14),
                          label: const Text('Imprimer',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Pied de tableau — total journée
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.summarize_outlined,
                    color: _primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'TOTAL :',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _primary,
                      fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_totalJournee.toStringAsFixed(2)} CDF',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _green,
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, IconData icon, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D47A1),
            fontSize: 12));
  }
}
