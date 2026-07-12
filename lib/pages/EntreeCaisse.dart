import 'dart:convert';
import 'package:beni_newlook/api_config.dart';
import 'package:beni_newlook/session_utilisateur.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Color _primaryColor = Color.fromARGB(255, 121, 169, 240);
const Color _lightGrey = Color.fromARGB(255, 245, 248, 255);

class Entreecaisse extends StatefulWidget {
  final int identreprise;
  final int idUtilisateur;

  const Entreecaisse({
    super.key,
    required this.identreprise,
    required this.idUtilisateur,
  });

  @override
  State<Entreecaisse> createState() => _EntreecaisseState();
}

class _EntreecaisseState extends State<Entreecaisse> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _montantController;
  late TextEditingController _refExtController;
  late TextEditingController _descriptionController;
  late TextEditingController _beneficiaireController;
  late TextEditingController _filterStartDateController;
  late TextEditingController _filterEndDateController;

  late Future<List<dynamic>> _mouvementsFuture;
  String? _selectedProvenance;
  String? _selectedModePaiement;
  bool _isLoading = false;

  List<Map<String, dynamic>> _sections = [];
  int? _selectedSection;

  static const List<String> _provenances = [
    'VENTES JOURNALIERES',
    'RECETTE LOGEMENT',
    'PAIEMENT DETTE',
    'AUTRES SERVICES'
  ];

  static const List<String> _modesPaiement = [
    'Espèces',
    'Mobile money',
    'virement bancaire',
    'chèque'
  ];

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _montantController = TextEditingController();
    _refExtController = TextEditingController();
    _descriptionController = TextEditingController();
    _beneficiaireController = TextEditingController();
    _filterStartDateController = TextEditingController();
    _filterEndDateController = TextEditingController();
    _mouvementsFuture = fetchMouvementsCaisse();
    _fetchSections();
  }

  Future<void> _fetchSections() async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/AfficherSectionsPrincipales.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'entreprise': widget.identreprise}),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _sections = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<List<dynamic>> fetchMouvementsCaisse() async {
    final url = Uri.parse('$apiBaseUrl/AfficherMouvementsEntreeCaisse.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entreprise': widget.identreprise}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map) {
          if (data['success'] == false) throw Exception(data['message'] ?? 'Erreur API');
          return data['data'] ?? [];
        }
        return [];
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching movements: $e");
      throw Exception('Erreur lors de la récupération des mouvements de caisse: $e');
    }
  }

  Future<Map<String, dynamic>> fetchEntrepriseInfos() async {
    final response = await http.post(
      Uri.parse("$apiBaseUrl/AfficherInfos_Ese.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idEse": widget.identreprise}),
    );
    final data = jsonDecode(response.body);
    return data['data'];
  }

  Future<pw.Document> _generateBonEntreePDF(Map<String, dynamic> mvt) async {
    final entreprise = await fetchEntrepriseInfos();
    final pdf = pw.Document();

    dynamic logoImage;
    try {
      final rawLogoPath = entreprise['logo_path']?.toString() ?? '';
    if (rawLogoPath.isNotEmpty) {
      final logoUrl = rawLogoPath.startsWith('http') ? rawLogoPath : '$apiBaseUrl/$rawLogoPath';
      logoImage = await flutterImageProvider(NetworkImage(logoUrl));
    }
    } catch (e) {
      debugPrint("Erreur chargement logo: $e");
      logoImage = null;
    }

    final dateSeule = mvt['date_mouvement'].toString().split(' ')[0];
    final numRefSolide = "REC/${mvt['id_mouvement']}/$dateSeule";
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo et informations entreprise
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        entreprise['Denomination'] ?? 'ENTREPRISE',
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColor.fromHex('1F3A93')),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("RCCM: ${entreprise['Numero_RCCM'] ?? ''}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("ID National: ${entreprise['ID_national'] ?? ''}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("N° Impôt: ${entreprise['Numero_impot'] ?? ''}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("Adresse: ${entreprise['Adresse'] ?? ''}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("Téléphone: ${entreprise['Telephone'] ?? ''}", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("Email: ${entreprise['Email'] ?? ''}", style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      height: 70,
                      width: 70,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColor.fromHex('1F3A93'), width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Ligne séparatrice
              pw.Container(
                height: 2,
                color: PdfColor.fromHex('1F3A93'),
              ),
              pw.SizedBox(height: 12),

              // Titre du document centré
              pw.Center(
                child: pw.Text(
                  'BON D\'ENTRÉE DE CAISSE',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 18,
                    color: PdfColor.fromHex('1F3A93'),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Section montant en évidence
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('E8F0FF'),
                  border: pw.Border.all(color: PdfColor.fromHex('1F3A93'), width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('MONTANT:', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                    pw.Text(
                      '${mvt['montant']} USD',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                        color: PdfColor.fromHex('1F3A93'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Grille d'informations
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: _buildInfoBox(fontBold, 'RÉFÉRENCE', numRefSolide),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildInfoBox(fontBold, 'DATE', dateSeule),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: _buildInfoBox(fontBold, 'PROVENANCE', mvt['Provenance'] ?? 'N/A'),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildInfoBox(fontBold, 'MODE PAIEMENT', mvt['Modepaiement'] ?? 'N/A'),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Section Description
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('D0D0D0'), width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MOTIF / DESCRIPTION', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('1F3A93'))),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      mvt['descriptionMvt'] ?? 'Aucune description',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Section Références externes (si disponible)
              if (mvt['reference_externe'] != null && mvt['reference_externe'].toString().isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('D0D0D0'), width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RÉFÉRENCE EXTERNE', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('1F3A93'))),
                      pw.SizedBox(height: 4),
                      pw.Text(mvt['reference_externe'].toString(), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),

              pw.Spacer(),

              // Section signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(height: 35, child: pw.Container()), // Espace pour signature
                      pw.Divider(color: PdfColor.fromHex('1F3A93')),
                      pw.SizedBox(height: 4),
                      pw.Text('Caissier', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.Text(mvt['Nom_utilisateur'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.SizedBox(height: 35, child: pw.Container()),
                      pw.Divider(color: PdfColor.fromHex('1F3A93')),
                      pw.SizedBox(height: 4),
                      pw.Text('Client / Bénéficiaire', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.Text(mvt['BeneficiaireOUdeposant']?.toString().isNotEmpty == true
                          ? mvt['BeneficiaireOUdeposant'].toString()
                          : 'Signature',
                        style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Pied de page
              pw.Divider(thickness: 0.5, color: PdfColor.fromHex('D0D0D0')),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Ce bon d\'entrée de caisse est un document officiel. Conservez-le avec vos archives.',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  'Généré le: ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildInfoBox(pw.Font fontBold, String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('E0E0E0'), width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColor.fromHex('1F3A93')),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
          ),
        ],
      ),
    );
  }

  Future<void> _printBonEntree(Map<String, dynamic> mvt) async {
    try {
      final pdf = await _generateBonEntreePDF(mvt);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Prévisualisation du Bon'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: PdfPreview(
              build: (format) => pdf.save(),
              allowPrinting: true,
              allowSharing: false,
              pdfFileName: "bon_entree_caisse.pdf",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSimpleDialog('Erreur', 'Impossible de générer le PDF: $e');
    }
  }

  void _refreshMouvements() {
    setState(() {
      _mouvementsFuture = fetchMouvementsCaisse();
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _montantController.dispose();
    _refExtController.dispose();
    _descriptionController.dispose();
    _beneficiaireController.dispose();
    _filterStartDateController.dispose();
    _filterEndDateController.dispose();
    super.dispose();
  }

  void resetForm() {
    _formKey.currentState!.reset();
    _dateController.clear();
    _montantController.clear();
    _refExtController.clear();
    _descriptionController.clear();
    _beneficiaireController.clear();
    setState(() {
      _selectedProvenance = null;
      _selectedModePaiement = null;
    });
  }

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
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      onTap: () => _selectDate(controller),
      validator: (value) => (value == null || value.isEmpty) ? 'Ce champ est requis' : null,
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = _formatDate(pickedDate);
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }


  Future<void> enregistrerEntreeCaisse(String typeOperation) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSection == null) {
      _showSimpleDialog('Erreur', 'Veuillez sélectionner une section.');
      return;
    }

    setState(() => _isLoading = true);
    final url = Uri.parse('$apiBaseUrl/EntreeCaisse.php');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': SessionUtilisateur.token,
        },
        body: jsonEncode({
          'dateoperation': _dateController.text,
          'montant': double.tryParse(_montantController.text.replaceAll(',', '.')) ?? 0.0,
          'provenance': _selectedProvenance,
          'modepaiement': _selectedModePaiement,
          'referenceExterne': _refExtController.text,
          'BeneficiaireOUdeposant': _beneficiaireController.text,
          'descriptionMouvement': _descriptionController.text,
          'idSection': _selectedSection,
          'typeoperation': typeOperation,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessDialog();
          resetForm();
          _refreshMouvements();
        } else {
          _showSimpleDialog('Erreur', data['message'] ?? 'Une erreur est survenue.');
        }
      } else {
        _showSimpleDialog('Erreur', 'Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _showSimpleDialog('Erreur', 'Erreur de connexion: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Succès'),
        content: const Text('L\'entrée de caisse a été enregistrée avec succès.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSimpleDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: _primaryColor),
            SizedBox(width: 12),
            Text(
              "Enregistrement Entrée",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _primaryColor,
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
                  _buildSectionDropdown(),
                  const SizedBox(height: 16),
                  _buildDateAndAmountRow(),
                  const SizedBox(height: 16),
                  _buildProvenanceAndPaymentRow(),
                  const SizedBox(height: 16),
                  _buildReferenceAndDescriptionRow(),
                  const SizedBox(height: 16),
                  _buildTextField(_beneficiaireController, "Bénéficiaire / Déposant", Icons.person),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedSection,
      decoration: InputDecoration(
        labelText: "Section",
        prefixIcon: const Icon(Icons.storefront_outlined, color: _primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _sections
          .map((s) => DropdownMenuItem<int>(
                value: s['idSection'],
                child: Text(s['descptionSection']),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedSection = v),
      validator: (v) => v == null ? 'Veuillez sélectionner une section' : null,
    );
  }

  Widget _buildDateAndAmountRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(_dateController, "Date de l'opération", Icons.calendar_today),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(_montantController, "Montant", Icons.attach_money, keyboardType: TextInputType.number),
        ),
      ],
    );
  }

  Widget _buildProvenanceAndPaymentRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedProvenance,
            decoration: InputDecoration(
              labelText: "Provenance",
              prefixIcon: const Icon(Icons.trending_up, color: _primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            items: _provenances.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
            onChanged: (value) => setState(() => _selectedProvenance = value),
            validator: (value) => value == null ? 'Ce champ est requis' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedModePaiement,
            decoration: InputDecoration(
              labelText: "Mode de paiement",
              prefixIcon: const Icon(Icons.payment, color: _primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            items: _modesPaiement.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
            onChanged: (value) => setState(() => _selectedModePaiement = value),
            validator: (value) => value == null ? 'Ce champ est requis' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceAndDescriptionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(_refExtController, "Référence externe", Icons.receipt_long),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(_descriptionController, "Description mouvement", Icons.description),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () {
        if (_formKey.currentState!.validate()) {
          enregistrerEntreeCaisse("Entrée Caisse");
        }
      },
      icon: const Icon(Icons.save),
      label: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text('Enregistrer l\'opération', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 3,
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _filterStartDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date début',
                  labelStyle: const TextStyle(color: _primaryColor),
                  prefixIcon: const Icon(Icons.calendar_today, color: _primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                onTap: () => _selectDate(_filterStartDateController),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _filterEndDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date fin',
                  labelStyle: const TextStyle(color: _primaryColor),
                  prefixIcon: const Icon(Icons.event, color: _primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                onTap: () => _selectDate(_filterEndDateController),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.redAccent),
              onPressed: () => setState(() {
                _filterStartDateController.clear();
                _filterEndDateController.clear();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMouvementsTable(List<dynamic> filteredMouvements) {
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
                headingRowColor: WidgetStateProperty.all(_primaryColor.withValues(alpha: 0.1)),
                headingRowHeight: 56,
                horizontalMargin: 24,
                columns: const [
                  DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Montant", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Provenance", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Mode_paiement", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Réf. Ext.", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Bénéficiaire/Déposant", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Utilisateur", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                  DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor))),
                ],
                rows: filteredMouvements.asMap().entries.map((entry) {
                  final mvt = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.all(entry.key.isEven ? Colors.white : _lightGrey),
                    cells: [
                      DataCell(Text(mvt['id_mouvement']?.toString() ?? '')),
                      DataCell(Text(mvt['date_mouvement']?.toString() ?? '')),
                      DataCell(Text("${mvt['montant'] ?? '0'} \$", style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(mvt['Provenance']?.toString() ?? '')),
                      DataCell(Text(mvt['Modepaiement']?.toString() ?? '')),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(mvt['descriptionMvt']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text(mvt['reference_externe']?.toString() ?? '')),
                      DataCell(Text(mvt['BeneficiaireOUdeposant']?.toString() ?? '')),
                      DataCell(Text(mvt['Nom_utilisateur']?.toString() ?? '')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.print, color: _primaryColor),
                          onPressed: () => _printBonEntree(mvt),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrée Caisse"),
        backgroundColor: _primaryColor,
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFormCard(),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFilterCard(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<dynamic>>(
                future: _mouvementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  } else if (snapshot.hasError) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text("Aucun mouvement trouvé", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    );
                  } else {
                    final allMouvements = snapshot.data!;
                    final filteredMouvements = allMouvements.where((mvt) {
                      final dateMvt = (mvt['date_mouvement'] ?? "").toString().split(' ')[0];
                      final matchesStart = _filterStartDateController.text.isEmpty ||
                          dateMvt.compareTo(_filterStartDateController.text) >= 0;
                      final matchesEnd = _filterEndDateController.text.isEmpty ||
                          dateMvt.compareTo(_filterEndDateController.text) <= 0;
                      return matchesStart && matchesEnd;
                    }).toList();

                    if (filteredMouvements.isEmpty) {
                      return const Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text("Aucun résultat pour cette période", style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      );
                    }

                    return _buildMouvementsTable(filteredMouvements);
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
