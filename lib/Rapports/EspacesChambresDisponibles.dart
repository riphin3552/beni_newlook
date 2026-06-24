import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Modèle pour les informations de l'entreprise
class EntrepriseInfos {
  final String denomination;
  final String adresse;
  final String telephone;
  final String email;
  final String logoPath;
  final String numeroRCCM;
  final String idNational;
  final String numeroImpot;

  EntrepriseInfos({
    required this.denomination,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.logoPath,
    required this.numeroRCCM,
    required this.idNational,
    required this.numeroImpot,
  });

  factory EntrepriseInfos.fromJson(Map<String, dynamic> json) {
    return EntrepriseInfos(
      denomination: json['Denomination'] ?? '',
      adresse: json['Adresse'] ?? '',
      telephone: json['Telephone'] ?? '',
      email: json['Email'] ?? '',
      logoPath: json['logo_path'] ?? '',
      numeroRCCM: json['Numero_RCCM'] ?? '',
      idNational: json['ID_national'] ?? '',
      numeroImpot: json['Numero_impot'] ?? '',
    );
  }
}

/// Modèle pour les espaces et chambres disponibles
class EspaceChambre {
  final int idEspace;
  final String designationEspace;
  final String designationSectionAuxi;
  final String prixEspace;
  final String equipement;
  final String capacite;

  EspaceChambre({
    required this.idEspace,
    required this.designationEspace,
    required this.designationSectionAuxi,
    required this.prixEspace,
    required this.equipement,
    required this.capacite,
  });

  factory EspaceChambre.fromJson(Map<String, dynamic> json) {
    return EspaceChambre(
      idEspace: json['IdEspace'] ?? 0,
      designationEspace: json['designationEspace'] ?? '',
      designationSectionAuxi: json['designationSectionAuxi'] ?? '',
      prixEspace: json['PrixEspace']?.toString() ?? '0',
      equipement: json['Equipement'] ?? '',
      capacite: json['Capacite'] ?? '',
    );
  }
}

/// Récupérer les infos de l'entreprise
Future<EntrepriseInfos> fetchEntreprise(int idEse) async {
  final response = await http.post(
    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/AfficherInfos_Ese.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"idEse": idEse}),
  );
  //print("DEBUG (Entreprise API): ${response.body}");
  final data = jsonDecode(response.body);
  return EntrepriseInfos.fromJson(data['data']);
}

/// Récupérer la liste des espaces disponibles via l'API
Future<List<EspaceChambre>> fetchEspacesDisponibles(int idEse) async {
  //print("DEBUG (Espaces API) - Sending Id_Ese: $idEse, statut: Disponible");
  final response = await http.post(
    Uri.parse("https://riphin-salemanager.com/beni_newlook_API/RapportEspacesChambresDisponibles.php"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "entreprise": idEse, // Testez avec "entreprise" ou "idEse" si "Id_Ese" échoue
      "statut": "Disponible", // Ajout du statut pour filtrer les espaces disponibles
    }),
  );

  //print("DEBUG (Espaces API) - Raw Response: ${response.body}");

  final dynamic decoded = jsonDecode(response.body);
  
  // Vérification si la donnée est enveloppée dans une clé 'data' comme les autres API
  List<dynamic> listData = [];
  if (decoded is List) {
    listData = decoded;
  } else if (decoded is Map && decoded.containsKey('data')) {
    listData = decoded['data'];
  }

  return listData.map((json) => EspaceChambre.fromJson(json)).toList();
}

/// Construction du document PDF
Future<pw.Document> buildEspacesDisponiblesPdf(int idEse) async {
  final entreprise = await fetchEntreprise(idEse);
  final espaces = await fetchEspacesDisponibles(idEse);
  final pdf = pw.Document();
  dynamic logo;
  try {
    if (entreprise.logoPath.isNotEmpty) {
      logo = await flutterImageProvider(NetworkImage(entreprise.logoPath));
    }
  } catch (_) {
    logo = null;
  }
  
  // Charger une police qui supporte les accents (Unicode)
  final font = await PdfGoogleFonts.robotoRegular();
  final fontBold = await PdfGoogleFonts.robotoBold();

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(entreprise.denomination, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: fontBold)),
                pw.Text("RCCM: ${entreprise.numeroRCCM}", style: const pw.TextStyle(fontSize: 9)),
                pw.Text("ID National: ${entreprise.idNational}", style: const pw.TextStyle(fontSize: 9)),
                pw.Text("N° Impôt: ${entreprise.numeroImpot}", style: const pw.TextStyle(fontSize: 9)),
                pw.Text("Adresse: ${entreprise.adresse}", style: const pw.TextStyle(fontSize: 9)),
                pw.Text("Tél: ${entreprise.telephone}", style: const pw.TextStyle(fontSize: 9)),
                pw.Text("Email: ${entreprise.email}", style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            if (logo != null)
              pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text("Rapport des Espaces & Chambres Disponibles",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: fontBold)),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['ID', 'Désignation', 'Catégorie', 'Prix', 'Équipement', 'Capacité'],
          data: espaces.map((e) => [
            e.idEspace.toString(),
            e.designationEspace,
            e.designationSectionAuxi,
            "${e.prixEspace} \$",
            e.equipement,
            e.capacite,
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ),
  );
  return pdf;
}

/// Page d'aperçu du rapport
class EspacesDisponiblesReportPage extends StatelessWidget {
  final int idEse;
  const EspacesDisponiblesReportPage({super.key, required this.idEse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rapport Disponibilités")),
      body: PdfPreview(build: (format) async => (await buildEspacesDisponiblesPdf(idEse)).save()),
    );
  }
}