# Backup Cleaner

Pequeña herramienta para eliminar archivos y carpetas antiguos en sistemas de almacenamiento (NAS, servidores o discos locales).

La herramienta recorre una ruta de forma recursiva y elimina elementos que cumplan ciertos criterios de fecha.

## Versiones disponibles

- **PowerShell** → `powershell/Clean-OldBackups.ps1`
- **Bash** → `bash/clean-old-backups.sh`

## Uso típico

Pensado para entornos donde se acumulan copias de seguridad que ya no es necesario conservar.

Puede ayudar a:

- liberar espacio en un NAS
- limpiar backups antiguos
- automatizar tareas de mantenimiento usando, por ejemplo, **cron** o el **Task Scheduler** de Windows

## Recomendación

Ejecutar primero siempre en **modo simulación** antes de borrar datos reales.

⚠️ **Disclaimer:** usa el script bajo tu propia responsabilidad. No me hago cargo de los posibles fallos del script 😉
