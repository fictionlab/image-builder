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
    -d        Dirty run. Don't clean the stage work directory before starting the stage. Implies -c
    -f first  Skip the stages preceding the specified one
    -l last   End on the specified stage
    -b stage  Only open a chrooted shell inside the root filesystem of the specified stage. Implies -c
    -e        Skip the export-image stages
    -x        Compress the resulted images
```

`path` should point to a directory configuration for `image-builder`. If no directory is specified, current working directory is assumed. \
The directory should have the following structure:

* `depends` - Specify dependencies needed to build the image
* `config.sh` - 
* `chroot-env.sh` - 
* `stage`_`X`_ - 
  * `prerun.sh` - 
  * _`substage`_ - 
    * _`XX`_`-debconf` - 
    * _`XX`_`-packages` -
    * _`XX`_`-packages-nr` - 
    * _`XX`_`-patches` - 
      * `EDIT`
    * _`XX`_`-run.sh` -
    * _`XX`_`-run-chroot.sh` -
    * `SKIP` - If this file exists, the substage is skipped
  * `EXPORT_IMAGE` -
  * `SKIP_IMAGES` - If this file exists, EXPORT_IMAGE file is ignored
  * `SKIP` - If this file exists, the whole stage is skipped
* `export-image` -

[pi-gen]: https://github.com/RPi-Distro/pi-gen