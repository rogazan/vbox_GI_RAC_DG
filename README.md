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
