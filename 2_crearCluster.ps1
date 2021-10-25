. .\comunes\iniEntorno.ps1

$ok = $true
loc "Comprobando que NO existen los servidores virtuales del cluster"
foreach ($nodo in $infra.nodos) {
    if ($nodo.existe()) { $ok = $false }
    if ($nodo.DiscoSistema.existe()) { $ok = $false }
}
validacion $ok "Ya existe alguno de los servidores virtuales o su disco de sistema, saliendo del proceso"

loc "Comprobando que No existen los discos compartidos del cluster"
foreach ($disco in $infra.SAN.Discos) {
    if ($disco.existe()) { $ok = $false }
}
validacion $ok "Ya existe alguno de discos compartidos, saliendo del proceso"

loc "Comprobando que existe disco imagen"
if (-not $infra.imagen.existe()) {
    $ok = $false
}
validacion $ok "No existe disco imagen, saliendo del proceso"

$null = $infra.red.CrearRedPriv()

$null = $infra.nodos[0].DiscoSistema.CrearDisco($infra.imagen, $infra.nodos[0].NombreVM)
$null = $infra.nodos[0].CrearNodo($infra.Red)
$infra.nodos[0].arrancarNodo()

$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$infra.red.CambioNomHost($mishell, $infra.nodos[0].NombreVM)
$infra.red.CrearConfIF($mishell, "G")
$infra.red.CrearConfIF($mishell, "P")
$infra.red.CrearFicheroHost($mishell, ($rutTemp + "\host.txt"))
$infra.red.ResetRed($mishell)
$infra.seguridad.modPas($mishell, "oracle", $infra.seguridad.pasOra)
$infra.seguridad.GruposOra($mishell)
if ($infra.seguridad.usrGrid -cne "oracle") {
    $infra.seguridad.modPas($mishell, $infra.seguridad.usrGrid, $infra.seguridad.pasGrid)
}
$infra.seguridad.ProfOra($mishell)
$infra.seguridad.PermDir($mishell)
$infra.nodos[0].modifFstab($mishell)
$infra.nodos[0].CrearSwap($mishell)
$infra.nodos[0].modifZonaH($mishell)
$mishell.EjecutarSh($infra.nodos[0].NombreVM, ("Ejecutando configuración LINUX en " + $infra.Nodos[0].NombreVM))

$infra.nodos[0].detenerNodo()

$infra.SAN.CrearSAN()
$infra.Nodos[0].MapearDiscos($infra.SAN)
$infra.nodos[0].arrancarNodo()

$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$infra.SAN.PartDiscos($mishell)
$infra.SAN.ConfDiscosTipo1($mishell)
$mishell.EjecutarSh($infra.nodos[0].NombreVM, ("Configurando discos compartidos en " + $infra.Nodos[0].NombreVM))
$infra.nodos[0].detenerNodo()

for ($i = 1; $i -lt $NumNodos; $i++) {
    $null = $infra.nodos[0].DiscoSistema.ClonarDisco($infra.nodos[$i].DiscoSistema, $infra.nodos[$i].NombreVM )
    Start-Sleep -Seconds 2
    $infra.nodos[$i].crearNodo($infra.red)
    $infra.Nodos[$i].MapearDiscos($infra.SAN)
    $infra.nodos[$i].arrancarNodo()

    $mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
    $infra.red.CambioNomHost($mishell, $infra.nodos[$i].NombreVM)
    $infra.red.CambioIPHost($mishell, $infra.red.Dir_Red_Pub, $infra.red.Dir_Red_Priv, [string]$infra.red.IPBase, [string]($infra.red.IPBase + $i)) 
    $infra.red.ResetRed($mishell)
    $infra.SAN.ConfDiscosTipoN($mishell)
    $mishell.EjecutarSh($infra.nodos[$i].NombreVM, ("Configurando sistema en " + $infra.Nodos[$i].NombreVM))

    $infra.nodos[$i].detenerNodo()
}
$null = $infra.nodos[0].arrancarNodo()

$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$infra.red.crearDNS($mishell)
$mishell.EjecutarSh($infra.nodos[0].NombreVM, ("Configurando DNS en " + $infra.Nodos[0].NombreVM))

$infra.nodos[0].detenerNodo()

loc "Fin del proceso"

$evento.finGestor()