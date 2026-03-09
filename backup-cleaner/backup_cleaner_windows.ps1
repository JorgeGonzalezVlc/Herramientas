# ============================================================
# Backup Cleaner - Version simple
# Borra archivos y carpetas vacias con mas de 2 años de antiguedad
# ============================================================

# CONFIGURACION
$RootPath = "C:\Users\Jorge\backups"
$AntiguedadDias = 730  # 2 años
$FechaLimite = (Get-Date).AddDays(-$AntiguedadDias)

# Borrar archivos con mas de 2 años
Get-ChildItem -Path $RootPath -Recurse -File |
  Where-Object { $_.CreationTime -lt $FechaLimite -and $_.LastWriteTime -lt $FechaLimite } |
  Remove-Item -Force

# Borrar carpetas vacias con mas de 2 años
Get-ChildItem -Path $RootPath -Recurse -Directory |
  Where-Object { $_.CreationTime -lt $FechaLimite -and $_.LastWriteTime -lt $FechaLimite } |
  Where-Object { (Get-ChildItem -Path $_.FullName -Recurse).Count -eq 0 } |
  Remove-Item -Force
