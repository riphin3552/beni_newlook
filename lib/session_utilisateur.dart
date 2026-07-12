/// Session utilisateur courante, en memoire, apres connexion.
/// Simple classe statique (pas de Provider/Riverpod) : l'app est mono-session
/// desktop, et les pages recoivent deja identreprise/idUtilisateur en parametres
/// de constructeur -- cette classe ne fait que completer ce qui manquait (role, section).
class SessionUtilisateur {
  static String token = '';
  static int idUtilisateur = 0;
  static int idEntreprise = 0;
  static String nomUtilisateur = '';
  static String role = 'Serveur'; // 'Gerant' | 'Comptable' | 'Caissier' | 'Serveur'
  static int? idSection; // null pour Gerant
  static bool actif = true;

  static bool get isGerant => role == 'Gerant';
  static bool get isComptable => role == 'Comptable';
  static bool get isCaissier => role == 'Caissier';
  static bool get isServeur => role == 'Serveur';

  static void clear() {
    token = '';
    idUtilisateur = 0;
    idEntreprise = 0;
    nomUtilisateur = '';
    role = 'Serveur';
    idSection = null;
    actif = true;
  }
}
