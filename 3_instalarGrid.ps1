. .\comunes\iniEntorno.ps1

$nNodos = $infra.numNodos()


loc "Comprobando que existen los servidores Virtuales"
$ok = $true

if ($ok) {
    foreach ($nodo in $infra.nodos) {
        if (-not $nodo.existe()) { $ok = $false }
    }
    validacion $ok "Alguno de los servidores virtuales NO existe, saliendo del proceso"
}

foreach ($nodo in $infra.nodos) {
    $nodo.arrancarNodo()
}

$ok = (-not $infra.GI.VerificarCluster())
validacion $ok "Ya está instalado, saliendo del proceso"

$discoverStr = "/dev/oracleasm/disks/*"
$infra.red.BuscaRedPriv($infra.nodos[0].nombreVM)
$infra.seguridad.passLessRoot()
$infra.seguridad.passLessUsuario($infra.seguridad.usrGrid)

$infra.nodos[0].CopiarSoft("GI")
$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$infra.nodos[0].UnzipSoft($mishell, "GI")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, ("Descomprimiendo software grid en " + $infra.Nodos[0].NombreVM))

$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$mishell.titulo("instalando CVUQDISK en todos los nodos")
$mishell.linea("for i in {1.." + $nNodos + "}")
$mishell.linea("do")
$mishell.linea("scp /u01/app/19.3.0/grid/cv/rpm/cvuqdisk-1.0.10-1.rpm " + $infra.prefNodo + "`$i:/tmp")
$mishell.linea("ssh " + $infra.prefNodo + "`$i 'CVUQDISK_GRP=oinstall;export CVUQDISK_GRP;rpm -iv /tmp/cvuqdisk-1.0.10-1.rpm 2>&1'")
$mishell.linea("done")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, "Instalando CVUQDISK en todos los nodos")

<#
$mishell = [shellLinux]::new("mish.sh", $infra.seguridad.usrGrid, $infra.seguridad.pasGrid, $RutTemp, "/tmp")
$mishell.titulo("Ejecutando validacion de preinstalacion CRS")
$mishell.linea("cd /u01/app/19.3.0/grid")
$mishell.linea("/u01/app/19.3.0/grid/runcluvfy.sh stage -pre crsinst -n '" + $infra.listanodos() + "' -fixupnoexec -orainv oinstall 2>&1")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, "Ejecutando verificación de preinstalación CRS")

