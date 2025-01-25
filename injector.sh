#!/bin/bash
# SWGEmu BACKUP INJECTOR 1.2 (Ubuntu/Debian Multithreading version)
# Execute in root mode
# Aeryna from Mod The Galaxy [2025]
# - customize it to your liking -

######
## Metodos
DDBB() {
# DDBB
read -p "Name of your SWGEmu Database (blank to default: 'swgemu'): " db
if [ "$db" == "" ];
then
    db="swgemu"
    echo -e "Default Database selected: \e[1;33m'$db'\e[0m"
    echo
fi
}

update_server_name() {
#Server name
read -p "Updating the server name (blank to Skip): " servername
if [ ! "$servername" == "" ];
then
   mysql -u root $db -e "USE $db; UPDATE galaxy SET name='$servername';"
   echo -e "\e[1;37mServer name was updated.\e[0m"
else
   echo -e "\e[1;37mSkipping.\e[0m"
fi
}

update_server_ip() {
#IP
read -p "Updating the server IP (blank to Skip): " IP
if [ ! "$IP" == "" ];
then
   mysql -u root $db -e "USE $db; UPDATE galaxy SET address='$IP';"
   echo -e "\e[1;37mServer IP was updated.\e[0m"
else
  echo -e "\e[1;37mSkipping.\e[0m"
fi
}

sistema_gestion_y_database() {
# ¿Existe Sistema de gestion de la BBDD? Por favor...
if [ ! $(command -v mysql) ] && [ ! $(command -v mariadb) ];
then
  echo -e "\e[1;31mCRITICAL!  Are you trying to manage a database without a database management system??\e[0m"
  echo -e "\e[1;31mPlease, install 'MYSQL' or 'MARIADB.\e[0m"
  echo
  exit 1
fi

res=$(mysql -u root --skip-column-names -e "SHOW DATABASES LIKE '$db'")
if [ "$res" == "$db" ]; then
    echo -e "\e[1;35m'\e[1;37m$db\e[1;35m' Database exists. The process can continue...\e[0m"
    echo
else
    echo -e "Error: Database \e[1;31m'$db'\e[0m does NOT exist. Try \e[1;33m'swgemu'\e[0m as database name."
    echo
    exit 1
fi
}
######

