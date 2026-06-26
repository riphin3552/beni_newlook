<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include 'connexion.php';

$data = json_decode(file_get_contents("php://input"), true);

$required = ['date', 'reservation', 'total', 'reduction', 'reste', 'acompte', 'typePaiement', 'moyenPaiement', 'entreprise'];
foreach ($required as $field) {
    if (!isset($data[$field])) {
        echo json_encode(["success" => false, "message" => "Paramètre manquant : $field"]);
        exit;
    }
}

$date          = trim($data['date']);
$idReservation = intval($data['reservation']);
$total         = floatval($data['total']);
$reduction     = floatval($data['reduction']);
$reste         = floatval($data['reste']);
$acompte       = floatval($data['acompte']);
$typePaiement  = trim($data['typePaiement']);
$moyenPaiement = trim($data['moyenPaiement']);
$idEse         = intval($data['entreprise']);

// Récupérer l'IdClient lié à la réservation
$stmtRes = $conn->prepare(
    "SELECT IdClient FROM Reservations WHERE IdReservation = ? AND Id_Ese = ? LIMIT 1"
);
$stmtRes->bind_param("ii", $idReservation, $idEse);
$stmtRes->execute();
$resultRes = $stmtRes->get_result();

if ($resultRes->num_rows === 0) {
    $stmtRes->close();
    echo json_encode(["success" => false, "message" => "Réservation introuvable."]);
    exit;
}

$reservation = $resultRes->fetch_assoc();
$idClient    = intval($reservation['IdClient']);
$stmtRes->close();

// Démarrer une transaction pour garantir la cohérence
$conn->begin_transaction();

try {
    // Insérer la facturation
    $stmtFact = $conn->prepare(
        "INSERT INTO FacturationChambreEspace
            (DateFacturation, IdReservation, MontantTotal, Reduction, Acompte, ResteAPayer, TypePaiement, MoyenPaiement, Id_Ese)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );
    $stmtFact->bind_param(
        "siddddssi",
        $date, $idReservation, $total, $reduction, $acompte, $reste, $typePaiement, $moyenPaiement, $idEse
    );

    if (!$stmtFact->execute()) {
        throw new Exception("Erreur lors de l'enregistrement de la facturation : " . $stmtFact->error);
    }
    $stmtFact->close();

    // Mettre à jour le statut de la réservation
    $stmtStatut = $conn->prepare(
        "UPDATE Reservations SET StatutReservation = 'Facturée' WHERE IdReservation = ? AND Id_Ese = ?"
    );
    $stmtStatut->bind_param("ii", $idReservation, $idEse);
    if (!$stmtStatut->execute()) {
        throw new Exception("Erreur lors de la mise à jour du statut : " . $stmtStatut->error);
    }
    $stmtStatut->close();

    // Si reste > 0, ajouter la dette au solde du client
    if ($reste > 0) {
        $stmtSolde = $conn->prepare(
            "UPDATE Clients SET Solde = Solde + ? WHERE client_id = ?"
        );
        $stmtSolde->bind_param("di", $reste, $idClient);
        if (!$stmtSolde->execute()) {
            throw new Exception("Erreur lors de la mise à jour du solde client : " . $stmtSolde->error);
        }
        $stmtSolde->close();
    }

    $conn->commit();
    echo json_encode(["success" => true, "message" => "Facturation enregistrée avec succès."]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => $e->getMessage()]);
}

$conn->close();
?>
