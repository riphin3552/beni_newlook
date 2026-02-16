// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class Entreprise extends StatefulWidget {

  const Entreprise({super.key});

  @override
  State<Entreprise> createState() => _EntrepriseState();
}

class _EntrepriseState extends State<Entreprise> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _denomationController = TextEditingController();
  final TextEditingController _numeroRCCMController = TextEditingController();
  final TextEditingController _idNationalController = TextEditingController();
  final TextEditingController _numImpotController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Uint8List? _logoBytes;
  String? _logoName;
  String? _logoPath;

  // Fonction pour sélectionner le logo
  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _logoBytes = result.files.first.bytes;
        _logoName = result.files.first.name;
        _logoPath = result.files.first.path; // chemin complet
      });
    }
  }

  // Fonction pour enregistrer l'entreprise
  Future<void> saveEntreprise({
  required String denomination,
  required String numeroRCCM,
  required String idNational,
  required String numImpot,
  required String adresse,
  required String telephone,
  required String email,
  File? logoFile, // 👈 optionnel
  required BuildContext context,
}) async {
  var url = Uri.parse('https://riphin-salemanager.com/beni_newlook_API/Ajouter_Entreprise.php');
  var request = http.MultipartRequest('POST', url);

  // Champs texte
  request.fields['nomEntreprise'] = denomination;
  request.fields['NumeroRCCM'] = numeroRCCM;
  request.fields['IDNational'] = idNational;
  request.fields['NumeroImpot'] = numImpot;
  request.fields['AdresseEntreprise'] = adresse;
  request.fields['TelephoneEntreprise'] = telephone;
  request.fields['EmailEntreprise'] = email;

  // 👇 Ajout du logo seulement si non null
  if (logoFile != null && logoFile.path.isNotEmpty) {
    request.files.add(await http.MultipartFile.fromPath('logo', logoFile.path));
  }

  try {
    var response = await request.send().timeout(const Duration(seconds: 10));
    var responseBody = await response.stream.bytesToString();

    //print("Status: ${response.statusCode}"); // Pour le débogage
    //print("Body: $responseBody"); // Pour le débogage

    if (response.statusCode == 200) {
      var data = jsonDecode(responseBody);
      if (data['success'] == true) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
              title: Text('Succès'),
              content: Text('Entreprise enregistrée avec succès'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                ),
              ],
            );
          },
        );
        resetformulaire();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
              title: Text('Erreur'),
              content: Text('Erreur: ${data['message'] ?? 'Réponse inattendue'}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: Icon(Icons.warning_amber, color: Colors.orange, size: 48),
            title: Text('Erreur'),
            content: Text('Erreur serveur: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: Text('Erreur Réseau'),
          content: Text('Erreur réseau: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 121, 169, 240))),
            ),
          ],
        );
      },
    );
  }
}


// Initialisation des champs et du formulaire
void resetformulaire() {
  _denomationController.clear();
  _numeroRCCMController.clear();
  _idNationalController.clear();
  _numImpotController.clear();
  _adresseController.clear();
  _telephoneController.clear();
  _emailController.clear();
  setState(() { // Réinitialiser le logo
    _logoBytes = null;
    _logoName = null;
    _logoPath = null;
  });

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informations de l'Entreprise"),
        backgroundColor: Color.fromARGB(255, 121, 169, 240),
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: Color.fromARGB(255, 245, 248, 255),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                TextFormField(
                  controller: _denomationController,
                  decoration: InputDecoration(
                    labelText: 'Dénomination',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                    prefixIcon: Icon(Icons.business, color: Color.fromARGB(255, 121, 169, 240)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _numeroRCCMController,
                  decoration: InputDecoration(
                    labelText: 'Numéro RCCM',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                    prefixIcon: Icon(Icons.confirmation_number, color: Color.fromARGB(255, 121, 169, 240)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _idNationalController,
                  decoration: InputDecoration(
                    labelText: 'ID National',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                    prefixIcon: Icon(Icons.badge, color: Color.fromARGB(255, 121, 169, 240)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Champ obligatoire'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _numImpotController,
                  decoration: InputDecoration(
                    labelText: 'Numéro Impôt',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                    prefixIcon: Icon(Icons.confirmation_number, color: Color.fromARGB(255, 121, 169, 240)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Champ obligatoire'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _adresseController,
                  decoration: InputDecoration(
                    labelText: 'Adresse',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                    prefixIcon: Icon(Icons.location_on, color: Color.fromARGB(255, 121, 169, 240)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                    prefixIcon: Icon(Icons.phone, color: Color.fromARGB(255, 121, 169, 240)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color.fromARGB(255, 121, 169, 240)),
                    prefixIcon: Icon(Icons.email, color: Color.fromARGB(255, 121, 169, 240)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color.fromARGB(255, 121, 169, 240), width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Color.fromARGB(255, 245, 248, 255),
                      ),
                      child: _logoBytes != null
                          ? Image.memory(_logoBytes!, fit: BoxFit.cover)
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Aucun logo',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choisir un Logo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 121, 169, 240),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_logoName != null) ...[
                  const SizedBox(height: 10),
                  Text('Fichier sélectionné : $_logoName'),
                ],

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      saveEntreprise(
                        denomination: _denomationController.text,
                        numeroRCCM: _numeroRCCMController.text,
                        idNational: _idNationalController.text,
                        numImpot: _numImpotController.text,
                        adresse: _adresseController.text,
                        telephone: _telephoneController.text,
                        email: _emailController.text,
                        logoFile: _logoPath != null ? File(_logoPath!) : null,
                        context: context,
                      );
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text(
                    'Enregistrer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 121, 169, 240),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  
