#!/bin/bash

BASE="/usr/share/asistente-actualizacion2/"
PASO_FILE="/usr/share/asistente-actualizacion2/paso.conf"
DIFERENCIA="/usr/share/asistente-actualizacion2/actualizar"
PREDESCARGAR="/usr/share/asistente-actualizacion2/predescargar"

UNO="/usr/share/asistente-actualizacion2/uno"
DOS="/usr/share/asistente-actualizacion2/dos"
PROGRESO="/usr/share/asistente-actualizacion2/progreso"
MSJPROGRESO="/usr/share/asistente-actualizacion2/msjprogreso"

. ${PASO_FILE}
echo "uno"
# Determina el Disco Duro al cual instalar y actualizar el burg
PARTS=$( /sbin/fdisk -l | awk '/^\/dev\// {if ($2 == "*") {if ($6 == "83") { print $1 };}}' | sed 's/+//g' )
DISCO=${parts:0:8}
RESULT=$( echo ${DISCO} | sed -e 's/\//\\\//g' )
sed -i "s/\/dev\/xxx/${RESULT}/g" ${DEBCONF_SEL}

# Organiza los paquetes diferentes entre 2.1 oficial y el del usuario
DIFF21=$( cat ${DIFERENCIA} | awk 'BEGIN {OFS = "\n"; ORS = " " }; {print $1}' )

echo "dos"
while [ ${PASO} -lt 60 ]
do

# Verificar si existe un gestor de paquetes
[ $( ps -A | grep -cw update-manager ) == 1 ] || [ $( ps -A | grep -cw apt-get ) == 1 ] || [ $( ps -A | grep -cw aptitude ) == 1 ] &&  zenity --title="Asistente de Actualización a Canaima 3.0" --text="¡Existe un gestor de paquetes trabajando! No podemos continuar." --error --width=600 && exit 1 && pkill actualizador

echo $PASO
. ${PASO_FILE}

case ${PASO} in

1)
# Ventana de bienvenida
zenity --title="Asistente de Actualización a Canaima 3.0" --text="Este asistente se encargará de hacer los cambios necesarios\npara actualizar el sistema a la versión 3.0 de Canaima.\n\nSe realizará la actualizacion de gran cantidad de paquetes\nLas aplicaciones que ud haya instalado en 2.X que requieran\nconfiguración durante la instalacion ameritaran de su intervención para ser configuradas, \nel resto de la actualización se realizará de forma transparente.\n\n\nSe recomienda conectar el equipo a una fuente de alimentación continua, al finalizar la actualizacion el sistema se reiniciará automaticamente, no apague el equipo hasta haber recibido el mensaje de \"Actualizacion Completada\".\nSe descargarán aprox: 1200MB.\n\n¿Desea continuar con la actualización?" --question --width=600
[ $? == 1 ] && exit 1
echo "Inicializando el Asistente" > ${UNO}
echo "Ejecutando procesos iniciales ..." > ${DOS}
echo "1" > ${PROGRESO}
echo "--" > ${MSJPROGRESO}
echo 'PASO=2' > ${PASO_FILE}
;;

2)

actualizador
echo "Descargando paquetes" >> ${UNO}
echo "Se descargarán una serie de paquetes necesarios para la actualización del sistema (1.5G aprox.)" >> ${DOS}

# Aseguramos que tenemos los repositorios correctos
cat <<EOF >/etc/apt/sources.list
deb http://mirror/debian/ squeeze main contrib non-free
EOF

aptitude update | tee /var/log/salida && sleep 2

# Predescarga de todos los paquetes requeridos para la instalación
echo ${DIFF21} >> ${PREDESCARGAR}

for paquete in $( cat ${PREDESCARGAR} ); do
$contador=$[$contador+1]
aptitude download $paquete
echo "scale=6;$contador/1440*40" | bc > ${PROGRESO}
echo "Descargando: $paquete" > ${MSJPROGRESO}
done

mkdir /usr/share/asistente-actualizacion2/predescargados/
mv *.deb /usr/share/asistente-actualizacion2/predescargados/

# ------- PREPARANDO CANAIMA 2.1 ------------------------------------------------------------------#
#==================================================================================================#

debconf-set-selections ${DEBCONF_SEL}

