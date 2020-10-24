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

`path` should point to a directory configuration for `image-builder`. If no directory is specified, current working directory is assumed.

## Configuration
The directory containing the configarion for `image-builder` should have the following structure:

* `depends` - Specifies the dependencies needed to build the image. See the [dependencies_check.sh] file for more info.
* `config.sh` - Exports environment variables that are used throughout the build.
* `chroot-env.sh` - Exports environment variables for chrooted bash sessions.
* `stageX` - A directory containing configuration for stage `X`.
  * `prerun.sh` - A script that is run before any substage.
  * _`substage`_ - A substage directory. Substages are processed in lexicographical order.
    * `XX-debconf` - A file used to preseed debconf database values (See [debconf-set-selections]). Can use the exported environment variables.
    * `XX-packages` - A file containing list of packages to install with `apt`. Comments in the file are allowed.
    * `XX-packages-nr` - The same as `XX-packages` except that `apt` is used with `--no-install-recommends` option.
    * `XX-patches` - Series of patches to apply using [quilt].
      * `EDIT` - If this file exists, `image-builder` will start an interactive bash session before applying the patches.
    * `XX-run.sh` - An executable to run.
    * `XX-run-chroot.sh` - A list of commands to run on a chrooted bash session.
    * `SKIP` - If this file exists, the substage is skipped.
  * `EXPORT_IMAGE` - Indicates an image for this stage should be exported. Can export additional environment variables for the `export` stage (e.g. `IMG_SUFFIX`).
  * `SKIP_IMAGES` - If this file exists, EXPORT_IMAGE file is ignored.
  * `SKIP` - If this file exists, the whole stage is skipped.
* `export-image` - A directory containing configuration for the `export` stage. The structure is the same as for any other stage except that `EXPORT_IMAGE` and `SKIP_IMAGES` file don't have any effect.

## Exported environment variables
common:
* `IMG_NAME`
* `IMG_VERSION`
* `STAGE`
* `LOG_FILE`
* `STAGE_DIR`
* `STAGE_WORK_DIR`
* `SHARED_WORK_DIR`
* `PREV_STAGE`
* `PREV_STAGE_DIR`
* `ROOTFS_DIR`
* `PREV_ROOTFS_DIR`

export:
* `EXPORT_STAGE`
* `EXPORT_ROOTFS_DIR`
* `IMG_FILENAME`
* `DEPLOY_DIR`

functions:
* `log`
* `copy_previous`
* `unmount`
* `unmount_image`
* `on_chroot`

[dependencies_check.sh]: ./scripts/dependencies_check.sh
[debconf-set-selections]: http://manpages.ubuntu.com/manpages/bionic/man1/debconf-set-selections.1.html
[pi-gen]: https://github.com/RPi-Distro/pi-gen
[quilt]: https://linux.die.net/man/1/quilt