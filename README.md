# vbox_GI_RAC_DG
Fully automated installation of Linux, Oracle Grid, ASM, RAC and DataGuard virtualized infrastructure.

Automatización completa de infraestructuras virtualizadas de Linux, Oracle Grid, ASM, RAC y DataGuard.

## Objetivo

1. Virtualizar en un PC HOST todos los componentes necesarios que permitan la ejecución de los productos ORACLE GI (ASM + Clusterware), ORACLE RAC y ORACLE DG

2. Automatizar la instalación y configuración de todos los elementos virtuales hasta conseguir una instalación operativa

## Host de alojamiento de elementos virtuales

Todo el proceso para alojar los sistemas virtualizados se realizará desde un ordenador PC Windows 10. La capacidad en términos de procesador, memoria y espacio disponible en disco debe ser suficiente para soportar la implantación.
- Memoria: Debemos contar con memoria suficiente para la ejeción simultánea de todas las máquinas virtuales que formarán el cluster Oracle. Dado que la recomendación de Oracle para 19c es de un mínimo de 8Gb. por máquina y que debemos preservar no menos de 3 o 4 Gb para el sistema anfitrión, debemos contar con al menos 20 Gb. para la solución mínima de un sistema de dos nodos. 32 Gb. puede ser una cantidad de memoria razonable para manejar cómodamente un sistema de 3 nodos.
- Espacio en disco: Se utilizarán discos de expansión dinámica para los discos de sistema de las máquinas virtuales y discos de tamaño fijo para los discos compartidos. Podemos estimar una tasa de ocupación de no menos del 50% del tamaño de disco de sistema de cada nodo, que hará que multiplicar por el número de nodos, y a eso hay que añadir el tamaño de cada disco compartido multiplicado por el número de discos compartidos de la instalación. Por tanto en un sistema de 3 nodos con disco de sistema de 64Gb. y 8 discos compartidos de 10Gb., necesitaremos un espacio total libre de ((64 * 3) / 2) + (10 * 8) = 176Gb. libres.
- 
   Por otro lado, si bien podemos trabajar con un único disco para contener la totalidad de la solución, parece recomendable virtualizar los discos en dos discos físicos diferenciados, uno para los discos de sistema de las máquinas virtuales y otro para los discos compartidos.
   
   Además, es altamente recomandable utilizar discos de tipo SSD por su elevada velocidad de respuesta
- Procesador: Necesitaremos disponer de un procesador que nos permita asignar un mínimo de un hilo dedicado para cada máquina virtual.

Como referencia, en las pruebas se ha utilizado un equipo Windows 10 PRO 21H1 con procesador Intel i7 de 8ª GEN (4nuclos, 8 hilos), 24 Gb RAM y 3 SSD de 500Gb cada uno, distribuidos del siguiente modo:

- Disco C: Sistema operativo del host Windows y software de virtualización (interno nvme)

- Disco E. Discos de Sistema para alojar las maquinas virtuales (Interno SATA3)

- Disco G: Discos compartidos virtualizados del sistema de almacenamiento ASM (SATA3 conectado a interfaz USB 3.1) 

Para la virtualización de componentes utilizará Oracle VirtualBox, mas concretamente la versión 6.1.26

## Elementos físicos a virtualizar

Son tres lo elementos que deben virtualizarse:

-   Máquinas virtuales que ejercerán la función de servidores de bases de datos: Se debe permitir la virtualización de dos o mas servidores capaces de ejecutar los productos Oracle.

-   Almacenamiento virtual: Se debe obtener un sistema de almacenamiento virtualizado capaz de proporcionar dispositivos de bloque para el uso compartido en los servidores de bases de datos utilizando Oracle ASM.

-   Redes virtuales: Se deben proporcionar dos redes diferenciadas para las comunicaciones públicas y privadas

### Maquinas virtuales

Se utilizará el sistema operativo Oracle Linux x86_64 R7-U9.

El software Oracle GI y RAC será la versión 19c (19.3) para Oracle Linux X86_64

Contarán con una controladora virtual de discos de tipo SATA para el disco de sistema y los discos compartidos y otra de tipo IDE para mapear DVDs en formato ISO (DVD de instalación y de Guest Additions)

Contarán con DOS NIC virtuales de conexión a la red, uno para la red pública y otro para la red provada.

### Almacenamiento virtual

Se utilizarán discos generados mediante VirtualBox con los atributos “type Shareable” y “variant Fixed”. En los parámetros de configuración debe especificarse la ruta donde se ubicarán, el tamaño de los discos y el número de ellos (todos comparten los mismos parámetros)

La distribución de discos se hará de modo que la mitad se asignarán a un diskgGroup DATA y la otra mitad a un diskGroup FRA (uno más para DATA en caso de número impar de discos)

Los diskGroup se configurarán en modo de redundancia “externa” para maximizar el espacio disponible en los diskGroups


### Redes virtuales

Las dos redes a configurar en las máquinas virtuales serán:

- Interfaz en configuración “Bridged” para el NIC1 (red pública)

- Interfaz en configuración “Host-Only” para el NIC2 (red privada)

El direccionamiento IP en la red pública estará en la misma subred clase C que el propio Host Windows que contiene las máquinas virtuales. El valor se especifica en un parámetro que se detalla mas adelante (p. e. Red 192.168.1.0/24, IP nodo 81).

El direccionamiento IP de la red privada será también de clase C y lo proporcionará VirtualBox al crear la red “Host-Only”. La IP de cada máquina virtual en esta red (4º octeto), será la misma que en la red publica para la misma máquina (p. e. Red 192.168.44.0/24, Nodo 81). Esta red NO tendrá ningún tipo de enrutado externo.

Gateway de acceso a internet: Las máquinas virtuales comparten con el host Windows el Gateway de salida a Internet. Dicha salida se enruta a través del interfaz de tipo “Bridged” (NIC1) y NO se enruta desde el interfaz “Host-only” (NIC2)

Servicio DNS: Se creará un servicio DNS en la primera máquina virtual al que accederán todos los servidores virtuales. Dicho servicio DNS contará con un forward para asegurar la salida a internet desde todas las máquinas virtuales (p.e. para la actualización de los sistemas).

Servicio NTP. Se utilizará el servicio “chrony” para dar solución a los requisitos de Oracle en materia de sincronización horaria.

Dominio: Todas las máquinas virtuales formarán parte de un dominio internet parametrizable (ver parámetros de configuración de infraestructura). No es necesario que el dominio del servidor Host forme parte del dominio al que pertenecerán las máquinas virtuales.

Hostname: Se establecerá una nomenclatura para las máquinas virtuales con el siguiente formato **\<PREFNODO>\<Num_secuencial>.\<DOMINIO** (ver parámetros de configuración de infraestructura)


