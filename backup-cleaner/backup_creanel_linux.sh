#!/usr/bin/env bash

# ============================================================
# Backup Cleaner
# Borra archivos y carpetas vacías con más de 2 años de antigüedad
# ============================================================

set -o nounset
set -o pipefail

# ============================================================
# CONFIGURACIÓN
# Cambia los parametros segun tus necesidades
# ============================================================
ROOT_PATH="/home/jorge/backups"
ANTIGUEDAD_DIAS=730  # 2 años

# Borrar archivos con más de 2 años
find "$ROOT_PATH" -mindepth 1 -type f -ctime +$ANTIGUEDAD_DIAS -mtime +$ANTIGUEDAD_DIAS -delete

# Borrar carpetas vacías con más de 2 años
find "$ROOT_PATH" -mindepth 1 -type d -ctime +$ANTIGUEDAD_DIAS -mtime +$ANTIGUEDAD_DIAS -empty -delete
