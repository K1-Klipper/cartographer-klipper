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
    rm /tmp/generic.sh #sanity check for deleting installer
    wget --no-check-certificate -qO /tmp/generic.sh https://raw.githubusercontent.com/Guilouz/Creality-Helper-Script/main/files/entware/generic.sh
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
  if [[ ! -d "/usr/data/KAMP-for-K1-Series/" && ! -d "/usr/data/KAMP/" && ! -d "/usr/data/Klipper-Adaptive-Meshing-Purging/" ]]; then
  git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git /usr/data/KAMP || {
    echo "Error: Git clone failed. Exiting..."
    exit 1
  }
else
  echo "One or more directories already exist. Skipping cloning."
  cp /usr/data/KAMP/Configuration/KAMP_Settings.cfg /usr/data/printer_data/config/
  mkdir -p /usr/data/printer_config/config/KAMP
  ln -s /usr/data/KAMP/Configuration/Line_Purge.cfg /usr/data/printer_data/config/KAMP/
  ln -s /usr/data/KAMP/Configuration/Smart_Park.cfg /usr/data/printer_data/config/KAMP/
  ln -s /usr/data/KAMP/Configuration/Adaptive_Meshing.cfg /usr/data/printer_data/config/KAMP/
  sed -i 's/^#\s+\[include \.\/KAMP\/Adaptive_Meshing\.cfg\]\s*$/[include \.\/KAMP\/Adaptive_Meshing\.cfg]\t# Include to enable adaptive meshing configuration./' /usr/data/printer_data/config/KAMP_Settings.cfg
  sed -i 's/^#\s+\[include \.\/KAMP\/Line_Purge\.cfg\]\s*$/[include \.\/KAMP\/Line_Purge\.cfg]\t# Include to enable adaptive line purging configuration./' /usr/data/printer_data/config/KAMP_Settings.cfg
  sed 's/^#\s+\[include \.\/KAMP\/Smart_Park\.cfg\]\s*$/[include \.\/KAMP\/Smart_Park\.cfg]\t# Include to enable the Smart Park function, which parks the printhead near the print area for final heating./' /usr/data/printer_data/config/KAMP_Settings.cfg
  fi
}

clone_cartographer() {
  if [[ ! -d "/usr/data/cartographer-klipper" ]]; then
    git -c http.sslVerify=false clone https://github.com/K1-Klipper/cartographer-klipper.git /usr/data/cartographer-klipper && {
      echo "Please don't forget to checkout the k1-carto branch in your klipper folder for best results"
    } || {
      echo "Error: Git cloning Cartographer failed. Exiting..."
      exit 1
    }
  fi
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
  if [[ ! -f "/usr/data/printer_data/config/gcode_macro.cfg" ]]; then
    echo "Error: gcode_macro.cfg not found!"
    return 1
  fi
  rm /usr/data/printer_data/config/start_end.cfg
  if ! wget --no-check-certificate -O /usr/data/printer_data/config/start_end.cfg https://raw.githubusercontent.com/K1-Klipper/cartographer-klipper/master/start_end.cfg; then
    echo "Error: Downloading start_end.cfg failed!"
    return 1
  fi
  if [[ ! -f /usr/data/printer_data/config/start_end.cfg ]]; then
    echo "Error: Downloaded start_end.cfg not found!"
    return 1
  fi
  if [[ ! -f "/usr/data/printer_data/config/printer.cfg.bak" ]]; then
    cp /usr/data/printer_data/config/printer.cfg /usr/data/printer_data/config/printer.cfg.bak
  fi
  if ! sed -i '/\[gcode_macro START_PRINT\]/,/CX_PRINT_DRAW_ONE_LINE/d' /usr/data/printer_data/config/gcode_macro.cfg; then
    echo "Error: Deleting lines in gcode_macro.cfg failed!"
    return 1
  fi
  mv /tmp/start_end.cfg /usr/data/printer_data/config/start_end.cfg
  if ! sed -i '/\[include printer_params.cfg\]/a\[include cartographer_macro.cfg\]' /usr/data/printer_data/config/printer.cfg; then
    echo "Error: Adding cartographer_macro.cfg to printer.cfg failed!"
    return 1
  fi
  if ! sed -i '/\[include cartographer_macro.cfg\]/a\[include start_end.cfg\]' /usr/data/printer_data/config/printer.cfg; then
    echo "Error: Adding start_end.cfg to printer.cfg failed!"
    return 1
  fi
  echo "Config files updated successfully!"
  return 0
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
  wget -O- --no-check-certificate https://raw.githubusercontent.com/K1-Klipper/installer_script_k1_and_max/main/S55klipper_service > /etc/init.d/S55klipper_service
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
