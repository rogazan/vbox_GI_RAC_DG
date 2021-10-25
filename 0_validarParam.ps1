$ErrorActionPreference = "SilentlyContinue"

. .\comunes\clases.ps1
. .\comunes\funciones.ps1

leer_parametros $args[0]
GestorDeEventos

$valid = $true
$misistema = Get-ComputerInfo
Add-Type -AssemblyName System.Net

# EVB
if ($EVB) {
    if ( -not (Test-path -path ($EVB + "\vboxmanage.exe") -PathType leaf)) {
        loc ("El parámetro 'EVB' no apunta a un subdirectorio con las utilidades de VirtualBox")
        loc ("La rutra indicada debe existir y contener la utilidad de gestión 'VBOXMANAGE.EXE'")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'EVB' no está definido.")
    $valid = $false
}

#RVM
if ($RVM) {
    if ( -not (Test-path -path $RVM -PathType container)) {
        loc ("El parámetro 'RVM' no apunta a una ruta valida")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'RVM' no está definido.")
    $valid = $false
}

#DOMINIO
if ($DOMINIO) {
    if (-not ($DOMINIO -match "^((?!-))(xn--)?[a-z0-9][a-z0-9-_]{0,61}[a-z0-9]{0,1}\.(xn--)?([a-z0-9\-]{1,61}|[a-z0-9-]{1,30}\.[a-z]{2,})$")) {
        loc ("El parámetro 'DOMINIO' tiene formato no válido o longitud incorrecta")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'DOMINIO' no está definido.")
    $valid = $false
}

#USUARIO
if ($USUARIO) {
    if ( -not ($USUARIO -match ("^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$"))) {
        loc ("El parámetro 'USUARIO' tiene formato no válido o longitud incorrecta")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'USUARIO' no está definido.")
    $valid = $false
}

#USRGRID
if ($USUARIO) {
    if ( -not ($USRGRID -match ("^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$"))) {
        loc ("El parámetro 'USRGRID' tiene formato no válido o longitud incorrecta")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'USRGRID' no está definido.")
    $valid = $false
}

#TMPNODO
if ($TMPNODO) {
    if ( -not ($TMPNODO -match ("(^[a-z])([a-z0-9_-]{3,7})$"))) {
        loc ("El parámetro 'TMPNODO' tiene formato no válido o longitud incorrecta (entre 4 y 8 caracteres)")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'TMPNODO' no está definido.")
    $valid = $false
}

#PREFNODO
if ($PREFNODO) {
    if ( -not ($PREFNODO -match ("(^[a-z])([a-z0-9_-]{3,6})$"))) {
        loc ("El parámetro 'PREFNODO' tiene formato no válido o longitud incorrecta (entre 4 y 7 caracteres")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'PREFNODO' no está definido.")
    $valid = $false
}

#PASSORA
if ($PASSORA) {
    if ( -not ($PASSORA -match ("^((?=.*[a-z])|(?=.*[A-Z])|(?=.*[0-9])|(?=.*[_!@#\$%\^&\*]))(?=.{6,})"))) {
        loc ("El parámetro 'PASSORA' tiene formato no válido o longitud incorrecta")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'PASSORA' no está definido.")
    $valid = $false
}

#PASSGRID
if ($PASSGRID) {
    if ( -not ($PASSGRID -match ("^((?=.*[a-z])|(?=.*[A-Z])|(?=.*[0-9])|(?=.*[_!@#\$%\^&\*]))(?=.{6,})"))) {
        loc ("El parámetro 'PASSGRID' tiene formato no válido o longitud incorrecta")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'PASSGRID' no está definido.")
    $valid = $false
}

#PASORASYS
if ($PASORASYS) {
    if ( -not ($PASORASYS -match ("^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[_!@#\$%\^&\*])(?=.{8,})"))) {
        loc ("El parámetro 'PASORASYS' tiene formato no válido o longitud incorrecta")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'PASORASYS' no está definido.")
    $valid = $false
}

#SID
if ($SID) {
    if ( -not ($SID -match ("^([a-z])([a-z0-9]{3,7})([a-z])$"))) {
        loc ("El parámetro 'SID' tiene formato no válido o longitud incorrecta")
        loc ("(Entre 4 y 8 caracteres alfanuméricos sin comenzar ni finalizar con un digito)")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'SID' no está definido.")
    $valid = $false
}

#STBY
if ($STBY) {
    if ( -not ($STBY -match ("^([a-z0-9]{3,7})([a-z])$"))) {
        loc ("El parámetro 'STBY' tiene formato no válido o longitud incorrecta")
        loc ("(Entre 4 y 8 caracteres alfanuméricos sin comenzar ni finalizar con un digito)")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'STBY' no está definido.")
    $valid = $false
}

#DBSI
if ($STBY) {
    if ( -not ($DBSI -match ("^([a-z0-9]{3,7})([a-z])$"))) {
        loc ("El parámetro 'DBSI' tiene formato no válido o longitud incorrecta")
        loc ("(Entre 4 y 8 caracteres alfanuméricos sin comenzar ni finalizar con un digito)")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'DBSI' no está definido.")
    $valid = $false
}

if (($SID -eq $STBY) -or `
    ($SID -eq $DBSI) -or `
    ($STBY -eq $DBSI)) {
        loc ("Los parámetros 'DBSI', 'STBY' y 'DBSI' deben ser diferentes")
        $valid = $false
    }

#INSDVD
if ($INSDVD) {
    if ( -not (Test-path -path $INSDVD -PathType leaf)) {
        loc ("El fichero ISO indicado en el parámetro 'INSDVD' no existe")
        $valid = $false
    } else {
        if (-not ((Get-Item $INSDVD).extension -eq ".iso")) {
            loc ("El fichero indicado en el parámetro 'INSDVD' debe ser un .ISO")    
            $valid = $false
        }
    }
}
else {
    loc ("El parámetro 'INSDVD' no está definido.")
    $valid = $false
}

#TAMDISCS
if ($TAMDISCS) {
    if ($TAMDISCS -lt 12288){
        loc ("El parámetro 'TAMDISCS' debe ser mayor o igual que 4096")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'TAMDISCS' no está definido.")
    $valid = $false
}

#NUMDISC
if ($NUMDISC) {
    if ($NUMDISC -lt 4){
        loc ("El parámetro 'NUMDISC' debe ser mayor o igual que 4")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'NUMDISC' no está definido.")
    $valid = $false
}

#TAMMEM
if ($TAMMEM) {
    if (($NUMNODOS) -and ($NUMNODOS -gt 0)) {
        $memNodo = ([int](($misistema.OsTotalVisibleMemorySize / 1024)) - 3072) / $NUMNODOS
        if (($TAMMEM -gt $memNodo) -or ($TAMMEM -lt 4096)) {
            loc ("El parámetro 'TAMMEM' tiene que estar entre 4096 y " + [int]$memNodo)
            $valid = $false
        }
    }
    else {
        loc ("El parámetro 'TAMMEN' depende del parámetro 'NUMNODOS', que no está definido correctamente.")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'TAMMEM' no está definido.")
    $valid = $false
}

#TAMVIDEO
if ($TAMVIDEO) {
    if (($TAMVIDEO -lt 8) -or ($TAMVIDEO -gt 128)) {
        loc ("El parámetro 'TAMVIDEO' tiene que estar entre 8 y 128")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'TAMVIDEO' no está definido.")
    $valid = $false
}

#IPBASE
if ($IPBASE) {
    if (-not ($IPBASE -as [IPAddress])) {
        loc ("El parámetro 'IPBASE' no es una direccion IP bien formada")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'IPBASE' no está definido.")
    $valid = $false
}
if (($NUMNODOS) -and ($NUMNODOS -gt 0)) {
    if ((([int]($IPBASE.split("."))[3]) + ($NUMNODOS * 2) + 3) -gt 254) {
        loc ("El último octeto del parámetro 'IPBASE' no puede ser superior a " + [string](254 - ($NUMNODOS * 2) - 3))
        $valid = $false
    }
}
else {
    loc ("El parámetro 'IPBASE' depende del parámetro 'NUMNODOS', que no está definido correctamente.")
    $valid = $false
}

#DNS
if ($DNS) {
    if (-not ($DNS -as [IPAddress])) {
        loc ("El parámetro 'DNS' no es una direccion IP bien formada")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'DNS' no está definido.")
    $valid = $false
}

#GW
if ($GW) {
    if (-not ($GW -as [IPAddress])) {
        loc ("El parámetro 'GW' no es una direccion IP bien formada")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'GW' no está definido.")
    $valid = $false
}

#NUMCPU
if ($NUMCPU) {
    if (($NUMNODOS) -and ($NUMNODOS -gt 0)) {
        $maxCPU = [int][math]::floor(($misistema.CsNumberOfLogicalProcessors - 2) / $NUMNODOS)
        if ($NUMCPU -gt $maxCPU) {
            loc ("El parámetro 'NUMCPU' no puede ser mayor que " + [string]$maxcpu)
            $valid = $false
        }
    }
    else {
        loc ("El parámetro 'NUMCPU' depende del parámetro 'NUMNODOS', que no está definido correctamente.")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'NUMCPU' no está definido.")
    $valid = $false
}

#RUTSF
if ($RUTSF) {
    if ( -not (Test-path -path $RUTSF -PathType container)) {
        loc ("el parámetro 'RUTSF' no es una ruta válida o no existe")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'RUTSF' no está definido.")
    $valid = $false
}

#ZIPGRID
if ($ZIPGRID) {
    if ( -not (Test-path -path ($RUTSF + "\" + $ZIPGRID) -PathType leaf)) {
        loc ("El fichero indicado por el parámetro 'ZIPGRID' no existe")
        $valid = $false
    } else {
        if (-not ((Get-Item ($RUTSF + "\" + $ZIPGRID)).extension -eq ".zip")) {
            loc ("El fichero indicado en el parámetro 'ZIPGRID' debe ser un .zip")    
            $valid = $false
        }
    }
}
else {
    loc ("El parámetro 'ZIPGRID' no está definido.")
    $valid = $false
}

#ZIPDB
if ($ZIPDB) {
    if ( -not (Test-path -path ($RUTSF + "\" + $ZIPDB) -PathType leaf)) {
        loc ("El fichero indicado por el parámetro 'ZIPDB' no existe")
        $valid = $false
    } else {
        if (-not ((Get-Item ($RUTSF + "\" + $ZIPDB)).extension -eq ".zip")) {
            loc ("El fichero indicado en el parámetro 'ZIPDB' debe ser un .zip")    
            $valid = $false
        }
    }
}
else {
    loc ("El parámetro 'ZIPDB' no está definido.")
    $valid = $false
}

#GAISO
if ($GAISO) {
    if ( -not (Test-path -path $GAISO -PathType leaf)) {
        loc ("El fichero ISO indicado en el parámetro 'GAISO' no existe")
        $valid = $false
    } else {
        if (-not ((Get-Item $GAISO).extension -eq ".iso")) {
            loc ("El fichero indicado en el parámetro 'GAISO' debe ser un .ISO")    
            $valid = $false
        }
    }
}
else {
    loc ("El parámetro 'GAISO' no está definido.")
    $valid = $false
}

#TIPOINST
if ($TIPOINST) {
    if (($TIPOINST -ne "UDEV") -and ($TIPOINST -ne "ASMLIB")) {
        loc ("El parámetro 'TIPOINST' solo admite valores 'UDEV' o 'ASMLIB'")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'TIPOINST' no está definido.")
    $valid = $false
}

#NUMNODOS
if ($NUMNODOS) {
    if (($NUMNODOS -lt 2) -or ($NUMNODOS -gt 6)) {
        loc ("El parámetro 'NUMNODOS' debe estar comprendido entre 2 y 6")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'NUMNODOS' no está definido.")
    $valid = $false
}

#RUTDCOMP
if ($RUTDCOMP) {
    if ( -not (Test-path -path $RUTDCOMP -PathType container)) {
        loc ("El parámetro 'RUTDCOMP' no es una ruta válida o no existe")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'RUTDCOMP' no está definido.")
    $valid = $false
}

#TAMDISCC
if ($TAMDISCC) {
    if (($TAMDISCC -lt 2000) -or ($TAMDISCC -gt 20000)) {
        loc ("El parámetro 'TAMDISCC' debe estar entre 2000 y 20000")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'TAMDISCC' no está definido.")
    $valid = $false
}

#BRIDIF
if ($BRIDIF) {
    $conexiones=[array]($misistema.CsNetworkAdapters | `
        Select-Object Description, ConnectionID, ConnectionStatus | `
        Where-object {($_.ConnectionStatus -eq "Connected") -and `
                     (($_.ConnectionID -eq "Wi-Fi") -or `
                      ($_.ConnectionID -eq "Ethernet"))}).description
    if(-not ($conexiones -contains $BRIDIF)) {
        loc ("El parámetro 'BRIDIF' no es un dispositivo válido")
        $valid = $false
        if ($conexiones) {
            loc ("Debe seleccionar uno de los siguientes:")
            foreach ($conexion in $conexiones){
                loc ($conexion)
            }
        } else {
            loc ("No hay dispistivos válidos conectados a la red")
            $valid = $false
        }
    }
}
else {
    loc ("El parámetro 'BRIDIF' no está definido.")
    $valid = $false
}

#IMGDISCO
if ($IMGDISCO) {
    if (-not (Test-path -path ((Get-Item $IMGDISCO).directoryName) -PathType container)) {
        loc ("El parámetro 'IMGDISCO' no apunta a una ruta valida")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'IMGDISCO' no está definido.")
    $valid = $false
}

#NODOSI
if ($NODOSI) {
    if (($NUMNODOS) -and ($NUMNODOS -gt 0)) {
        if (-not (($NODOSI -gt 0) -and ($NODOSI -le $NUMNODOS))) {
            loc ("El parámetro 'NODOSI' debe estar entre 1 y " + $NUMNODOS)
            $valid = $false
        }
    }
    else {
        loc ("El parámetro 'NODOSI' depende del parámetro 'NUMNODOS', que no está correctamente definido.")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'NODOSI' no está definido.")
    $valid = $false
}

#CONVOZ
if ($CONVOZ) {
    if (($CONVOZ -ne "SI") -and ($CONVOZ -ne "NO")) {
        loc("El parámetro 'CONVOZ' solo admite valores 'SI' y 'NO'")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'CONVOZ' no está definido.")
    $valid = $false
}

#VERLOG
if ($VERLOG) {
    if (($VERLOG -ne "SI") -and ($VERLOG -ne "NO")) {
        loc("El parámetro 'VERLOG' solo admite valores 'SI' y 'NO'")
        $valid = $false
    }
}
else {
    loc ("El parámetro 'VERLOG' no está definido.")
    $valid = $false
}

#ESPACIO LIBRE
if ($valid) {
    $libreVM = [int](((($RVM | get-item).psdrive) | select-object).free / 1024 / 1024)
    $unidadVM = [string]((($RVM | get-item).psdrive) | select-object).root
    $reqVM = ($TAMDISCS * $NUMNODOS) / 2
    $libreDC = [int](((($RUTDCOMP | get-item).psdrive) | select-object).free / 1024 / 1024)
    $unidadDC = [string]((($RUTDCOMP | get-item).psdrive) | select-object).root
    $reqDC = $TAMDISCC * $NUMDISC

    if ($unidadVM -ne $unidadDC) {
        if ($reqVM -gt $libreVM) {
            loc ("La unidad " + $unidadVM + " no tiene espacio suficiente para:")
            loc ([string]$NUMNODOS + " discos de sistema de " + [string]$TAMDISCS + " Mb")  
            $valid = $false
        }
        if ($reqDC -gt $libreDC) {
            loc ("La unidad " + $unidadDC + " no tiene espacio suficiente para:")
            loc ([string]$NUMDISC + " discos compartidos de " + [string]$TAMDISCC + " Mb")
            $valid = $false
        }
    } else {
        if (($reqVM + $reqDC) -gt $libreVM) {
            loc ("La unidad " + $unidadVM + " no tiene espacio suficiente para:")
            loc ([string]$NUMNODOS + " discos de sistema de " + [string]$TAMDISCS + " Mb")
            loc ([string]$NUMDISC + " discos compartidos de " + [string]$TAMDISCC + " Mb")
            $valid = $false
        }
    }
}

if (-not $valid) {
    loc "Resolver los errores indicados antes de ejecutar los procesos"
} else {
    loc ("Todos los parámetros parecen correctos")
}