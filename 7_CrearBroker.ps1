. .\comunes\iniEntorno.ps1

loc "Comprobando que existen los servidores Virtuales"
$ok = $true
foreach ($nodo in $infra.nodos) {
    if (-not $nodo.existe()) { $ok = $false }
}
validacion $ok "Alguno de los servidores virtuales NO existe, saliendo del proceso"

foreach ($nodo in $Infra.nodos) {
    $nodo.arrancarNodo()
}

$ok = $infra.GI.VerificarCluster()
validacion $ok "El cluster no está en el estado esperado, saliendo del proceso"

$ok = $infra.GI.ValidarBD($infra.GI.prim)
validacion $ok "La base de datos primaria no está en el estado esperado, saliendo del proceso"

$ok = $infra.GI.ValidarBD($infra.GI.stby)
validacion $ok "La base de datos en espera no existe, saliendo del proceso"

$mishell = [shellLinux]::new("mish.sh", "oracle", $Infra.seguridad.pasORA, $RutTemp, "/tmp")
$mishell.titulo("Preparando primaria para broker")
$mishell.linea("export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1")
$mishell.linea("export ORACLE_SID=" + $infra.GI.prim)
$mishell.linea("export ORACLE_BASE=/u01/app/oracle")
$mishell.linea("/u01/app/oracle/product/19.3.0/dbhome_1/bin/sqlplus /nolog << EOF")
$mishell.linea("connect sys/" + $infra.seguridad.pasOraSys + "@" + $infra.GI.prim + " as sysdba;")
$mishell.linea("alter system set dg_broker_start=false scope=both sid='*';")
$mishell.linea("alter system set log_archive_dest_2='' scope=both sid='*';")
$mishell.linea("alter system set dg_broker_config_file1='+data/" + $infra.GI.prim + "/brcfg1.dat' scope=both sid='*';")
$mishell.linea("alter system set dg_broker_config_file2='+fra/" + $infra.GI.prim + "/brcfg2.dat' scope=both sid='*';")
$mishell.linea("alter system set dg_broker_start=true scope=both sid='*';")
$mishell.linea("EOF")
$mishell.titulo("Preparando en espera para broker")
$mishell.linea("export ORACLE_SID=" + $infra.GI.stby)
$mishell.linea("/u01/app/oracle/product/19.3.0/dbhome_1/bin/sqlplus /nolog << EOF")
$mishell.linea("connect sys/" + $infra.seguridad.pasOraSys + "@" + $infra.GI.stby + " as sysdba;")
$mishell.linea("alter system set dg_broker_start=false scope=both sid='*';")
$mishell.linea("alter system set log_archive_dest_2='' scope=both sid='*';")
$mishell.linea("alter system set dg_broker_config_file1='+data/" + $infra.GI.stby + "/brcfg1.dat' scope=both sid='*';")
$mishell.linea("alter system set dg_broker_config_file2='+fra/" + $infra.GI.stby + "/brcfg2.dat' scope=both sid='*';")
$mishell.linea("alter system set dg_broker_start=true scope=both sid='*';")
$mishell.linea("EOF")
$mishell.titulo("Configurando Broker")
$mishell.linea("/u01/app/oracle/product/19.3.0/dbhome_1/bin/dgmgrl << EOF")
$mishell.linea("connect sys/" + $infra.seguridad.pasOraSys + "@" + $infra.GI.prim + " as sysdba;")
$mishell.linea("host sleep 3")
$mishell.linea("create configuration 'configuracion' as primary database is '" + $infra.GI.prim + "' connect identifier is '" + $infra.GI.prim + "';")
$mishell.linea("host sleep 3")
$mishell.linea("add database '" + $infra.GI.stby + "' as connect identifier is '" + $infra.GI.stby + "';");
$mishell.linea("host sleep 3")
$mishell.linea("edit database '" + $infra.GI.prim + "' SET PROPERTY 'RedoRoutes' = '(" + $infra.GI.prim + ":" + $infra.GI.stby + " ASYNC)';")
$mishell.linea("edit database '" + $infra.GI.stby + "' SET PROPERTY 'RedoRoutes' = '(" + $infra.GI.stby + ":" + $infra.GI.prim + " ASYNC)';")
$mishell.linea("edit configuration set property CommunicationTimeout = 300;")
$mishell.linea("edit configuration set property OperationTimeout = 600;")
$mishell.linea("edit configuration set protection mode as maxPerformance;")
$mishell.linea("enable configuration;")
$mishell.linea("exit")
$mishell.linea("EOF")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, "Creando Configuracion Broker")

loc "Fin del proceso"

$evento.finGestor()
