
// Modèle Entreprise
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EntrepriseInfos {
  final String denomination;
  final String adresse;
  final String telephone;
  final String email;
  final String logoPath; // 👈 ajout du logo

  EntrepriseInfos({
    required this.denomination,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.logoPath,
  });

  factory EntrepriseInfos.fromJson(Map<String, dynamic> json) {
    return EntrepriseInfos(
      denomination: json['Denomination'],
      adresse: json['Adresse'],
      telephone: json['Telephone'],
      email: json['Email'],
      logoPath: json['logo_path'], // 👈 récupération du logo
    );
  }
}

class Produit {
  
  final String designationProduit;
  final String prixVente;
  final String uniteMesure;
  final double seuilMinimum;
  final String designationCategorie;


  Produit({
    
    required this.designationProduit,
    required this.prixVente,
    required this.uniteMesure,
    required this.seuilMinimum,
    required this.designationCategorie,
    
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      
      designationProduit: json['designationProduit'],
      prixVente: json['PrixVente'],
      uniteMesure: json['uniteMesure'],
      seuilMinimum: double.parse(json['seuil_minimum'].toString()),
      designationCategorie: json['designationCategorie'],
    );
  }
}

// Fonction pour récupérer infos entreprise
Future<EntrepriseInfos> fetchEntreprise(int idEse) async {
  final response = await http.post(
    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"idEse": idEse}),
  );

  final data = jsonDecode(response.body);
  return EntrepriseInfos.fromJson(data['data']);
}

// Fonction pour récupérer la liste des produits
Future<List<Produit>> fetchProduits(int idEse) async {
  final response = await http.post(
    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherProduits.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"entreprise": idEse}),
  );

  final decoded = jsonDecode(response.body);

  // Ici on récupère la liste sous la clé "data"
  final List<dynamic> data = decoded['data'];

  return data.map((json) => Produit.fromJson(json)).toList();
}


// Fonction pour construire le PDF
Future<pw.Document> buildPdf(int idEse) async {
  final entreprise = await fetchEntreprise(idEse);
  final produits = await fetchProduits(idEse);

  final pdf = pw.Document();

  // Charger le logo depuis l’URL
  final logo = await networkImage(entreprise.logoPath);

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        // Entête entreprise avec logo
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(entreprise.denomination,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text("Adresse: ${entreprise.adresse}"),
                pw.Text("Téléphone: ${entreprise.telephone}"),
                pw.Text("Email: ${entreprise.email}"),
              ],
            ),
            pw.Container(
              height: 60,
              width: 60,
              child: pw.Image(logo), // 👈 affichage du logo
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Titre centré et en gras
        pw.Center(
          child: pw.Text(
            "Nos Produits",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),

        // Tableau stocks avec texte réduit
        // ignore: deprecated_member_use
        pw.Table.fromTextArray(
          headers: [
            
            'Désignation Produit',
            'Prix de vente',
            'Unité de mesure',
            'Seuil minimum',
            'Catégorie',
            
          ],
          data: produits.map((p) => [
            p.designationProduit,
            p.prixVente.toString(),
            p.uniteMesure,
            p.seuilMinimum.toString(),
            p.designationCategorie,
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: pw.TextStyle(fontSize: 9), // 👈 texte réduit
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.center,
        ),
      ],
    ),
  );

  return pdf;
}

// Page d’aperçu PDF
class PdfPreviewPAGE extends StatelessWidget {
  final int idEse;
  const PdfPreviewPAGE({super.key, required this.idEse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Aperçu du PDF")),
      body: FutureBuilder<pw.Document>(
        future: buildPdf(idEse),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else {
            return PdfPreview(
              build: (format) => snapshot.data!.save(),
            );
          }
        },
      ),
    );
  }
}