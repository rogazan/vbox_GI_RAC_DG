. .\comunes\iniEntorno.ps1

for ($i = 1; $i -le $infra.numNodos(); $i++) {
    $infra.nodos[$i - 1].arrancarNodo()
}

$null = $infra.GI.VerificarCluster()
validacion $true ""

$null = $infra.GI.ValidarBD($infra.GI.prim)
validacion $true ""

$null = (-not $infra.GI.ValidarBD($infra.GI.stby))
validacion $true ""

loc "Fin del proceso"
$evento.finGestor()
