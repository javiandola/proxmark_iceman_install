#!/bin/bash

# Colores
verde="\e[0;32m\033[1m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
morado="\e[0;35m\033[1m"
turquesa="\e[0;36m\033[1m"
gris="\e[0;37m\033[1m"
fin="\033[0m\e[0m"

# Verificar si el script se está ejecutando con permisos de sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${rojo}Por favor, ejecuta este script como superusuario (sudo)${fin}" 
   exit 1
fi

# Variable del usuario
USUARIO=${SUDO_USER:-$USER}

# Ruta del repositorio
REPO_GIT="/home/$USUARIO/"
REPO_PATH="/home/$USUARIO/proxmark3"

# Comprobar si los comandos necesarios están instalados
for cmd in git make; do
  if ! command -v $cmd &> /dev/null; then
    echo "El comando $cmd no se encontró. Por favor, instálalo e intenta de nuevo."
    exit 1
  fi
done

# Instalar dependencias
apt-get update && apt-get upgrade -y
apt-get install --no-install-recommends git ca-certificates build-essential pkg-config libreadline-dev gcc-arm-none-eabi libnewlib-dev qtbase5-dev libbz2-dev liblz4-dev libbluetooth-dev libpython3-dev libssl-dev 
apt-get install -y libcanberra-gtk-module

# Clonar repositorio
if git -C $REPO_GIT clone https://github.com/RfidResearchGroup/proxmark3.git; then
  echo "Repositorio clonado con éxito."
else
  echo "Hubo un error al clonar el repositorio."
  exit 1
fi

cd $REPO_PATH

# Dar permisos al usuario para el ttyACM0
make accessrights
if [ -r /dev/ttyACM0 ] && [ -w /dev/ttyACM0 ]; then
  echo -e "${verde}OK PERMISOS${fin}"
else
  echo -e "${rojo}Error al establecer permisos.${fin}"
  exit 1
fi

echo -e "${rojo}Deberás reiniciar para que los permisos tengan efecto.${fin}"
echo -e "${verde}Continuando con la compilación en 5 segundos.${fin}"
sleep 5

# Compilando
git pull
make clean && make -j
make install

# Respuesta al usuario
echo -e "${amarillo}Hola${fin} ${verde}$USUARIO${fin}"
echo -e "${amarillo}Ejecuta${fin} ${verde}./pm3-flash-bootrom${fin}   ${amarillo}Este comando se utiliza para actualizar el cargador de arranque${fin}"
echo -e "${amarillo}Ejecuta${fin} ${verde}./pm3-flash-fullimage${fin} ${amarillo}Este comando se utiliza para actualizar el firmware${fin}"
echo -e "${amarillo}Ejecuta${fin} ${verde}./pm3${fin}                 ${amarillo}Este comando se utiliza para iniciar el cliente Proxmark3${fin}"

exit 0
