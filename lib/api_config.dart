// Point d'entree unique pour l'URL de base de l'API PHP.
// Permet de basculer local/production en un seul endroit au lieu de
// chercher chaque URL codee en dur dans les fichiers.

// PROD (decommenter avant upload / build final, recommenter la ligne LOCAL TEST) :
const String apiBaseUrl = 'https://riphin-salemanager.com/beni_newlook_API';

// LOCAL TEST ONLY (developpement RBAC, serveur PHP local sur le port 8090) :
// const String apiBaseUrl = 'http://127.0.0.1:8090';