## Software de desarrollo

Toda la solución está construida utilizando PowerShell 5.1 nativo de Windows 10 y no se requiere ningún complemento añadido. Estructuralmente está desarrollado con un modelo de objetos reutilizables que contienen las clases, métodos y atributos necesarios para implantar la infraestructura y proporcionar todos los elementos necesarios para procesarla. También tiene un módulo de funciones para ciertas tareas y un fichero de encabezado que aglutina las tareas con las que comienza cada proceso. Estas tres piezas se ubican en una carpeta denominada “comunes”.

El modelo del proceso se repite de manera similar en todos los procesos ejecutables y básicamente consiste en:

1. Carga del fichero de definición de infraestructura

2. Verificaciones previas

3. Inicio, parada y/o configuración de los servidores VirtualBox

4. Construcción de scripts Bash desde los procesos powershell

5. Traza por pantalla de las tareas que se van realizando (y opcionalmente verbalizada mediante sintetizador de voz)

6. Copia de los scripts construidos a un directorio temporal de trabajo en Windows con denominación **milog\<nnn>.sh**

7. Trasferencia de los scripts al servidores Linux que corresponda

8. Configuración del formato y los permisos de los scripts transferidos

9. Ejecución de los scripts transferidos en los servidores Linux

10. Captura de la salida stdout y stderr que produce la ejecución en linux y almacenamiento del resultado en Windows junto con los scripts ejecutados, con denominación **milog\<nnn>.log.** La salida de los scripts puede mostrarse en una ventana mientras se ejecutan o solamente almacenarse en disco.

La relación entre el proceso PoweShell y las máquinas virtuales se establece mediante invocaciones a las funcionalidades del componente de virtualBox VBoxManage

Cada uno de los procesos ejecutará uno o varios scripts bash en las máquinas virtuales de manera secuencial hasta la finalización de todas sus tareas.

Los procesos ejecutables que se proporcionan son los siguientes:

| **Proceso**| **Objetivo**|
|---|---|
| 0_validarParam.ps1| Valida los parámetros del fichero de configuración|
| 1_crearImagen.ps1| Automatiza la instalación base Linux como modelo para las máquinas virtuales|
| 1b_ActualizarImagen.ps1| (optativo) Actualiza el software Linux del disco imagen desde los repositorios de internet para evitarcrear un disco imagen desde cero|
| 2_crearCluster.ps1| Construye la infraestructura física virtualizada: máquinas virtuales, discos compartidos y redes, e  instala piezas de software de base|
| 3_instalarGrid.ps1| Instala el software GI Oracle y construye un cluster sobre la infraestructura física virtualizada con dos diskGroups: DATA y FRA|
| 4_InstalarSoftDB.ps1| Despliega el software de base de datos en el cluster y prepara instalación de Bases de Datos RAC o Single Instance|
| 5_CrearDBRAC.ps1| Crea la base de datos RAC primaria sobre el cluster con almacenamiento ASM|
| 5b_CrearDBSI.ps1| (optativo) crea una base de datos Single Instance con almacenamiento en ASM|
| 6_CrearStandbyRAC.ps1| Crea una base de datos DG Standby sobre el cluster mediante RMAN|
| 7_CrearBroker.ps1| Crea y activa la configuración DataGuard Broker sobre las bases de datos primaria y standby|

Además se proporcionan unas utilidades de servicio:

| **Utilidad**           | **Función**                 |
|------------------------|-----------------------------|
| utl_iniciarCluster.ps1 | Inicio ordenado del cluster |
| utl_pararCluster.ps1   | Parada ordenada del cluster |


## Tareas previas a la instalación

Antes de proceder a la ejecución de los procesos de instalación automatizada hay que configurar y obtener ciertos elementos y realizar algunas acciones en el Host:

1. Autorizar la ejecución scripts. Típicamente Windows no permite la ejecución de scripts PowerShell desde línea de comandos. Se resolverá abriendo una ventana Powershell como administrador y modificando la política de ejecución mediante el comando:

   ```
   Set-ExecutionPolicy RemoteSigned
   ```

2. Configuración de Firewall. Es probable que ciertas peticiones de echo ICMP no se ejecuten correctamente entre el host y las máquinas virtuales. Para solucionarlo es necesario habilitar una regla de entrada (la regla probablemente exista pero suele estar deshabilitada). En primer lugar verificaremos si la regla existe y si está habilitada. Puede hacerse desde línea de comandos PowerShell como administrador mediante:

   ```
   Get-NetFirewallRule -name "vm-monitoring-icmpv4"
   ```

   Si la regla existe, mostrará la información detallada de su definición. Pueden dase tres situaciones:

   La regla existe y el atributo “Enabled” presenta valor “True”. En ese caso la regla ya estará activada y no hay que hacer nada mas.

   La regla existe y el atributo “Enabled” presenta valor “False”. En ese caso habrá que habilitarla desde línea de comandos PowerShell como dministrador mediante:

   ```
   Set-NetFirewallRule -name "vm-monitoring-icmpv4" -Enabled True
   ```

   La regla no existe. En ese caso debe crearse desde línea de comandos owerShell como administrador mediante:

   ```
   New-NetFirewallRule -Name "vm-monitoring-icmpv4" -DisplayName "vm-monitoring-icmpv4" -Description "Permitir ICMP4" -Profile Any -Direction Inbound -Action Allow -Protocol ICMPv4 -Program Any -LocalAddress Any -RemoteAddress Any -Enabled True
   ```

3. Identificar el nombre del dispositivo de red que permite la salida a Internet y sobre el que se construirá la red pública de la solución. Típicamente Será ethernet cableada o WiFi. Se puede localizar desde PowerShell como administrador mediante:

   ```
   ((Get-ComputerInfo).CsNetworkAdapters\|Select-Object Description, ConnectionID, ConnectionStatus \| Where-object {$\_.ConnectionStatus -eq "Connected" -and ($\_.ConnectionID -in ("Wi-Fi", "Ethernet"))}).description
   ```

   El resultado será una expresión similar a: 
   ``` Intel(R) Dual BandWireless-AC 8265```

   Debe anotarse ese nombre del dispositivo, que se utilizará EXACTAMENTE como aparece en la salida del comando en el parámetro de configuración correspondiente.

4. Descargar el fichero ISO de instalación del sistema operativo Oracle Linux 7.9 R7 U9 x86_64 de la web de Oracle <https://yum.oracle.com/ISOS/OracleLinux/OL7/u9/x86_64/OracleLinux-R7-U9-Server-x86_64-dvd.iso>

