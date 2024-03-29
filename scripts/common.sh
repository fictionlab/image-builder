log (){
	date +"[%T] $*" | tee -a "${LOG_FILE}"
}
export -f log

copy_previous(){
	log "copy_previous is deprecated, ignoring.."
}
export -f copy_previous

unmount(){
	if [[ -z $1 ]]; then
		DIR=$PWD
	else
		DIR=$1
	fi

	while mount | grep -q "$DIR"; do
		local LOCS
		LOCS=$(mount | grep "$DIR" | cut -f 3 -d ' ' | sort -r)
		for loc in $LOCS; do
			umount "$loc"
		done
	done
}
export -f unmount

unmount_image(){
	sync
	sleep 1
	local LOOP_DEVICES
	LOOP_DEVICES=$(losetup --list | grep "$(basename "${1}")" | cut -f1 -d' ')
	for LOOP_DEV in ${LOOP_DEVICES}; do
		if [[ -n $LOOP_DEV ]]; then
			local MOUNTED_DIR
			MOUNTED_DIR=$(mount | grep "$(basename "${LOOP_DEV}")" | head -n 1 | cut -f 3 -d ' ')
			if [[ -n $MOUNTED_DIR && $MOUNTED_DIR != "/" ]]; then
				unmount "$(dirname "${MOUNTED_DIR}")"
			fi
			sleep 1
			losetup -d "${LOOP_DEV}"
		fi
	done
}
export -f unmount_image

on_chroot() {
	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/proc)"; then
		mount -t proc proc "${ROOTFS_DIR}/proc"
	fi

	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/dev)"; then
		mount --bind /dev "${ROOTFS_DIR}/dev"
	fi
	
	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/dev/pts)"; then
		mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"
	fi

	if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/sys)"; then
		mount --bind /sys "${ROOTFS_DIR}/sys"
	fi

	if [[ $1 ]]; then
		COMMAND="chroot \"${ROOTFS_DIR}\" /bin/bash -e -l -c \"$@\""
	elif [[ -t 0 ]]; then 
		COMMAND="chroot \"${ROOTFS_DIR}\" /bin/bash -l"
	else
		COMMAND="chroot \"${ROOTFS_DIR}\" /bin/bash -e -l"
	fi

	if [[ -f ${BASE_DIR}/chroot-env.sh ]]; then
		env -i bash --noprofile --norc -c "source "${BASE_DIR}/chroot-env.sh" && ${COMMAND}"
	else
		env -i bash --noprofile --norc -c "${COMMAND}"
	fi
}
export -f on_chroot
