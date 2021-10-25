. .\comunes\iniEntorno.ps1

$discoGA = [DiscoDVD]::new($GAISO)
$nodotmp = [nodo]::new($tmpNodo, $RVM + "\" + $tmpNodo, $IPBase, $infra.tamDSis, `
                    2048, 16, 1, 1, $discoGA)

loc ("Comprobando que NO existe el servidor temporal")
if ($nodotmp.existe()) {
    validacion $false "El servidor temporal ya existe, saliendo"
}
validacion $true ""

loc ("Comprobando que existe el disco imagen")
if (-not $infra.imagen.existe()) {
    validacion $false "El disco imagen NO existe, saliendo"
}
validacion $true ""

$null = $nodotmp.discoSistema.CrearDisco($infra.imagen, $tmpNodo)
$null = $nodotmp.crearNodo($infra.red)
$nodotmp.arrancarNodo()

$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$mishell.titulo("Actualizando software Linux")
$mishell.actualizarSoftware()
$mishell.EjecutarSh($nodotmp.NombreVM, "Ejecutando actualización en servidor temporal")

$nodotmp.detenerNodo()
$null = $infra.imagen.borrarImagen()
$null = $nodotmp.discoSistema.CrearImagen($infra.imagen, $nodotmp.NombreVM)
$null = $nodotmp.borrarNodo()

loc "Fin del proceso"

$evento.finGestor()
