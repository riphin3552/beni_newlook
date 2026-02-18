import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Modèle Entreprise
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

// Modèle Stock
class Stock {
  final int idStock;
  final String designationStock;
  final String descriptionStock;
  final String designationProduit;
  final int quantiteDisponible;

  Stock({
    required this.idStock,
    required this.designationStock,
    required this.descriptionStock,
    required this.designationProduit,
    required this.quantiteDisponible,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      idStock: int.parse(json['IdStock'].toString()),
      designationStock: json['designationStock'],
      descriptionStock: json['Description_stock'],
      designationProduit: json['designationProduit'],
      quantiteDisponible: int.parse(json['QuantiteDisponible'].toString()),
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

// Fonction pour récupérer stocks
Future<List<Stock>> fetchStocks(int idEse) async {
  final response = await http.post(
    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherTypeStocks.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"entreprise": idEse}),
  );

  final List<dynamic> data = jsonDecode(response.body);
  return data.map((json) => Stock.fromJson(json)).toList();
}

// Fonction pour construire le PDF
Future<pw.Document> buildPdf(int idEse) async {
  final entreprise = await fetchEntreprise(idEse);
  final stocks = await fetchStocks(idEse);

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
            "Nos Stocks",
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
            'ID Stock',
            'Désignation_stock',
            'Description',
            'Produit',
            'Quantité'
          ],
          data: stocks.map((s) => [
            s.idStock.toString(),
            s.designationStock,
            s.descriptionStock,
            s.designationProduit,
            s.quantiteDisponible.toString(),
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
class PdfPreviewPage extends StatelessWidget {
  final int idEse;
  const PdfPreviewPage({super.key, required this.idEse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Aperçu du rapport")),
      body: FutureBuilder<pw.Document>(
        future: buildPdf(idEse),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return Center(child: Text("Aucun document généré"));
          }

          final pdf = snapshot.data!;
          return PdfPreview(
            build: (format) async => pdf.save(),
            allowPrinting: true,   // 👈 permet d’imprimer après aperçu
            allowSharing: true,    // 👈 permet de partager/exporter
          );
        },
      ),
    );
  }
}