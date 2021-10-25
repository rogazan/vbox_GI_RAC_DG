. .\comunes\iniEntorno.ps1

$discoGA = [DiscoDVD]::new($GAISO)
$nodotmp = [nodo]::new($tmpNodo, $RVM + "\" + $tmpNodo, $IPBase, $infra.tamDSis, `
                    2048, 16, 1, 1, $discoGA)

loc ("Comprobando que NO existe el servidor temporal")
if ($nodotmp.existe()) {
    validacion $false "El servidor temporal ya existe, saliendo"
}
validacion $true ""

loc ("Comprobando que NO existe el disco imagen")
if ($infra.imagen.existe()) {
    validacion $false "El disco imagen ya existe, saliendo"
}
validacion $true ""

$null = $nodotmp.discoSistema.CrearDiscoVacio($tmpNodo, $nodotmp.TamDSis)
Start-Sleep 4
$null = $nodotmp.crearNodo($infra.red)
$discoInst = [DiscoDVD]::new($insDVD)
$null = $nodotmp.instalarNodo($discoInst, $infra.seguridad.ususis, $infra.seguridad.pasRoot, $infra.red.Dominio)

loc ("Procesando la instalacion desatendida")
loc ("Se trata de un proceso largo que se desarrolla de manera desatendida en el servidor virtual")
loc ("El proceso de instalación seguirá trabajando en segundo plano aunque no muestre ningún signo de actividad.")
loc ("Ignore la petición de login y no interfiera hasta que se indique el fin del proceso.")

$nodotmp.esperarNodoArrancar()
validacion $true ""

$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$mishell.dos2unix($nodotmp.NombreVM)
$infra.red.CambioNomHost($mishell, $nodotmp.nombreVM)
$mishell.titulo("Configurando teclado")
$mishell.linea("localectl set-keymap es")
$mishell.titulo("Deshabilitando NetworkManager")
$mishell.linea("systemctl disable NetworkManager 2>&1")
$mishell.linea("systemctl stop NetworkManager 2>&1")
$mishell.titulo("Deshabilitando Firewall")
$mishell.linea("systemctl disable firewalld 2>&1")
$mishell.linea("systemctl stop firewalld 2>&1")
$mishell.titulo("Configurando chrony")
$mishell.linea("sed -i '/^server /d' /etc/chrony.conf")
$mishell.linea("echo `"server 0.jp.pool.ntp.org iburst`" >> /etc/chrony.conf")
$mishell.linea("echo `"server 1.jp.pool.ntp.org iburst`" >> /etc/chrony.conf")
$mishell.linea("echo `"server 2.jp.pool.ntp.org iburst`" >> /etc/chrony.conf")
$mishell.linea("echo `"allow 192.168.0.0/16`" >> /etc/chrony.conf")
$mishell.linea("systemctl enable chronyd 2>&1")
$mishell.linea("systemctl restart chronyd 2>&1")
$mishell.instalarSoftware("deltarpm")
$mishell.instalarSoftware("expect")
$mishell.instalarSoftware("oracle-database-preinstall-19c")
$mishell.instalarSoftware("oracleasm-support")
$mishell.instalarSoftware("gcc-c++")
$mishell.instalarSoftware("bind")
$mishell.instalarSoftware("rlwrap")
$mishell.instalarSoftware("nscd")
$mishell.linea("systemctl start nscd 2>&1")
$mishell.linea("systemctl enable nscd 2>&1")
$mishell.actualizarSoftware()
$mishell.EjecutarSh($nodotmp.NombreVM, "Ejecutando configuración LINUX en servidor temporal")
$nodotmp.detenerNodo()

$nodotmp.arrancarNodo()
$mishell = [shellLinux]::new("mish.sh", "root", $infra.seguridad.pasRoot, $RutTemp, "/tmp")
$mishell.titulo("Estableciendo kernel de arranque")
$mishell.linea("sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub")
$mishell.linea("awk -F\' '`$1==`"menuentry `" {print `$2}' /etc/grub2.cfg | grep ' with Linux' > /tmp/kernels")
$mishell.linea("mikernel=`$(head -n 1 '/tmp/kernels')")
$mishell.linea("grub2-set-default `"`$mikernel`"")
$mishell.linea("grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1")
$mishell.linea("rm -f /tmp/kernels")
$mishell.EjecutarSh($nodotmp.NombreVM, "Estableciendo kernel de arranque")
$nodotmp.detenerNodo()

$null = $nodotmp.discoSistema.CrearImagen($infra.imagen, $nodotmp.NombreVM)
$null = $nodotmp.borrarNodo()

loc "Fin del proceso"

$evento.finGestor()
