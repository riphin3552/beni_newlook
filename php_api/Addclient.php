<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include 'connexion.php';

$data = json_decode(file_get_contents("php://input"), true);

$required = ['nomClient', 'telephone', 'numcarte', 'descCarte', 'nationalite', 'dateNaissance', 'adresse', 'entreprise'];
foreach ($required as $field) {
    if (!isset($data[$field])) {
        echo json_encode(["success" => false, "error" => "Paramètre manquant : $field"]);
        exit;
    }
}

$nomClient     = trim($data['nomClient']);
$telephone     = trim($data['telephone']);
$numCarte      = trim($data['numcarte']);
$descCarte     = trim($data['descCarte']);
$nationalite   = trim($data['nationalite']);
$dateNaissance = trim($data['dateNaissance']);
$adresse       = trim($data['adresse']);
$idEse         = intval($data['entreprise']);

if (empty($nomClient)) {
    echo json_encode(["success" => false, "error" => "Le nom du client ne peut pas être vide."]);
    exit;
}

$stmt = $conn->prepare(
    "INSERT INTO Clients (client_name, phone_number, ID_card, DescriptionCarte, nationalite, dateNaissance, client_adress, Id_Ese, Solde)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0.00)"
);
$stmt->bind_param(
    "sssssssi",
    $nomClient, $telephone, $numCarte, $descCarte, $nationalite, $dateNaissance, $adresse, $idEse
);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Client ajouté avec succès.", "client_id" => $stmt->insert_id]);
} else {
    echo json_encode(["success" => false, "error" => "Erreur lors de l'insertion : " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
