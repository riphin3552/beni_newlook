import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AjouterClient extends StatefulWidget {
  final int identreprise;
  const AjouterClient({super.key, required this.identreprise});

  @override
  State<AjouterClient> createState() => _AjouterClientState();
}

class _AjouterClientState extends State<AjouterClient> {
  final _formKey = GlobalKey<FormState>();

  final _clientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idCardController = TextEditingController();
  final _nationaliteController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _clientAddressController = TextEditingController();

  late Future<List<dynamic>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _clientsFuture = fetchClients(widget.identreprise);
  }

  String _selectedTypePiece = "Carte de lecteur";

 

  bool _isLoading = false;

  void resetForm() {
    _formKey.currentState!.reset();
    _clientNameController.clear();
    _phoneController.clear();
    _idCardController.clear();
    _nationaliteController.clear();
    _dateNaissanceController.clear();
    _clientAddressController.clear();
    setState(() {
      _selectedTypePiece = "Carte de lecteur";
    });
  }

  Future<void> addClient() async {
    try {
      setState(() {
        _isLoading = true;
      });
      var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/Addclient.php");
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "nomClient": _clientNameController.text,
          "telephone": _phoneController.text,
          "numcarte": _idCardController.text,
          "descCarte": _selectedTypePiece,
          "nationalite": _nationaliteController.text,
          "dateNaissance": _dateNaissanceController.text,
          "adresse": _clientAddressController.text,
          "entreprise": widget.identreprise,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });

        var responseData = jsonDecode(response.body);
        print("body: ${response.body}");
        print(responseData);
        if (responseData['success'] == true) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                title: const Text('Succès'),
                content: const Text("Client ajouté avec succès"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                  ),
                ],
              );
            },
          );
          resetForm();
          setState(() {
            _clientsFuture = fetchClients(widget.identreprise);
          });
        } else {
          _showErrorDialog("Erreur d'enregistrement: ${responseData['error']}");
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Erreur de connexion: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
            ),
          ],
        );
      },
    );
  }


//Affchager la liste des clients
Future<List<dynamic>> fetchClients(int entrepriseId) async {
  try {
    var url = Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherClients.php");
    var response = await http.post(
      url, 
      headers: {'Content-Type': 'application/json'}, 
      body: json.encode({"entreprise": entrepriseId}));

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      if(responseData is List) {
          return responseData;
      } else if (responseData is Map && responseData['success'] == true) {

        return responseData['data'];
      }
      return [];
    } else {
      _showErrorDialog("Erreur de chargement des clients: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    _showErrorDialog("Erreur de connexion: $e");
    return [];
  }
}


// afficher les champs de saisie pour ajouter un client
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 121, 169, 240)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _nationaliteController.dispose();
    _dateNaissanceController.dispose();
    _clientAddressController.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter Client"),
        backgroundColor: const Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  backgroundColor: Colors.white,
                  title: const Row(
                    children: [
                      Icon(Icons.person_add, color: Color.fromARGB(255, 121, 169, 240)),
                      SizedBox(width: 12),
                      Text(
                        "Informations du Client",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 121, 169, 240),
                        ),
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
                            _buildTextField(_clientNameController, "Nom Complet", Icons.person),
                            const SizedBox(height: 16),
                            _buildTextField(_phoneController, "Téléphone", Icons.phone, keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildTextField(_idCardController, "Numéro de Pièce d'Identité", Icons.badge),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  "Type de Pièce d'Identité",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Carte de lecteur', style: TextStyle(fontSize: 12)),
                                    value: 'Carte de lecteur',
                                    groupValue: _selectedTypePiece,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color.fromARGB(255, 121, 169, 240),
                                    onChanged: (value) => setState(() => _selectedTypePiece = value!),
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Passport', style: TextStyle(fontSize: 12)),
                                    value: 'Passport',
                                    groupValue: _selectedTypePiece,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color.fromARGB(255, 121, 169, 240),
                                    onChanged: (value) => setState(() => _selectedTypePiece = value!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(_nationaliteController, "Nationalité", Icons.flag),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dateNaissanceController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Date de Naissance",
                                prefixIcon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 121, 169, 240)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                                ),
                              ),
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    _dateNaissanceController.text =
                                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                  });
                                }
                              },
                              validator: (value) => (value == null || value.isEmpty)
                                  ? 'Ce champ est requis'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(_clientAddressController, "Adresse Résidentielle", Icons.home),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () {
                                if (_formKey.currentState!.validate()) {
                                  addClient();
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Enregistrer le Client', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 121, 169, 240),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // --- Tableau des Clients ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: _clientsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 121, 169, 240)),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 24),
                            const SizedBox(width: 12),
                            Expanded(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  } else {
                    final clients = snapshot.data ?? [];
                    if (clients.isEmpty) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.group_off_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                "Aucun client enregistré",
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              const Color.fromARGB(255, 121, 169, 240).withOpacity(0.15)),
                          headingRowHeight: 56,
                          dataRowMaxHeight: 56,
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                          columns: const [
                            DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Nom", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Téléphone", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("N° Pièce", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Nationalité", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Né(e) le", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                            DataColumn(label: Text("Adresse", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 121, 169, 240)))),
                          ],
                          rows: clients.asMap().entries.map((entry) {
                            int index = entry.key;
                            var client = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.all(
                                index.isEven ? Colors.white : const Color.fromARGB(255, 245, 248, 255),
                              ),
                              cells: [
                                DataCell(Text(client['client_id'].toString())),
                                DataCell(Text(client['client_name'] ?? "")),
                                DataCell(Text(client['phone_number'] ?? "-")),
                                DataCell(Text(client['ID_card'] ?? "-")),
                                DataCell(Text(client['DescriptionCarte'] ?? "-")),
                                DataCell(Text(client['nationalite'] ?? "-")),
                                DataCell(Text(client['dateNaissance'] ?? "-")),
                                DataCell(Text(client['client_adress'] ?? "-")),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}


    