$ErrorActionPreference = "Continue"

. .\comunes\clases.ps1
. .\comunes\funciones.ps1

leer_parametros $args[0]
modificar_path
GestorDeEventos
CargarInfraestructura