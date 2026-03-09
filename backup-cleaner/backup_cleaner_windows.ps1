# ============================================================
# Backup Cleaner - Version compleja
# Borra archivos y carpetas vacias con mas de 2 años de antiguedad
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURACION
# Cambia los parametros segun tus necesidades
# ============================================================
$RootPath = "C:\Users\Jorge\backups"
$AntiguedadDias = 730  # 2 años
$FechaLimite = (Get-Date).AddDays(-$AntiguedadDias)

function Se-Debe-Borrar {
  param (
    [System.IO.FileSystemInfo]$Elemento
  )

  $fechaCreacion = $Elemento.CreationTime
  $fechaModificacion = $Elemento.LastWriteTime

  if ($null -eq $fechaCreacion) {
    return $false
  }

  if ($null -eq $fechaModificacion) {
    return $false
  }

  if ($fechaCreacion -lt $FechaLimite -and $fechaModificacion -lt $FechaLimite) {
    return $true
  }

  return $false
}

function Carpeta-Vacia {
  param (
    [string]$Carpeta
  )

  $contenido = Get-ChildItem -Path $Carpeta -Recurse
  return $contenido.Count -eq 0
}

function Main {
  if (-not (Test-Path -Path $RootPath -PathType Container)) {
    exit 1
  }

  Get-ChildItem -Path $RootPath -Recurse -File | ForEach-Object {
    if (Se-Debe-Borrar -Elemento $_) {
      Remove-Item -Path $_.FullName -Force
    }
  }

  Get-ChildItem -Path $RootPath -Recurse -Directory |
    Sort-Object -Property FullName -Descending |
    ForEach-Object {
      if (Se-Debe-Borrar -Elemento $_) {
        if (Carpeta-Vacia -Carpeta $_.FullName) {
          Remove-Item -Path $_.FullName -Force
        }
      }
    }
}

Main
