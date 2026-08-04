$body = @{ email='suporte'; senha='320260804' } | ConvertTo-Json
$login = Invoke-RestMethod -Uri 'http://localhost:8080/api/login' -Method Post -Body $body -ContentType 'application/json'
$token = $login.token
Write-Host "TOKEN: $token"
$headers = @{ Authorization = 'Bearer ' + $token }
foreach ($path in @('http://localhost:8080/api/veiculos', 'http://localhost:8080/api/veiculos/', 'http://localhost:8080/api/empresas', 'http://localhost:8080/api/colaboradores')) {
    Write-Host "\nREQUEST: $path"
    try {
        $resp = Invoke-WebRequest -Uri $path -Method Get -Headers $headers -UseBasicParsing
        Write-Host "STATUS:" $resp.StatusCode
        Write-Host "BODY:" $resp.Content
    } catch {
        Write-Host "ERROR:" $_.Exception.Message
        if ($_.Exception.Response -ne $null) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "BODY:" $reader.ReadToEnd()
        }
    }
}
