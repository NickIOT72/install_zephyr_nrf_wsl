# Install Zephyr and NRF tools on WSL

This file is developed to install Zephyr and some essential tools like nrfjprog and nrfutil, within a Windows Subsystem for Linux (WSL) environment. It aims to set up a complete development environment for working with Nordic Semiconductor devices.

---

## Pre-requisites
- Installed utilities on Power Shell:
  - `wsl`
  - `usbipd`
- Windows Subsystem for Linux (WSL) environment.
- WSL must be version 2
- Install `git` on WSL
---

## Set up WSL
To install WSL use the command  `wsl --install` and it will ask for UNIX name and password to initialize it. After that, close the WSL prompt.

Once installed and closed or if you have installed already, use the command on Power Shell:

`wsl --list --verbose`

to confirm the version of the WSL. It will display the following message:
```bash
  NAME      STATE           VERSION
* Ubuntu    Stopped         2
```

For zephyr installation, it's required version 2. To set up that, use the 
command:

`wsl --set-version <distro_name> 2`

Verify the version using `wsl --list --verbose`.

## Run bash file

Open WSL prompt , clone this repository and paste these commands:

```bash
cd install_zephyr_nrf_wsl
chmod +x install_zephyr_nrf_wsl.sh
./install_zephyr_nrf_wsl.sh
```

Once the installation is completed, close the WSL prompt.

NOTE: During the execution of the script, it will be requested to download the [SEGGER -J-link file](https://www.segger.com/downloads/jlink/) on your windows. To move the file to WSL use the command `sudo mv /mnt/c/Users/<user>/<dir_of_file>/JLink_Linux_V<version>_<linux_arch>.tgz $HOME/Downloads`. All these instructions will be explained in more detail during the installation 

## Attach device to WSL

Connect device (recommended NRF SDK device) to PC/LAPTOP and open Power Shell as administrator. If you don't have `usbipd` installed, use the command `winget install usbipd`. Once isntalled, use the following command:

`usbipd list`

This will print all the devices connectted to the PC

```bash
BUSID  VID:PID    DEVICE                                                        STATE
1-2    1234:1234  JLink CDC UART Port (COM7), J-Link driver                     Not shared
4-1    ssss:ssss  USB Input Device                                              Not shared
4-3    aaaa:aaaa  USB Input Device                                              Not shared
```

As we can see, we have a nrf device connected to the PC, specifically `nrf52840dk` on the port COM7. Looking at the STATE column, the device is not attached to WSL. To do that, let's give permission to the device to connect wit WSL and shared this port as well.

```bash
usbipd bind --busid <bus_id>
usbipd attach --wsl --busid <bus_id>
```

Using `usbipd list` we obtain
```bash
BUSID  VID:PID    DEVICE                                                        STATE
1-2    1234:1234  JLink CDC UART Port (COM7), J-Link driver                     Attached
4-1    ssss:ssss  USB Input Device                                              Not shared
4-3    aaaa:aaaa  USB Input Device                                              Not shared
```

To confirm this, let's open WSL and type `nrfjprog --com` and should display something like this:

`<device_id>    /dev/tty<port>   VCOM<num>`

## Flah device

on WSL, write the commands:
```bash
source ~/zephyrproject/.venv/bin/activate
cd ~/zephyrproject/zephyr
west build -p always -b <your-board-name> samples/basic/blinky
```
In this case `<your-board-name> = nrf52840dk/nrf52840`. 

Finally, flash the program using `west flash --erase`

## Additional notes

* If your using another device like `esp32s3_devkitc` the process to attach the device to WSL is the same but to identify the port use the command `lsusb`, showing something like this

`Bus 001 Device 004: ID bbbb:aaaa Silicon Labs CP210x UART Bridge`

To flash this device it's required to use find the port using `dmesg | grep tty` returning:

`[time] usb <bus_id>: cp210x converter now attached to ttyUSBX`

and then give the permission using `sudo chmod 0666 /dev/ttyUSBX`. After that, just use `west flash --erase`