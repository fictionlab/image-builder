run_sub_stage()
{
	log "Begin ${SUB_STAGE_DIR}"
	pushd "${SUB_STAGE_DIR}" > /dev/null

	for i in {00..99}; do
		if [[ -f ${i}-debconf ]]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-debconf"
			envsubst < "${i}-debconf" | on_chroot "debconf-set-selections"
			log "End ${SUB_STAGE_DIR}/${i}-debconf"
		fi

		if [[ -f ${i}-packages-nr ]]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-packages-nr"
			PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${i}-packages-nr")"
			if [ -n "$PACKAGES" ]; then
				on_chroot "apt-get -o APT::Acquire::Retries=3 install --no-install-recommends -y $PACKAGES"
			fi
			log "End ${SUB_STAGE_DIR}/${i}-packages-nr"
		fi

		if [[ -f ${i}-packages ]]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-packages"
			PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${i}-packages")"
			if [[ -n $PACKAGES ]]; then
				on_chroot "apt-get -o APT::Acquire::Retries=3 install -y $PACKAGES"
			fi
			log "End ${SUB_STAGE_DIR}/${i}-packages"
		fi

		if [[ -d ${i}-patches ]]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-patches"
			pushd "${STAGE_WORK_DIR}" > /dev/null

			export QUILT_PATCHES="${SUB_STAGE_DIR}/${i}-patches"
			SUB_STAGE_QUILT_PATCH_DIR="$(basename "$SUB_STAGE_DIR")-pc"
			mkdir -p "$SUB_STAGE_QUILT_PATCH_DIR"
			ln -snf "$SUB_STAGE_QUILT_PATCH_DIR" .pc
			quilt upgrade
			if [[ -e ${SUB_STAGE_DIR}/${i}-patches/EDIT ]]; then
				echo "Dropping into bash to edit patches..."
				bash
			fi
			RC=0
			quilt push -a || RC=$?
			case "$RC" in
				0|2)
					;;
				*)
					false
					;;
			esac

			popd > /dev/null
			log "End ${SUB_STAGE_DIR}/${i}-patches"
		fi

		if [[ -x ${i}-run.sh ]]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-run.sh"
			./${i}-run.sh
			log "End ${SUB_STAGE_DIR}/${i}-run.sh"
		fi

		if [[ -f ${i}-run-chroot.sh ]]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
			on_chroot < ${i}-run-chroot.sh
			log "End ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
		fi
	done

	popd > /dev/null
	log "End ${SUB_STAGE_DIR}"
}

run_stage(){
	pushd "${STAGE_DIR}" > /dev/null
	if [[ -x prerun.sh ]]; then
		log "Begin ${STAGE_DIR}/prerun.sh"
		./prerun.sh
		log "End ${STAGE_DIR}/prerun.sh"
	fi
	for SUB_STAGE_DIR in "${STAGE_DIR}"/*; do
		if [[ -d $SUB_STAGE_DIR ]]; then
			if [[ ! -f ${SUB_STAGE_DIR}/SKIP ]]; then
				run_sub_stage
			else
				log "Skipping ${STAGE}/$(basename ${SUB_STAGE_DIR})"
			fi
		fi
	done
	popd > /dev/null
}

mount_stage(){
	log "Mounting overlay"
	MOUNT_DIR="$1"
	rm -rf "${MOUNT_DIR}/overlay_work" "${MOUNT_DIR}/rootfs"
	mkdir -p "${MOUNT_DIR}/overlay" "${MOUNT_DIR}/overlay_work" "${MOUNT_DIR}/rootfs"
	mount -t overlay overlay -o lowerdir="$(cat "${MOUNT_DIR}/underlay")",upperdir="${MOUNT_DIR}/overlay",workdir="${MOUNT_DIR}/overlay_work" "${MOUNT_DIR}/rootfs"
}

begin_stage(){
	log "Begin ${STAGE_DIR}"

	STAGE="$(basename "${STAGE_DIR}")"
	STAGE_WORK_DIR="${WORK_DIR}/${STAGE}"
	ROOTFS_DIR="${STAGE_WORK_DIR}/rootfs"

	unmount "${WORK_DIR}"

	if [[ ! -f "${STAGE_DIR}/SKIP_IMAGES" ]]; then
		if [[ -f "${STAGE_DIR}/EXPORT_IMAGE" ]]; then
			EXPORT_STAGES+=( $STAGE )
		fi
	fi

	if [[ $STAGE = "export-image" ]]; then

		rm -rf "${STAGE_WORK_DIR}"
		mkdir -p "${STAGE_WORK_DIR}"

		if [[ -f "${EXPORT_STAGE_WORK_DIR}/underlay" ]]; then
			mount_stage "${EXPORT_STAGE_WORK_DIR}"
		fi

		run_stage

	elif [[ $STAGE_NR -ge $STAGE_FIRST && ! -f SKIP ]]; then

		if [[ $CLEAN = true && -d $STAGE_WORK_DIR ]]; then
			log "Cleaning stage work dir from previous build"
			rm -rf "${STAGE_WORK_DIR}"
		fi
		mkdir -p "${STAGE_WORK_DIR}"
		
		if [[ ! -z $UNDERLAY ]]; then
			printf "%s" "${UNDERLAY}" > "${STAGE_WORK_DIR}/underlay"
			mount_stage "${STAGE_WORK_DIR}"
		fi

		run_stage
	else
		log "Skipping ${STAGE}"
	fi

	unmount "${WORK_DIR}"
	
	if [[ $STAGE != "export-image" ]]; then
		if [[ $STAGE_NR = 0 ]]; then
			UNDERLAY="${ROOTFS_DIR}"
		else
			UNDERLAY="${STAGE_WORK_DIR}/overlay:${UNDERLAY}"
		fi
	fi

	log "End ${STAGE_DIR}"
}
