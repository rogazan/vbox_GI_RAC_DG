. .\comunes\iniEntorno.ps1

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

$ok = $infra.GI.VerificarCluster()
validacion $ok "El cluster no está en el estado esperado, , saliendo del proceso"

$ok = (-not $infra.GI.ValidarBD($infra.GI.prim))
validacion $ok "La base de datos primaria ya existe en el cluster, saliendo del proceso"

$listaNodos = $infra.listanodos()

$tamFRA = [int]($infra.SAN.tamFRA() / 2)

$mishell = [shellLinux]::new("mish.sh", "oracle", $Infra.seguridad.pasORA, $RutTemp, "/tmp")
$mishell.titulo("Creando fichero de respuestas")
$mishell.linea("echo `"responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v12.2.0`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"gdbName=" + $infra.GI.prim + "." + $infra.red.dominio + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"sid=" + $infra.GI.prim + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"databaseConfigType=RAC`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"policyManaged=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"createServerPool=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"force=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"createAsContainerDatabase=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"numberOfPDBs=0`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"useLocalUndoForPDBs=true`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"nodelist=" + $listaNodos + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"templateName=/u01/app/oracle/product/19.3.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"sysPassword=" + $infra.seguridad.pasOraSys + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"systemPassword=" + $infra.seguridad.pasOraSys + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"emExpressPort=5500`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"runCVUChecks=FALSE`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"omsHost=`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"omsPort=0`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"dvConfiguration=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"olsConfiguration=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"datafileJarLocation={ORACLE_HOME}/assistants/dbca/templates/`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"datafileDestination=+DATA/{DB_UNIQUE_NAME}/`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"recoveryAreaDestination=+FRA`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"storageType=ASM`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"diskGroupName=+DATA/{DB_UNIQUE_NAME}/`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"recoveryGroupName=+FRA`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"characterSet=AL32UTF8`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"nationalCharacterSet=AL16UTF16`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"registerWithDirService=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"listeners=LISTENER`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"variables=ORACLE_BASE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1,DB_UNIQUE_NAME=" + $infra.GI.prim + ",ORACLE_BASE=/u01/app/oracle,PDB_NAME=,DB_NAME=" + $infra.GI.prim + ",ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1,SID=" + $infra.GI.prim + "`" >> /tmp/oracle.rsp")
$paramsDB = "echo `"initParams="
for ($i = 1; $i -le $infra.numNodos(); $i++) {
    $paramsDB += $infra.GI.prim + [string]$i + ".undo_tablespace=UNDOTBS" + [string]$i + ","
    $paramsDB += $infra.GI.prim + [string]$i + ".thread=" + [string]$i + ","
    $paramsDB += $infra.GI.prim + [string]$i + ".instance_number=" + [string]$i + ","
}
$paramsDB += "sga_target=1200MB,db_block_size=8192BYTES,cluster_database=true,family:dw_helper.instance_mode=read-only,nls_language=AMERICAN,dispatchers=(PROTOCOL=TCP) (SERVICE=" + $infra.GI.prim + "XDB),diagnostic_dest={ORACLE_BASE},remote_login_passwordfile=exclusive,db_create_file_dest=+DATA/{DB_UNIQUE_NAME}/,audit_file_dest={ORACLE_BASE}/admin/{DB_UNIQUE_NAME}/adump,processes=300,pga_aggregate_target=400MB,nls_territory=AMERICA,local_listener=-oraagent-dummy-,db_recovery_file_dest_size=" + $tamFRA + "MB,open_cursors=300,log_archive_format=%t_%s_%r.dbf,db_domain=" + $infra.red.dominio + ",compatible=19.0.0,db_name=" + $infra.GI.prim + ",db_recovery_file_dest=+FRA,audit_trail=db`" >> /tmp/oracle.rsp"
$mishell.linea($paramsDB)
$mishell.linea("echo `"sampleSchema=true`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"memoryPercentage=40`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"databaseType=MULTIPURPOSE`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"automaticMemoryManagement=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"totalMemory=0`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"`" >> /tmp/oracle.rsp")
$mishell.titulo("Creando Base de datos " + $infra.GI.prim)
$mishell.linea("cd /u01/app/oracle/product/19.3.0/dbhome_1/bin")
$mishell.linea("/u01/app/oracle/product/19.3.0/dbhome_1/bin/dbca -silent -createDatabase -ignorePreReqs -ignorePrereqFailure -responseFile /tmp/oracle.rsp")
$mishell.linea("rm -rf /tmp/oracle.rsp")
$mishell.titulo("configurando /etc/oratab " + $infra.GI.prim + " en todos los nodos")
$mishell.linea("for i in {1.." + $infra.numNodos() + "}")
$mishell.linea("do")
$mishell.linea("  ssh " + $infra.prefNodo + "`$i 'echo `"" + $infra.GI.prim + ":/u01/app/oracle/product/19.3.0/dbhome_1:N`" >> /etc/oratab'")
$mishell.linea("done")
$mishell.EjecutarSh($infra.nodos[0].NombreVM, ("Creando base de datos " + $infra.GI.prim))

loc "Fin del proceso"

$evento.finGestor()
