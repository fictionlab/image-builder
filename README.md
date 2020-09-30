# image-builder
image-builder is a helper script for creating Debian-based OS images. It is based on [pi-gen], but introduces some changes to make it applicable for more general use and adds some command line arguments that facilitate the development process.

## Requirements
The script does not target any specific Linux distro, but has been mainly developed and tested on Ubuntu 20.04 LTS Focal Fossa. The only real requirements is the bash interpreter and some basic utilities (see the `depends` file).

## Installation
image-builder does not require any installation procedure. Simply clone this repository or download the ZIP archive and unpack it. If you want to have the script available from anywhere without specifing the full path, simply add a symbolic link to the executable in `/usr/bin` directory:
```
sudo ln -s $(pwd)/image-builder /usr/bin/image-builder
```

## Usage
```
image-builder [-cdex] [-f first] [-l last] [-b stage] [path]"
    -c        Continue from the last work directory instead of creating a new one
    -d        Dirty run. 
    -f first  
    -l last   
    -b stage  
    -e        Skip the export-image stages
    -x        Compress the result images
```

[pi-gen]: https://github.com/RPi-Distro/pi-gen