msg="-= SWGEmu BACKUP INJECTOR v1.2 (Multithreading version) =-"
msg2="An importer tool to use with the Aeryna's SWGEmu BACKUPPER"
msg_long=${#msg}
msg_long2=${#msg2}
width=$(tput cols)
space=$(( ($width - $msg_long) / 2 ))
space2=$(( ($width - $msg_long2) / 2 ))

clear
echo
echo -e "$(printf "%*s" $space)" "\e[1;37m$msg\e[0m"
echo
echo -e "$(printf "%*s" $space2)" "\e[1;36m$msg2\e[0m"
echo



########################
# ¿Parametro de inicio?
if [ "$1" == "server" ];
then
echo -e "\e[1;32mUpdating the Server name and its IP.\e[0m"
echo

DDBB
sistema_gestion_y_database

  read -p "Choose a new name for your server (blank to Skip): " servername
  if [ ! "$servername" == "" ];
  then
    mysql -u root $db -e "USE $db; UPDATE galaxy SET name='$servername';"
    echo -e "\e[1;37mServer name was updated.\e[0m"
    echo
  else
    echo
    echo "Process aborted. No change was made."
    exit 1
  fi

  read -p "Change the server IP (blank to Skip): " IP
  if [ ! "$IP" == "" ];
  then
    mysql -u root $db -e "USE $db; UPDATE galaxy SET address='$IP';"
    echo -e "\e[1;37mServer IP was updated.\e[0m"
    echo
  else
    echo "Process aborted. No change was made."
    exit 1
  fi
echo -e "\e[1;5;32mPROCESS COMPLETED.\e[0m\e[1;32m All the changes were made.\e[0m"
exit 0
fi
########################

echo -e "\e[1;33mNOTE:"
echo
echo -e "\e[1;33mThe program will use the default 'backup' directory to work with if you don't choose another one."
echo
echo -e "\e[1;31mWARNING!!\e[1;33m It will overwrite all files in the 'databases' directory and the necessary data in the game database.\e[0m"
echo

# PETICIONES INICIALES
#DDBB
DDBB

# ¿BBDD?
sistema_gestion_y_database


# Definicion de variables
destination=bin/databases
folder_=backup

read -p "Backup filename: " filename

if [[ "$filename" != *.zip ]];
then
   filename="$filename.zip"
fi

if [ "$filename" == "" ] || [ ! -e "$filename" ];
then
   echo -e "\e[1;31mError: Filename not valid or file not found. Quitting.\e[0m"
   echo
   exit 1
fi


read -p "Choose a temporary folder to work with (blank to default: 'backup'): " folder
if [ "$folder" == "" ];
then
   folder="$folder_"
   echo -e "Default folder selected: \e[1;33m'$folder'\e[0m"
else
   echo -e "A custom folder has been selected: \e[1;33m'$folder'\e[0m"
fi


# P7Zip si no esta instalado
if [ ! $(command -v 7z) ];
then
    echo -e "\e[1;33mFile decompressor NOT installed. Proceeding to install...\e[0m"
    echo
    apt install p7zip-full -y
    echo
fi


# A descomprimir...
if [ ! -d "$folder" ];
then
mkdir $folder
fi
echo -e "\e[1;32mNow unzipping files. Please wait..........\e[0m"
###unzip -oq $filename -d $folder >/dev/null 2>&1
7z x $filename -o$folder -mmt=on

echo
echo -e "\e[1;36mAll files have been decompressed.\e[0m"


# USANDO LOS ARCHIVOS CSV
echo
echo -e "\e[1;32mImporting csv files. Tables will be replaced...\e[0m"
sleep 2

# Creando Arrays para añadir los csv
CSVs=()
while IFS= read -r -d '' csv;
do
    CSVs+=("$csv")
done < <(find "$folder" -maxdepth 1 -type f -print0)

echo
echo "Tables found: "
for csv in "${CSVs[@]}"; do
    echo -e "\e[1;37m$csv\e[0m"
done
echo

# Iteramos la importacion
for csv in "${CSVs[@]}";
do
# Sin extension .csv para usarla como nombre de tabla del swgemu.
table="${csv##*/}"
table="${table%.csv}"

mysql -u root $db -e "DELETE FROM $db.$table"
# Importamos y reemplazamos los datos si fuera necesario
Consulta="LOAD DATA LOCAL INFILE '$csv' INTO TABLE $db.$table \
    FIELDS TERMINATED BY '\t' ENCLOSED BY '' LINES TERMINATED BY '\n' IGNORE 1 ROWS;"

echo "$Consulta" | mysql -u root $db

if [ ! $? -eq 0 ];
then
  echo -e "\e[1;31mCRITICAL! '$csv' could NOT be imported. Your import was unfinished. Quitting.\e[0m"
  rm -rf $folder
  exit 1
fi
done

echo -e "\e[1;36mThe tables were imported successfully.\e[0m"
echo


#El mismo nombre e IP del servidor?
update_server_name
update_server_ip
echo

# Copiando directorio databases
echo -e "\e[1;32mCopying database directory and files. Please wait......\e[0m"
sleep 1

if [ ! -d "$destination" ];
 then
  mkdir -p "$destination"
 else
  echo -e "\e[1;33mThe destination folder already exists. Overwriting files......\e[0m"
fi
mv -f "$folder"/databases/* bin/databases
echo


# Eliminando el TempDir
echo "Removing the temporary directory..."
rm -rf $folder

# FINALIZAR
echo
echo -e "\e[1;5;32mIMPORT PROCESS COMPLETED.\e[0m\e[1;32m May the Force be with you... btw NGE sucks.\e[0m"
