import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FacturationchambreEspace extends StatefulWidget {
  final int identreprise;
  const FacturationchambreEspace({super.key, required this.identreprise});

  @override
  State<FacturationchambreEspace> createState() => _FacturationchambreEspaceState();
}

class _FacturationchambreEspaceState extends State<FacturationchambreEspace> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<dynamic>> _reservationsFuture;
  
  // Form Controllers
  final _clientController = TextEditingController();
  final _espaceController = TextEditingController();
  final _totalController = TextEditingController();
  final _dateFacturationController = TextEditingController();
  final _reductionController = TextEditingController();
  final _resteController = TextEditingController();
  final _acompteController = TextEditingController();
  final _moyenController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  // State variables for selection and logic
  int? _selectedReservationId;
  int? selectedEspaceId;
  String? _selectedTypePaiement;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reservationsFuture = displayReservations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clientController.dispose();
    _espaceController.dispose();
    _totalController.dispose();
    _dateFacturationController.dispose();
    _reductionController.dispose();
    _resteController.dispose();
    _acompteController.dispose();
    _moyenController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 121, 169, 240)),
      border: const OutlineInputBorder(),
    );
  }

  void _calculateReste() {
    double total = double.tryParse(_totalController.text) ?? 0.0;
    double reduction = double.tryParse(_reductionController.text) ?? 0.0;
    double netValue = total - reduction;

    double paid = 0.0;
    if (_selectedTypePaiement == "Acompte") {
      paid = double.tryParse(_acompteController.text) ?? 0.0;
    } else if (_selectedTypePaiement == "Total") {
      paid = netValue;
    }

    setState(() {
      _resteController.text = (netValue - paid).toStringAsFixed(2);
    });
  }

  void _onRowSelected(dynamic item) {
    setState(() {
      _selectedReservationId = item['IdReservation'];
      // Memorize the space ID (assuming the API returns it as 'IdEspace' or 'espace')
      selectedEspaceId = item['IdEspace'] ?? item['espace']; 
      
      _clientController.text = item['client_name']?.toString() ?? '';
      _espaceController.text = item['designationEspace']?.toString() ?? '';
      _totalController.text = item['Totalpayer']?.toString() ?? '0';
      _acompteController.clear();
      _selectedTypePaiement = null;
      _calculateReste();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Réservation de ${_clientController.text} sélectionnée"),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitFacturation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez d'abord sélectionner une réservation dans le tableau"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      // Simulated API Call
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text("Succès"),
          content: const Text("Facturation enregistrée avec succès"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _formKey.currentState!.reset();
                setState(() {
                  _selectedReservationId = null;
                  selectedEspaceId = null;
                  _clientController.clear();
                  _acompteController.clear();
                  _espaceController.clear();
                  _totalController.clear();
                });
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // Fetch the list of reservations to display in the table
  Future<List<dynamic>> displayReservations() async {
    try {
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficheReservations.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"entreprise": widget.identreprise.toString()}),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['success'] == true) return data['data'];
        return [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération des réservations: $e");
      return [];
    }
  }

  //Fonction pour enregistrer la facturation (à implémenter selon votre API)
  Future<void> enregistrerFacturation() async {
  if (_selectedReservationId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Veuillez d'abord sélectionner une réservation dans le tableau"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/FacturerChambreEspace.php");
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "date": _dateFacturationController.text,
        "reservation": _selectedReservationId.toString(), // ✅ clé adaptée à l’API
        "espacechambre": _espaceController.text,
        "total": _totalController.text,
        "reduction": _reductionController.text,
        "reste": _resteController.text,
        "acompte": _acompteController.text,
        "typePaiement": _selectedTypePaiement,
        "moyenPaiement": _moyenController.text,
        "entreprise": widget.identreprise,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data is Map && data.containsKey('success')) {
        if (data['success'] == true) {
          // ✅ Succès
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              title: const Text("Succès"),
              content: Text(data['message'] ?? "Facturation enregistrée avec succès"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _formKey.currentState!.reset();
                    setState(() {
                      _selectedReservationId = null;
                      selectedEspaceId = null;
                      _clientController.clear();
                      _acompteController.clear();
                      _espaceController.clear();
                      _totalController.clear();
                    });
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        } else {
          // ✅ Erreur côté API
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.error, color: Colors.red, size: 48),
              title: const Text("Erreur"),
              content: Text(data['message'] ?? "Une erreur est survenue"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
              ],
            ),
          );
        }
      } else {
        throw Exception("Réponse inattendue du serveur : ${response.body}");
      }
    } else {
      throw Exception("Erreur HTTP : ${response.statusCode}");
    }
  } catch (e) {
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text("Erreur de connexion"),
        content: Text("Impossible de se connecter au serveur.\n\nDétails : $e"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  } finally {
    setState(() => _isSubmitting = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturation Chambre Espace'),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 248, 255),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Facturation Form ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                initiallyExpanded: false,
                backgroundColor: Colors.white,
                title: const Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color.fromARGB(255, 121, 169, 240)),
                    SizedBox(width: 12),
                    Text(
                      "Détails de Facturation",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _clientController, readOnly: true, decoration: _inputDecoration(labelText: 'Client', icon: Icons.person))),
                              const SizedBox(width: 16),
                              Expanded(child: TextFormField(controller: _espaceController, readOnly: true, decoration: _inputDecoration(labelText: 'Espace', icon: Icons.bedroom_parent))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _totalController, readOnly: true, decoration: _inputDecoration(labelText: 'Montant Total', icon: Icons.attach_money))),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _dateFacturationController,
                                  readOnly: true,
                                  decoration: _inputDecoration(labelText: 'Date de Facturation', icon: Icons.calendar_today),
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                                    if (picked != null) setState(() => _dateFacturationController.text = picked.toString().split(' ')[0]);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _reductionController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(labelText: 'Réduction', icon: Icons.discount),
                                  onChanged: (val) => _calculateReste(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTypePaiement,
                                  decoration: _inputDecoration(labelText: 'Type de paiement', icon: Icons.payment),
                                  items: ["Total", "Acompte"].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedTypePaiement = val;
                                      if (val == "Total") _acompteController.clear();
                                    });
                                    _calculateReste();
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_selectedTypePaiement == "Acompte") ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _acompteController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(labelText: 'Montant Acompte', icon: Icons.payments),
                              onChanged: (val) => _calculateReste(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _resteController, readOnly: true, decoration: _inputDecoration(labelText: 'Reste à payer', icon: Icons.account_balance_wallet))),
                              const SizedBox(width: 16),
                              Expanded(child: TextFormField(controller: _moyenController, decoration: _inputDecoration(labelText: 'Moyen de paiement', icon: Icons.credit_card))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : enregistrerFacturation,
                            icon: _isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle),
                            label: Text(_isSubmitting ? 'Traitement...' : 'Valider la Facturation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 121, 169, 240),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une reservation par client...',
                  prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 121, 169, 240)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                  ),
                ),
              ),
            ),
            FutureBuilder<List<dynamic>>(
              future: _reservationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color.fromARGB(255, 121, 169, 240)));
                } else if (snapshot.hasError) {
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text("Aucune réservation trouvée", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                } else {
                  final filteredList = snapshot.data!.where((item) {
                    final clientName = item['client_name']?.toString().toLowerCase() ?? '';
                    return clientName.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredList.isEmpty) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text("Aucun résultat pour '$_searchQuery'", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                              headingRowHeight: 56,
                              dataRowHeight: 48,
                              horizontalMargin: 24,
                              border: TableBorder(
                                horizontalInside: BorderSide(color: Colors.grey[300]!),
                                bottom: BorderSide(color: Colors.grey[300]!),
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                              columns: const [
                                
                                DataColumn(label: Text("ID", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Client", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Espace", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Arrivée", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Départ", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Jours", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Total", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Statut", style: TextStyle(color: Color.fromARGB(255, 121, 169, 240), fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredList.reversed.toList().asMap().entries.map((entry) {
                                int index = entry.key;
                                var item = entry.value;
                                return DataRow(
                                  selected: _selectedReservationId == item['IdReservation'],
                                  onSelectChanged: (bool? selected) {
                                    if (selected != null && selected) _onRowSelected(item);
                                  },
                                  color: WidgetStateProperty.all(index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255)),
                                  cells: [
                                   
                                    DataCell(Text(item['IdReservation']?.toString() ?? '')),
                                    DataCell(Text(item['client_name']?.toString() ?? '')),
                                    DataCell(Text(item['designationEspace']?.toString() ?? '')),
                                    DataCell(Text(item['DateArrivee']?.toString() ?? '')),
                                    DataCell(Text(item['DateDepart']?.toString() ?? '')),
                                    DataCell(Text(item['NbreJours']?.toString() ?? '0')),
                                    DataCell(Text("${item['Totalpayer']} \$", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item['statutReservation'] == "Confirmée" ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['statutReservation']?.toString() ?? '',
                                          style: TextStyle(
                                            color: item['statutReservation'] == "Confirmée" ? Colors.green : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
