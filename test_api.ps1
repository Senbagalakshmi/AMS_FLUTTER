$baseUrl = "http://localhost:8085/api"

Write-Host "Logging in..."
$loginBody = @{
    username = "admin"
    password = "password"
} | ConvertTo-Json

try {
    $loginRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginRes.jwt
    Write-Host "Token: $token"
} catch {
    Write-Host "Login failed or no token."
}

Write-Host "Fetching queue..."
$headers = @{}
if ($token) {
    $headers["Authorization"] = "Bearer $token"
}

try {
    $qRes = Invoke-RestMethod -Uri "$baseUrl/auth/queue" -Method Get -Headers $headers
    $qRes | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Queue fetch failed."
    $_.Exception.Response
}
