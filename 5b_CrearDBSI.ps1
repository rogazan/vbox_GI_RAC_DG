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

$midb = $DBSI

$ok = $infra.GI.VerificarCluster()
validacion $ok "El cluster no está en el estado esperado, , saliendo del proceso"

$ok = (-not $infra.GI.ValidarBD($midb))
validacion $ok "La base de datos ya existe en el cluster, saliendo del proceso"

$ok = (-not $infra.GI.ExisteEnASM($midb))
validacion $ok "La base de datos ya existe en ASM, saliendo del proceso"

$ok = (-not $infra.GI.ExisteEnOratab($midb))
validacion $ok "La base de datos ya existe en Oratab, saliendo del proceso"

$tamFRA = [int]($infra.SAN.tamFRA() / 2)

$mishell = [shellLinux]::new("mish.sh", "oracle", $Infra.seguridad.pasORA, $RutTemp, "/tmp")
$mishell.titulo("Creando fichero de respuestas")
$mishell.linea("echo `"responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v12.2.0`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"gdbName=" + $midb + "." + $infra.red.dominio + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"sid=" + $midb + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"databaseConfigType=SI`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"policyManaged=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"createServerPool=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"force=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"createAsContainerDatabase=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"useLocalUndoForPDBs=true`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"templateName=/u01/app/oracle/product/19.3.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"sysPassword=" + $infra.seguridad.pasOraSys + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"systemPassword=" + $infra.seguridad.pasOraSys + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"runCVUChecks=FALSE`" >> /tmp/oracle.rsp")
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
$mishell.linea("echo `"variables=ORACLE_BASE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1,DB_UNIQUE_NAME=" + $midb + ",ORACLE_BASE=/u01/app/oracle,PDB_NAME=,DB_NAME=" + $midb + ",ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1,SID=" + $midb + "`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"initParams=undo_tablespace=UNDOTBS1,sga_target=1200MB,db_block_size=8192BYTES,nls_language=AMERICAN,dispatchers=(PROTOCOL=TCP) (SERVICE=" + $midb + "XDB),diagnostic_dest={ORACLE_BASE},remote_login_passwordfile=EXCLUSIVE,db_create_file_dest=+DATA/{DB_UNIQUE_NAME}/,audit_file_dest={ORACLE_BASE}/admin/{DB_UNIQUE_NAME}/adump,processes=300,pga_aggregate_target=400MB,nls_territory=AMERICA,local_listener=LISTENER_" + $midb + ",db_recovery_file_dest_size=" + $tamFra + "MB,open_cursors=300,log_archive_format=%t_%s_%r.dbf,db_domain=" + $infra.red.dominio + ",compatible=19.0.0,db_name=" + $midb + ",db_recovery_file_dest=+FRA,audit_trail=db`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"sampleSchema=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"memoryPercentage=40`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"databaseType=MULTIPURPOSE`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"automaticMemoryManagement=false`" >> /tmp/oracle.rsp")
$mishell.linea("echo `"totalMemory=0`" >> /tmp/oracle.rsp")

$mishell.titulo("Creando Base de datos " + $midb)
$mishell.linea("cd /u01/app/oracle/product/19.3.0/dbhome_1/bin")
$mishell.linea("/u01/app/oracle/product/19.3.0/dbhome_1/bin/dbca -silent -createDatabase -ignorePreReqs -ignorePrereqFailure -responseFile /tmp/oracle.rsp")
$mishell.linea("rm -rf /tmp/oracle.rsp")
$mishell.linea("for i in {2.." + $infra.numNodos() + "}")
$mishell.linea("do")
$mishell.linea("  ssh " + $infra.prefnodo + "`$i 'cp /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/tnsnames.ora /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/tnsnames.ora.bck'")
$mishell.linea("  scp /u01/app/oracle/product/19.3.0/dbhome_1/network/admin/tnsnames.ora " + $infra.prefnodo + "`$i:/u01/app/oracle/product/19.3.0/dbhome_1/network/admin/tnsnames.ora")
$mishell.linea("done")

$mishell.EjecutarSh($infra.nodos[$global:NODOSI - 1].NombreVM, ("Creando base de datos " + $infra.GI.prim))

loc "Fin del proceso"

$evento.finGestor()