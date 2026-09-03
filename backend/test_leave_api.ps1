$tok = (Invoke-RestMethod -Uri "http://localhost:8000/auth/login" -Method POST -ContentType "application/json" -Body '{"employee_number":"EMP001","password":"Yarmouk@2025"}').access_token
$h = @{Authorization="Bearer $tok"}

$bodyOfficial = @'
{
  "leave_kind": "official",
  "outing_date": "2026-09-23",
  "departure_time": "10:00",
  "return_time": "14:00",
  "destination": "موقع العمل الميداني",
  "reason": "مهمة ميدانية",
  "tracking_required": true,
  "tracking_acknowledged": true
}
'@

Write-Host "=== Official short leave (with GPS tracking) ==="
$result = Invoke-RestMethod -Uri "http://localhost:8000/leave/short" -Method POST -ContentType "application/json" -Headers $h -Body $bodyOfficial
$result | ConvertTo-Json -Depth 5

Write-Host "=== Leave types ==="
Invoke-RestMethod -Uri "http://localhost:8000/leave/types" -Headers $h | ConvertTo-Json -Depth 3

Write-Host "=== My leaves ==="
Invoke-RestMethod -Uri "http://localhost:8000/leave/my" -Headers $h | ConvertTo-Json -Depth 3

Write-Host "=== My short leaves ==="
Invoke-RestMethod -Uri "http://localhost:8000/leave/short/my" -Headers $h | ConvertTo-Json -Depth 3
