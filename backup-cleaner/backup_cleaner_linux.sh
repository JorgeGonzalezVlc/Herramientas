#!/usr/bin/env bash

# ============================================================
# Backup Cleaner
# Borra archivos y carpetas vacías que tengan más de 2 años de creación y más de 2 años sin modificarse
# ============================================================
set -o nounset
set -o pipefail
# ============================================================
# CONFIGURACIÓN
# Cambia los parametros segun tus necesidades
# ============================================================

ROOT_PATH="/home/jorge/backups"
CREATED_BEFORE=$(date -d "2 years ago" +%Y-%m-%d)
MODIFIED_BEFORE=$(date -d "2 years ago" +%Y-%m-%d)

# Convierte una fecha YYYY-MM-DD a segundos epoch
fecha_a_epoch() {
  date -d "$1" +%s 2>/dev/null
}

# Devuelve la fecha de creacion del fichero en epoch
fecha_creacion() {
  stat -c %W "$1" 2>/dev/null || echo "-1"
}

# Devuelve la fecha de modificacion del fichero en epoch
fecha_modificacion() {
  stat -c %Y "$1" 2>/dev/null
}

# Devuelve 0 si el fichero cumple ambas condiciones de fecha
se_debe_borrar() {
  local fichero="$1"
  local limite_creacion="$2"
  local limite_modificacion="$3"
  local epoch_creacion=$(fecha_creacion "$fichero")
  local epoch_modificacion=$(fecha_modificacion "$fichero")

  # Si no tiene fecha de creacion valida, no borrar
  if [[ -z "$epoch_creacion" || "$epoch_creacion" == "-1" || "$epoch_creacion" == "0" ]]; then
    return 1
  fi

  # Borrar solo si fue creado Y modificado hace mas de 2 años
  if (( epoch_creacion < limite_creacion && epoch_modificacion < limite_modificacion )); then
    return 0
  fi

  return 1
}

# Devuelve 0 si la carpeta esta vacia
carpeta_vacia() {
  local carpeta="$1"
  if find "$carpeta" -mindepth 1 -maxdepth 1 | read -r; then
    return 1
  fi
  return 0
}

main() {
  if [[ ! -d "$ROOT_PATH" ]]; then
    exit 1
  fi

  local limite_creacion
  local limite_modificacion

  limite_creacion=$(fecha_a_epoch "$CREATED_BEFORE")
  limite_modificacion=$(fecha_a_epoch "$MODIFIED_BEFORE")

  # Borrar archivos que cumplan las condiciones
  while IFS= read -r -d '' fichero; do
    if se_debe_borrar "$fichero" "$limite_creacion" "$limite_modificacion"; then
      rm -f -- "$fichero"
    fi
  done < <(find "$ROOT_PATH" -mindepth 1 -type f -print0)

  # Borrar carpetas vacias que cumplan las condiciones
  while IFS= read -r -d '' carpeta; do
    if se_debe_borrar "$carpeta" "$limite_creacion" "$limite_modificacion"; then
      if carpeta_vacia "$carpeta"; then
        rmdir -- "$carpeta"
      fi
    fi
  done < <(find "$ROOT_PATH" -mindepth 1 -type d -depth -print0)
}

main "$@"