# Aseguramos que tenemos los repositorios correctos
cat <<EOF >/etc/apt/sources.list
#
# Repositorios de Canaima GNU/Linux
#

# Repositorio Antiguo
deb http://mirror/canaima3/repositorio/ aponwao usuarios

# Repositorio Estable
#deb http://mirror/canaima3/repositorio/ roraima usuarios

# Repositorio de Desarrollo
#deb http://mirror/canaima3/repositorio/ auyantepui usuarios

# Repositorio de la Base (Debian)
deb http://mirror/debian/ lenny main contrib non-free

EOF
echo "PASO=3" > ${PASO_FILE}
;;

3)
# Actualizamos la lista de paquetes
echo "Ejecutando rutina de actualizacion" >> ${UNO}
echo "Actualizando lista de paquetes ..." >> ${DOS}
echo "41" > ${PROGRESO}
echo "" > ${MSJPROGRESO}

aptitude update | tee /var/log/salida && sleep 2
echo "PASO=4" > ${PASO_FILE}
;;

4)
# Removemos paquetes huérfanos
echo "Removiendo paquetes huerfanos..." >> ${DOS}
echo "42" >> ${PROGRESO}
apt-get autoclean | tee /var/log/salida && sleep 2
echo "PASO=5" > ${PASO_FILE}
;;

5)
# Actualizamos Canaima 2.1
echo "Actualizacion de Canaima 2.1..." >> ${DOS}
echo "43" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" full-upgrade | tee /var/log/salida && sleep 2
echo "PASO=6" > ${PASO_FILE}
;;

6)
# Instalamos otro proveedor de gnome-www-browser
echo "Instacion de otro proveedor de gnome-www-browser" >> ${DOS}
echo "44" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" galeon | tee /var/log/salida && sleep 2
echo "PASO=7" > ${PASO_FILE}
;;

7)
# Removemos la configuración vieja del GRUB
echo "Eliminando configuracion anterior del GRUB" >> ${DOS}
echo "45" > ${PROGRESO}
rm /etc/default/grub && sleep 2
echo "PASO=8" > ${PASO_FILE}
;;

8)
# Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0
echo "Limpiando Canaima 2.1 de aplicaciones no utilizadas en 3.0" >> ${DOS}
echo "46" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get purge --force-yes -y openoffice* firefox* thunderbird* canaima-accesibilidad canaima-instalador-vivo canaima-particionador | tee /var/log/salida && sleep 2
echo "PASO=9" > ${PASO_FILE}
;;

9) 
# Limpiando paquetes huérfanos
echo "Limpiando paquetes huérfanos" >> ${DOS}
echo "47" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get autoremove --force-yes -y | tee /var/log/salida && sleep 2
echo "PASO=10" > ${PASO_FILE}
;;

10) 
# ------- ACTUALIZANDO COMPONENTES DE INSTALACIÓN DE LA BASE (DEBIAN SQUEEZE) ---------------------#
#==================================================================================================#
echo "Actualizando componentes de la instalacion de la base (squeeze)" >> ${DOS}
echo "48" > ${PROGRESO}
# Estableciendo repositorios sólo para el sistema base
cat <<EOF >/etc/apt/sources.list
deb http://mirror/debian/ squeeze main contrib non-free

EOF

# Estableciendo prioridades superiores para paquetes provenientes de Debian
cat <<EOF >/etc/apt/preferences
Package: *
Pin: release o=Debian
Pin-Priority: 800

EOF

echo "PASO=11" > ${PASO_FILE}
;;

11) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" >> ${DOS}
echo "49" > ${PROGRESO}
aptitude update | tee /var/log/salida && sleep 2
echo "PASO=12" > ${PASO_FILE}
;;

12) 
# Removemos paquetes huérfanos
echo "Removemos paquetes huérfanos" >> ${DOS}
echo "50" > ${PROGRESO}
apt-get autoclean | tee /var/log/salida && sleep 2
echo "PASO=13" > ${PASO_FILE}
;;

