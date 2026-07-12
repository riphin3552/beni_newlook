//modification au 14/05/2023
import 'dart:convert';

import 'package:beni_newlook/Rapports/Facture.dart';
import 'package:beni_newlook/api_config.dart';
import 'package:beni_newlook/session_utilisateur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

class CommandePage extends StatefulWidget {
  final int idEntreprise;
  const CommandePage({super.key, required this.idEntreprise});

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _produitController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _dateController = TextEditingController();
  final _accompteController = TextEditingController();

  final TextEditingController prixController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController uniteController = TextEditingController();
  final TextEditingController seuilController = TextEditingController();

  List<Map<String, dynamic>> sections = [];
  DateTime? selectedDate;
  int? selectedClient;
  int? selectedSection;
  int? selectedProduit;
  int? selectedStockId;

  // true quand le produit sélectionné est non-stockable
  bool _isNonStockable = false;
  String? _selectedTypeRepas;

  List<Map<String, dynamic>> stock = [];

  @override
  void initState() {
    super.initState();
    fetchSections();
  }

  Map<String, dynamic>? produitDetails;
  final List<Map<String, dynamic>> panier = [];

  // ─── Suggestions ──────────────────────────────────────────────────────────
  // FetchProduit.php retourne un objet unique avec "estStockable" (bool)
  Future<List<Map<String, dynamic>>> _suggestionProduits(String pattern) async {
    if (pattern.isEmpty || pattern.length < 2) return [];

    final response = await http.post(
      Uri.parse("$apiBaseUrl/FetchProduit.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "produit": pattern,
        "entreprise": widget.idEntreprise.toString(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['produit'] != null) {
        final p = data['produit'];
        // L'API retourne toujours un objet unique (pas une liste)
        if (p is Map) {
          return [
            {
              "id": p['id'],
              "designationProduit": p['designationProduit'],
              "estStockable": p['estStockable'] ?? true,
            }
          ];
        }
        // Sécurité : si un jour l'API retourne une liste
        if (p is List) {
          return p
              .map<Map<String, dynamic>>((item) => {
                    "id": item['id'],
                    "designationProduit": item['designationProduit'],
                    "estStockable": item['estStockable'] ?? true,
                  })
              .toList();
        }
      }
    }
    return [];
  }

  // ─── Détails produit STOCKABLE ─────────────────────────────────────────────
  // FetchProduit_inStock_F(X)ese_idprod_idsection.php
  // Retourne { "success": true, "data": [ { IdStock, QuantiteDisponible, … } ] }
  Future<Map<String, dynamic>> fetchProduitDansStock() async {
    final response = await http.post(
      Uri.parse(
          "$apiBaseUrl/FetchProduit_inStock_F(X)ese_idprod_idsection.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "entreprise": widget.idEntreprise,
        "section": selectedSection,
        "produit": selectedProduit,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true && data["data"] != null) {
        final List produits = data["data"] as List;
        if (produits.isNotEmpty) {
          final p = produits.first as Map<String, dynamic>;
          return {
            "IdStock": p['IdStock'],
            "designationStock": p['designationStock'],
            "IdProduit": p['IdProduit'],
            "designationProduit": p['designationProduit'],
            "PrixVente": int.tryParse(p['PrixVente'].toString()) ?? 0,
            "uniteMesure": p['uniteMesure'],
            "seuil_minimum": p['seuil_minimum'],
            "QuantiteDisponible": p['QuantiteDisponible'],
            "idSection": p['idSection'],
            "descptionSection": p['descptionSection'],
            "Id_Ese": p['Id_Ese'],
            "isStockable": true,
          };
        }
        throw Exception("Aucun stock trouvé pour ce produit dans cette section");
      }
      throw Exception(data['message'] ?? "Produit introuvable dans le stock");
    }
    throw Exception("Erreur serveur: ${response.statusCode}");
  }

  // ─── Détails produit NON-STOCKABLE ────────────────────────────────────────
  // FetchProduit_NonStockable_F(X)ese_idprod_idsection.php
  // Retourne { "success": true, "data": { IdProduit, PrixVente, idSection, … } }
  // "data" est un OBJET unique (array_merge PHP), pas une liste
  Future<Map<String, dynamic>> fetchProduitNonStockable() async {
    final response = await http.post(
      Uri.parse(
          "$apiBaseUrl/FetchProduit_NonStockable_F(X)ese_idprod_idsection.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "entreprise": widget.idEntreprise,
        "section": selectedSection,
        "produit": selectedProduit,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true && data["data"] != null) {
        // data["data"] est un Map (objet JSON), pas une liste
        final p = Map<String, dynamic>.from(data["data"] as Map);
        return {
          "IdStock": null,           // pas de stock pour ce type
          "designationStock": null,
          "IdProduit": p['IdProduit'],
          "designationProduit": p['designationProduit'],
          "PrixVente": int.tryParse(p['PrixVente'].toString()) ?? 0,
          "uniteMesure": p['uniteMesure'] ?? "Unité",
          "seuil_minimum": null,     // pas de seuil à surveiller
          "QuantiteDisponible": null, // pas de stock à vérifier
          "idSection": p['idSection'],
          "descptionSection": p['descptionSection'],
          "Id_Ese": p['Id_Ese'],
          "isStockable": false,
        };
      }
      throw Exception(data['message'] ?? "Produit non-stockable introuvable");
    }
    throw Exception("Erreur serveur: ${response.statusCode}");
  }

  // ─── Ajout au panier ──────────────────────────────────────────────────────
  // Vérifie le stock uniquement pour les produits stockables
  void _ajouterAuPanier(Map<String, dynamic> details) {
    if (details.isEmpty || _quantiteController.text.isEmpty) return;

    final quantite = int.tryParse(_quantiteController.text);
    if (quantite == null || quantite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer une quantité valide")),
      );
      return;
    }

    // Contrôle de stock uniquement pour les produits stockables
    if (!_isNonStockable && details["QuantiteDisponible"] != null) {
      final stockDispo =
          int.tryParse(details["QuantiteDisponible"].toString()) ?? 0;
      if (quantite > stockDispo) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Quantité trop élevée par rapport au stock disponible")),
        );
        return;
      }
    }

    // Pour les non-stockables, le type de repas est obligatoire
    if (_isNonStockable && (_selectedTypeRepas == null || _selectedTypeRepas!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner le type de repas")),
      );
      return;
    }

    final prixUnitaire = int.tryParse(details["PrixVente"].toString()) ?? 0;

    final index =
        panier.indexWhere((item) => item["id"] == details["IdProduit"]);
    if (index != -1) {
      final int ancienneQte = (panier[index]["quantite"] as int?) ?? 0;
      final int nouvelleQte = ancienneQte + quantite;
      panier[index]["quantite"] = nouvelleQte;
      panier[index]["prixTotal"] = nouvelleQte * (panier[index]["prixUnitaire"] as int);
    } else {
      panier.add({
        "id": details["IdProduit"],
        "idStock": details["IdStock"],
        "idSection": details["idSection"],
        "produit": details["designationProduit"],
        "quantite": quantite,
        "prixUnitaire": prixUnitaire,
        "prixTotal": quantite * prixUnitaire,
        "isStockable": !_isNonStockable,
        "typeRepas": _isNonStockable ? _selectedTypeRepas : null,
      });
    }

    setState(() {
      produitDetails = null;
      _isNonStockable = false;
      _selectedTypeRepas = null;
    });
    _produitController.clear();
    _quantiteController.clear();
    prixController.clear();
    stockController.clear();
    uniteController.clear();
    seuilController.clear();
  }

  double get total {
    return panier.fold(
        0, (sum, item) => sum + (item["quantite"] * item["prixUnitaire"]));
  }

  double get _accompte {
    final val = double.tryParse(_accompteController.text);
    if (val == null || val < 0) return total;
    return val > total ? total : val;
  }

  double get _restApayer => (total - _accompte).clamp(0, double.infinity);

  Future<void> fetchSections() async {
    var url = Uri.parse(
        "$apiBaseUrl/AfficherSectionsPrincipales.php");
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"entreprise": widget.idEntreprise}),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        sections = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> fetchProduitInStock() async {
    if (selectedSection == null || selectedClient == null) {
      setState(() {
        stock = [];
        selectedStockId = null;
      });
      return;
    }

    final url = Uri.parse(
      "$apiBaseUrl/FetchProduit_inStock_F(X)ese_idprod_idsection.php",
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "section": selectedSection,
        "produit": selectedProduit,
        "entreprise": widget.idEntreprise,
      }),
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);

      if (data is List) {
        final records = List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)));
        setState(() {
          stock = records;
          selectedStockId = records.isNotEmpty
              ? int.tryParse(records[0]['IdStock']?.toString() ?? '')
              : null;
        });
        return;
      }

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final allRecords = <Map<String, dynamic>>[];
        for (final item in data['results']) {
          if (item is Map<String, dynamic> && item.containsKey('data')) {
            final dataList = item['data'];
            if (dataList is List) {
              allRecords.addAll(List<Map<String, dynamic>>.from(
                  dataList.map((r) => Map<String, dynamic>.from(r))));
            }
          }
        }
        setState(() {
          stock = allRecords;
          selectedStockId = allRecords.isNotEmpty
              ? int.tryParse(allRecords[0]['IdStock']?.toString() ?? '')
              : null;
        });
        return;
      }

      setState(() {
        stock = [];
        selectedStockId = null;
      });
    }
  }

  // ─── Enregistrement commande ───────────────────────────────────────────────
  // idStock est null pour les lignes non-stockables → le backend doit ignorer
  // la mise à jour du stock pour ces lignes (champ isStockable envoyé en plus)
  Future<void> addCommande() async {
    var url = Uri.parse(
        "$apiBaseUrl/RegisterCommandeANDFacturer.php");

    double montantTotal = panier.fold(
        0, (sum, item) => sum + (item["quantite"] * item["prixUnitaire"]));

    List<Map<String, dynamic>> details = panier.map((item) {
      // Cast explicite : garantit que la valeur saisie (int) est envoyée,
      // jamais null, que le produit soit stockable ou non
      final int qte = (item["quantite"] as int?) ?? 0;
      final int pu  = (item["prixUnitaire"] as int?) ?? 0;
      return {
        "idProduit": item["id"],
        "idStock": item["idStock"],
        "idSection": item["idSection"],
        "quantiteCommande": qte,
        "prixUnitaire": pu,
        "sousTotal": qte * pu,
        "isStockable": item["isStockable"],
        "typeRepas": item["typeRepas"],
      };
    }).toList();

    final double accompteVal = _accompte;
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionUtilisateur.token,
      },
      body: json.encode({
        "entreprise": widget.idEntreprise,
        "client": selectedClient,
        "datecommande": _dateController.text,
        "statutcommande": "Facturée",
        "prixtotal": montantTotal,
        "accompte": accompteVal,
        "montantEntreeCaisse": accompteVal,
        "sourceMontant": selectedSection,
        "MotifsEnteeCaisse": "vente du jour",
        "dateEntreeCaisse": _dateController.text,
        "details": details,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success']) {
        final double resteApayer =
            double.tryParse(data['restApayer']?.toString() ?? '0') ?? 0;

        showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: _green, size: 24),
                    const SizedBox(width: 8),
                    const Text("Commande enregistrée",
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        "La commande a été enregistrée et facturée avec succès."),
                    if (resteApayer > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFD32F2F), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Reste dû : ${resteApayer.toStringAsFixed(2)} CDF\nAjouté au compte client comme dette.",
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (resteApayer > 0)
                    TextButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined,
                          size: 16, color: Color(0xFFD32F2F)),
                      label: const Text("Voir Recouvrement",
                          style: TextStyle(color: Color(0xFFD32F2F))),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      int? idcommande = data['idCommande'];
                      final factureResponse = await http.post(
                        Uri.parse(
                            "$apiBaseUrl/facture.php"),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          "entreprise": widget.idEntreprise,
                          "idCommande": idcommande
                        }),
                      );
                      if (!mounted) return;
                      final factureData = jsonDecode(factureResponse.body);
                      if (factureData['success'] &&
                          factureData['data'] != null) {
                        final entrepriseResponse = await http.post(
                          Uri.parse(
                              "$apiBaseUrl/AfficherInfos_Ese.php"),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({"idEse": widget.idEntreprise}),
                        );
                        if (!mounted) return;
                        final entrepriseData =
                            jsonDecode(entrepriseResponse.body)['data'];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FacturePreviewPage(
                              entreprise: entrepriseData,
                              facture: factureData['data'],
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                            context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                title: const Text("Erreur"),
                                content: Text(
                                    "La facture n'a pas pu être récupérée: ${factureData['message']}"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(),
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            });
                      }
                    },
                    child: const Text("Voir la facture"),
                  ),
                ],
              );
            });
      } else {
        showDialog(
            context: context,
            builder: (BuildContext ctx) {
              return AlertDialog(
                title: const Text("Erreur"),
                content: Text(
                    "Échec de l'enregistrement: ${data['message']}"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("OK"),
                  ),
                ],
              );
            });
      }
    } else {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text("Erreur"),
              content: Text("Erreur serveur: ${response.statusCode}"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("OK"),
                ),
              ],
            );
          });
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  static const Color _primary = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF1976D2);
  static const Color _bgLight = Color(0xFFF5F8FF);
  static const Color _green = Color(0xFF388E3C);
  static const Color _orange = Color(0xFFF57C00);

  InputDecoration _inputDecoration(
      {required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _accent),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionHeader(
      String numero, String titre, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(numero,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(titre,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _styledCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text('Nouvelle Commande',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ══════════════════════════════════════════════════
            // PANNEAU GAUCHE — Infos client + Sélection produit
            // ══════════════════════════════════════════════════
            Expanded(
              flex: 42,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('1', 'Informations générales',
                          Icons.info_outline, _accent),
                      _buildInformationsGeneralesCard(),
                      const SizedBox(height: 20),
                      _sectionHeader('2', 'Sélection du produit',
                          Icons.inventory_2_outlined,
                          const Color(0xFF7B1FA2)),
                      _buildDetailsProduitCard(),
                    ],
                  ),
                ),
              ),
            ),

            // Séparateur
            Container(width: 1, color: Colors.grey.shade200),

            // ══════════════════════════════════════════════════
            // PANNEAU DROIT — Panier + Paiement + Validation
            // ══════════════════════════════════════════════════
            Expanded(
              flex: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête panier
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: _sectionHeader('3', 'Panier de commande',
                        Icons.shopping_cart_outlined, _green),
                  ),

                  // Tableau panier — prend tout l'espace disponible
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCartCard(),
                    ),
                  ),

                  // Section paiement + bouton valider
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildTotalAndValidateSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationsGeneralesCard() {
    return _styledCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypeAheadField<Map<String, dynamic>>(
              controller: _clientController,
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty || pattern.length < 2) return [];
                final response = await http.post(
                  Uri.parse(
                      '$apiBaseUrl/FetchANDaddClient.php'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'client': pattern,
                    'entreprise': widget.idEntreprise
                  }),
                );
                if (response.statusCode == 200) {
                  final json = jsonDecode(response.body);
                  if (json['client'] != null) {
                    return [
                      {
                        "client_id": json['client']['id'],
                        "client_name": json['client']['client_name'],
                        "Id_Ese": json['client']['Id_Ese'],
                      }
                    ];
                  }
                }
                return [];
              },
              builder: (context, controller, focusNode) => TextFormField(
                controller: _clientController,
                focusNode: focusNode,
                decoration: _inputDecoration(
                    labelText: 'Rechercher client',
                    icon: Icons.person_search_outlined),
                validator: (v) => v == null || v.isEmpty
                    ? 'Veuillez entrer un client'
                    : null,
              ),
              itemBuilder: (context, s) => ListTile(
                leading: const Icon(Icons.person, color: _accent),
                title: Text(s['client_name']),
              ),
              onSelected: (s) => setState(() {
                _clientController.text = s['client_name'];
                selectedClient = s['client_id'];
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: selectedSection,
              decoration: _inputDecoration(
                  labelText: 'Source / Section',
                  icon: Icons.storefront_outlined),
              items: sections
                  .map((s) => DropdownMenuItem<int>(
                        value: s['idSection'],
                        child: Text(s['descptionSection']),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedSection = v),
              validator: (v) =>
                  v == null ? 'Veuillez sélectionner une section' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsProduitCard() {
    final Color cardColor =
        _isNonStockable ? const Color(0xFFFFF3E0) : const Color(0xFFF3E5F5);
    final Color themeColor =
        _isNonStockable ? _orange : const Color(0xFF7B1FA2);

    return _styledCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ recherche produit — affiche le type dans la liste
            TypeAheadField<Map<String, dynamic>>(
              key: UniqueKey(),
              controller: _produitController,
              suggestionsCallback: _suggestionProduits,
              builder: (context, controller, focusNode) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: _inputDecoration(
                    labelText: 'Rechercher un produit (stockable ou non)',
                    icon: Icons.search),
              ),
              itemBuilder: (context, s) {
                final bool nonStock = s['estStockable'] == false;
                return ListTile(
                  leading: Icon(
                    nonStock
                        ? Icons.restaurant_outlined
                        : Icons.inventory_2_outlined,
                    color: nonStock ? _orange : const Color(0xFF7B1FA2),
                  ),
                  title: Text(s['designationProduit']),
                  subtitle: Text(
                    nonStock ? 'Non-stockable' : 'Stockable',
                    style: TextStyle(
                      fontSize: 11,
                      color: nonStock ? _orange : const Color(0xFF7B1FA2),
                    ),
                  ),
                );
              },
              onSelected: (s) async {
                if (selectedSection == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Veuillez d\'abord sélectionner une section.')),
                  );
                  return;
                }

                selectedProduit = int.parse(s['id'].toString());
                final bool nonStock = s['estStockable'] == false;

                try {
                  final Map<String, dynamic> produit = nonStock
                      ? await fetchProduitNonStockable()
                      : await fetchProduitDansStock();

                  setState(() {
                    produitDetails = produit;
                    _isNonStockable = nonStock;
                    _produitController.text = produit['designationProduit'];
                    prixController.text = produit['PrixVente'].toString();
                    uniteController.text =
                        produit['uniteMesure']?.toString() ?? '';
                    stockController.text = nonStock
                        ? 'N/A'
                        : (produit['QuantiteDisponible'] ?? '0').toString();
                    seuilController.text = nonStock
                        ? 'N/A'
                        : (produit['seuil_minimum'] ?? '0').toString();
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Erreur chargement produit: $e')),
                    );
                  }
                }
              },
            ),

            // Fiche produit (visible une fois sélectionné)
            if (produitDetails != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: themeColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge type de produit
                    Row(
                      children: [
                        Icon(
                          _isNonStockable
                              ? Icons.restaurant_outlined
                              : Icons.inventory_2_outlined,
                          size: 15,
                          color: themeColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isNonStockable
                              ? 'Produit non-stockable'
                              : 'Produit stockable',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF7B1FA2), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              _infoChip(
                                  Icons.attach_money,
                                  'Prix',
                                  '${produitDetails!["PrixVente"]} CDF',
                                  _green),
                              _infoChip(Icons.square_foot, 'Unité',
                                  uniteController.text, _orange),
                              // Stock et seuil uniquement pour les stockables
                              if (!_isNonStockable) ...[
                                _infoChip(Icons.inventory, 'Stock',
                                    stockController.text, _accent),
                                _infoChip(
                                    Icons.warning_amber_rounded,
                                    'Seuil',
                                    seuilController.text,
                                    const Color(0xFFD32F2F)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Prix modifiable
                        SizedBox(
                          width: 130,
                          child: TextFormField(
                            controller: prixController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                                labelText: 'Prix vente',
                                icon: Icons.edit),
                            onChanged: (val) {
                              produitDetails!['PrixVente'] =
                                  int.tryParse(val) ??
                                      produitDetails!['PrixVente'];
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // ── Dropdown Type de repas (non-stockables uniquement) ──────────
            if (_isNonStockable) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedTypeRepas,
                decoration: _inputDecoration(
                  labelText: 'Type de repas',
                  icon: Icons.restaurant_menu_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'Petit déjeuner', child: Text('Petit déjeuner')),
                  DropdownMenuItem(value: 'Déjeuner',       child: Text('Déjeuner')),
                  DropdownMenuItem(value: 'Dîner',          child: Text('Dîner')),
                  DropdownMenuItem(value: 'Souper',         child: Text('Souper')),
                ],
                onChanged: (v) => setState(() => _selectedTypeRepas = v),
                validator: (_) => (_isNonStockable && (_selectedTypeRepas == null || _selectedTypeRepas!.isEmpty))
                    ? 'Veuillez choisir un type de repas'
                    : null,
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantiteController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                        labelText: 'Quantité à commander',
                        icon: Icons.production_quantity_limits),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Veuillez entrer une quantité'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (produitDetails != null) {
                          _ajouterAuPanier(produitDetails!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Veuillez sélectionner un produit d\'abord.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('Ajouter au panier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600)),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartCard() {
    return _styledCard(
      child: Column(
        children: [
          // En-tête colonnes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text('Produit',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _green,
                            fontSize: 13))),
                Expanded(
                    flex: 2,
                    child: Text('Qté',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _green,
                            fontSize: 13))),
                Expanded(
                    flex: 3,
                    child: Text('Prix unit.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _green,
                            fontSize: 13))),
                Expanded(
                    flex: 3,
                    child: Text('Sous-total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _green,
                            fontSize: 13))),
                const SizedBox(width: 44),
              ],
            ),
          ),
          const Divider(height: 1),

          if (panier.isEmpty)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Le panier est vide',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 15)),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: panier.length,
              separatorBuilder: (_, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = panier[index];
                final bool stockable = item['isStockable'] ?? true;
                final isEven = index.isEven;
                return Container(
                  color: isEven ? Colors.white : _bgLight,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(item['produit'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            if (!stockable && item['typeRepas'] != null)
                              Row(
                                children: [
                                  Icon(Icons.restaurant_menu_outlined,
                                      size: 11, color: _orange),
                                  const SizedBox(width: 3),
                                  Text(item['typeRepas'],
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: _orange,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            const SizedBox(height: 2),
                            // Badge stockable / non-stockable
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: stockable
                                    ? const Color(0xFF7B1FA2)
                                        .withValues(alpha: 0.12)
                                    : _orange.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Text(
                                stockable
                                    ? 'Stockable'
                                    : 'Non-stockable',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: stockable
                                      ? const Color(0xFF7B1FA2)
                                      : _orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(item['quantite'].toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _accent)),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('${item["prixUnitaire"]}',
                            textAlign: TextAlign.right,
                            style:
                                TextStyle(color: Colors.grey[700])),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${item["quantite"] * item["prixUnitaire"]}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _green),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () =>
                              setState(() => panier.removeAt(index)),
                          tooltip: 'Retirer',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),        // ferme Expanded
        ],
      ),
    );
  }

  Widget _buildTotalAndValidateSection() {
    final double rest = _restApayer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Résumé financier ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL À PAYER',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Text('${total.toStringAsFixed(2)} CDF',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Acompte versé ─────────────────────────────────────────────────
        _styledCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('4', 'Paiement', Icons.payments_outlined, _orange),
                TextFormField(
                  controller: _accompteController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(
                    labelText: 'Acompte versé (CDF)',
                    icon: Icons.monetization_on_outlined,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        'Acompte',
                        '${_accompte.toStringAsFixed(2)} CDF',
                        _green,
                        Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryTile(
                        'Reste (dette)',
                        '${rest.toStringAsFixed(2)} CDF',
                        rest > 0 ? const Color(0xFFD32F2F) : _green,
                        rest > 0 ? Icons.warning_amber_rounded : Icons.done_all,
                      ),
                    ),
                  ],
                ),
                if (rest > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.red[700]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${rest.toStringAsFixed(2)} CDF seront ajoutés comme dette au compte du client.',
                            style: TextStyle(
                                fontSize: 11, color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, size: 22),
          label: const Text('Valider la commande et Facturer',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          onPressed: panier.isEmpty
              ? null
              : () async {
                  await addCommande();
                  setState(() {
                    panier.clear();
                    _clientController.clear();
                    _produitController.clear();
                    _accompteController.clear();
                    _dateController.text = '';
                    produitDetails = null;
                    _isNonStockable = false;
                    selectedClient = null;
                    selectedSection = null;
                    selectedProduit = null;
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
        ),
      ],
    );
  }
}
