# vim: set ts=4 sw=4 et:

check_pkg_arch() {
    local cross="$1" _arch f found

    if [ -n "$only_for_archs" ]; then
        if [ -n "$cross" ]; then
            _arch="$XBPS_TARGET_MACHINE"
        elif [ -n "$XBPS_ARCH" ]; then
            _arch="$XBPS_ARCH"
        else
            _arch="$XBPS_MACHINE"
        fi
        for f in ${only_for_archs}; do
            if [ "$f" = "${_arch}" ]; then
                found=1
                break
            fi
        done
        if [ -z "$found" ]; then
            msg_red "$pkgname: this package cannot be built for ${_arch}.\n"
            exit 2
        fi
    fi
}

remove_pkg_autodeps() {
    local rval= tmplogf=

    [ -n "$XBPS_KEEP_ALL" ] && return 0

    cd $XBPS_MASTERDIR || return 1
    msg_normal "${pkgver:-xbps-src}: removing autodeps, please wait...\n"
    tmplogf=$(mktemp)

    if [ -z "$CHROOT_READY" ]; then
        xbps-reconfigure -r $XBPS_MASTERDIR -a >> $tmplogf 2>&1
        xbps-remove -r $XBPS_MASTERDIR -Ryo >> $tmplogf 2>&1
    else
        remove_pkg_cross_deps
        xbps-reconfigure -a >> $tmplogf 2>&1
        xbps-remove -Ryo >> $tmplogf 2>&1
    fi

    if [ $? -ne 0 ]; then
        msg_red "${pkgver:-xbps-src}: failed to remove autodeps:\n"
        cat $tmplogf && rm -f $tmplogf
        msg_error "${pkgver:-xbps-src}: cannot continue!\n"
    fi
    rm -f $tmplogf
}

remove_pkg_wrksrc() {
    if [ -d "$wrksrc" ]; then
        msg_normal "$pkgver: cleaning build directory...\n"
        rm -rf $wrksrc
    fi
}

remove_pkg_statedir() {
    if [ -d "$XBPS_STATEDIR" ]; then
        rm -rf "$XBPS_STATEDIR"
    fi
}

remove_pkg() {
    local cross="$1" _destdir f

    [ -z $pkgname ] && msg_error "unexistent package, aborting.\n"

    if [ -n "$cross" ]; then
        _destdir="$XBPS_DESTDIR/$XBPS_CROSS_TRIPLET"
    else
        _destdir="$XBPS_DESTDIR"
    fi

    [ ! -d ${_destdir} ] && return

    for f in ${sourcepkg} ${subpackages}; do
        if [ -d "${_destdir}/${f}-${version}" ]; then
            msg_normal "$f: removing files from destdir...\n"
            rm -rf ${_destdir}/${f}-${version}
        fi
        if [ -d "${_destdir}/${f}-dbg-${version}" ]; then
            msg_normal "$f: removing dbg files from destdir...\n"
            rm -rf ${_destdir}/${f}-dbg-${version}
        fi
        if [ -d "${_destdir}/${f}-32bit-${version}" ]; then
            msg_normal "$f: removing 32bit files from destdir...\n"
            rm -rf ${_destdir}/${f}-32bit-${version}
        fi
        rm -f ${XBPS_STATEDIR}/${f}_${cross}_subpkg_install_done
        rm -f ${XBPS_STATEDIR}/${f}_${cross}_prepkg_done
    done
    rm -f ${XBPS_STATEDIR}/${sourcepkg}_${cross}_install_done
    rm -f ${XBPS_STATEDIR}/${sourcepkg}_${cross}_pre_install_done
    rm -f ${XBPS_STATEDIR}/${sourcepkg}_${cross}_post_install_done
}
