#Go to home page
cd $HOME

#update dependencies
sudo apt update
sudo apt upgrade
#
#install the required dependencies install python3
sudo apt install --no-install-recommends git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget python3-dev python3-venv python3-tk \
  xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1

sudo apt install curl minicom zip unzip usbutils

#Verify version of dependencies
cmake --version
python3 --version
dtc --version

#Verify if exist already a folder called zephyrproject
zephyr_path="$HOME/zephyrproject/"

if [ ! -d "$zephyr_path" ]; then
    echo "Creating folder for zephyr project"
    mkdir "$zephyr_path"
fi

#Verify if exist a virtual enviroment
zephyr_venv_path="$HOME/zephyrproject/.venv"
if [ ! -d "$zephyr_venv_path" ]; then
    echo "Creating virtual enviroment"
    python3 -m venv $zephyr_venv_path
fi

# Set up virtual enviroment
source "$zephyr_venv_path/bin/activate"

# install pip dependencies for zephyr and nrf devices
pip install west

# insall last version of zephyr project repository
west init $zephyr_path
cd $zephyr_path
west update

#Export a Zephyr CMake package. 
west zephyr-export

#Install west dependencies
west packages pip --install

#instal sdk
zephyr_zephyr_path="$HOME/zephyrproject/zephyr"
cd $zephyr_zephyr_path
west sdk install

# verify of nrfjprog is installed
if ! command -v nrfjprog &> /dev/null
then
    echo "nrfjprog could not be found, installing nrf-command-line-tools"
    # Download the nRF Command Line Tools package
    download_dir="$HOME/Downloads/"
    echo $download_dir
    if [ ! -d "$download_dir" ]; then
        echo "Creating download folder"
        mkdir "$download_dir"
    fi
    cd $download_dir
    # Detect architecture and download the appropriate package
    arch_v=$(uname -m)
    file_install=""
    echo $arch_v
    if [ "$arch_v" = "x86_64" ] || [ "$arch_v" = "amd64" ]; then
        file_install="nrf-command-line-tools_10.24.2_amd64.deb"
        if [ -f "nrf-command-line-tools_10.24.2_amd64.deb" ]; then
          rm -rf "nrf-command-line-tools_10.24.2_amd64.deb"
        fi
        curl -O -L https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-2/nrf-command-line-tools_10.24.2_amd64.deb
    elif [ "$arch_v" = "x86_32" ] || [ "$arch_v" = "i386" ]; then
        file_install="nrf-command-line-tools_10_12_2_linux-i386.zip"
        if [ -f "nrf-command-line-tools_10_12_2_linux-i386.zip" ]; then
          rm -rf "nrf-command-line-tools_10_12_2_linux-i386.zip"
        fi
        curl -O -L https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-12-2/nrf-command-line-tools_10_12_2_linux-i386.zip
    elif [ "$arch_v" = "arm64" ] || [ "$arch_v" = "aarch64" ]; then
        file_install="nrf-command-line-tools_10.24.2_arm64.deb"
        if [ -f "nrf-command-line-tools_10.24.2_arm64.deb" ]; then
          rm -rf "nrf-command-line-tools_10.24.2_arm64.deb"
        fi
        curl -O -L https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-2/nrf-command-line-tools_10.24.2_arm64.deb
    elif [ "$arch_v" = "arm32" ] || [ "$arch_v" = "armhf" ]; then
        file_install="nrf-command-line-tools_10.24.2_armhf.deb"
        if [ -f "nrf-command-line-tools_10.24.2_armhf.deb" ]; then
          rm -rf "nrf-command-line-tools_10.24.2_armhf.deb"
        fi
        curl -O -L https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-2/nrf-command-line-tools_10.24.2_armhf.deb
    fi
    # Install the package
    if [[ "$file_install" == *.deb ]]; then
        sudo dpkg -i $file_install
        sudo apt-get install -f
    elif [[ "$file_install" == *.zip ]]; then
        unzip $file_install -d nrf-command-line-tools
        cd nrf-command-line-tools
        sudo ./install.sh
    fi
  else
    echo "nrfjprog is already installed"
