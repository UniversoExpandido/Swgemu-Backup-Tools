#!/bin/bash
# SWGEmu BACKUPPER 1.2 (Ubuntu/Debian Multithreading version)
# Execute in root mode
# Aeryna from Mod The Galaxy [2025]
# - customize it to your liking -

msg="-= SWGEmu BACKUPPER v1.2 (Multithreading version) =-"
msg2="A backup tool to use with the Aeryna's SWGEmu INJECTOR"
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
echo -e "\e[1;33mNOTE:"
echo
echo -e "\e[1;33mThis program must stay in your MMOCoreORB directory to work.\e[0m"
echo -e "\e[1;33mIt will use a default 'backup' directory to work with if no other is chosen.\e[0m"
echo -e "\e[1;33mIt will copy the 'databases' folder from the server and will export the necessary Database tables to store in a universal Zip file.\e[0m"
echo

source=bin/databases
folder_=backup

if [ ! -d "$source" ];
then
  echo
  echo -e "\e[1;31mError: No Database directory detected! Can't continue. Quitting.\e[0m"
  exit 1
fi


# Peticiones iniciales
read -p "Choose a temporary folder (blank to default: 'backup'): " folder
if [ "$folder" == "" ];
then
   folder="$folder_"
   echo -e "Default folder selected: \e[1;33m'$folder'\e[0m"
else
   echo -e "A custom folder has been selected: \e[1;33m'$folder'\e[0m"
fi
echo

read -p "Choose a filename w/o extension (blank to a default name with date): " filename
if [ "$filename" == "" ];
then
  date=$(date "+%d-%m-%Y_%H:%M:%S")
  filename="backup_$date.zip"
  echo -e "Default filename selected: \e[1;33m'$filename'\e[0m"
else
  filename="$filename.zip"
fi

# ¿Existe "filename".zip?
if [ -f "$filename" ];
then
   echo -e "\e[1;33mA file called \e[1;37m'$filename'\e[0m \e[1;33malready exists.\e[0m"
   while [ "$respuesta" != "yes" ]  && [ "$respuesta" != "y" ] && [ "$respuesta" != "no" ]  && [ "$respuesta" != "n" ];
   do
     read -p "Overwrite file? (Yes / No): " respuesta
     respuesta=$(echo "$respuesta" | tr '[:upper:]' '[:lower:]')
     if [ "$respuesta" == "no" ] || [ "$respuesta" == "n" ]; then
       echo -e "\e[1;33mAborting the backup session.\e[0m"
       echo
       exit 0
     elif [ "$respuesta" == "yes" ] || [ "$respuesta" == "y" ] ; then
       echo -e "\e[1;33m'$filename' will be overwritten!\e[0m"
       echo
       break
     else
       echo -e "\e[1;37mAnswer not valid. Say Yes or No.\e[0m"
       echo
       continue
     fi
   done
fi


if [ -d "$folder/databases" ];
then
   echo -e "\e[1;36mWarning: '$folder/databases' directory already exists. It will be overwritten...\e[0m"
   echo
fi

read -p "Name of your SWGEMU Database (blank to default: 'swgemu'): " db
if [ "$db" == "" ];
then
    db="swgemu"
    echo
    echo -e "Default folder selected: \e[1;33m'$db'\e[0m"
    echo
fi

# ¿Existe Sistema de gestion?
if [ ! $(command -v mysql) ] && [ ! $(command -v mariadb) ];
then
  echo -e "\e[1;31mCRITICAL!  Are you trying to manage a database without a database management system??\e[0m"
  echo -e "\e[1;31mPlease, install 'MYSQL' or 'MARIADB.\e[0m"
  echo
  exit 1
fi


# Comprobaciones
res=$(mysql -u root --skip-column-names -e "SHOW DATABASES LIKE '$db'")
if [ "$res" == "$db" ];
then
    echo
    echo -e "\e[1;32m'$db' Database exists. The process continues...\e[0m"
    echo
