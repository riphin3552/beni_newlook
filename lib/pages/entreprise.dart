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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entreprise enregistrée avec succès')),
        );
        resetformulaire(); // Réinitialiser le formulaire après succès
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${data['message'] ?? 'Réponse inattendue'}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur serveur: ${response.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur réseau: $e')),
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
        title: const Text("Informations de l'entreprise")
        ),
      body: Padding( 
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            color: const Color.fromARGB(255, 211, 225, 247),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _denomationController,
                  decoration: const InputDecoration(
                    labelText: 'Dénomination',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                TextFormField(
                  controller: _numeroRCCMController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro RCCM',
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                TextFormField(
                  controller: _idNationalController,
                  decoration: const InputDecoration(
                    labelText: 'ID National',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Champ obligatoire'
                      : null,
                ),
                TextFormField(
                  controller: _numImpotController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro Impôt',
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Champ obligatoire'
                      : null,
                ),
                TextFormField(
                  controller: _adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ obligatoire' : null,
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _logoBytes != null
                          ? Image.memory(_logoBytes!, fit: BoxFit.cover)
                          : const Center(child: Text('Aucun logo sélectionné')),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _pickLogo,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choisir un logo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 121, 169, 240),
                      ),
                    ),
                  ],
                ),
                if (_logoName != null) ...[
                  const SizedBox(height: 10),
                  Text('Fichier sélectionné : $_logoName'),
                ],

                const SizedBox(height: 40),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 121, 169, 240),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  