5. Descargar los componentes Oracle GI y DB 19.3 para Linux x86_64 en formato .zip desde la web de Oracle <https://www.oracle.com/es/database/technologies/oracle19c-linux-downloads.html>.
   Los ficheros a obtener son:

   -  Oracle Database 19c (19.3) for Linux x86-64 (LINUX.X64_193000_db_home.zip)

   -  Oracle Database 19c Grid Infrastructure (19.3) for Linux x86-64 (LINUX.X64_193000_grid_home.zip)

   Ambos ficheros deberán guardarse en el mismo directorio.

6. Instalar Virtualbox 6.1.X. Anotar la ruta de instalación de VirtualBox V.6.1.x (típicamente **C:\\Program Files\\Oracle\\VirtualBox**) y confirmar que dicha ruta contiene el fichero .iso de Guest Additions **VBoxGuestAdditions.iso** y la utilidad **vboxmanage.exe**

   > NOTA: Se han detectado ciertos problemas de compatibilidad entre la plataforma de virtualización Windows y la versión de VirtualBox 6.1.28. Si se utiliza dicha plataforma de virtualización, se recomienda la versión 6.1.26 (<https://download.virtualbox.org/virtualbox/6.1.26/VirtualBox-6.1.26-145957-Win.exe>)

7. Crear el fichero de definición de infraestructura. Se debe construir con los parámetros necesarios con una estructura JSON. Por defecto se llamará “params.json” y se almacenará en el mismo directorio que los programas ejecutables. Se proporciona un ejemplo junto con el software que puede ser editado con los valores que correspondan en cada instalación. Los parámetros de dicho fichero se detallan a continuación

|**Parámetro**|**Descripción**|**Valores***|
|---|---|---|
|EVB|Ruta de instalación del software Virtual Box|Debe existir y contener el software de utilidad de VirtualBox (obtenido en Tareas previas, paso 6)|
|RVM|Ruta en la que se instalarán las máquinas virtuales|Debe existir. Se remienda un SSD independiente|
|RUTTEMP|Ruta para almacenamiento de ficheros temporales|Debe existir|
|DOMINIO|Dominio internet de las máquinas virtuales|Debe ser un nombre de dominio válido para uso interno de las máquinas virtuales|
|INSDVD|Fichero iso de instalación de sistema de las máquinas virtuales|Ruta completa. Debe existir en la ruta indicada (obtenido en Tareas previas, paso 4)|
|NUMNODOS|Número de nodos a crear|Valor entero entre 2 y 6|
|TAMDISCS|Tamaño en megas de los discos de sistema de las máquinas virtuales|Tamaño en megas de los discos de sistema de las VM (min. 12280)|
|TAMMEM|Tamaño en megas de las la memoria de las máquinas virtuales|Superior a 4096. Deseable 8192|
|TAMVIDEO|Tamaño en megas de la memoria de video de las máquinas virtuales|Igual o superior a 8. No es necesario un valor a 8 puesto que los servidores NO se instalan con entorno gráfico|
|NUMCPU|Número de CPUs de cada máquina virtual|Entero &gt;= 1|
|RUTSF|Ruta que contiene el software de Oracle GI y DB|Debe existir (obtenida en le paso 5)|
|ZIPGRID|Nombre del ZIP de instalación de Oracle GI|Debe existir en la ruta indicada por RUTSF (obtenido en Tareas previas,  paso 5)|
|ZIPDB|Nombre del ZIP de instalación de Oracle DataBase|Debe existir en la ruta indicada por RUTSF (obtenido en Tareas previas,  paso 5)|
|BRIDIF|Nombre del dispositivo de red para la red pública|Debe ser un dispositivo válido en el sistema (obtenido en Tareas previas,  paso 3)|
|IPBASE|Dirección IP en red publica del primer servidor virtual (incrementada en 1 para los subsiguientes)|Debe ser una IP válida y libre en la red pública|
|DNS|Dirección IP del servidor DNS de nuestra red pública|Debe ser la IP del servidor DNS de la red pública del host Windows|
|GW|Dirección IP del GW|Debe ser la IP del router de la red pública del host Windows|
|CLUSTER|Nombre del cluster GI|Nombre válido para un cluster oracle GI|
|RUTDCOMP|Ruta donde se crearán los discos compartidos|Debe existir y preferiblemente debe tratarse de un disco SSD y preferiblemente distinto al que contenga los discos de sistema de las máquinas virtuales|
|TAMDISCC|Tamaño en Mb de los discos compartidos (todos se crearán del mismo tamaño)|Entero entre 2000 y 20000|
|NUMDISC|Número de discos compartidos que se crearán|Entero mayor de 4|
|TIPOINST|Tipo de instalación para los discos compartidos|“ASMLIB” o “UDEV”|
|USUARIO|Nombre de usuario Linux|Login válido en Linux|
|PASSUSR|Password de usuario Linux (también será el password de root)|Password válido Linux. El mismo password se asignará a root|
|PASSORA|Password del usuario Linux Oracle|Password válido Linux|
|USRGRID|Usuario Linux para grid|Usuario Linux valido. Si no se desea separación de roles grid-oracle se pondrá el valor “oracle”|
|PASSGRID|Password de usuario de grid|Password válido Linux|
|PASORASYS|Password Oracle para los usuarios de DB sys y system|Password válido en BD Oracle|
|GAISO|Ruta completa del fichero ISO de VirtualBox GuestAdditions|El fichero debe existir en la ruta indicada|
|IMGDISCO|Path completo del fichero VDI que se utilizará para crear la imagen de discopara crear los discos de sistema de las máquinas virtuales|La ruta debe existir|
|TMPNODO|Nombre de máquina virtual VirtualBox que se utilizará para modelar el disco imagen|Debe ser u nombre válido en VirtualBox y la máquina NO debe existir previamente|
|PREFNODO|Prefijo del nombre de las máquinas virtuales|Será un nombre de máquina virtual válido Virtualbox|
|CONVOZ|Parámetro que indica si la ejecución de los comandos debe verbalizar los pasos de ejecución mediante síntesis de voz|“SI” verbaliza los pasos de ejecución y los muestra en pantalla. "NO” Sólo muestra la salida por pantalla|
|VERLOG|Parámetro que indica si debe mostrarse por pantalla el log de ejecución de los scripts Bash que se ejecutan en las máquinas virtuales|“SI” Se muestran por pantalla y se guardan en fichero. “NO” Sólo se guardan en fichero|
|SID|SID de la base de datos primaria|SID Oracle válido|
|STBY|Valor del DB_UNIQUE_NAME de la BD standby|DB_UNIQUE_NAME válido|
|DBSI|(Optativo) SID de una instancia complementaria Single Instance|SID Oracle válido|
|NODOSI|(Optativo) número de orden del nodo en el que se instalará la Single instance|Número de orden de máquina virtual en la que instalar DBSI|

8. Validar el fichero de parámetros mediante la utilidad proporcionada a tal efecto. Sin pretender realizar una validación exhaustiva, proporciona una ayuda básica para identificar errores en los parámetros. Se invoca desde PowerShell como administrador en el directorio que contiene el software:

```
.\\0_validarParam.ps1 \[fichero_parámetros_json\]
```


## Ejecución de los procesos de instalación del sistema

> NOTA: Todos los procesos deben ejecutarse en secuencia y CON LOS MISMOS PARAMETROS EN EL FICHERO DE CONFIGURACION


### Crear imagen

Este proceso crea una máquina virtual VirtualBox sobre la que hace una instalación Básica del sistema operativo y a continuación genera y ejecuta dos scripts Bash secuencialmente:

-  Configuración del sistema Linux de la imagen, instalación de piezas de software y actualización del sistema operativo Linux

-  Configuración del Kernel de arranque

Y termina preservando una copia imagen del disco de sistema funcional y actualizada y eliminando el servidor temporal

Se ejecuta con la siguiente sintaxis desde el directorio que contiene el software

```
.\\1_crearImagen.ps1 \[fichero_parámetros_json\]
```

El proceso tardará aproximadamente 45 MINUTOS en la instalación de referencia.

Tras el proceso podemos verificar en el administrador de medios virtuales de virtualBox que el disco imagen se ha generado

```
dir E:\VirtualBox\imagen

    Directorio: E:\VirtualBox\imagen

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        24/10/2021     20:36     5470420992 imagen.vdi
```


### Crear Cluster

Este proceso realiza las siguientes acciones:

- Crea todas las máquinas virtuales

- Configura la red pública en la primera máquina virtual

- Configura usuarios linux (grupos de pertenencia, permisos, profiles, limits y umask)

- Crea y configura la red privada en la primera máquina virtual

- Crea los discos compartidos

- Particiona y mapea los discos compartidos en la primera máquina virtual

- Configura el método elegido para el acceso a los discos compartidos (UDEV o ASLIB) en la primera máquina virtual

- Clona el disco de la primera máquina virtual para todas las demás

- Configura el resto de las máquinas virtuales (redes y acceso a los discos compartidos)

- Crea el servicio DNS


Se Crean y ejecutan los siguientes scripts Bash:

- Configuraciones iniciales del primer nodo

- Particionado fdisk y configuración de los discos compartidos en el primer nodo (udev o asmlib)

- Configuración de redes y discos compartidos en el resto de los nodos (uno por cada nodo)

- Crea el servidor DNS


Se ejecuta con la siguiente sintaxis desde el directorio que contiene el software

```
.\\2_crearCluster.ps1 \[fichero_parámetros_json\]
```

El proceso tardará aproximadamente 15 MINUTOS en la instalación de referencia (Con dos máquinas virtuales y 8 discos compartidos de 10Gb. Por unidad)

Tras el proceso podemos hacer una serie de verificaciones. Se inicarán los DOS servidores vituales y sesión root en ambos. Desde ahí se puede verificar:

Almacenamiento compartido, que tendrá un aspecto similar a

```
ls -l /dev/oracleasm/disks
lrwxrwxrwx. 1 root root 10 Oct 25 22:01 DISK1 -> ../../sdb1
lrwxrwxrwx. 1 root root 10 Oct 25 22:02 DISK2 -> ../../sdc1
lrwxrwxrwx. 1 root root 10 Oct 25 22:02 DISK3 -> ../../sdd1
lrwxrwxrwx. 1 root root 10 Oct 25 22:02 DISK4 -> ../../sde1
lrwxrwxrwx. 1 root root 10 Oct 25 22:01 DISK5 -> ../../sdf1
lrwxrwxrwx. 1 root root 10 Oct 25 22:01 DISK6 -> ../../sdg1
lrwxrwxrwx. 1 root root 10 Oct 25 21:49 DISK7 -> ../../sdh1
lrwxrwxrwx. 1 root root 10 Oct 25 21:56 DISK8 -> ../../sdi1
```

```
ls -l /dev/sd[b-z]1
brw-rw----. 1 grid asmadmin 8,  17 Oct 25 22:41 /dev/sdb1
brw-rw----. 1 grid asmadmin 8,  33 Oct 25 22:41 /dev/sdc1
brw-rw----. 1 grid asmadmin 8,  49 Oct 25 22:41 /dev/sdd1
brw-rw----. 1 grid asmadmin 8,  65 Oct 25 22:41 /dev/sde1
brw-rw----. 1 grid asmadmin 8,  81 Oct 25 22:41 /dev/sdf1
brw-rw----. 1 grid asmadmin 8,  97 Oct 25 22:39 /dev/sdg1
brw-rw----. 1 grid asmadmin 8, 113 Oct 25 22:39 /dev/sdh1
brw-rw----. 1 grid asmadmin 8, 129 Oct 25 22:41 /dev/sdi1
```

Memoria y swap

```
free
              total        used        free      shared  buff/cache   available
Mem:        8009160     3627644      207700     3411124     4173816      756100
Swap:       8010180      210944     7799236
```

Configuración de red

```
ifconfig enp0s3 | grep "inet "
inet 192.168.1.81  netmask 255.255.255.0  broadcast 192.168.1.255
```

```
ifconfig enp0s8 | grep "inet "
inet 192.168.185.81  netmask 255.255.255.0  broadcast 192.168.185.255
```


Resolución de nombres y conexiones
```
nslookup nodo1
Server:         192.168.1.81
Address:        192.168.1.81#53

Name:   nodo1.example.com
Address: 192.168.1.81
```

```
nslookup nodo1-vip
Server:         192.168.1.81
Address:        192.168.1.81#53

Name:   nodo1-vip.example.com
Address: 192.168.1.83
```

```
nslookup nodo1-priv
Server:         192.168.1.81
Address:        192.168.1.81#53

Name:   nodo1-priv.example.com
Address: 192.168.185.81
```

```
nslookup cluster01-scan
Server:         192.168.1.81
Address:        192.168.1.81#53

Name:   cluster01-scan.example.com
Address: 192.168.1.87
Name:   cluster01-scan.example.com
Address: 192.168.1.86
Name:   cluster01-scan.example.com
Address: 192.168.1.85
```

```
nslookup www.google.com
Server:         192.168.1.81
Address:        192.168.1.81#53

Non-authoritative answer:
Name:   www.google.com
Address: 142.250.200.132
Name:   www.google.com
Address: 2a00:1450:4003:80f::2004
```

```
ping -c 2 nodo1
PING nodo1.example.com (192.168.1.81) 56(84) bytes of data.
64 bytes from nodo1.example.com (192.168.1.81): icmp_seq=1 ttl=64 time=0.011 ms
64 bytes from nodo1.example.com (192.168.1.81): icmp_seq=2 ttl=64 time=0.021 ms
```

``` 
ping -c 2 nodo1-vip
64 bytes from nodo1-vip.example.com (192.168.1.83): icmp_seq=1 ttl=64 time=0.012 ms
64 bytes from nodo1-vip.example.com (192.168.1.83): icmp_seq=2 ttl=64 time=0.025 ms
```

```
ping -c 2 nodo1-priv
PING nodo1-priv.example.com (192.168.185.81) 56(84) bytes of data.
64 bytes from nodo1-priv.example.com (192.168.185.81): icmp_seq=1 ttl=64 time=0.012 ms
64 bytes from nodo1-priv.example.com (192.168.185.81): icmp_seq=2 ttl=64 time=0.015 ms
```

```
ping -c www.google.com
PING www.google.com (172.217.168.164) 56(84) bytes of data.
64 bytes from mad07s10-in-f4.1e100.net (172.217.168.164): icmp_seq=1 ttl=117 time=6.88 ms
64 bytes from mad07s10-in-f4.1e100.net (172.217.168.164): icmp_seq=2 ttl=117 time=6.54 ms
```


### Instalar Grid

Este proceso realiza las siguientes acciones:

- Crea claves RSA para root y configura la conexión de usuario root en modo passwordless desde el primer nodo hacia todos los demás

- Crea claves RSA para usuario de grid y configura la conexión de usuario de grid en modo passwordless entre todos los nodos

- Copia el zip de Oracle grid al directorio /tmp del primer nodo

- Desempaqueta el zip de Oracle grid en el ORACLE_HOME de grid (/u01/app/19.3.0/grid) del primer nodo

- Elimina el zip de /tmp

- Instala CVUQDISK en todos los nodos

- Crea un fichero de respuestas adaptado a la configuración

- Instala grid con el fichero de respuestas

- Ejecuta orainstRoot.sh en todos los nodos

- Ejecuta root.sh en todos los nodos

- Añade un groupDisk FRA


Se crean y ejecutan los siguientes scripts Bash:

- Configuración passwordless root

- Configuración passwordless grid

- Desempaquetado de zip grid

- Instalación CVUQDISK en todos los nodos (un único script que actúa contra todos los nodos mediante scp y ssh)

- Generación de fichero de respuestas e instalación de grid mediante gridSetup en modo silent

- Ejecucion de orainstRoot.sh en todos los nodos (un único script que actúa contra todos los nodos mediante scp y ssh)

- Ejecución de root.sh en todos los nodos (uno por cada nodo, ejecutados de manera secuencial)

- Generación del diskGroup FRA mediante asmca en modo silent

Se ejecuta con la siguiente sintaxis desde el directorio que contiene el software

```
.\\3_instalarGrid.ps1 \[fichero_parámetros_json\]
```

El proceso tardará aproximadamente 55 MINUTOS en la instalación de referencia

Tras el proceso podemos hacer una serie de verificaciones. Por ejemplo desde una sesion con el usario de grid abierta en el primer nodo, se puede verificar el estado del cluster:

```
. oraenv
ORACLE_SID = [grid] ? +ASM1
The Oracle base has been set to /u01/app/grid

crsctl check cluster -all
**************************************************************
nodo1:
CRS-4537: Cluster Ready Services is online
CRS-4529: Cluster Synchronization Services is online
CRS-4533: Event Manager is online
**************************************************************
nodo2:
CRS-4537: Cluster Ready Services is online
CRS-4529: Cluster Synchronization Services is online
CRS-4533: Event Manager is online
**************************************************************
```

O podemos ver la totalidad de recursos del cluster:

```
. oraenv
ORACLE_SID = [grid] ? +ASM1
The Oracle base has been set to /u01/app/grid

crsctl stat res -t
--------------------------------------------------------------------------------
Name           Target  State        Server                   State details
--------------------------------------------------------------------------------
Local Resources
--------------------------------------------------------------------------------
ora.LISTENER.lsnr
               ONLINE  ONLINE       nodo1                    STABLE
               ONLINE  ONLINE       nodo2                    STABLE
ora.chad
               ONLINE  ONLINE       nodo1                    STABLE
               ONLINE  ONLINE       nodo2                    STABLE
ora.net1.network
               ONLINE  ONLINE       nodo1                    STABLE
               ONLINE  ONLINE       nodo2                    STABLE
ora.ons
               ONLINE  ONLINE       nodo1                    STABLE
               ONLINE  ONLINE       nodo2                    STABLE
ora.proxy_advm
               OFFLINE OFFLINE      nodo1                    STABLE
               OFFLINE OFFLINE      nodo2                    STABLE
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.ASMNET1LSNR_ASM.lsnr(ora.asmgroup)
      1        ONLINE  ONLINE       nodo1                    STABLE
      2        ONLINE  ONLINE       nodo2                    STABLE
      3        ONLINE  OFFLINE                               STABLE
ora.DATA.dg(ora.asmgroup)
      1        ONLINE  ONLINE       nodo1                    STABLE
      2        ONLINE  ONLINE       nodo2                    STABLE
      3        OFFLINE OFFLINE                               STABLE
ora.FRA.dg(ora.asmgroup)
      1        ONLINE  ONLINE       nodo1                    STABLE
      2        ONLINE  ONLINE       nodo2                    STABLE
      3        OFFLINE OFFLINE                               STABLE
ora.LISTENER_SCAN1.lsnr
      1        ONLINE  ONLINE       nodo2                    STABLE
ora.LISTENER_SCAN2.lsnr
      1        ONLINE  ONLINE       nodo1                    STABLE
ora.LISTENER_SCAN3.lsnr
      1        ONLINE  ONLINE       nodo1                    STABLE
ora.asm(ora.asmgroup)
      1        ONLINE  ONLINE       nodo1                    Started,STABLE
      2        ONLINE  ONLINE       nodo2                    Started,STABLE
      3        OFFLINE OFFLINE                               STABLE
ora.asmnet1.asmnetwork(ora.asmgroup)
      1        ONLINE  ONLINE       nodo1                    STABLE
      2        ONLINE  ONLINE       nodo2                    STABLE
      3        OFFLINE OFFLINE                               STABLE
ora.cvu
      1        ONLINE  ONLINE       nodo1                    STABLE
ora.nodo1.vip
      1        ONLINE  ONLINE       nodo1                    STABLE
ora.nodo2.vip
      1        ONLINE  ONLINE       nodo2                    STABLE
ora.qosmserver
      1        ONLINE  ONLINE       nodo1                    STABLE
ora.scan1.vip
      1        ONLINE  ONLINE       nodo2                    STABLE
ora.scan2.vip
      1        ONLINE  ONLINE       nodo1                    STABLE
ora.scan3.vip
      1        ONLINE  ONLINE       nodo1                    STABLE
--------------------------------------------------------------------------------
```


### Instalar Software de base de datos Oracle

Este proceso realiza las siguientes acciones:

- Crea claves RSA para usuario de grid y configura la conexión de usuario de oracle en modo passwordless entre todos los nodos (sólo en el caso de que los usuarios de grid y de oracle DB sean diferentes)

- Copia el zip de Oracle DB al directorio /tmp del primer nodo

- Desempaqueta el zip de Oracle DB en el ORACLE_HOME de oracle (/u01/app/oracle/product/19.3.0/dbhome_1) del primer nodo

- Elimina el zip de /tmp

- Crea un fichero de respuestas adaptado a la configuración 

- Instala el sofware de base de datos oracle con el fichero de respuestas

- Ejecuta root.sh en todos los nodos


Se crean y ejecutan los siguientes scripts Bash:

- Configuración passwordless oracle (sólo en el caso de que los usuarios de grid y de oracle DB sean diferentes)

- Desempaquetado de zip Oracle

- Generación de fichero de respuestas

- Instalación de db oracle mediante runInstaller en modo silent

- Ejecución de root.sh en todos los nodos (uno por cada nodo, ejecutados de manera secuencial)

- Generación del diskGroup FRA mediante asmca en modo silent

Se ejecuta con la siguiente sintaxis desde el directorio que contiene el software

```
.\\4_InstalarSoftDB.ps1 \[fichero_parámetros_json\]
```

El proceso tardará aproximadamente 30 MINUTOS en la instalación de referencia

Tras el proceso podemos verificar que se ha desplegado el sofware oracle en el HOME de todos los nodos iniciando sesión con usuario oracle. En el siguiente ejemplo se ha iniciado sesión en el primer nodo y desde ahí se cuentan los objetos contenidos en HOME para ambos nodos (el número de objetos puede variar ligeramente, pero en todos los casos debe ser superior a los 40.000) 

```
find /u01/app/oracle/product/19.3.0/dbhome_1 | wc -l
42081

ssh nodo2 'find /u01/app/oracle/product/19.3.0/dbhome_1 | wc -l'
41977
```


### Crear base de datos RAC

Este proceso realiza las siguientes acciones:

- Crea un fichero de respuestas adaptado a la configuración 

- Instala una base de datos RAC con el fichero de respuestas

- Configura /etc/oratab en todos los nodos


Se crean y ejecutan los siguientes scripts Bash:

- Generación de fichero de respuestas, instalación de db oracle mediante dbca en modo silent y configuración de /etc/oratab (todo en un único script)


Se ejecuta con la siguiente sintaxis desde el directorio que contiene el software

```
.\\5_CrearDBRAC.ps1 \[fichero_parámetros_json\]
```

El proceso tardará aproximadamente 30 MINUTOS en la instalación de referencia

Tras el proceso podemos verificar que se ha creado la base de datos y que está operativa:

```
. oraenv
ORACLE_SID = [oracle] ? primaria
The Oracle base has been set to /u01/app/oracle

srvctl status database -db primaria -v
Instance primaria1 is running on node nodo1. Instance status: Open.
Instance primaria2 is running on node nodo2. Instance status: Open
```

y por supuesto se podrá acceder a la base de datos:
```
sqlplus sys@primaria as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Oct 26 11:33:38 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Enter password:

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> select name, open_mode, database_role from v$database
  2  ;

NAME      OPEN_MODE            DATABASE_ROLE
--------- -------------------- ----------------
PRIMARIA  READ WRITE           PRIMARY

SQL> col name format a20
SQL> col value format a20
SQL> select name, value from v$parameter where name = 'cluster_database'
  2  ;

NAME                 VALUE
-------------------- --------------------
cluster_database     TRUE
```

### Crear Base de datos DataGuard Standby

Este proceso realiza las siguientes acciones:

- Crea una entrada temporal en el servicio listener del nodo 1

- Configura la base de datos primaria en modo archivelog

- Crea standby log files en la base de datos primaria

- Configura los parámetros de replicación de logs en la base de datos primaria (log_archive_config, log_archive_dest_1, log_archive_dest_2, standby_file_management, fal_server, db_file_name_convert y log_file_name_convert)

- Crea directorios necesarios para la base de datos standby en todos los nodos

- Crea e inicia la instancia auxiliar en modo nomount en nodo 1

- Duplica la base de datos mediante RMAN mediante "duplicate target database for standby from active database"

- Crea pfile y spfile de la base de datos standby

- Crea recursos de cluster (base de datos e instancias) para la base de datos standby

- Replica fichero de password de base de datos primaria en la base de datos standby

- Crea entradas TNS en todos los nodos para la base de datos standby

- Elimina entrada temporal de listener en nodo 1

- Configura flashback en ambas bases de datos


Se crean y ejecutan los siguientes scripts Bash:

- Generación de entrada listener y reinicio del servicio en nodo 1

- Proceso completo de replicación RMAN y clusterización de la base de datos standby

- Copia del fichero de password de primaria a standby

- Generación de entradas TNS en todos los nodos (un único script para todos los nodos)

- Eliminación de listener temporal y reinicio del servicio en nodo 1

- Configuración de flashback en ambas bases de datos


Se ejecuta con la siguiente sintaxis desde el directorio que contiene el software

```
.\\6_CrearStandbyRAC.ps1 \[fichero_parámetros_json\]
```

El proceso tardará aproximadamente 20 MINUTOS en la instalación de referencia

Tras el proceso podemos verificar que se ha creado la base de datos y que está operativa en estado MOUNT:

```
. oraenv
ORACLE_SID = [oracle] ? primaria
The Oracle base has been set to /u01/app/oracle

srvctl status database -db espera -v
Instance espera1 is running on node nodo1. Instance status: Mounted (Closed).
Instance espera2 is running on node nodo2. Instance status: Mounted (Closed).
```

y por supuesto se podrá acceder a la base de datos:

```
sqlplus sys@espera as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Oct 26 11:59:49 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Enter password:

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> select name, open_mode, database_role from v$database;

NAME      OPEN_MODE            DATABASE_ROLE
--------- -------------------- ----------------
PRIMARIA  MOUNTED              PHYSICAL STANDBY
```

Se puede verificar el estado de replicación
```
connect sys@primaria as sysdba
Enter password:
Connected.
SQL> select thread#, max(sequence#) "ult_generado" from v$archived_log val, v$database vdb where val.resetlogs_change# = vdb.resetlogs_change# group by thread# order by 1;

   THREAD# ult_generado
---------- ------------
         1           16
         2           13

SQL> connect sys@espera as sysdba
Enter password:
Connected.

SQL> select thread#, max(sequence#) "ult_recibido" from v$archived_log val, v$database vdb where val.resetlogs_change# = vdb.resetlogs_change# group by thread# order by 1;

   THREAD# ult_recibido
---------- ------------
         1           16
         2           13

SQL>  select thread#, max(sequence#) "ult_aplicado" from v$archived_log val, v$database vdb where val.resetlogs_change# = vdb.resetlogs_change# and val.applied in ('YES','IN-MEMORY') group by thread# order by 1;

   THREAD# ult_aplicado
---------- ------------
         1           16
         2           13
```

Tambien podemos dar un repaso a la tabla de estado de dataguard:
```
SQL> set lin 999
SQL> set pages 999
SQL> col message format a100
SQL> col facility format a30
SQL> connect sys@primaria as sysdba
Enter password:
Connected.
SQL> SELECT inst_id, timestamp, facility, message FROM gv$dataguard_status ORDER by timestamp;

   INST_ID TIMESTAMP FACILITY                       MESSAGE
---------- --------- ------------------------------ ------------------------------------------------------------------------------------------
         1 26-OCT-21 Log Transport Services         Redo network throttle feature is disabled at mount time
         1 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES
         1 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES COMPLETE
         1 26-OCT-21 Log Transport Services         ARC0: Archival started
         1 26-OCT-21 Log Transport Services         ARC1: Archival started
         1 26-OCT-21 Log Transport Services         ARC2: Archival started
         1 26-OCT-21 Log Transport Services         Becoming a 'no FAL' ARCH
         1 26-OCT-21 Log Transport Services         Becoming the 'no SRL' ARCH
         1 26-OCT-21 Log Transport Services         Gap Manager starting
         1 26-OCT-21 Log Transport Services         ARC3: Archival started
         1 26-OCT-21 Log Transport Services         Beginning to archive T-1.S-16 (SCN:0x000000000022c342-SCN:0x0000000000244ab8)
         1 26-OCT-21 Log Transport Services         Completed archiving T-1.S-16 (SCN:0x000000000022c342-SCN:0x0000000000244ab8)
         1 26-OCT-21 Log Transport Services         SRL selected for T-1.S-16 for LAD:2
         1 26-OCT-21 Log Transport Services         Beginning to archive LNO:1 T-1.S-17
         1 26-OCT-21 Log Transport Services         SRL selected for T-1.S-17 for LAD:2
         2 26-OCT-21 Log Transport Services         Redo network throttle feature is disabled at mount time
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES
         2 26-OCT-21 Log Transport Services         ARC0: Archival started
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES COMPLETE
         2 26-OCT-21 Log Transport Services         Becoming a 'no FAL' ARCH
         2 26-OCT-21 Log Transport Services         Becoming the 'no SRL' ARCH
         2 26-OCT-21 Log Transport Services         Completed archiving T-2.S-13 (SCN:0x0000000000244fbc-SCN:0x0000000000244fc3)
         2 26-OCT-21 Log Transport Services         Beginning to archive T-2.S-13 (SCN:0x0000000000244fbc-SCN:0x0000000000244fc3)
         2 26-OCT-21 Log Transport Services         Gap Manager starting
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES
         2 26-OCT-21 Log Transport Services         SRL selected for T-2.S-14 for LAD:2
         2 26-OCT-21 Log Transport Services         Beginning to archive LNO:4 T-2.S-14
         2 26-OCT-21 Log Transport Services         ARC3: Archival started
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES COMPLETE
         2 26-OCT-21 Log Transport Services         ARC1: Archival started
         2 26-OCT-21 Log Transport Services         ARC2: Archival started
         2 26-OCT-21 Log Transport Services         SRL selected for T-2.S-13 for LAD:2

32 rows selected.
SQL> connect sys@espera as sysdba
Enter password:
Connected.
SQL> SELECT inst_id, timestamp, facility, message FROM gv$dataguard_status ORDER by timestamp;

   INST_ID TIMESTAMP FACILITY                       MESSAGE
---------- --------- ------------------------------ ------------------------------------------------------------------------------------------
         1 26-OCT-21 Log Transport Services         Redo network throttle feature is disabled at mount time
         1 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES
         1 26-OCT-21 Log Transport Services         ARC0: Archival started
         1 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES COMPLETE
         1 26-OCT-21 Log Transport Services         Becoming a 'no FAL' ARCH
         1 26-OCT-21 Log Transport Services         Becoming the Active Gap Manager
         1 26-OCT-21 Log Transport Services         Gap Manager starting
         1 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES
         1 26-OCT-21 Log Transport Services         ARC2: Archival started
         1 26-OCT-21 Log Transport Services         ARC3: Archival started
         1 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES COMPLETE
         1 26-OCT-21 Log Transport Services         ARC1: Archival started
         1 26-OCT-21 Remote File Server             Selected LNO:7 for T-1.S-16 dbid 102313836 branch 1086893359
         1 26-OCT-21 Remote File Server             Primary database is in MAXIMUM PERFORMANCE mode
         1 26-OCT-21 Remote File Server             Selected LNO:7 for T-1.S-17 dbid 102313836 branch 1086893359
         1 26-OCT-21 Log Transport Services         Completed archiving T-1.S-16 (SCN:0x0000000000000000-SCN:0x0000000000000000)
         1 26-OCT-21 Log Transport Services         Beginning to archive T-1.S-16 (SCN:0x000000000022c342-SCN:0x0000000000244ab8)
         1 26-OCT-21 Log Apply Services             Attempt to start background Managed Standby Recovery process
         1 26-OCT-21 Log Apply Services             Background Managed Standby Recovery process started
         1 26-OCT-21 Log Apply Services             Managed Standby Recovery starting Real Time Apply
         1 26-OCT-21 Log Apply Services             Media Recovery Log +FRA/ESPERA/ARCHIVELOG/2021_10_25/thread_1_seq_15.324.1086909431
         1 26-OCT-21 Log Apply Services             Media Recovery Log +FRA/ESPERA/ARCHIVELOG/2021_10_26/thread_1_seq_16.328.1086950035
         1 26-OCT-21 Log Apply Services             Media Recovery Waiting for T-1.S-17 (in transit)
         1 26-OCT-21 Log Apply Services             Media Recovery Waiting for T-2.S-13
         1 26-OCT-21 Remote File Server             Primary database is in MAXIMUM PERFORMANCE mode
         1 26-OCT-21 Remote File Server             Selected LNO:10 for T-2.S-14 dbid 102313836 branch 1086893359
         1 26-OCT-21 Remote File Server             Selected LNO:11 for T-2.S-13 dbid 102313836 branch 1086893359
         1 26-OCT-21 Log Transport Services         Beginning to archive T-2.S-13 (SCN:0x0000000000244fbc-SCN:0x0000000000244fc3)
         1 26-OCT-21 Log Apply Services             Media Recovery Log +FRA/ESPERA/ARCHIVELOG/2021_10_26/thread_2_seq_13.330.1086950197
         1 26-OCT-21 Log Transport Services         Completed archiving T-2.S-13 (SCN:0x0000000000000000-SCN:0x0000000000000000)
         1 26-OCT-21 Log Apply Services             Media Recovery Waiting for T-2.S-14 (in transit)
         2 26-OCT-21 Log Transport Services         Redo network throttle feature is disabled at mount time
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES COMPLETE
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES
         2 26-OCT-21 Log Transport Services         ARC0: Archival started
         2 26-OCT-21 Log Transport Services         Becoming a 'no FAL' ARCH
         2 26-OCT-21 Log Transport Services         Gap Manager starting
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES
         2 26-OCT-21 Log Transport Services         ARC2: Archival started
         2 26-OCT-21 Log Transport Services         STARTING ARCH PROCESSES COMPLETE
         2 26-OCT-21 Log Transport Services         ARC1: Archival started
         2 26-OCT-21 Log Transport Services         ARC3: Archival started

42 rows selected.
```


### Configurar DataGuard Broker

Este proceso realiza las siguientes acciones:

- Configura los parámetros necesarios en la base de datos primaria (log_archive_dest_2, dg_broker_start, dg_broker_config_file1, dg_broker_config_file2)

- Configura los parámetros necesarios en la base de datos standby (log_archive_dest_2, dg_broker_start, dg_broker_config_file1, dg_broker_config_file2)

- Crea una nueva configuración Broker a partir de la base de datos primaria

- Establece propiedad RedoRoutes de primaria a standby en modo ASYNC

- Establece propiedad RedoRoutes de standby a primaria en modo ASYNC

- Establece propiedades de Timeout (CommunicationTimeout y OperationTimeout)

- Habilita la nueva configuración 


Se crean y ejecutan los siguientes scripts Bash:

- Todo el proceso se realiza con un único script


Se ejecuta con la siguiente sintaxis desde el directorio que contiene el software

```
.\\7_CrearBroker.ps1 \[fichero_parámetros_json\]
```

El proceso tardará aproximadamente 4 MINUTOS en la instalación de referencia

Tras el proceso podemos verificar la situación de DataGuard a través de broker:

```
dgmgrl
DGMGRL for Linux: Release 19.0.0.0.0 - Production on Tue Oct 26 15:10:03 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

Welcome to DGMGRL, type "help" for information.
DGMGRL> connect sys@primaria
Password:
Connected to "primaria"
Connected as SYSDBA.
DGMGRL> show configuration

Configuration - configuracion

  Protection Mode: MaxPerformance
  Members:
  primaria - Primary database
    espera   - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 70 seconds ago)

DGMGRL> show database primaria

Database - primaria

  Role:               PRIMARY
  Intended State:     TRANSPORT-ON
  Instance(s):
    primaria1
    primaria2

Database Status:
SUCCESS

DGMGRL> show database espera

Database - espera

  Role:               PHYSICAL STANDBY
  Intended State:     APPLY-ON
  Transport Lag:      0 seconds (computed 1 second ago)
  Apply Lag:          0 seconds (computed 0 seconds ago)
  Average Apply Rate: 4.00 KByte/s
  Real Time Query:    OFF
  Instance(s):
    espera1 (apply instance)
    espera2

Database Status:
SUCCESS
```

Validamos la base de datos primaria:

```
DGMGRL> validate database primaria

  Database Role:    Primary database

  Ready for Switchover:  Yes

  Managed by Clusterware:
    primaria:  YES
```

Y de manera detallada la base de datos standby

```
DGMGRL> validate database verbose espera

  Database Role:     Physical standby database
  Primary Database:  primaria

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Flashback Database Status:
    primaria:  On
    espera  :  On

  Capacity Information:
    Database  Instances        Threads
    primaria  2                2
    espera    2                2

  Managed by Clusterware:
    primaria:  YES
    espera  :  YES

  Temporary Tablespace File Information:
    primaria TEMP Files:  1
    espera TEMP Files:    1

  Data file Online Move in Progress:
    primaria:  No
    espera:    No

  Standby Apply-Related Information:
    Apply State:      Running
    Apply Lag:        0 seconds (computed 0 seconds ago)
    Apply Delay:      0 minutes

  Transport-Related Information:
    Transport On:  Yes
    Gap Status:    No Gap
    Transport Lag:  0 seconds (computed 0 seconds ago)
    Transport Status:  Success

  Log Files Cleared:
    primaria Standby Redo Log Files:  Cleared
    espera Online Redo Log Files:     Cleared
    espera Standby Redo Log Files:    Available

  Current Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status
              (primaria)              (espera)
    1         2                       3                       Sufficient SRLs
    2         2                       3                       Sufficient SRLs

  Future Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status
              (espera)                (primaria)
    1         2                       3                       Sufficient SRLs
    2         2                       3                       Sufficient SRLs

  Current Configuration Log File Sizes:
    Thread #   Smallest Online Redo      Smallest Standby Redo
               Log File Size             Log File Size
               (primaria)                (espera)
    1          200 MBytes                200 MBytes
    2          200 MBytes                200 MBytes

  Future Configuration Log File Sizes:
    Thread #   Smallest Online Redo      Smallest Standby Redo
               Log File Size             Log File Size
               (espera)                  (primaria)
    1          200 MBytes                200 MBytes
    2          200 MBytes                200 MBytes

  Apply-Related Property Settings:
    Property                        primaria Value           espera Value
    DelayMins                       0                        0
    ApplyParallel                   AUTO                     AUTO
    ApplyInstances                  0                        0

  Transport-Related Property Settings:
    Property                        primaria Value           espera Value
    LogShipping                     ON                       ON
    LogXptMode                      ASYNC                    ASYNC
    Dependency                      <empty>                  <empty>
    DelayMins                       0                        0
    Binding                         optional                 optional
    MaxFailure                      0                        0
    ReopenSecs                      300                      300
    NetTimeout                      30                       30
    RedoCompression                 DISABLE                  DISABLE
```

Podemos ejecutar un switchover

```
DGMGRL> switchover to espera
Performing switchover NOW, please wait...
Operation requires a connection to database "espera"
Connecting ...
Connected to "espera"
Connected as SYSDBA.
New primary database "espera" is opening...
Oracle Clusterware is restarting database "primaria" ...
Connected to "primaria"
Connected to "primaria"
Switchover succeeded, new primary is "espera"

DGMGRL> show configuration

Configuration - configuracion

  Protection Mode: MaxPerformance
  Members:
  espera   - Primary database
    primaria - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 20 seconds ago)

DGMGRL>
```
