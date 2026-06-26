<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include 'connexion.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['client']) || !isset($data['entreprise'])) {
    echo json_encode(["success" => false, "message" => "Paramètres manquants (client, entreprise)."]);
    exit;
}

$clientName = trim($data['client']);
$idEse      = intval($data['entreprise']);

if (empty($clientName)) {
    echo json_encode(["success" => false, "message" => "Le nom du client ne peut pas être vide."]);
    exit;
}

// Rechercher le client par nom et entreprise
$stmt = $conn->prepare("SELECT client_id, client_name, Id_Ese FROM Clients WHERE client_name LIKE ? AND Id_Ese = ? LIMIT 1");
$searchPattern = "%" . $clientName . "%";
$stmt->bind_param("si", $searchPattern, $idEse);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $client = $result->fetch_assoc();
    $stmt->close();
    echo json_encode([
        "success" => true,
        "created" => false,
        "client" => [
            "id"          => $client['client_id'],
            "client_name" => $client['client_name'],
            "Id_Ese"      => $client['Id_Ese'],
        ]
    ]);
} else {
    $stmt->close();

    // Créer le client avec Solde initialisé à 0
    $insert = $conn->prepare("INSERT INTO Clients (client_name, Id_Ese, Solde) VALUES (?, ?, 0.00)");
    $insert->bind_param("si", $clientName, $idEse);

    if ($insert->execute()) {
        $newId = $insert->insert_id;
        $insert->close();
        echo json_encode([
            "success" => true,
            "created" => true,
            "client" => [
                "id"          => $newId,
                "client_name" => $clientName,
                "Id_Ese"      => $idEse,
            ]
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Erreur lors de la création du client : " . $insert->error]);
        $insert->close();
    }
}

$conn->close();
?>
