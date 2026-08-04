$body = @{ email='suporte'; senha='320260804' } | ConvertTo-Json
$login = Invoke-RestMethod -Uri 'http://localhost:8080/api/login' -Method Post -Body $body -ContentType 'application/json'
$token = $login.token
Write-Host "TOKEN: $token"
$headers = @{ Authorization = 'Bearer ' + $token }
$response = Invoke-WebRequest -Uri 'http://localhost:8080/api/veiculos' -Method Get -Headers $headers
Write-Host "STATUS: $($response.StatusCode)"
Write-Host 'BODY:'
Write-Host $response.Content
