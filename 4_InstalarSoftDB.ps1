. .\comunes\iniEntorno.ps1

loc "Comprobando que existen los servidores Virtuales"

foreach ($nodo in $infra.nodos) {
    if (-not $nodo.existe()) { 
        validacion $false "Alguno de los servidores virtuales NO existe, saliendo del proceso"
    }
}
validacion $true ""

foreach ($nodo in $infra.nodos) {
    $nodo.arrancarNodo()
}

$ok = $infra.GI.VerificarCluster()
validacion $ok "El cluster no está en el estado esperado, saliendo del proceso"

$listaNodos = $infra.listanodos()

if ($infra.seguridad.usrGrid -cne "oracle") {
    $infra.seguridad.passLessUsuario("oracle")
}

$infra.nodos[0].CopiarSoft("DB")
$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$infra.nodos[0].UnzipSoft($mishell, "DB")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, ("Descomprimiendo software DB oracle en " + $infra.Nodos[0].NombreVM))

<#
$mishell = [shellLinux]::new("mish.sh", "oracle", $Infra.seguridad.pasORA, $RutTemp, "/tmp")
$mishell.titulo("Ejecutando validacion de preinstalacion RAC")
$mishell.linea("cd /u01/app/19.3.0/grid")
$mishell.linea("/u01/app/19.3.0/grid/runcluvfy.sh stage -pre dbinst -n '" + $listaNodos + "' -fixupnoexec 2>&1")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, "Ejecutando verificación de preinstalación RAC")

for ($i = 0; $i -lt $numNodos; $i++) {
    $mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
    $mishell.titulo("ejecutando fixup en " + $infra.nodos[$i].NombreVM)
    $mishell.linea("if [ -f \`"/tmp/CVU_19.0.0.0.0_oracle/runfixup.sh\`" ];then")
    $mishell.linea("  /tmp/CVU_19.0.0.0.0_oracle/runfixup.sh")
    $mishell.linea("fi")
    $mishell.EjecutarSh($infra.nodos[$i].NombreVM, ("ejecutando fixup en " + $infra.nodos[$i].NombreVM))
}
#>

$mishell = [shellLinux]::new("mish.sh", "oracle", $Infra.seguridad.pasORA, $RutTemp, "/tmp")
$mishell.titulo("Instalando software de base de datos oracle")
$mishell.linea("echo `"oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.3.0`" > /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.option=INSTALL_DB_SWONLY`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"UNIX_GROUP_NAME=oinstall`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"INVENTORY_LOCATION=/u01/app/oraInventory`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"ORACLE_BASE=/u01/app/oracle`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.InstallEdition=EE`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.OSDBA_GROUP=dba`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.OSOPER_GROUP=oper`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.OSBACKUPDBA_GROUP=backupdba`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.OSDGDBA_GROUP=dgdba`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.OSKMDBA_GROUP=kmdba`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.OSRACDBA_GROUP=racdba`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.CLUSTER_NODES=" + $listanodos + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.isRACOneInstall=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.rac.serverpoolCardinality=0`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.config.starterdb.type=GENERAL_PURPOSE`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.ConfigureAsContainerDB=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.config.starterdb.memoryOption=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.config.starterdb.installExampleSchemas=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.config.starterdb.managementOption=DEFAULT`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.config.starterdb.omsHost=`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.config.starterdb.omsPort=0`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"oracle.install.db.config.starterdb.enableRecovery=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"SECURITY_UPDATES_VIA_MYORACLESUPPORT=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"DECLINE_SECURITY_UPDATES=true`" >> /tmp/oracle.rsp")
$mishell.linea("/u01/app/oracle/product/19.3.0/dbhome_1/runInstaller -silent -responseFile /tmp/oracle.rsp -ignorePrereqFailure -waitforcompletion 2>&1")
$mishell.linea("rm -rf /tmp/oracle.rsp")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, "Instalando software de base de datos")

for ($i = 0; $i -lt $numNodos; $i++) {
    $mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
    $mishell.titulo("ejecutando root.sh en " + $infra.nodos[$i].NombreVM)
    $mishell.linea("/u01/app/oracle/product/19.3.0/dbhome_1/root.sh 2>&1")
    $mishell.EjecutarSh($infra.nodos[$i].NombreVM, ("ejecutando shell root en " + $infra.nodos[$i].NombreVM))
}

loc "Fin del proceso"

$evento.finGestor()
