. .\comunes\iniEntorno.ps1

for ($i = $infra.numNodos(); $i -gt 0; $i--) {
    $infra.nodos[$i -1].detenerNodo()
}

loc "Fin del proceso"

$evento.finGestor()