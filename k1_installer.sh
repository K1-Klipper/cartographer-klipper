#!/bin/sh

check_klipper_directory() {
  if [ ! -d "/usr/data/klipper" ]; then
    echo "Please install vanilla klipper update from here: https://github.com/K1-Klipper/installer_script_k1_and_max and try again"
    exit 1
  fi
}

gcode_shell_check(){
  if ! [ -f "/usr/data/klipper/klippy/extras/gcode_shell_command.py" ]; then
  echo "Downloading gcode_shell_command.py..."
  wget --no-check-certificate -qO "/usr/data/klipper/klippy/extras/gcode_shell_command.py" "https://raw.githubusercontent.com/dw-0/kiauh/master/resources/gcode_shell_command.py"
    if [ $? -ne 0 ]; then
      echo "Error: Download failed!"
      exit 1
    fi
  fi
}

entware_check(){
  if ! [ -f "/opt/bin/opkg" ]; then
    echo "File '/opt/bin/opkg' not found. Fetching files..."
    wget --no-check-certificate -qO /tmp/generic.sh https://raw.githubusercontent.com/Guilouz/Creality-K1-and-K1-Max/main/Scripts/files/entware/generic.sh
    chmod +x /tmp/generic.sh
    /tmp/generic.sh

    if [ $? -ne 0 ]; then
      echo "Error: Failed to install EntWare"
      exit 1  
    fi
  fi
  opkg install mjpg-streamer mjpg-streamer-input-http mjpg-streamer-input-uvc mjpg-streamer-output-http mjpg-streamer-www
}

kamp_check(){
  if [[ ! -d "/usr/data/KAMP-for-K1-Series/" ]]; then
  git clone https://github.com/Guilouz/KAMP-for-K1-Series.git /usr/data/ || {
    echo "Error: Git clone failed. Exiting..."
    exit 1
  }
  cp KAMP-for-K1-Series/Configuration/KAMP_Settings.cfg /usr/data/printer_data/config/
  fi
}

clone_cartographer() {
  git config --global http.sslVerify false
  git clone https://github.com/K1-Klipper/cartographer-klipper.git /usr/data/cartographer-klipper
  cd /usr/data/klipper
  git fetch origin
  git checkout k1-klipper
}

create_cartographer_symlink() {
  if [ ! -e "/usr/data/klipper/klippy/extras/cartographer.py" ]; then
    if [ -e "/usr/data/cartographer-klipper/cartographer.py" ]; then
      ln -sf "/usr/data/cartographer-klipper/cartographer.py" "/usr/data/klipper/klippy/extras/cartographer.py" || { echo "Error: Failed to create symlink"; exit 1; }
      echo "klippy/extras/cartographer.py" >> /usr/data/klipper/.gitignore
    else
      echo "Error: cartographer.py not found in /usr/data/cartographer-klipper/"
      exit 1
    fi
  fi
}

update_config_files() {
  sed -i '/\[gcode_macro START_PRINT\]/,/CX_PRINT_DRAW_ONE_LINE/d' /usr/data/printer_data/config/gcode_macro.cfg
  wget --no-check-certificate -P  /usr/data/printer_data/config/ https://raw.githubusercontent.com/K1-Klipper/cartographer-klipper/master/start_end.cfg
  sed -i '/\[include printer_params.cfg\]/a\[include cartographer_macro.cfg]\' /usr/data/printer_data/config/printer.cfg

  if grep -q "include start_macro_KAMP.cfg" /usr/data/printer_data/config/printer.cfg || grep -q "include start_macro.cfg" /usr/data/printer_data/config/printer.cfg; then
    sed -i 's/\[include start_(macro|macro_KAMP)\.cfg\]/[include start_stop.cfg]/g' /usr/data/printer_data/config/printer.cfg
  else
    sed -i '/\[include printer_params.cfg\]/a\[include start_end.cfg]\' /usr/data/printer_data/config/printer.cfg
  fi
}

backup_sensorless_config() {
  if [ ! -d "/usr/data/backups/" ]; then
  mkdir -p /usr/data/backups/
  fi
  mv /usr/data/printer_data/config/sensorless.cfg /usr/data/backups/
  wget --no-check-certificate -P  /usr/data/printer_data/config/ https://raw.githubusercontent.com/K1-Klipper/cartographer-klipper/master/sensorless.cfg
  wget --no-check-certificate -P  /usr/data/printer_data/config/ https://raw.githubusercontent.com/K1-Klipper/cartographer-klipper/master/cartographer_macro.cfg
  sed -i '/\[mcu\]/i\[include cartographer_macro.cfg]' /usr/data/printer_data/config/printer.cfg
}

update_klipper_service() {
  rm /etc/init.d/S55klipper_service
  wget -O- --no-check-certificate https://raw.githubusercontent.com/Guilouz/Creality-K1-and-K1-Max/main/Scripts/files/services/S55klipper_service > /etc/init.d/S55klipper_service
  sed -i '/\[include Helper-Script\/screws-tilt-adjust.cfg\]/d' /usr/data/printer_data/config/printer.cfg
  sed -i '/\[include Helper-Script\/save-zoffset.cfg\]/d' /usr/data/printer_data/config/printer.cfg
  chmod +x  /etc/init.d/S55klipper_service
  sh /etc/init.d/S55klipper_service restart
}


check_klipper_directory
gcode_shell_check
entware_check
kamp_check
clone_cartographer
create_cartographer_symlink
update_config_files
backup_sensorless_config
update_klipper_service