fi

if ! command -v nrfutil &> /dev/null
then
    arch_v=$(uname -m)
    echo $arch_v
    if [ "$arch_v" = "x86_64" ] || [ "$arch_v" = "amd64" ]; then
      echo "nrfutil could not be found, installing it"
      # Install nrfutil using pip
      curl https://files.nordicsemi.com/artifactory/swtools/external/nrfutil/executables/x86_64-unknown-linux-gnu/nrfutil -o nrfutil
      sudo mv nrfutil /usr/local/bin/
      cd /usr/local/bin/
      chmod +x nrfutil
      nrfutil install completion
      nrfutil install device
      nrfutil install nrf5sdk-tools
      nrfutil self-upgrade
    else
      echo "nrfutil installation for $arch_v is not available, please install it manually"
    fi
  else
    echo "nrfutil is already installed"
fi

## install SEGGER J-LINK
arch_v=$(uname -m)
segger_file=""
arch_filename=""
echo "Linux architecture: $arch_v"
if [ "$arch_v" = "x86_64" ] || [ "$arch_v" = "amd64" ]; then
    arch_filename="x86_64"
    segger_file="JLink_Linux_x86_64.tgz"
elif [ "$arch_v" = "x86_32" ] || [ "$arch_v" = "i386" ]; then
    arch_filename="i386"
    segger_file="JLink_Linux_i386.tgz"
elif [ "$arch_v" = "arm64" ] || [ "$arch_v" = "aarch64" ]; then
    arch_filename="arm64"
    segger_file="JLink_Linux_arm64.tgz"
elif [ "$arch_v" = "arm32" ] || [ "$arch_v" = "armhf" ]; then
    arch_filename="arm"
    segger_file="JLink_Linux_arm.tgz"
fi

download_route="$HOME/Downloads"
echo "Go to this link:https://www.segger.com/downloads/jlink/$segger_file 
  and download the file. Once downloaded, store it on download folder
  on Linux ('$download_route') and press enter to continue.
  NOTE: open another prompt and use the following command to move the file from windows to WSL:
  sudo mv /mnt/c/Users/<user>/<dir_of_file>/JLink_Linux_V*_$arch_filename.tgz $download_route"
read -p ""

while ! ls $download_route/JLink_Linux_V*_$arch_filename.tgz 1> /dev/null 2>&1;
do
    echo "Verify that the file exist on route $download_route and try again. Cancel with Crtl+C"
    read -p ""
done

lin_file_seg_name=""
cd $download_route
num_jlink_files=$(find . -maxdepth 1 -type f -name "JLink_Linux_V*_$arch_filename.tgz" | wc -l)
if [ "$num_jlink_files" -gt 1 ]; then
    echo "Multiple JLink files found. Please select the correct one:"
    select file in $(ls JLink_Linux_V*_$arch_filename.tgz); do
        lin_file_seg_name="$file"
        break
    done
else
    lin_file_seg_name=$(ls JLink_Linux_V*_$arch_filename.tgz)
fi
exe_file_seg_name="${lin_file_seg_name%.tgz}"
echo "Installing SEGGER J-LINK"

lin_file_seg="$download_route/$lin_file_seg_name"
opt_path="opt/SEGGER"

if [ ! -d "$HOME/$opt_path" ]; then
    mkdir -p $HOME/$opt_path
fi
cd $HOME/$opt_path
if [ -d "$HOME/$opt_path/$exe_file_seg_name" ]; then
    rm -rf $HOME/$opt_path/$exe_file_seg_name
fi
tar xf $lin_file_seg
chmod a-w $HOME/$opt_path/$exe_file_seg_name

sudo cp $HOME/$opt_path/$exe_file_seg_name/99-jlink.rules /etc/udev/rules.d/99-jlink.rules

echo "Installation completed. Please close the prompt and open a new one to refresh the paths"
