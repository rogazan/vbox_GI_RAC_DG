class Seguridad {
    [string]$pasRoot
    [string]$pasOra
    [string]$usrGrid
    [string]$pasGrid
    [string]$pasOraSys
    [string]$ususis

    Seguridad() {
        $this.pasRoot   = $global:PASSUSR
        $this.pasOra    = $global:PASSORA
        $this.usrGrid   = $global:USRGRID
        $this.pasGrid   = $global:PASSGRID
        $this.pasOraSys = $global:PASORASYS
        $this.ususis    = $global:USUARIO
    }

    PermDir([shellLinux]$shell) {
        $shell.titulo("Creando directorios y permisos")
        $shell.linea("mkdir -p /u01/app/19.3.0/grid")
        $shell.linea("mkdir -p /u01/app/oracle")
        $shell.linea("mkdir -p /u01/app/oracle/product/19.3.0/dbhome_1")
        $shell.linea("chown -R " + $this.usrGrid + ":oinstall /u01")
        $shell.linea("chown -R oracle:oinstall /u01/app/oracle")
        $shell.linea("chmod -R 775 /u01/")
    }

    ModPas([shellLinux]$shell, $usuario, $mipass) {
        $shell.titulo("Asignando password de " + $usuario)
        $shell.linea("passwd " + $usuario + " << EOF 2>&1" )
        $shell.linea($mipass)
        $shell.linea($mipass)
        $shell.linea("EOF")
    }

    GruposOra([shellLinux]$shell) {
        $shell.titulo("Creando grupos y asignando usuarios")
        $shell.linea("groupadd -g 54327 asmdba"   )
        $shell.linea("groupadd -g 54328 asmoper"  )
        $shell.linea("groupadd -g 54329 asmadmin" )

        if ($this.usrGrid -cne "oracle") {
            $shell.linea("useradd -u 54322 -g oinstall " + $this.usrGrid)
            $shell.linea("usermod -G dba,asmdba,asmoper,asmadmin,racdba,vboxsf " + $this.usrGrid)
            $shell.linea("usermod -G dba,backupdba,dgdba,kmdba,racdba,oper,asmdba,vboxsf oracle")
            $shell.titulo("Modificando limits grid")
            $shell.linea("cat /etc/security/limits.d/oracle-database-preinstall-19c.conf | sed 's/oracle/" + $this.usrGrid + "/g' > /tmp/limites.conf")
            $shell.linea("cat /tmp/limites.conf >> /etc/security/limits.d/oracle-database-preinstall-19c.conf")
            $shell.linea("rm -f /tmp/limites.conf")
        } else {
            $shell.linea("usermod -G dba,backupdba,dgdba,kmdba,racdba,oper,asmdba,asmoper,asmadmin,vboxsf oracle")
        }
    }
    
    ProfOra([shellLinux]$shell) {
        $shell.titulo("Modificando /etc/profile para establecer limites de usuario")
        $shell.linea("echo `"if [ `$USER = \`"oracle\`" ]; then`" >> /etc/profile")
        $shell.linea("echo `"  if [ `$SHELL = \`"/bin/ksh\`" ]; then`" >> /etc/profile")
        $shell.linea("echo `"    ulimit -p 16384`" >> /etc/profile")
        $shell.linea("echo `"    ulimit -n 65536`" >> /etc/profile")
        $shell.linea("echo `"    ulimit -s 32768`" >> /etc/profile")
        $shell.linea("echo `"  else`" >> /etc/profile")
        $shell.linea("echo `"    ulimit -u 16384 -n 65536`" >> /etc/profile")
        $shell.linea("echo `"    ulimit -s 32768`" >> /etc/profile")
        $shell.linea("echo `"  fi`" >> /etc/profile")
        $shell.linea("echo `"fi`" >> /etc/profile")
        if ($this.usrGrid -cne "oracle") {
            $shell.linea(    "echo `"if [ `$USER = \`"" + $this.usrGrid + "\`" ]; then`" >> /etc/profile")
            $shell.linea(    "echo `"  if [ `$SHELL = \`"/bin/ksh\`" ]; then`" >> /etc/profile")
            $shell.linea(    "echo `"    ulimit -p 16384`" >> /etc/profile")
            $shell.linea(    "echo `"    ulimit -n 65536`" >> /etc/profile")
            $shell.linea(    "echo `"    ulimit -s 32768`" >> /etc/profile")
            $shell.linea(    "echo `"  else`" >> /etc/profile")
            $shell.linea(    "echo `"    ulimit -u 16384 -n 65536`" >> /etc/profile")
            $shell.linea(    "echo `"    ulimit -s 32768`" >> /etc/profile")
            $shell.linea(    "echo `"  fi`" >> /etc/profile")
            $shell.linea(    "echo `"fi`" >> /etc/profile")
        }
        $shell.titulo("Modificando /home/oracle/.bash_profile para establecer umask")
        $shell.linea("echo `"umask 022`" >> /home/oracle/.bash_profile")
        if ($this.usrGrid -cne "oracle") {
            $shell.titulo("Modificando /home/" + $this.usrGrid + "/.bash_profile para establecer umask")
            $shell.linea("echo `"umask 022`" >> /home/" + $this.usrGrid + "/.bash_profile")
        }
    }

    passLessRoot() {
        $mishell = [shellLinux]::new("mish.sh", "root", $this.pasRoot, $global:RutTemp, "/tmp")
        $mishell.titulo("Creando claves root en primer nodo")
        $mishell.linea("rm -rf /root/.ssh/*")
        $mishell.linea("echo `"#! /usr/bin/expect`" > /tmp/cpkey.sh")
        $mishell.linea("echo `"set timeout -1`" >> /tmp/cpkey.sh")
        $mishell.linea("echo `"spawn /usr/bin/ssh-keygen -t rsa -b 4096`" >> /tmp/cpkey.sh")
        $mishell.linea("echo `"expect \`"id_rsa):\`" { send \`"\r\`" }`"  >> /tmp/cpkey.sh")
        $mishell.linea("echo `"expect \`"passphrase):\`" { send \`"\r\`" }`" >> /tmp/cpkey.sh")
        $mishell.linea("echo `"expect \`"again:\`" { send \`"\r\`" }`" >> /tmp/cpkey.sh")
        $mishell.linea("echo `"interact`" >> /tmp/cpkey.sh >> /tmp/cpkey.sh")
        $mishell.linea("chmod +x /tmp/cpkey.sh")
        $mishell.linea("/tmp/cpkey.sh")
        $mishell.titulo("Transfiriendo clave publica de root a root de todos los nodos")
        $mishell.linea("for i in {1.." + $global:infra.numNodos() + "}")
        $mishell.linea("do")
        $mishell.linea("    echo `"#! /usr/bin/expect`" > /tmp/cpkey.sh")
        $mishell.linea("    echo `"set timeout -1`" >> /tmp/cpkey.sh")
        $mishell.linea("    echo `"spawn /usr/bin/ssh-copy-id root@" + $global:infra.prefNodo + "`$i`" >> /tmp/cpkey.sh")
        $mishell.linea("    echo `"expect \`"(yes/no)?\`" { send \`"yes\r\`" }`" >> /tmp/cpkey.sh")
        $mishell.linea("    echo `"expect \`"password:\`" { send \`"" + $this.pasRoot + "\r\`" }`" >> /tmp/cpkey.sh")
        $mishell.linea("    echo `"interact`" >> /tmp/cpkey.sh")
        $mishell.linea("    chmod +x /tmp/cpkey.sh")
        $mishell.linea("    /tmp/cpkey.sh")
        $mishell.linea("done")
        $mishell.EjecutarSh($global:infra.nodos[0].NombreVM, "Configurando claves para conexion root sin password")
    }

    passLessUsuario($usu) {
        if ($usu -ceq "oracle") {
            $pas = $this.pasOra
        } else {
            $pas = $this.pasGrid
        }
        $mishell = [shellLinux]::new("mish.sh", "root", $this.pasRoot, $global:RutTemp, "/tmp")
        $mishell.titulo("Transfiriendo clave publica de root a " + $usu + " en todos los nodos")
        $mishell.linea("for i in {1.." + $global:infra.numNodos() + "}")
        $mishell.linea("do")
        $mishell.linea("    echo `"#! /usr/bin/expect`" > /tmp/cpkey.sh")
        $mishell.linea("    echo `"set timeout -1`" >> /tmp/cpkey.sh")
        $mishell.linea("    echo `"spawn /usr/bin/ssh-copy-id " + $usu + "@" + $global:infra.prefNodo + "`$i`" >> /tmp/cpkey.sh")
        $mishell.linea("    echo `"expect \`"password:\`" { send \`"" + $pas + "\r\`" }`" >> /tmp/cpkey.sh")
        $mishell.linea("    echo `"interact`" >> /tmp/cpkey.sh")
        $mishell.linea("    chmod +x /tmp/cpkey.sh")
        $mishell.linea("    /tmp/cpkey.sh")
        $mishell.linea("done")
        $mishell.titulo("Creando claves de " + $usu + " en todos los nodos")
        $mishell.linea("echo `"#! /usr/bin/expect`" > /tmp/cpkeyg.sh")
        $mishell.linea("echo `"set timeout -1`" >> /tmp/cpkeyg.sh")
        $mishell.linea("echo `"spawn /usr/bin/ssh-keygen -t dsa`" >> /tmp/cpkeyg.sh")
        $mishell.linea("echo `"expect \`"id_dsa):\`" { send \`"\r\`" }`"  >> /tmp/cpkeyg.sh")
        $mishell.linea("echo `"expect \`"passphrase):\`" { send \`"\r\`" }`" >> /tmp/cpkeyg.sh")
        $mishell.linea("echo `"expect \`"again:\`" { send \`"\r\`" }`" >> /tmp/cpkeyg.sh")
        $mishell.linea("echo `"interact`" >> /tmp/cpkey.sh >> /tmp/cpkeyg.sh")
        $mishell.linea("chmod +x /tmp/cpkeyg.sh")
        $mishell.linea("for i in {1.." + $global:infra.numNodos() + "}")
        $mishell.linea("do")
        $mishell.linea("    scp /tmp/cpkeyg.sh " + $global:infra.prefNodo + "`$i:/tmp")
        $mishell.linea("    ssh " + $global:infra.prefNodo + "`$i chown " + $usu + ":oinstall /tmp/cpkeyg.sh")
        $mishell.linea("    ssh " + $usu + "@" + $global:infra.prefNodo + "`$i /tmp/cpkeyg.sh")
        $mishell.linea("    ssh " + $usu + "@" + $global:infra.prefNodo + "`$i 'cat /home/" + $usu + "/.ssh/id_dsa.pub >> /home/" + $usu + "/.ssh/authorized_keys'")
        $mishell.linea("done")   
        $mishell.titulo("Transfiriendo clave publica de " + $usu + " entre todos los nodos")
        $mishell.linea("for j in {1.." + $global:infra.numNodos() + "}")
        $mishell.linea("do")
        $mishell.linea("  for i in {1.." + $global:infra.numNodos() + "}")
        $mishell.linea("  do")
        $mishell.linea("    echo `"#! /usr/bin/expect`" > /tmp/cpkeyg2.sh")
        $mishell.linea("    echo `"set timeout -1`" >> /tmp/cpkeyg2.sh")
        $mishell.linea("    echo `"spawn /usr/bin/ssh-copy-id " + $usu + "@" + $global:infra.prefNodo + "`$j`" >> /tmp/cpkeyg2.sh")
        $mishell.linea("    echo `"expect \`"(yes/no)?\`" { send \`"yes\r\`" }`" >> /tmp/cpkeyg2.sh")
        $mishell.linea("    echo `"expect \`"password:\`" { send \`"" + $pas + "\r\`" }`" >> /tmp/cpkeyg2.sh")
        $mishell.linea("    echo `"interact`" >> /tmp/cpkeyg2.sh")
        $mishell.linea("    chmod +x /tmp/cpkeyg2.sh")        
        $mishell.linea("    scp /tmp/cpkeyg2.sh " + $global:infra.prefNodo + "`$i:/tmp")
        $mishell.linea("    ssh " + $global:infra.prefNodo + "`$i chown " + $usu + ":oinstall /tmp/cpkeyg2.sh")
        $mishell.linea("    ssh " + $usu + "@" + $global:infra.prefNodo + "`$i '/tmp/cpkeyg2.sh 2>&1'")
        $mishell.linea("  done")
        $mishell.linea("done")
        $mishell.linea("rm -rf /tmp/cpkeyg2.sh")
        $mishell.EjecutarSh($global:infra.nodos[0].NombreVM, ("Configurando claves para conexion " + $usu + " sin password"))
    }
}

class GestorEventos {
    [string]$nombre
    [System.Management.Automation.Job]$miEvento
    [System.Object]$voz
    [System.Object]$terminaVoz

    GestorEventos($nombre) {
        $this.nombre = $nombre
        $this.miEvento = Register-EngineEvent -SourceIdentifier Mievento -Action { "{0}" -f $event.messagedata | Write-Host}
        if ( -not ([appdomain]::currentdomain.getassemblies() | where-object {$_.FullName -like 'System.Speech*'}).FullName) {
            Add-Type -AssemblyName System.speech
        }
        $this.voz = New-Object System.Speech.Synthesis.SpeechSynthesizer
        if ($global:CONVOZ -eq "SI") {
            $this.terminaVoz = $this.voz.SpeakAsync("Iniciando sintetizador de voz")
            while (-not $this.terminaVoz.Iscompleted) {Start-Sleep -milliseconds 50}
            $this.voz.Rate = 0
        }
    }

    finGestor() {
        Stop-Job $this.miEvento
        Remove-Job $this.miEvento
    }
}

class shellLinux {
    [string]$nombre
    [string]$PathWin
    [string]$PathLinux
    [string]$usuario
    [string]$password
    [string]$fichero
    [string]$milog
    [string]$nomlog
    [int32]$idlog

    shellLinux($nombre, $usuario, $pass, $PathWin, $PathLinux) {
        $this.nombre    = $nombre
        $this.PathWin   = $PathWin
        $this.PathLinux = $PathLinux
        $this.usuario   = $usuario
        $this.password  = $pass
        $this.fichero   = $this.PathWin + "\" + $this.nombre

        $fich = [string](Get-ChildItem -Path ($global:RutTemp + "\milog[0-9][0-9][0-9].log") -Name | `
            Sort-object | `
            Select-Object -Last 1)
        
        $this.milog = $global:RutTemp + "\milog"
        if ($fich) {
            $this.milog = $this.milog + ([string]([int]$fich.substring(5, 3) + 1)).PadLeft(3,"0")
        }
        else {
            $this.milog = $this.milog + "000"
        }
        $this.nomlog = $this.milog + ".sh"
        $this.milog = $this.milog + ".log"

        "#!/bin/bash" | Out-File $this.fichero -encoding ascii
        $this.cabecera()
        "" | Out-File $this.milog -encoding ascii
        if ($global:VERLOG -eq "SI") {
            $this.idlog = (Start-Process powershell -argumentlist ("Get-Content -Path " + $this.milog + " -Wait") -PassThru).id
        }
    }

    linea([string]$linea) {
        $linea | Out-File $this.fichero -encoding ascii -Append
    }

    titulo([string]$linea) {
        $this.linea("echo ' '")
        $this.linea("echo '# " + ("*" * 60) +"'")
        $this.linea("echo '# " + $linea + "'")
        $this.linea("echo '# " + ("*" * 60) +"'")
        $this.linea("echo ' '")
    }

    cabecera(){
        $this.linea("instini=`$((``date +%s%N`` / (1000 * 1000)))")
        $this.linea("echo ' '")
        $this.linea("echo '# " + ("*" * 60) +"'")
        $this.linea("echo '#'")
        $this.linea("echo '# Autor         : " + "A.T.V." + "'")
        $this.linea("echo '# Fecha y hora  : " + (Get-date).datetime + "'")
        $this.linea("echo '# fichero bash  : " + $this.nomlog + "'")
        $this.linea("echo '# log ejecucion : " + $this.milog + "'")
        $this.linea("echo '# usuario       : " + $this.usuario + "'")
        $this.linea("echo `"# servidor      : ``hostnamectl | grep hostname | tr -d ' ' | cut -d ':' -f 2```"") 
        $this.linea("echo '#'")
        $this.linea("echo '# " + ("*" * 60) +"'")
        $this.linea("echo ' '")
    }

    pie([string]$nombreVM){
        $this.linea("echo ' '")
        $this.linea("instfin=`$((``date +%s%N`` / (1000 * 1000)))")
        $this.linea("instdif=`$((`$instfin - `$instini))")
        $this.linea("insteje=``bc <<< `"scale=2;`$instdif / 1000`"``")
        $this.linea("echo ' '")
        $this.linea("echo '# " + ("*" * 60) +"'")
        $this.linea("echo `"# Tiempo proceso: `$insteje segundos`"")
        $this.linea("echo '# " + ("*" * 60) +"'")
        $this.linea("echo ' '")
        $this.linea("sleep 5")
    }

    dos2unix([string]$nodo) {
    VBoxManage guestcontrol $nodo run `
        --username root --password $global:infra.seguridad.pasRoot `
        --exe /usr/bin/yum --wait-stdout -- yum install -y dos2unix
    }

    EjecutarSh([string]$NombreVM, [string]$locucion) {
        if ($locucion -ne "") {
            loc ($locucion)
        }
        $this.Ejecutar($NombreVM)
        if ($locucion -ne "") {
            validacion $true ""
        }
    }

    Ejecutar([string]$NombreVM) {
        if (Test-Path $this.fichero) {
            $this.pie($NombreVM)
            copy-item $this.fichero -destination $this.nomlog -Force
            $null = VBoxManage guestcontrol $NombreVM copyto $this.fichero `
                --username $this.usuario --password $this.password `
                --target-directory /tmp

            VBoxManage guestcontrol $NombreVM run `
                --username $this.usuario --password $this.password `
                --exe /usr/bin/dos2unix --wait-stdout -- dos2unix -q /tmp/mish.sh

            VBoxManage guestcontrol $NombreVM run `
                --username $this.usuario --password $this.password `
                --exe /usr/bin/chmod --wait-stdout -- chmod +x /tmp/mish.sh

            VBoxManage guestcontrol $NombreVM run `
                --username $this.usuario --password $this.password `
                --exe /tmp/mish.sh --wait-stdout -- mish.sh | Out-File $this.milog -Encoding ASCII -Append

            VBoxManage guestcontrol $NombreVM run `
                --username $this.usuario --password $this.password `
                --exe /usr/bin/rm --wait-stdout -- rm -rf /tmp/mish.sh | Out-File $this.milog -Encoding ASCII -Append

            if ($global:VERLOG -eq "SI") {
                if (get-process -id $this.idlog -ErrorAction SilentlyContinue) {
                    stop-process -id $this.idlog -Force
                }
            }
        }
    }

    instalarSoftware([string]$producto) {
        $this.titulo("Instalando producto "  + $producto)
        $this.linea("yum install " + $producto + " -y 2>&1")
    }

    actualizarSoftware() {
        $this.titulo("Actualizando claves de repositorio")
        $this.linea("cp /usr/share/rhn/ULN-CA-CERT /usr/share/rhn/ULN-CA-CERT.old")
        $this.linea("wget https://linux-update.oracle.com/rpms/ULN-CA-CERT.sha2 -P /tmp 2>&1")
        $this.linea("rm -rf /usr/share/rhn/ULN-CA-CERT")
        $this.linea("cp /tmp/ULN-CA-CERT.sha2 /usr/share/rhn/ULN-CA-CERT")        
        $this.titulo("Actualizando sistema operativo")
        $this.linea("yum update -y 2>&1")
    }
}

class DiscoBase {
    [string]$fqdn
    [String]$deviceLinux

    DiscoBase($fqdn, $deviceLinux) {
        $this.fqdn = $fqdn
        $this.deviceLinux = $deviceLinux
    }

    [bool]existe() {
        return (Test-Path $this.fqdn)
    }
}

class DiscoSAN:DiscoBase {

    DiscoSAN($fqdn, $deviceLinux) : base($fqdn, $deviceLinux){}

    [bool]CrearDisco($tamanio) {
        $retorno = $false
        if (-not $this.existe()) {
            VBoxManage createhd --filename $this.fqdn --size $tamanio --format VDI --variant Fixed
            Start-Sleep -Seconds 2
            VBoxManage modifyhd $this.fqdn --type shareable
            $retorno = $true
        }
        return $retorno
    }
}

class DiscoLINUX:DiscoBase {

    DiscoLINUX($fqdn, $deviceLinux) : base($fqdn, $deviceLinux){}

    [bool]CrearDisco([discoIMAGEN]$Imagen, [string]$nodo) {
        $retorno = $false
        if (-not $this.existe()) {
            loc ("Creando Disco de sistema " + $nodo)
            VBoxManage clonemedium $Imagen.fqdn $this.fqdn --format VDI
            validacion $true ""
            $retorno = $true
        }
        return $retorno
    }

    [bool]CrearImagen([discoIMAGEN]$destino, [string]$nodo) {
        $retorno = $false
        if (-not $destino.existe()) {
            loc ("Creando disco imagen")
            VBoxManage clonemedium $this.fqdn $destino.fqdn --format VDI
            $retorno = $true
            validacion $true ""
        }
        return $retorno
    }
    
    [bool]ClonarDisco([discoLINUX]$destino, [string]$nodo) {
        $retorno = $false
        if (-not $destino.existe()) {
            loc ("Clonando Disco " + $nodo)
            VBoxManage clonemedium $this.fqdn $destino.fqdn --format VDI
            $retorno = $true
            validacion $true ""
        }
        return $retorno
    }

    CrearDiscoVacio([string]$nodo, [int]$tamanio) {
        loc ("creando Disco " + $nodo)
        VBoxManage createhd --filename $this.fqdn --size $tamanio --format VDI --variant Standard
        validacion $true ""
    }
}

class DiscoIMAGEN:DiscoBase {
    DiscoIMAGEN($fqdn) : base($fqdn, ""){}

    borrarImagen() {
        loc ("Borrando imagen obsoleta")
        vboxmanage closemedium disk $this.fqdn --delete | Out-Null
        validacion $true ""
    }
}

class DiscoDVD:DiscoBase {
    DiscoDVD($fqdn) : base($fqdn, "/dev/sr0"){}
}

class SAN {
    [string]$Nombre
    [string]$Tipo
    [string]$Path
    [int]$TamDiscos
    [DiscoSAN[]]$Discos = [DiscoSAN[]]::new($global:NUMDISC)    

    SAN([string]$nombre) { 
        $this.Nombre    = $nombre
        $this.TamDiscos = $global:TAMDISCC
        $this.Path      = $global:RUTDCOMP
        $this.Tipo = $global:TIPOINST
        for ($i = 0; $i -lt $this.NumDiscos(); $i++) {
            $fqdn = $this.Path + "\asm" + [string]($i + 1) + ".vdi"
            $dev = "dev/sd" + [char]($i + 98)
            $Disco = [DiscoSAN]::new($fqdn, $dev)
            $this.Discos[$i] = $Disco
        }
    }

    PartDiscos($shell) {
        $shell.titulo("Creando paticiones de discos compartidos")
        for ($i = 1; $i -le $this.numDiscos(); $i++) {
            $shell.linea("parted /dev/sd" + [char]($i + 97) +" --script -- mklabel msdos mkpart primary 0% 100%")
        }
    }

    ConfDiscosTipo1($shell) {
        if ($this.Tipo -eq "UDEV") {
            $shell.titulo("Creando configuracion UDEV")
            for ($i = 1; $i -le $this.numDiscos(); $i++) {
                $shell.linea("D" + [char]($i + 97) + "=``/usr/lib/udev/scsi_id -g -u -d /dev/sd" + [char]($i + 97) + "1``")
            }
            $shell.linea("rm -f /tmp/rudev")
            $shell.linea("touch /tmp/rudev")
            for ($i = 1; $i -le $this.numDiscos(); $i++) {
                $shell.linea("echo `"KERNEL==\`"sd?1\`", SUBSYSTEM==\`"block\`", PROGRAM==\`"/usr/lib/udev/scsi_id -g -u -d /dev/\`$parent\`", RESULT==\`"`$D" + [char]($i + 97) + "\`", SYMLINK+=\`"oracleasm/disks/DISK$i\`", OWNER=\`"" + $global:infra.seguridad.usrGrid + "`\`", GROUP=\`"asmadmin\`", MODE=\`"0660\`"`" >> /tmp/rudev")
            }
            $shell.linea("cp /tmp/rudev /etc/udev/rules.d/99-oracle-asmdevices.rules")
            $shell.linea("chmod +r /etc/udev/rules.d/99-oracle-asmdevices.rules")

            for ($i = 1; $i -le $this.numDiscos() ; $i++) {
                $shell.linea("/sbin/partprobe /dev/sd" + [char]($i + 97) + "1")
            }
            $shell.linea("/sbin/udevadm control --reload-rules")
        }
        else {
            $shell.titulo("Creando configuracion ASMLIB")
            $shell.linea("oracleasm configure -u grid -g asmadmin -e -b -s y")
            $shell.linea("oracleasm init 2>&1")
            for ($i = 1; $i -le $this.numDiscos(); $i++) {
                $shell.linea("oracleasm createdisk DISK" + $i + " /dev/sd" + [char]($i + 97) + "1 2>&1")
            }
            $shell.linea("oracleasm scandisks 2>&1")
            $shell.linea("oracleasm listdisks 2>&1")
        }
    }

    ConfDiscosTipoN($shell) {
        if ($this.Tipo -ne "UDEV") {    
            $shell.titulo("Creando configuracion ASMLIB")
            $shell.linea("oracleasm init 2>&1")
            $shell.linea("oracleasm scandisks 2>&1")
            $shell.linea("oracleasm listdisks 2>&1")
        }    
    }

    [int]numDiscos() {
        return $this.discos.length
    }

    CrearSAN() {
        $i = 1
        loc ("Creando discos compartidos")
        foreach ($disco in $this.Discos) {
            loc ("Disco " + [string]$i)
            $disco.CrearDisco($this.TamDiscos)
            Start-Sleep -Seconds 2
            $i++
        }
        validacion $true ""
    }

    [int]TamDATA() {
        $ndisc = $this.numDiscos()
        return [int]((($ndisc / 2) + ($ndisc % 2)) * $this.TamDiscos)
    }

    [int]TAMFRA() {
        $ndisc = $this.numDiscos()
        return [int](($nDisc - (($nDisc / 2) + ($nDisc % 2) + 1) + 1) * $this.TamDiscos)
    }

    [string]listaDisDATA() {
        $ndisc = $this.numDiscos()
        $listadiscos = ""
        $hasta = [int]($nDisC / 2) + ($nDisC % 2)
        for ($i = 1; $i -le $hasta; $i++) {
            $listadiscos = $listadiscos + "/dev/oracleasm/disks/DISK" + $i + ","
        }
        $listadiscos = $listadiscos.Substring(0,$listadiscos.LastIndexOf(","))
        return $listadiscos
    }
    
    [string]listaDisFRA() {
        $ndisc = $this.numDiscos()
        $discosFRA = ""
        $desde = [int]($nDisC / 2) + ($nDisC % 2) + 1
        for ($i = $desde; $i -le $nDisC; $i++) {
            $discosFRA = $discosFRA + "/dev/oracleasm/disks/DISK" + $i + ","
        }
        if ($discosFRA -ne "") {
            $discosFRA = $discosFRA.Substring(0,$discosFRA.LastIndexOf(","))
        }
        return $discosFRA
    }
}

class Red {
    [string]$nombre
    [string]$Dir_Red_Priv
    [string]$Dir_Red_Pub
    [string]$Mask_Red_Priv
    [string]$Mask_Red_Pub
    [string]$Dominio
    [int]$IPBase
    [string]$Nombre_Interfaz_HostOnly
    [string]$Nombre_Interfaz_Bridged
    [string]$FicheroHost
    [string]$Gateway
    [string]$DNS

    Red([string]$nombre) {
        $this.IPBase        = [int]$global:IPBASE.Substring($global:IPBASE.LastIndexOf(".") + 1)
        $this.Dir_Red_Pub   = $global:IPBASE.Substring(0, $global:IPBASE.LastIndexOf('.')) 
        $this.Mask_Red_Pub  = "255.255.255.0"
        $this.Nombre        = $nombre
        $this.Dominio       = $global:Dominio
        $this.Dir_Red_Priv  = ""
        $this.Mask_Red_Priv = "255.255.255.0"
        $this.Nombre_Interfaz_Bridged = $global:BRIDIF
        $this.DNS = $global:DNS
        $this.Gateway = $global:GW
        $this.FicheroHost = ""
    }

    CambioNomHost([shellLinux]$shell, [string]$mihost) {
        $shell.titulo("Cambiando nombre de host")
        $shell.linea("hostnamectl set-hostname " + $mihost + "." + $this.Dominio)
    }

    CambioIPHost([shellLinux]$shell, [string]$IPRG, [string]$IPRP, [string]$IPB, [string]$IPD) {
        $shell.titulo("Modificando IP")
        $shell.linea("sed -i 's/IPADDR=" + $IPRG + "." + $IPB + "/IPADDR=" + $IPRG + "." + $IPD + "/' /etc/sysconfig/network-scripts/ifcfg-enp0s3")
        $shell.linea("sed -i 's/IPADDR=" + $IPRP + "." + $IPB + "/IPADDR=" + $IPRP + "." + $IPD + "/' /etc/sysconfig/network-scripts/ifcfg-enp0s8")
        $shell.linea("sed -i '/^HWADDR=/d' /etc/sysconfig/network-scripts/ifcfg-enp0s3")
        $shell.linea("echo `"HWADDR=``ifconfig enp0s3 | grep 'ether '| sed -e 's/^ *//' | cut -d `" `" -f 2```" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3")
        $shell.linea("sed -i '/^HWADDR=/d' /etc/sysconfig/network-scripts/ifcfg-enp0s8")
        $shell.linea("echo `"HWADDR=``ifconfig enp0s8 | grep 'ether '| sed -e 's/^ *//' | cut -d `" `" -f 2```" >> /etc/sysconfig/network-scripts/ifcfg-enp0s8")
    }

    ResetRed([shellLinux]$shell) {
        $shell.titulo("Reiniciando red")
        $shell.linea("service network stop")
        $shell.linea("service network start")
    }

    [bool]CrearRedPriv() {
        $retorno = $False
        loc "Creando Red Privada"
        if ($this.Dir_Red_Priv -eq "") {
            $RED = VBoxManage hostonlyif create
            $RED = $RED.Substring($RED.IndexOf("'") + 1)
            $RED = $RED.Substring(0, $RED.IndexOf("'"))
            $this.Nombre_Interfaz_HostOnly = $RED
            
            $REDES = [Array](VBoxManage list hostonlyifs)
            for ($i = 0; $i -lt $REDES.count; $i++) {
                $REDES[$i] = $REDES[$i].Substring($REDES[$i].indexOf(":") + 1).trim()
            }
            $IPPRIV = $REDES[$REDES.indexOf($RED) + 3]
            $this.Dir_Red_Priv = $IPPRIV.Substring(0, $IPPRIV.LastIndexOf('.')) 

            $retorno = $true
        }
        validacion $true ""
        return $retorno
    }

    CrearConfIF($shell, $tipo) {

        $IP = ""
        $NM = ""
        $routed = ""
        $dispo = ""
        $GW = ""
        $DNS1 = ""
        switch ($tipo) {
            "G" {
                $IP = $this.Dir_Red_Pub + "." + [string]$this.IPBase
                $NM = $this.Mask_Red_Pub
                $routed = "yes"
                $dispo = "enp0s3"
                $GW = $this.Gateway
                $DNS1 =$this.Dir_Red_Pub + "." + [string]$this.IPBase
              }
            "P" {
                $IP = $this.Dir_Red_Priv + "." + [string]$this.IPBase
                $NM = $this.Mask_Red_Priv
                $routed = "no"
                $dispo = "enp0s8"
            }
        }
        $shell.titulo("Modificando IF " + $dispo)
        $shell.linea("echo `"TYPE=Ethernet`" > /tmp/" + $dispo)
        $shell.linea("echo `"BOOTPROTO=none`" >> /tmp/" + $dispo)
        $shell.linea("echo `"DEFROUTE="+ $routed + "`" >> /tmp/" + $dispo)
        $shell.linea("echo `"IPV4_FAILURE_FATAL=no`" >> /tmp/" + $dispo)
        $shell.linea("echo `"IPV6INIT=yes`" >> /tmp/" + $dispo)
        $shell.linea("echo `"IPV6_AUTOCONF=yes`" >> /tmp/" + $dispo)
        $shell.linea("echo `"IPV6_DEFROUTE=" + $routed + "`" >> /tmp/" + $dispo)
        $shell.linea("echo `"IPV4_FAILURE_FATAL=no`" >> /tmp/" + $dispo)
        $shell.linea("echo `"IPV6_FAILURE_FATAL=no`" >> /tmp/" + $dispo)
        $shell.linea("echo `"NAME=" + $dispo + "`" >> /tmp/" + $dispo)
        $shell.linea("echo `"ONBOOT=yes`" >> /tmp/" + $dispo)
        $shell.linea("echo `"DEVICE=" + $dispo + "`" >> /tmp/" + $dispo)
        $shell.linea("echo `"IPADDR=" + $IP + "`" >> /tmp/" + $dispo)
        $shell.linea("echo `"NETMASK=" + $NM + "`" >> /tmp/" + $dispo)
        $shell.linea("echo `"DOMAIN=" + $this.dominio + "`" >> /tmp/" + $dispo)
        $shell.linea("echo `"HWADDR=``ifconfig " + $dispo + " | grep 'ether '| sed -e 's/^ *//' | cut -d `" `" -f 2```" >> /tmp/" + $dispo)
        if ($tipo -eq "G") {
            $shell.linea("echo `"GATEWAY=" + $GW + "`" >> /tmp/" + $dispo)
            $shell.linea("echo `"DNS1=" + $DNS1 + "`" >> /tmp/" + $dispo)
        }
        $shell.linea("rm -f /etc/sysconfig/network-scripts/ifcfg-" + $dispo)
        $shell.linea("cp /tmp/" + $dispo + " /etc/sysconfig/network-scripts/ifcfg-" + $dispo)
        $shell.linea("rm -f /tmp/" + $dispo)    
    }

    CrearFicheroHost([shellLinux]$shell, $Fichero) {
        $LnumNodos = $global:infra.numNodos()
        $shell.titulo("Creando Fichero Host")
        if ($this.Dir_Red_Priv -ne "") {
            $i = $this.IPBase
            [array]$IPNodos = [string]$i++
            for ($j = 1; $j -lt $LnumNodos; $j++) { [array]$IPNodos += [string]$i++ }
            [array]$IPVIP = [string]$i++
            for ($j = 1; $j -lt $LnumNodos; $j++) { [array]$IPVIP += [string]$i++ }
            [array]$IPClus = [string]$i++
            for ($j = 1; $j -lt 3; $j++) { [array]$IPClus += [string]$i++}
            [array]$nodos = [string]($global:infra.PrefNodo + "1")
            for ($j = 2; $j -le $LnumNodos; $j++) { [array]$nodos += [string]($global:infra.PrefNodo + [string]$j)}

            "" | Out-File $Fichero -encoding ascii

            for ($j = 0; $j -lt $LnumNodos; $j++) {
                ($this.Dir_Red_Pub + "." + $IPNodos[$j]).PadRight(20) + ($nodos[$j] + "."  + $this.Dominio).PadRight(40) + $nodos[$j] | Out-File $Fichero -encoding ascii -Append
            }        
            for ($j = 0; $j -lt $LnumNodos; $j++) {
                ($this.Dir_Red_Pub + "." + $IPVIP[$j]).PadRight(20) + ($nodos[$j] + "-vip." + $this.Dominio).PadRight(40) + $nodos[$j] + "-vip" | Out-File $Fichero -encoding ascii -Append
            }
            for ($j = 0; $j -lt $LnumNodos; $j++) {
                ($this.Dir_Red_Priv + "." + $IPNodos[$j]).PadRight(20) + ($nodos[$j] + "-priv." + $this.Dominio).PadRight(40) + $nodos[$j] + "-priv" | Out-File $Fichero -encoding ascii -Append
            }
            for ($j = 0; $j -lt 3; $j++) {
                ($this.Dir_Red_Pub + "." + $IPClus[$j]).PadRight(20) + ($global:infra.GI.Cluster + "-scan."  + $this.Dominio).PadRight(40) + $global:infra.GI.Cluster + "-scan" | Out-File $Fichero -encoding ascii -Append
            }
            $this.FicheroHost = $Fichero
        }
        $Fhost = Get-Content $fichero
        foreach ($linea in $Fhost) { $shell.linea("echo `"" + $linea + "`" >> /etc/hosts") }
    }

    BuscaRedPriv($nodo) {
        $adaptador = [array](VBoxManage showvminfo $nodo | findstr 'Host-Only').split("'")[1]
        $adaptadores=Vboxmanage list hostonlyifs | findstr -b -c:"Name:" -c:"IPAddress:"
        $ipred = ""
        for ($i = 0; $i -lt $adaptadores.length; $i++) {
            if ( $adaptadores[$i] -match $adaptador ) {
                $ipred = $adaptadores[$i + 1]
            }
        }
        $ipred = ($ipred.split(":"))[1].trim()
        $this.Dir_Red_Priv = $ipred.substring(0,$ipred.lastindexof("."))
    }

    crearDNS([shellLinux]$mishell) {
        $i = $this.IPBase
        $numNodos = $global:infra.numNodos()
        [array]$IPNodos = [string]$i++
        for ($j = 1; $j -lt $numNodos; $j++) { [array]$IPNodos += [string]$i++ }
        [array]$IPVIP = [string]$i++
        for ($j = 1; $j -lt $numNodos; $j++) { [array]$IPVIP += [string]$i++ }
        [array]$IPClus = [string]$i++
        for ($j = 1; $j -lt 3; $j++) { [array]$IPClus += [string]$i++}
        [array]$nodos = [string]($global:PrefNodo + "1")
        for ($j = 2; $j -le $numNodos; $j++) { [array]$nodos += [string]($global:PrefNodo + [string]$j)}

        $IPListenG = $this.Dir_Red_Pub  + "." + [string]$this.IPBase
        $IPListenP = $this.Dir_Red_Priv + "." + [string]$this.IPBase
        $IPQueryG = $this.Dir_Red_Pub  + ".0/24"
        $IPQueryP = $this.Dir_Red_Priv + ".0/24"
        
        $mishell.titulo("Creando DNS")
        $mishell.linea("echo `" `" > /etc/named.conf")
        $mishell.linea("echo `"options {`" >> /etc/named.conf")
        $mishell.linea("echo `"    listen-on               port 53 { 127.0.0.1;" + $IPListenG + ";" + $IPListenP + "; };`" >> /etc/named.conf")
        $mishell.linea("echo `"    directory               \`"/var/named\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"    dump-file               \`"/var/named/data/cache_dump.db\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"    statistics-file         \`"/var/named/data/named_stats.txt\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"    memstatistics-file      \`"/var/named/data/named_mem_stats.txt\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"    recursion               yes;`" >> /etc/named.conf")
        $mishell.linea("echo `"    dnssec-validation       no;`" >> /etc/named.conf")
        $mishell.linea("echo `"    allow-transfer          { none; };`" >> /etc/named.conf")
        $mishell.linea("echo `"    allow-query             { 127.0.0.1;" + $IPQueryG + ";" + $IPQueryP + "; };`" >> /etc/named.conf")
        $mishell.linea("echo `"    forwarders              { " + $this.DNS + "; };`" >> /etc/named.conf")
        $mishell.linea("echo `"};`" >> /etc/named.conf")
        
        $mishell.linea("echo `"zone \`"" + $this.dominio + "\`" IN {`" >> /etc/named.conf")
        $mishell.linea("echo `"type master;`" >> /etc/named.conf")
        $mishell.linea("echo `"file \`"db." + $this.dominio + ".zone\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"};`" >> /etc/named.conf")

        $partes = $this.Dir_Red_Pub.split(".")
        $redInvG = $partes[2] + "." + $partes[1] + "." + $partes[0]
        
        $mishell.linea("echo `"zone \`"" + $redInvG + ".in-addr.arpa\`" IN {`" >> /etc/named.conf")
        $mishell.linea("echo `"type master;`" >> /etc/named.conf")
        $mishell.linea("echo `"file \`"db." + $redInvG + ".zone\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"};`" >> /etc/named.conf")
        
        $partes = $this.Dir_Red_Priv.split(".")
        $redInvP = $partes[2] + "." + $partes[1] + "." + $partes[0]
        
        $mishell.linea("echo `"zone \`"" + $redInvP + ".in-addr.arpa\`" IN {`" >> /etc/named.conf")
        $mishell.linea("echo `"type master;`" >> /etc/named.conf")
        $mishell.linea("echo `"file \`"db." + $redInvP + ".zone\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"};`" >> /etc/named.conf")
        
        $mishell.linea("echo `"include \`"/etc/named.rfc1912.zones\`";`" >> /etc/named.conf")
        $mishell.linea("echo `"include \`"/etc/named.root.key\`";`" >> /etc/named.conf")
        
        $mishell.linea("echo `" `" >> /etc/named.conf")
        
        $mishell.linea("chown named:named /etc/named")

        $dest="/var/named/db." + $this.dominio + ".zone"

        $mishell.linea("echo `"\`$TTL    604800`"" + " > " + $dest)
        $mishell.linea("echo `"@       IN      SOA     dns." + $this.dominio + ". root." + $this.dominio + ". (`""  + " >> " + $dest)
        $mishell.linea("echo `"                              8         ; Serial`"" + " >> " + $dest)
        $mishell.linea("echo `"                         604800         ; Refresh`"" + " >> " + $dest)
        $mishell.linea("echo `"                          86400         ; Retry`"" + " >> " + $dest)
        $mishell.linea("echo `"                        2419200         ; Expire`"" + " >> " + $dest)
        $mishell.linea("echo `"                         604800 )       ; Negative Cache TTL`"" + " >> " + $dest)
        
        $mishell.linea("echo `"@".PadRight(20) + "IN  NS "+ $nodos[0] + "." + $this.dominio + ".`" >> " + $dest)

        for ($j = 0; $j -lt $numNodos; $j++) {
            $mishell.linea("echo `"" + ($nodos[$j]).PadRight(20) + "IN  A  " + $this.Dir_Red_Pub + "." + $IPNodos[$j] + "`"" + " >> " + $dest)
        }
        
        for ($j = 0; $j -lt $numNodos; $j++) {
            $mishell.linea("echo `"" + ($nodos[$j] + "-vip").PadRight(20) + "IN  A  " + $this.Dir_Red_Pub + "." + $IPVIP[$j] + "`"" + " >> " + $dest)
        }
        
        for ($j = 0; $j -lt $numNodos; $j++) {
            $mishell.linea("echo `"" + ($nodos[$j] + "-priv").PadRight(20) + "IN  A  " + $this.Dir_Red_Priv + "." + $IPNodos[$j] + "`"" + " >> " + $dest)
        }
        
        for ($j = 0; $j -lt 3; $j++) {
            $mishell.linea("echo `"" + ($global:Infra.GI.Cluster + "-scan").PadRight(20) + "IN  A  " + $this.Dir_Red_Pub + "." + $IPClus[$j] + "`"" + " >> " + $dest)
        }

        $mishell.linea("chown named:named " + $dest)
        
        $dest="/var/named/db." + $redInvG + ".zone"
        
        $mishell.linea("echo `"\`$ORIGIN " + $redInvG + ".in-addr.arpa.`"" + " > " + $dest)
        $mishell.linea("echo `"\`$TTL    604800`"" + " >> " + $dest)
        $mishell.linea("echo `"@       IN      SOA     dns." + $this.dominio + ". root." + $this.dominio + ". (`"" + " >> " + $dest)
        $mishell.linea("echo `"                              8         ; Serial`"" + " >> " + $dest)
        $mishell.linea("echo `"                         604800         ; Refresh`"" + " >> " + $dest)
        $mishell.linea("echo `"                          86400         ; Retry`"" + " >> " + $dest)
        $mishell.linea("echo `"                        2419200         ; Expire`"" + " >> " + $dest)
        $mishell.linea("echo `"                         604800 )       ; Negative Cache TTL`"" + " >> " + $dest)
        
        $mishell.linea("echo `"" + $redInvG + ".in-addr.arpa.   IN  NS     " + $nodos[0] + "." + $this.dominio + ".`"" + " >> " + $dest)
        
        for ($j = 0; $j -lt $numNodos; $j++) {
            $mishell.linea("echo `"" + ($IPNodos[$j]).PadRight(5) + "IN  PTR    " + $nodos[$j] + "." + $this.dominio + ".`"" + " >> " + $dest)
        }
        
        for ($j = 0; $j -lt $numNodos; $j++) {
            $mishell.linea("echo `"" + ($IPVIP[$j]).PadRight(5) + "IN  PTR    " + $nodos[$j] + "-vip." + $this.dominio + ".`"" + " >> " + $dest)
        }
        
        for ($j = 0; $j -lt 3; $j++) {
            $mishell.linea("echo `"" + ($IPClus[$j]).PadRight(5) + "IN  PTR    " + $global:infra.GI.cluster + "-scan." + $this.dominio + ".`"" + " >> " + $dest)
        }
        
        $mishell.linea("chown named:named " + $dest)

        $dest="/var/named/db." + $redInvP + ".zone"
        
        $mishell.linea("echo `"\`$ORIGIN " + $redInvP + ".in-addr.arpa.`"" + " > " + $dest)
        $mishell.linea("echo `"\`$TTL    604800`"" + " >> " + $dest)
        $mishell.linea("echo `"@       IN      SOA     dns." + $this.dominio + ". root." + $this.dominio + ". (`"" + " >> " + $dest)
        $mishell.linea("echo `"                              8         ; Serial`"" + " >> " + $dest)
        $mishell.linea("echo `"                         604800         ; Refresh`"" + " >> " + $dest)
        $mishell.linea("echo `"                          86400         ; Retry`"" + " >> " + $dest)
        $mishell.linea("echo `"                        2419200         ; Expire`"" + " >> " + $dest)
        $mishell.linea("echo `"                         604800 )       ; Negative Cache TTL`"" + " >> " + $dest)
        
        $mishell.linea("echo `"" + $redInvP + ".in-addr.arpa.   IN  NS     " + $nodos[0] + "." + $this.dominio + ".`"" + " >> " + $dest)
        
        for ($j = 0; $j -lt $numNodos; $j++) {
            $mishell.linea("echo `"" + ($IPNodos[$j]).PadRight(5) + "IN  PTR    " + $nodos[$j] + "-priv." + $this.dominio + ".`"" + " >> " + $dest)
        }

        $mishell.linea("chown named:named " + $dest)
        
        $mishell.linea("systemctl enable named 2>&1")
        $mishell.linea("systemctl start named 2>&1")
    }
}

class Nodo {
    [discoLINUX]$DiscoSistema
    [discoDVD]$guestAditions
    [string]$NombreVM
    [string]$NombreLinux
    [string]$Dir_IP_Nodo
    [string]$Ruta
    [string]$ctlSATA
    [string]$ctlIDE
    [int]$Memoria
    [int]$CPUs
    [int]$VRAM
    [int]$TamDSis
    [string]$rutSF
    [string]$zipGI
    [string]$zipDB

    Nodo($Nombre, $PathVM, $IP, $TamDSis, $TamRAM, $TamMemVid, `
    $numcpu, $numOrden, [discoDVD]$guestAditions) {
        $devLinux           = "/dev/sda"
        $this.ctlSATA       = "SATA"
        $this.ctlIDE        = "IDE"
        $this.Ruta          = $PathVM
        $this.DiscoSistema  = [DiscoLINUX]::new($this.Ruta + "\" + $Nombre + ".vdi", $devLinux)
        $this.NombreVM      = $Nombre
        $this.NombreLinux   = $nombre
        $this.guestAditions = $guestAditions
        $this.Dir_IP_Nodo   = $IP
        $this.Memoria       = $global:TAMMEM
        $this.CPUs          = $global:NUMCPU
        $this.VRAM          = $global:TAMVIDEO
        $this.TamDSis       = $global:TAMDISCS
        $this.rutSF         = $global:RUTSF
        $this.zipGI         = $global:ZIPGRID
        $this.zipDB         = $global:ZIPDB
    }

    CopiarSoft([string]$tipo) {
        loc ("Copiando zip de software " + $tipo)
        $mizip   = ""
        $usuario = ""
        $pass    = ""
        switch ($tipo) {
            "GI" { 
                $mizip = $this.RUTSF + "\" + $this.zipGI
                $usuario = $global:infra.seguridad.usrGrid
                $pass = $global:infra.seguridad.pasGrid
            }
            "DB" { 
                $mizip = $this.RUTSF + "\" + $this.zipDB
                $usuario = "oracle"
                $pass = $global:infra.seguridad.pasOra
             }
        }
        $null = VBoxManage guestcontrol $this.NombreVM copyto $mizip `
        --username $usuario --password $pass `
        --target-directory /tmp
        validacion $true ""
    }

    UnzipSoft([shellLinux]$shell, [string]$tipo) {
        $usuario = ""
        $mizip   = ""
        $destino = ""
        switch ($tipo) {
            "GI" { 
                $mizip = $this.zipGI
                $usuario = $global:infra.seguridad.usrGrid
                $destino = "/u01/app/19.3.0/grid"
            }
            "DB" { 
                $mizip = $this.zipDB
                $usuario = "oracle"
                $destino = "/u01/app/oracle/product/19.3.0/dbhome_1"
             }
        }
        $shell.titulo("Desempaquetando software " + $tipo)
        $shell.Linea("unzip -d " + $destino + " /tmp/" + $mizip)
        $shell.Linea("chown -R " + $usuario + ":oinstall " + $destino)
        $shell.Linea("chmod -R 775 " + $destino)
        $shell.Linea("rm -f /tmp/" + $mizip)
    }

    modifZonaH([shellLinux]$shell) {
        $shell.titulo("Estableciendo zona horaria UTC")
        $shell.linea("timedatectl set-timezone UTC 2>&1")
    }

    modifFstab([shellLinux]$shell) {
        $shell.titulo("Modificando /etc/fstab")
        $shell.linea("echo `"tmpfs  /dev/shm  tmpfs  defaults  0  0`" >> /etc/fstab")
        $shell.linea("echo `"kernel.watchdog_thresh = 60`" >> /etc/sysctl.conf") 
    }

    CrearSwap([shellLinux]$shell) {
        $shell.titulo("Creando fichero swap para igualar a la RAM del sistema")
        $shell.linea("mem=``free | grep '^Mem:' | tr -s `" `" | cut -d `" `" -f 2``")
        $shell.linea("swap=``free | grep '^Swap:' | tr -s `" `" | cut -d `" `" -f 2``")
        $shell.linea("dif=`$((`$mem - `$swap + 1024))")
        $shell.linea("if (( `$dif > 0 )); then")
        $shell.linea("    dd if=/dev/zero of=/swapfile bs=1024 count=`$dif 2>&1")
        $shell.linea("    chmod 600 /swapfile")
        $shell.linea("    mkswap /swapfile 2>&1")
        $shell.linea("    swapon /swapfile")
        $shell.linea("    echo `"/swapfile swap swap defaults 0 0`" >> /etc/fstab")
        $shell.linea("fi")
    }

    [bool]Existe() {
        $existe = $False
        $strcmp = '"' + $this.NombreVM + '"'
        foreach ($i in VBoxManage list vms) {
            if ($i.indexOf($strcmp) -gt -1) {
                $existe = $True
            }
        }
        return ($existe)
    }

    [bool]verificarApagado() {
        [bool]$retorno = $false
        [string]$tmp = VBoxManage -q showvminfo $this.NombreVM | findstr /b "State.*powered off"
        if ($tmp) {
            $retorno = $true
        }
        return $retorno
    }

    arrancarNodo() {
        loc ("Arrancando " + $this.NombreVM)
        if ($this.verificarApagado()) {
            VBoxManage startvm $this.NombreVM
        }
        #VBoxManage startvm $this.NombreVM --type headless
        Start-Sleep -Seconds 2
        loc ("Esperando inicio de Sistema en " + $this.NombreVM)
        $this.esperarNodoArrancar()
        validacion $true ""
    }

    detenerNodo() {
        loc ("Deteniendo " + $this.NombreVM)
        # $this.esperarNodoArrancar()
        if (-not $this.verificarApagado()) {
            VBoxManage -q controlvm $this.NombreVM acpipowerbutton
        }
        Start-Sleep -Seconds 2
        loc ("Esperando cierre de Sistema en " + $this.NombreVM)
        $this.esperarNodoDetener()
        validacion $true ""
    }

    crearNodo([red]$mired) {
        loc ("Creando Servidor virtual " + $this.NombreVM)
        VBoxManage createvm `
            --name $this.NombreVM `
            --register `
            --ostype oracle_64 `
            --basefolder $this.Ruta.Substring(0, $this.Ruta.LastIndexOf("\"))
        VBoxManage storagectl $this.NombreVM `
            --name $this.ctlSATA --add sata --controller IntelAHCI
        VBoxManage storagectl $this.NombreVM --name $this.ctlIDE --add ide
    
        VBoxManage storageattach $this.NombreVM `
            --storagectl "SATA" `
            --port 0 `
            --device 0 `
            --type hdd `
            --medium $this.DiscoSistema.fqdn

        VBoxManage storageattach $this.NombreVM `
            --storagectl "IDE" `
            --port 0 `
            --device 0 `
            --type dvddrive `
            --medium $this.guestAditions.fqdn
        
        $ifho = ""
        if (-not $mired.Nombre_Interfaz_HostOnly) {
            $ifho = "VirtualBox Host-Only Ethernet Adapter"
        } else {
            $ifho = $mired.Nombre_Interfaz_HostOnly
        }
    
        VBoxManage -q modifyvm $this.NombreVM `
            --memory $this.Memoria `
            --cpus $this.CPUs `
            --vram $this.VRAM `
            --graphicscontroller vmsvga `
            --ioapic on `
            --boot1 disk --boot2 dvd --boot3 none --boot4 none `
            --nic1 bridged --bridgeadapter1 $mired.Nombre_Interfaz_Bridged `
            --nic2 hostonly --hostonlyadapter2 $ifho `
            --audio none `
            --usb off --usbehci off

        validacion $true ""
    }

    instalarNodo([discoDVD]$insDVD, $usuario, $passusr, $dominio) {
        loc ("Iniciando instalacion desatendida en " + $this.nombreVM)
        VBoxManage -q unattended install $this.nombreVM `
            --iso $insDVD.fqdn `
            --user $usuario `
            --password $passusr `
            --full-user-name $usuario `
            --install-additions `
            --additions-iso $this.guestAditions.fqdn `
            --time-zone CEST `
            --hostname ($this.nombreVM + "." + $dominio) `
            --package-selection-adjustment=minimal `
            --start-vm gui
        validacion $true ""
    }

    borrarNodo() {
        loc ("Eliminando servidor " + $this.NombreVM)
        VBoxManage unregistervm $this.nombreVM -delete | Out-Null
        validacion $true ""
    }

    [bool]verificarSistema() {
        $retorno = $false
        $mitmp = VBoxManage guestproperty get $this.NombreVM "/VirtualBox/GuestInfo/OS/LoggedInUsers"
        if ($mitmp) {
            $mitmp = $mitmp.substring(0,$mitmp.indexof(" "))
            if ($mitmp.trim() -eq "Value:") {
                $retorno = $true
            }
        }
        return $retorno
    }

    esperarNodoArrancar() {
        do {
            Start-Sleep -Seconds 4
        } while (-not $this.verificarSistema())
    }

    esperarNodoDetener() {
        $tmp = ""
        do {
            [string]$tmp = VBoxManage -q showvminfo $this.NombreVM | findstr /b "State.*powered off"
            Start-Sleep -Seconds 2
        } while ($tmp.trim() -eq "") 
        Start-Sleep -Seconds 4
    }
    
    MapearDiscos([SAN]$SAN) {
        loc ("Mapeando discos compartidos en " + $this.NombreVM )
        $i = 1
        foreach ($disco in $SAN.Discos) {
            VBoxManage storageattach $this.NombreVM `
                --storagectl $this.ctlSATA `
                --port $i `
                --device 0 `
                --type hdd `
                --medium $disco.fqdn --mtype shareable
            $i++
        }
        validacion $true ""
    }
}

class GI {
    [string]$prim
    [string]$stby
    [string]$cluster
    [array]$clnodos

    GI() {
        $this.prim = $global:SID
        $this.stby = $global:STBY  
        $this.cluster = $global:cluster
        $this.clNodos = New-Object string[] $global:NUMNODOS
        for ($i = 0; $i -lt $global:NUMNODOS; $i++) {
            $this.clnodos[$i] = $global:PREFNODO + [string]($i + 1)
        }
    }

    [bool]VerificarCluster() {
        loc ("Verificando cluster")
        $retorno = $false
        $i = 0
        while (-not $retorno -and ($i -lt 8)) {
            $retorno = $this.EsperarCluster()
            if (-not $retorno) {
                Start-Sleep -seconds 5
            }
            $i++
        }
        return $retorno
    }
    
    [bool]EsperarCluster() {
        $nNodos = $this.NumNodos()
        $retorno = $true
        for ($i=1; $i -le $nNodos; $i++) {
            $recursos=(VBoxManage.exe guestcontrol ($this.clnodos[0]) run `
                      --username root `
                      --password oracle `
                      --exe /u01/app/19.3.0/grid/bin/crsctl `
                      --wait-stdout -- crsctl check cluster -n ($this.clnodos[$i - 1]))
            if (($recursos -like "*CRS-4405*") -or (-not $recursos)) {
                $retorno = $false
            }
        }
        if ($retorno) {
            $esperar = $true
            $estados = New-Object bool[] $nNodos
            do {
                for ($i = 1; $i -le $nNodos; $i++) {
                    if (-not $estados[$i - 1]) {
                        $recursos=(VBoxManage.exe guestcontrol ($this.clnodos[0]) run `
                                --username root `
                                --password ($global:infra.seguridad.pasRoot) `
                                --exe /u01/app/19.3.0/grid/bin/crsctl `
                                --wait-stdout -- crsctl check cluster -n ($this.clnodos[$i - 1]))
                        if (($recursos -like "*CRS-4537*") -and `
                            ($recursos -like "*CRS-4529*") -and `
                            ($recursos -like "*CRS-4533*")) {
                                loc ("Operativo en " + $this.clnodos[$i - 1])
                                $estados[$i - 1] = $true
                        }
                    }
                }
                if (-not ($estados -contains $false)) {
                    $esperar = $false
                } else {
                    Start-Sleep -seconds 5
                }
            } while ($esperar)
        }
        return $retorno
    }

    [bool]ExisteEnASM($miBD) {
        loc ("Verificando existencia en ASM")
        $retorno = $false
        $recursos=(VBoxManage.exe guestcontrol ($global:infra.nodos[0].NombreVM) run `
                --username root `
                --password ($global:infra.seguridad.pasRoot) `
                --exe /u01/app/19.3.0/grid/bin/asmcmd `
                --wait-stdout `
                --no-wait-stderr `
                -- asmcmd ls ("data/" + $miBD + "/"))
        if ($recursos -like ("^CONTROLFILE/")) {
            loc ("Registrada en ASM")
            $retorno = $true
        }
        else {
            loc ("No registrada en ASM")
        }
        return $retorno
    }

    [bool]ExisteEnOratab($miBD) {
        loc ("Verificando existencia en oratab")
        $retorno = $false
        $recursos=(VBoxManage.exe guestcontrol ($global:infra.nodos[0].NombreVM) run `
                --username root `
                --password ($global:infra.seguridad.pasRoot) `
                --exe /usr/bin/cat `
                --wait-stdout `
                --no-wait-stderr `
                -- cat /etc/oratab)
        if ($recursos -like ("^" + $miBD + ":/")) {
            loc ("Registrada en oratab")
            $retorno = $true
        } else {
            loc ("No registrada en oratab")
        }
        return $retorno
    }

    [bool]ValidarBD($miBD) {
        $retorno = $true
        $esperar = $true
        $nNodos = $this.NumNodos()
        loc ("Verificando Base de Datos " + $miBD)
        $estados = New-Object bool[] $nNodos
        $recursos=(VBoxManage.exe guestcontrol ($this.clnodos[0]) run `
                --username root `
                --password ($global:infra.seguridad.pasRoot) `
                --exe /u01/app/19.3.0/grid/bin/crsctl `
                --wait-stdout `
                -- crsctl status resource ("ora." + $miBD + ".db"))
        if ($recursos -like "*CRS-2613*") {
            loc ("La base de datos no existe en el cluster")
            $retorno = $false
        } 
        else {
            do {
               for ($i=1; $i -le $nNodos; $i++) {
                   if (-not $estados[$i - 1]) {
                       
                       $recursos=(VBoxManage.exe guestcontrol ($this.clnodos[0]) run `
                               --username root `
                               --password ($global:infra.seguridad.pasRoot) `
                               --exe /u01/app/19.3.0/grid/bin/crsctl `
                               --wait-stdout `
                               -- crsctl status resource ("ora." + $miBD + ".db") -n ($this.clNodos[$i - 1]))
        
                        if ($recursos -like "STATE=ONLINE") {
                            loc ("Instancia operativa en nodo" + [string]$i)
                            $estados[$i - 1] = $true
                        }
                        if ($recursos -like "STATE=INTERMEDIATE") {
                            loc ("Instancia montada en nodo" + [string]$i)
                            $estados[$i - 1] = $true
                        }
                        if ($recursos -like "*CRS-4655*") {
                            loc ("La instancia no existe en nodo" + [string]$i)
                            $retorno = $false
                            $esperar = $false
                        }
                    }
                }
        
                if ($retorno) {
                    if (-not ($estados -contains $false)) {
                        $esperar = $false
                    } else {
                        Start-Sleep -seconds 5
                    }
                }       
            } while ($esperar)
        }
    return $retorno
    }

    [int]numNodos() {
        return $this.clNodos.length
    }
}

class Infra {
    [string]$Nombre
    [string]$PathVMS
    [Red]$Red
    [SAN]$SAN
    [DiscoIMAGEN]$imagen
    [DiscoDVD]$guestAditions
    [Seguridad]$seguridad
    [GI]$GI
    [int]$tamDSis
    [int]$tamRAM
    [int]$tamVideo
    [int]$numCPU
    [string]$prefNodo
    [Nodo[]]$Nodos = [Nodo[]]::new($numNodos)

    Infra($Nombre, [Red]$Red, [SAN]$SAN, [Seguridad]$seguridad, [DiscoImagen]$imagen, `
                   [DiscoDVD]$guestAditions, [GI]$GI) {

        $this.PathVMS       = $global:RVM
        $this.Nombre        = $nombre
        $this.Red           = $Red
        $This.SAN           = $SAN
        $this.Seguridad     = $seguridad
        $this.imagen        = $imagen
        $this.guestAditions = $guestAditions
        $this.GI            = $GI
        $this.tamDSis       = $global:TAMDISCS
        $this.tamRAM        = $global:TAMMEM
        $this.tamVideo      = $global:TAMVIDEO
        $this.numCPU        = $global:NUMCPU
        $this.prefNodo      = $global:prefNodo
    
        $IPInt = [int]($global:IPBase.Substring($global:IPBase.LastIndexOf('.') + 1))
        for ($i = 0; $i -lt $global:NumNodos; $i++) {
            $nom = $this.prefNodo + [string]($i + 1)
            $IP_Nodo = [string]($IPInt + $i)
            $PathVM = $this.PathVMS + "\" + $nom
            $nodo = [nodo]::new($nom, $PathVM, $IP_Nodo, $this.tamDsis, `
                                $this.tamRAM, $this.tamVideo, $this.numCPU, $i, $guestAditions)

            $this.Nodos[$i] = $Nodo
        }
    }

    [int]numNodos() {
        return $this.nodos.length
    }

    [string]listanodos() {
        $listaNodos = ""
        foreach ($i in $this.nodos) {
            $listanodos = $listanodos + $i.nombreVM + ","
        }
        $listanodos = $listanodos.Substring(0,$listanodos.LastIndexOf(","))
        return $listanodos
    }

    [string]listaNodosExt() {
        $dominio = $this.red.dominio 
        $listanodosext = ""
        foreach ($i in $this.nodos) {
            $listanodosext = $listanodosext + $i.nombreVM + "." + $dominio + ":"
            $listanodosext = $listanodosext + $i.nombreVM + "-vip." + $dominio
            $listanodosext = $listanodosext + ","
        }
        $listanodosext = $listanodosext.Substring(0,$listanodosext.LastIndexOf(","))
        return $listanodosext
    }
}