13) 
# Actualizando componentes fundamentales de instalación
echo "Actualizando componentes fundamentales de instalación" >> ${DOS}
echo "51" > ${PROGRESO}
cp /usr/share/asistente-actualizacion2/predescargados/*.deb /var/cache/apt/archives/
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" aptitude apt dpkg debian-keyring locales --without-recommends | tee /var/log/salida && sleep 2 
echo "PASO=14" > ${PASO_FILE}
;;

14) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" >> ${DOS}
echo "52" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes -f install | tee /var/log/salida && sleep 2
echo "PASO=15" > ${PASO_FILE}
;;

15) 
# Instalando nuevo Kernel y librerías Perl
echo "Instalando nuevo Kernel y librerías Perl" >> ${DOS}
echo "53" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" linux-image-2.6.32-5-686 perl libperl5.10 | tee /var/log/salida && sleep 2
echo "PASO=16" > ${PASO_FILE}
;;

16) 
# Estableciendo repositorios sólo para el sistema base
echo "Estableciendo repositorios sólo para el sistema base" >> ${DOS}
echo "54" > ${PROGRESO}
debconf-set-selections ${DEBCONF_SEL}
cat <<EOF >/etc/apt/sources.list
deb http://mirror/debian/ squeeze main contrib non-free

EOF

# Estableciendo prioridades superiores para paquetes provenientes de Debian
echo "Estableciendo prioridades superiores para paquetes provenientes de Debian" >> ${DOS}
echo "55" > ${PROGRESO}
cat <<EOF >/etc/apt/preferences
Package: *
Pin: release o=Debian
Pin-Priority: 800

EOF

echo "PASO=17" > ${PASO_FILE}
;;

17) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" >> ${DOS}
echo "56" > ${PROGRESO}
aptitude update | tee /var/log/salida && sleep 2
echo "PASO=18" > ${PASO_FILE}
;;

18) 
# Removemos paquetes huérfanos
echo "Removemos paquetes huérfanos" >> ${DOS}
echo "57" > ${PROGRESO}
apt-get autoclean | tee /var/log/salida && sleep 2
echo "PASO=19" > ${PASO_FILE}
;;

19) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" >> ${DOS}
cp /usr/share/asistente-actualizacion2/predescargados/*.deb /var/cache/apt/archives/
echo "58" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes -f install | tee /var/log/salida && sleep 2
echo "PASO=20" > ${PASO_FILE}
;;

20) 
# Actualizando gestor de dispositivos UDEV
echo "Actualizando gestor de dispositivos UDEV" >> ${DOS}
echo "59" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" udev | tee /var/log/salida && sleep 2
echo "PASO=21" > ${PASO_FILE}
;;

21) 
# Estableciendo repositorios sólo para el sistema base
echo "Estableciendo repositorios sólo para el sistema base" >> ${DOS}
echo "60" > ${PROGRESO}
debconf-set-selections ${DEBCONF_SEL}
cat <<EOF >/etc/apt/sources.list
deb http://mirror/debian/ squeeze main contrib non-free
EOF
echo "PASO=22" > ${PASO_FILE}
;;

22) 
# Estableciendo prioridades superiores para paquetes provenientes de Debian
echo "Estableciendo prioridades superiores para paquetes provenientes de Debian" >> ${DOS}
echo "61" > ${PROGRESO}
cat <<EOF >/etc/apt/preferences
Package: *
Pin: release o=Debian
Pin-Priority: 800
EOF
echo "PASO=23" > ${PASO_FILE}
;;

23) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" >> ${DOS}
echo "62" > ${PROGRESO}
aptitude update | tee /var/log/salida && sleep 2
echo "PASO=24" > ${PASO_FILE}
;;

24) 
# Removemos paquetes huérfanos
echo "Removemos paquetes huérfanos" >> ${DOS}
echo "63" > ${PROGRESO}
apt-get autoclean | tee /var/log/salida && sleep 2
cp /usr/share/asistente-actualizacion2/predescargados/*.deb /var/cache/apt/archives/
echo "PASO=25" > ${PASO_FILE}
;;

25) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" >> ${DOS}
echo "64" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes -f install | tee /var/log/salida && sleep 2
echo "PASO=26" > ${PASO_FILE}
;;

26) 
# Actualizando gconf2
echo "Actualizando gconf2" >> ${DOS}
echo "65" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" install gconf2=2.28.1-6 libgconf2-4=2.28.1-6 gconf2-common=2.28.1-6 | tee /var/log/salida && sleep 2
echo "PASO=27" > ${PASO_FILE}
;;

27) 
# Actualización de componentes adicionales instalados por el usuario (no incluidos en canaima 2.1)
echo "Actualización de componentes adicionales instalados por el usuario" >> ${DOS}
echo "66" > ${PROGRESO}

xterm -e "aptitude --assume-yes --allow-untrusted install $todos"

echo "PASO=28" > ${PASO_FILE}
;;

28) 
# Actualización parcial de la base
echo "Actualización parcial de la base" >> ${DOS}
echo "67" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get --force-yes -y upgrade | tee /var/log/salida && sleep 2
echo "PASO=29" > ${PASO_FILE}
;;

29) 
# Actualización total de la base
echo "Actualización total de la base" >> ${DOS}
echo "68" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get --force-yes -y dist-upgrade | tee /var/log/salida && sleep 2
echo "PASO=30" > ${PASO_FILE}
;;

30) 
# Actualización completa de la base
echo "Actualización completa de la base" >> ${DOS}
echo "69" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" full-upgrade | tee /var/log/salida && sleep 2
echo "PASO=31" > ${PASO_FILE}
;;

31) 
# Estableciendo repositorios sólo para el sistema base
echo "Estableciendo repositorios sólo para el sistema base" >> ${DOS}
echo "70" > ${PROGRESO}
debconf-set-selections ${DEBCONF_SEL}
cat <<EOF >/etc/apt/sources.list
deb http://mirror/canaima3/repositorio/ roraima usuarios
deb http://mirror/debian/ squeeze main contrib non-free
EOF
echo "PASO=32" > ${PASO_FILE}
;;

32) 
# Estableciendo prioridades superiores para paquetes provenientes de Debian
echo "Estableciendo prioridades superiores para paquetes provenientes de Debian" >> ${DOS}
echo "71" > ${PROGRESO}
cat <<EOF >/etc/apt/preferences
Package: *
Pin: release o=Canaima
Pin-Priority: 900

Package: *
Pin: release o=Debian
Pin-Priority: 800
EOF
echo "PASO=33" > ${PASO_FILE}
;;

33) 
# Actualizamos la lista de paquetes
echo "Actualizamos la lista de paquetes" >> ${DOS}
echo "72" > ${PROGRESO}
aptitude update | tee /var/log/salida && sleep 2
echo "PASO=34" > ${PASO_FILE}
;;

34) 
# Removemos paquetes huérfanos
echo "Removemos paquetes huérfanos" >> ${DOS}
echo "73" > ${PROGRESO}
apt-get autoclean | tee /var/log/salida && sleep 2
echo "PASO=36" > ${PASO_FILE}
;;

36) 
# Arreglando paquetes en mal estado
echo "Arreglando paquetes en mal estado" >> ${DOS}
echo "74" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes -f install | tee /var/log/salida && sleep 2
echo "PASO=37" > ${PASO_FILE}
;;

37) 
# Instalando llaves del repositorio Canaima
echo "Instalando llaves del repositorio Canaima" >> ${DOS}
echo "75" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" canaima-llaves | tee /var/log/salida && sleep 2
echo "PASO=38" > ${PASO_FILE}
;;

38) 
# Removiendo paquetes innecesarios
echo "Removiendo paquetes innecesarios" >> ${DOS}
echo "76" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" epiphany-browser epiphany-browser-data libgraphviz4 libslab0 gtkhtml3.14 busybox-syslogd dsyslog inetutils-syslogd rsyslog socklog-run sysklogd syslog-ng libfam0c102 | tee /var/log/salida && sleep 2
echo "PASO=39" > ${PASO_FILE}
;;

39) 
# Removemos configuraciones obsoletas
echo "Removemos configuraciones obsoletas" >> ${DOS}
echo "77" > ${PROGRESO}
rm -rf /etc/skel/.purple/ 
rm /etc/canaima_version 
rm /usr/share/applications/openoffice.org-*
echo "PASO=40" > ${PASO_FILE}
;;

40) 
# Instalando escritorio de Canaima 3.0
echo "Instalando escritorio de Canaima 3.0" >> ${DOS}
echo "78" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" canaima-escritorio-gnome | tee /var/log/salida && sleep 2
echo "PASO=41" > ${PASO_FILE}
;;

41) 
# Removiendo Navegador web de transición
echo "Removiendo Navegador web de transición" >> ${DOS}
echo "79" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" galeon | tee /var/log/salida && sleep 2
echo "PASO=42" > ${PASO_FILE}
;;

42) 
# Actualización final a Canaima 3.0
echo "Actualización final a Canaima 3.0" >> ${DOS}
echo "80" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" full-upgrade | tee /var/log/salida && sleep 2
echo "PASO=43" > ${PASO_FILE}
;;

43) 
# Removiendo paquetes innecesarios
echo "Removiendo paquetes innecesarios" >> ${DOS}
echo "81" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude purge --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" gstreamer0.10-gnomevfs splashy | tee /var/log/salida && sleep 2
echo "PASO=44" > ${PASO_FILE}
;;

44) 
# Actualizando a GDM3
echo "Actualizando a GDM3" >> ${DOS}
echo "82" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" gdm3 | tee /var/log/salida && sleep 2
echo "PASO=46" > ${PASO_FILE}
;;

46) 
# Actualizando a BURG
echo "Actualizando a BURG" >> ${DOS}
echo "83" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude install --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" burg | tee /var/log/salida && sleep 2
echo "PASO=47" > ${PASO_FILE}
;;

47) 
# Reinstalando Base de Canaima
echo "Reinstalando Base de Canaima" >> ${DOS}
echo "84" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" canaima-base | tee /var/log/salida && sleep 2
echo "PASO=48" > ${PASO_FILE}
;;

48) 
# Reinstalando Estilo Visual
echo "Finalizando rutina de actualización" >> ${UNO}
echo "Reinstalando Estilo Visual" >> ${DOS}
echo "85" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" canaima-estilo-visual | tee /var/log/salida && sleep 2
echo "PASO=49" > ${PASO_FILE}
;;

49) 
# Reinstalando Escritorio
echo "Reinstalando Escritorio" >> ${DOS}
echo "86" > ${PROGRESO}
DEBIAN_FRONTEND=noninteractive aptitude reinstall --assume-yes --allow-untrusted -o DPkg::Options::="--force-confmiss" canaima-escritorio-gnome | tee /var/log/salida && sleep 2
echo "PASO=50" > ${PASO_FILE}
;;

50) 
# Actualizando entradas del BURG
echo "Actualizando entradas del BURG" >> ${DOS}
echo "87" > ${PROGRESO}
update-burg | tee /var/log/salida && sleep 2
echo "PASO=51" > ${PASO_FILE}
;;

51) 
# Estableciendo GDM3 como Manejador de Pantalla por defecto
echo "Estableciendo GDM3 como Manejador de Pantalla por defecto" >> ${DOS}
echo "88" > ${PROGRESO}
echo "/usr/sbin/gdm3" > /etc/X11/default-display-manager && sleep 2
echo "PASO=52" > ${PASO_FILE}
;;

52) 
# Reconfigurando el Estilo Visual
echo "Fin de la actualización" >> ${UNO}
echo "Reconfigurando el Estilo Visual" >> ${DOS}
echo "90" > ${PROGRESO}
dpkg-reconfigure canaima-estilo-visual | tee /var/log/salida && sleep 2
echo "PASO=53" > ${PASO_FILE}
;;

53) 
echo "" >> ${DOS}
echo "95" > ${PROGRESO}
update-burg

		# Para cada usuario en /home/ ...
		for usuario in /home/*? ; do

			#Obteniendo sólo el nombre del usuario
			usuario_min=$(basename ${usuario})

			#Y en caso de que el usuario sea un usuario activo (existente en /etc/shadow) ...
			case  $(grep "${usuario_min}:.*:.*:.*:.*:.*:::" /etc/shadow) in

				'')
				#No hace nada si no se encuentra en /etc/shadow
				;;

				*)

					# Elimina configuracion de gconf previo
					rm -rf ${usuario}/.gconf/
				;;
			esac

		done
echo "Reiniciando el sistema en 20 segundos..." >> ${DOS}
echo "99" > ${PROGRESO}
sleep 20
echo 'PASO=70' > ${PASO_FILE}
reboot
exit 0
;;
esac
done