else
    echo
    echo -e "Error: Database \e[1;31m'$db'\e[0m does NOT exist. Try \e[1;33m'swgemu'\e[0m as database name. Quitting."
    echo
    exit 1
fi


# Trabajamos con la BBDD
CSVs=("accounts" "characters" "galaxy")
echo -e "\e[1;35mMay add more tables to your backup if you wish. Tables 'accounts', 'characters' and 'galaxy' are already included by default.\e[0m"

function data_exists() {
    local csv="$1"
    for n in "${CSVs[@]}"; do
        [[ "$n" == "$csv" ]] && return 0
    done
    return 1
}

while true;
do
    read -p "Extra Table to Backup? (blank to Skip): " data

    # Break
    if [[ "$data" == "" ]];
    then
        break
    fi

    # Verificamos
    if data_exists "$data";
    then
        echo -e "\e[1;33m'$data' was already on the list.\e[0m"
    else
        CSVs+=("$data")
        echo -e "\e[1;37m'$data' has been added to the list.\e[0m"
    fi
done

echo
echo "Tables to add: "
for csv in "${CSVs[@]}";
do
   echo -en "\e[1;37m'$csv'  \e[0m"
done

# Creando directorio si no existe.
if [ ! -d "$folder" ];
then
mkdir $folder
fi

echo
echo
echo -e "\e[1;32mExporting tables...\e[0m"
echo
sleep 3

# Iteramos
for csv in "${CSVs[@]}";
do
  csv_file="$folder/$csv.csv"
  mysql -u root "$db" -e "SELECT * FROM $db.$csv" > $csv_file

if [ $? -eq 0 ];
   then
     echo -e "\e[1;37m$csv.csv ... was created.\e[0m"
   else
     echo
     if [ "$csv_file" == "accounts.csv" ] || [ "$csv_file" == "characters.csv" ];
      then
        echo -e "\e[1;31mCRITICAL! '$csv.csv' was NOT created or table doesn't exist. Can't continue. Removing temporary directory and quitting.\e[0m "
        echo
        rm -rf $folder
        exit 1
      else
        echo -e "\e[1;33mWarning! '$csv.csv' was NOT created or table doesn't exist. Table '$csv' won't be added to backup.\e[0m"
        rm -f $csv_file
     fi
  fi
done


# Copiado de archivos del directorio "Databases"
echo
echo -e "\e[1;32mSTARTING HEAVY TASKS...\e[0m"
echo
sleep 1

if [ -d "$source" ];
then
  if [ -d "$folder/databases" ];
  then
    echo -e "\e[1;33mOverwriting database directory and files.....\e[0m"
    echo
  else
    echo "Copying database directory and files....."
    echo
  fi
  cp -rf $source $folder
  echo "Database directory and files were copied."
  echo
else
  echo -e "\e[1;31mCRITICAL! Error copying the BIN/DATABASES directory or it does NOT exist. Check you run BACKUPPER within MMOCoreORB/\e[0m"
  exit 1
fi

# Instalar P7zip si no esta en el sistema
if [ ! $(command -v 7z) ];
then
    echo -e "\e[1;33mCompressor NOT installed. Proceeding to install...\e[0m"
    echo
    apt install p7zip-full -y
    echo
fi

# A comprimir...
echo -e "\e[1;32mNow compressing files. Please wait..........\e[0m"

if [ -f "$filename"  ];
then
  rm -f "$filename"
fi

##(cd "$folder" && zip -r "../$filename" .) > /dev/null 2>&1  ## zip version
(cd "$folder" && 7z a -mmt=on "../$filename" .) > /dev/null 2>&1

echo
echo -e "\e[1;36m'$filename' file was created.\e[0m"
echo "Removing the temporary folder..."
rm -rf $folder


# Finalizamos
echo
echo -e "\e[1;37mLook into your directory to find your backup file.\e[0m"
echo -e "\e[1;5;32mBACKUP PROCESS COMPLETED.\e[0m\e[1;32m May the Force be with you... btw NGE sucks.\e[0m"
