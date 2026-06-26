<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include 'connexion.php';

$data = json_decode(file_get_contents("php://input"), true);

if (
    isset($data['designation']) &&
    isset($data['entreprise'])
) {
    $designationCharge = trim($data['designation']);
    $idEse             = intval($data['entreprise']);

    if (empty($designationCharge)) {
        echo json_encode(["success" => false, "error" => "La désignation ne peut pas être vide."]);
        exit;
    }

    $sql = "INSERT INTO TypeCharge (DesignationCharge, Id_Ese) VALUES (?, ?)";
    $stmt = $conn->prepare($sql);

    if ($stmt) {
        $stmt->bind_param("si", $designationCharge, $idEse);

        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Type de charge ajouté avec succès."]);
        } else {
            echo json_encode(["success" => false, "error" => "Erreur lors de l'insertion : " . $stmt->error]);
        }

        $stmt->close();
    } else {
        echo json_encode(["success" => false, "error" => "Erreur de préparation : " . $conn->error]);
    }
} else {
    echo json_encode(["success" => false, "error" => "Paramètres manquants (designation, entreprise)."]);
}

$conn->close();
?>