for ($i = 0; $i -lt $numNodos; $i++) {
    $mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
    $mishell.titulo("ejecutando fixup en " + $infra.nodos[$i].NombreVM)
    $mishell.linea("if [ -f \`"/tmp/CVU_19.0.0.0.0_grid/runfixup.sh\`" ];then")
    $mishell.linea("  /tmp/CVU_19.0.0.0.0_grid/runfixup.sh")
    $mishell.linea("fi")
    $mishell.EjecutarSh($infra.nodos[$i].NombreVM, ("ejecutando fixup en " + $infra.nodos[$i].NombreVM))
}
#>

$mishell = [shellLinux]::new("mish.sh", $infra.seguridad.usrGrid, $infra.seguridad.pasGrid, $RutTemp, "/tmp")        
$mishell.titulo("Creando fichero de respuestas")
$mishell.linea("echo `"oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v19.0.0`" > /tmp/grid.rsp")
$mishell.linea("echo `"INVENTORY_LOCATION=/u01/app/oraInventory`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.option=CRS_CONFIG`" >> /tmp/grid.rsp")
$mishell.linea("echo `"ORACLE_BASE=/u01/app/grid`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.OSDBA=asmdba`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.OSOPER=asmoper`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.OSASM=asmadmin`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.scanType=LOCAL_SCAN`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.gpnp.scanName=" + $infra.GI.cluster + "-scan`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.gpnp.scanPort=1521`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.ClusterConfiguration=STANDALONE`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.configureAsExtendedCluster=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.clusterName=" + $infra.GI.cluster + "`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.gpnp.configureGNS=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.autoConfigureClusterNodeVIP=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.clusterNodes=" + $infra.listaNodosExt() + "`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.networkInterfaceList=enp0s3:" + $infra.red.Dir_Red_Pub + ".0:1,enp0s8:" + $infra.red.Dir_Red_Priv + ".0:5`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.configureGIMR=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.configureGIMRDataDG=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.storageOption=FLEX_ASM_STORAGE`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.sharedFileSystemStorage.votingDiskLocations=`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.sharedFileSystemStorage.ocrLocations=`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.useIPMI=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.SYSASMPassword=" + $infra.seguridad.pasOraSys + "`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.diskGroup.name=DATA`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.diskGroup.redundancy=EXTERNAL`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.diskGroup.AUSize=4`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.diskGroup.disks=" + $infra.SAN.listaDisDATA() + "`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.diskGroup.disksWithFailureGroupNames=" + ($infra.SAN.listaDisDATA()).replace(",", ",,") + "," + "`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.diskGroup.diskDiscoveryString=" + $discoverStr + "`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.monitorPassword=" + $infra.seguridad.pasOraSys + "`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.gimrDG.AUSize=1`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.asm.configureAFD=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.configureRHPS=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.config.ignoreDownNodes=false`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.config.managementOption=NONE`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.config.omsPort=0`" >> /tmp/grid.rsp")
$mishell.linea("echo `"oracle.install.crs.rootconfig.executeRootScript=false`" >> /tmp/grid.rsp")
$mishell.titulo("Instalando grid")
$mishell.linea("/u01/app/19.3.0/grid/gridSetup.sh -silent -responseFile /tmp/grid.rsp -skipPrereqs -ignorePrereqFailure 2>&1")
$mishell.linea("rm -rf /tmp/grid.rsp")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, "instalando grid")

$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$mishell.titulo("ejecutando orainstRoot.sh en todos los nodos")
$mishell.linea("for i in {1.." + $nNodos + "}")
$mishell.linea("do")
$mishell.linea("    ssh -tt " + $infra.prefNodo + "`$i '/u01/app/oraInventory/orainstRoot.sh' 2>&1")
$mishell.linea("done")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, "Ejecutando shell orainstRoot en todos los nodos")

for ($i = 0; $i -lt $numNodos; $i++) {
    $mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
    $mishell.titulo("Ejecutando root.sh en " + $infra.nodos[$i].NombreVM)
    $mishell.linea("/u01/app/19.3.0/grid/root.sh 2>&1 &")
    $mishell.linea("sleep 3")
    $mishell.linea("mipid=``pgrep root.sh``")
    $mishell.linea("tail -f --pid `$mipid /proc/`$mipid/fd/1")
    $mishell.linea("echo `"+ASM" + [string]($i + 1) + ":/u01/app/19.3.0/grid:N`" >> /etc/oratab" )
    $mishell.EjecutarSh($infra.nodos[$i].NombreVM, ("ejecutando shell root en " + $infra.nodos[$i].NombreVM))
}

$listadiscos = $infra.SAN.listaDisFRA()
if ($listadiscos -ne "") {
    $mishell = [shellLinux]::new("mish.sh", $infra.seguridad.usrGrid, $infra.seguridad.pasGrid, $RutTemp, "/tmp")
    $mishell.titulo("Creando ASM +FRA")
    $mishell.linea("/u01/app/19.3.0/grid/bin/asmca -silent -createDiskGroup -diskGroupName FRA -diskList " + $listadiscos + " -redundancy EXTERNAL 2>&1")
    $mishell.EjecutarSh($infra.nodos[0].NombreVM, "Creando FRA")
}
else {
    loc ("AVISO:")
    loc ("No hay discos compartidos disponibles para generar el DG FRA")
    loc ("Posiblemente el número de discos compartidos sea menor que 4")
    loc ("Debe resolverse nanualmente antes de continuar con otros procesos")
    loc ("Se sugiere utilizar asmca, suprimiendo un disco del DG DATA")
    loc ("y creando el DG FRA con redundancia externa sobre el disco liberado")
}

loc "Fin del proceso"

$evento.finGestor()