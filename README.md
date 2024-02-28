# Hardware Setup

* [Download the Model]
* [Follow the Assembly Manual]

# Software Prerequisites

* [Root access]
* [Moonraker & Fluidd **OR** Mainsail]. Having both installed may cause issues / mcu timeout
* [Updated klipper] (from Zarboz)
* [Guppyscreen with De-creality] (suggested to lower MCU utilization)

# Software Setup

1. Open a ssh connection to the printer
2. Download the repo and run the installer:
``` shell
git clone https://github.com/K1-Klipper/cartographer-klipper.git
```
```
cd cartographer-klipper && sh ./k1_installer.sh
```
3. Find the serial device for the cartographer. Save the file path for later use in configuration
``` shell
ls /dev/serial/by-id/usb-Cartographer*
```
4. Add the include for KAMP to your your `printer.cfg` (if it does not already exist)
``` ini
[include KAMP_Settings.cfg]
```
5. Inside your `printer.cfg`, remove anything related to PRtouch (ie. `[prtouch_v2]`, `[prtouch default]`). This includes anything below the save config section. (the section that looks like `#*#`)
6. Add the following mcu at the top of `printer.cfg`, but below the `[mcu_rpi]` section. Replace the `(ID YOU NOTED EARLIER)` with the output from step 2, e.g. `/dev/serial/by-id/usb-Cartographer_614e_048015001043303856303820-if00`
``` ini
[cartographer]
serial: /dev/serial/by-id/(ID YOU NOTED EARLIER)   # change this line to have your cartographer id.
speed: 40.                      #   Z probing dive speed.
lift_speed: 5.                  #   Z probing lift speed.
backlash_comp: 0.5              #   Backlash compensation distance for removing Z backlash before measuring the sensor response.
x_offset: 0.                    #   X offset of cartographer from the nozzle.
y_offset: 16.86                 #   Y offset of cartographer from the nozzle.
trigger_distance: 2.            #   cartographer triggers distance for homing.
trigger_dive_threshold: 1.5     #   Threshold for range vs dive mode probing. Beyond `trigger_distance + trigger_dive_threshold` a dive will be used.
trigger_hysteresis: 0.006       #   Hysteresis on trigger threshold for un triggering, as a percentage of the trigger threshold.
cal_nozzle_z: 0.1               #   Expected nozzle offset after completing manual Z offset calibration.
cal_floor: 0.1                  #   Minimum z bound on sensor response measurement.
cal_ceil:5.                     #   Maximum z bound on sensor response measurement.
cal_speed: 1.0                  #   Speed while measuring response curve.
cal_move_speed: 10.             #   Speed while moving to position for response curve measurement.
default_model_name: default     #   Name of default cartographer model to load.
mesh_main_direction: x          #   Primary travel direction during mesh measurement.
#mesh_overscan: -1              #   Distance to use for direction changes at mesh line ends. Omit this setting and a default will be calculated from line spacing and available travel.
mesh_cluster_size: 1            #   Radius of mesh grid point clusters.
mesh_runs: 2                    #   Number of passes to make during mesh scan.
```
7. In `printer.cfg` under `[stepper_z]` edit the endstop pin to the following:

   1. Remove the following:
   ``` ini
   endstop_pin: tmc2209_stepper_z:virtual_endstop# PA15   #probe:z_virtual_endstop 
   position_endstop: 0
   ```
   2. Replace with the following:
   ``` ini
   endstop_pin: probe:z_virtual_endstop # use cartographer as virtual endstop
   homing_retract_dist: 0 # cartographer needs this to be set to 0
   ```
8. Inside `printer.cfg` remove your `[bed_mesh]` section and replace it with the appropriate section for your printer:
   * For the K1:
   ``` ini
   [bed_mesh]              # K1
   zero_reference_position: 112,112
   speed: 135              # recommended max 150 - absolute max 180. Going above 150 will cause mcu hanging / crashing or inconsistent spikey meshes due to bandwidth limitation.  
   mesh_min: 30,25         # up to 30x30 if you have a weird spike bottom left of mesh
   mesh_max: 210,210       # 210 max before hitting rear plate screws on stock bed
   probe_count: 20,20      # tested 100x100 working
   algorithm: bicubic      # required for above 5x5 meshing
   bicubic_tension: 0.1
   ```
   * For the K1 Max:
   ``` ini
   [bed_mesh]              # K1 MAX
   speed: 150              # max of 150 or cartographer will stutter / timeout
   mesh_min: 10,22         # x / y offsets for cartographer.
   mesh_max: 290,280       # add a little space from the back of the bed to prevent scanning screws or crashing into the motor mounts
   probe_count: 40,40      # tested up to 150x150 points, any higher will timeout the mcu after meshing.
   algorithm: bicubic      # required for above 5x5 meshing
   bicubic_tension: 0.1
   ```

# First Steps and Calibration:

1. Move your bed plate 2-3 mm away from the nozzle 
2. On the homescreen of your web UIX, press the **`CARTO_CALIBRATE`** macro and wait for the Z offset wizard to pop up.
Follow the [Paper Test Method]
Upon completion *`SAVE_CONFIG`*

### IMPORTANT SAFETY CHECK

While your motors are disabled, manually move the bed away from the nozzle (at least a fist away) and type into klipper’s console: **`M119`**.

If your Z endstop is “OPEN” you are safe to continue however if it is “TRIGGERED” re-do step 2 or begin troubleshooting.

3. If you have verified that your Z endstop is functioning correctly, please home all. If the nozzle crashes please e-stop the printer and re-try from step 1.
4. You may now run **`CARTO_BED_MESH`** to produce your first mesh! Save this one complete, make any tramming adjustments you require to make the bed flat. It is expected you will have up to 1.4mm variance from PRTouch as there is a known issue with their mesh accuracy.
5. Once you have your first bed mesh you will need to change your machine settings in your slicer Start G-Code to the following:
``` gcode
M104 S0 ; Stops OrcaSlicer from sending temp waits separately
M140 S0
SET_GCODE_VARIABLE MACRO=PRINT_START VARIABLE=bed_temp VALUE=[first_layer_bed_temperature] 
SET_GCODE_VARIABLE MACRO=PRINT_START VARIABLE=extruder_temp VALUE=[first_layer_temperature] 
print_start EXTRUDER_TEMP=[first_layer_temperature] BED_TEMP=[first_layer_bed_temperature] CHAMBER=[chamber_temperature]
```
6. You may now start your first print! 

***Special Thanks to Zarboz, Shima, BootyCall Jones, and Destinal for their contributions to this project***

[Download the Model]: https://makerworld.com/en/models/200689
[Follow the Assembly Manual]: https://docs.google.com/document/d/1iOOGeqHqNmlJenYUOr2cGRdccpGq-NLx-ezH2wCMzag/edit?usp=sharing
[Root access]: https://github.com/Guilouz/Creality-K1-and-K1-Max/wiki/Install-&-Update-Rooted-Firmware#enable-root-access
[Moonraker & Fluidd **OR** Mainsail]: https://github.com/Guilouz/Creality-K1-and-K1-Max/wiki/Moonraker-and-Nginx
[Updated klipper]: https://github.com/K1-Klipper/installer_script_k1_and_max
[Guppyscreen with De-creality]: https://github.com/ballaswag/guppyscreen
[Paper Test Method]: https://www.klipper3d.org/Bed_Level.html#the-paper-test
