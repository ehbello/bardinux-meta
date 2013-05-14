#!/bin/bash
# -*- coding: utf-8 -*-

#_ Interactive script to create a custom Linux kernel for Ubuntu
#
# Copyright © 2009-2012  B. Clausius
#
# Use this however you want, just give credit where credit is due.

function echo_() { echo "$@"; }
SCRIPTNAME="$(basename "$0")"

function print_usage()
{
    echo_ "Interactive script to create a custom Linux kernel for Ubuntu"
    echo
    echo_ "Usage:
${SCRIPTNAME} --help | -h
${SCRIPTNAME} FLAVOUR"
}

function print_configs()
{
    echo_ 'Existing configurations:'
    for flavour in $(ls -1 ../config-* | cut -d - -f 4- | sort -u); do
        echo
        echo $flavour :
        ls ../config-*-$flavour
    done
}

function print_help()
{
echo_ "Examples:
${SCRIPTNAME} generic
      Build the Ubuntu kernel for desktop computers
${SCRIPTNAME} server
      Build the Ubuntu kernel for servers
${SCRIPTNAME} core2
      Custom flavour (if it does not exist, it will be created)"
echo
echo_ \
'Notes:
    - Run the script from inside the source directory.
      It is intended to build the Linux kernel from Ubuntu 8.04.
      For source code from kernel.org the script is not suitable.
    - The used configuration tool is
      xconfig (Qt interface, package libqt3-mt-dev or libqt4-dev),
      gconfig (GTK interface, packages libgtk2.0-dev,
                                libglib2.0-dev, libglade2-dev)
      menuconfig (ncurses interface, package libncurses5-dev) oder
      config (line-oriented tool),
      whichever is found first.
    - The configuration is searched at these locations:
        1. ".config"
        2. "../config-KERNELVERSION-FLAVOUR"
        3. configuration in the source code for default flavour (generic
                                or $FLAVOUR)
    - After the configuration step the kernel configuration is stored
      in the file "../config-KERNELVERSION-VARIANTE"'
}


[ "$1" = "" -o "$2" ] && {
    print_usage
    echo
    print_configs
    exit 1
}

[ "$1" = "-h" -o "$1" = "--help" ] && {
    print_usage
    echo
    print_help
    exit 0
}


function read_msg()
{
    echo
    echo "***** $* *****"
    read -p "[Enter: continue, Ctrl+D: skip, Ctrl+C: abort]" || { echo; return 1; }
}

function query_git_reset()
{
    [ -d .git ] && read_msg 'Discard changes in the git directory' && {
        git reset --hard
        git clean -fdx
    }
}

#####_ Preparations

function ubuntu_release()
{
    dpkg --compare-versions $UBUNTU_RELEASE $1 $2
}

#_ Supported Ubuntu version?
echo_ "Installed distribution:"
lsb_release -a
which lsb_release >/dev/null &&
    [ ! "$UBUNTU_RELEASE" ] &&
    [ "$(lsb_release -is)" = 'Ubuntu' ] && {
        UBUNTU_RELEASE=$(lsb_release -rs)
        #UBUNTU_CODENAME=$(lsb_release -cs)
    }
if [ ! "$UBUNTU_RELEASE" ]; then
    echo
    echo_ \
'Error: unknown distribution
        The environment variable UBUNTU_RELEASE must be set manually'
    exit 1
fi

[ "$(sed 's/^[0-9]\{2\}\.[0-9]\{2\}\(\.[0-9]\)\?$//' <<<$UBUNTU_RELEASE)" ] && {
    echo
    echo_ \
"Error: UBUNTU_RELEASE=${UBUNTU_RELEASE}
        The environment variable UBUNTU_RELEASE must be a valid
        Ubuntu version, eg 10.04, 11.10 or 12.04.
        If UBUNTU_RELEASE is not specified, the output of
        'lsb_release-rs' is used"
    exit 1
}
echo
echo_ "Using method for '${UBUNTU_RELEASE}'.
(Set environment variable UBUNTU_RELEASE for different version)"

_ubuntu_codename_installed="$(lsb_release -cs)"
_ubuntu_codename_code="$(sed '1s/^[^ ]\+ [^ ]\+ \([a-z]\+\).*$/\1/;q' debian*/changelog 2>/dev/null)"
[ "$_ubuntu_codename_installed" != "$_ubuntu_codename_code" ] && {
    echo
    echo_ "Warning: In the source code is '${_ubuntu_codename_code}' specified,
but the installed distribution is '${_ubuntu_codename_installed}'.
Maybe the kernel can not be built."
}

if ubuntu_release lt-nl 8.04; then
    echo
    echo_ 'Error: this script does not support versions before Ubuntu 8.04'
    exit 1
elif ubuntu_release eq 8.04; then
    DEBIAN=debian
    DEBIAN2=debian
elif ubuntu_release le 9.10; then
    DEBIAN=debian.master
    DEBIAN2=debian.master
elif ubuntu_release le 13.04; then
    DEBIAN=debian.master
    DEBIAN2=debian
else
    DEBIAN=debian.master
    DEBIAN2=debian
    echo
    echo_ \
'Warning: this script is not tested for versions from Ubuntu 13.10'
fi


#_ Called from source directory?
if [ ! -d kernel ] || [ ! -f MAINTAINERS ] || [ ! -f Makefile ]; then
    echo
    echo_ 'Error: the script must be called from source directory'
    exit 1
fi
if [ ! -d $DEBIAN ] || [ ! -d $DEBIAN2 ]; then
    echo
    [ -d $DEBIAN ] || {
        echo_ "Error: directory '$DEBIAN' does not exist."; }
    [ -d $DEBIAN2 ] || {
        echo_ "Error: directory '$DEBIAN2' does not exist."; }
    echo_ \
'        This script only works with Ubuntu git trees
        and with code downloaded with "apt-get source",
        but not with the source code from kernel.org.
        Also you may have assigned UBUNTU_RELEASE wrong.'
        
    query_git_reset
    exit 1
fi


#_ Some details about the running kernel
SYS_RELEASE=$(uname -r | awk -F- '{print $1}')
SYS_ARCH=$(uname -m)
SYS_FLAVOUR=$(uname -r | cut -d - -f 3-)
[ "$FLAVOUR" ] || FLAVOUR=generic
KARCH=$SYS_ARCH
[ $KARCH = i686 ] && KARCH=i386
[ $KARCH = x86_64 ] && KARCH=amd64
[ $KARCH = arm ] && KARCH=armel
KFLAVOUR=$1

[ "$(sed 's/^[a-zA-Z0-9]\+$//' <<<$KFLAVOUR)" ] && {
    echo
    echo_ \
"Warning: flavour '${KFLAVOUR}'
         flavour should contain only alphanumeric characters."
}

echo
echo_ \
"Details about the running kernel:
  Version:      ${SYS_RELEASE}
  Architecture: ${SYS_ARCH} (${KARCH})
  Flavour:      ${SYS_FLAVOUR}

Flavour to be created: ${KFLAVOUR}
Default flavour:       ${FLAVOUR}"


#_ Select configuration tool
function is_installed()
{
    dpkg -s $1 >/dev/null 2>&1 &&
        [ $(dpkg -s $1 | grep '^Status:' | awk '{print $4}') == 'installed' ]
}

if is_installed libqt4-dev; then
    CONFIGPRG=xconfig
elif is_installed libqt3-mt-dev; then
    CONFIGPRG=xconfig
elif is_installed libgtk2.0-dev && is_installed libglib2.0-dev && is_installed libglade2-dev; then
    CONFIGPRG=gconfig
elif is_installed libncurses5-dev; then
    CONFIGPRG=menuconfig
else
    CONFIGPRG=config
fi
echo
echo_ \
"  config        - line-oriented console tool
  menuconfig    - menu-based console tool
  xconfig       - Qt program
  gconfig       - GTK program
Use for configuration: ${CONFIGPRG}"


#_ Collect information from source code
if ubuntu_release le 8.04; then
    printenv=$(./$DEBIAN/rules printenv)
else
    printenv=$(make DEBIAN=$DEBIAN -f $DEBIAN2/rules.d/0-common-vars.mk -f <(echo '
printenv:
        @echo "release           = $(release)"
        @echo "revision          = $(revision)"
        @echo "prev_revision     = $(prev_revision)"
        @echo "abinum            = $(abinum)"
        @echo "CONCURRENCY_LEVEL = $(CONCURRENCY_LEVEL)"
' | sed 's/^        /\t/') printenv)
fi
KRELEASE=$(echo "$printenv" | grep '^release\>' | awk '{print $3}')
KREVISION=$(echo "$printenv" | grep '^revision\>' | awk '{print $3}')
KPREVISION=$(echo "$printenv" | grep '^prev_revision\>' | awk '{print $3}')
KABINUM=$(echo "$printenv" | grep '^abinum\>' | awk '{print $3}')
CONCURRENCY_LEVEL=$(echo "$printenv" | grep '^CONCURRENCY_LEVEL\>' | awk '{print $3}')
UPSTREAM_VERSION=$(make kernelversion)
echo
echo_ \
"Details about kernel source:
  Kernel Version:    ${UPSTREAM_VERSION}
  Release:           ${KRELEASE}
  Ubuntu Revision:   ${KREVISION}
  Previous Revision: ${KPREVISION}
  ABI-Number:        ${KABINUM}
CONCURRENCY_LEVEL: ${CONCURRENCY_LEVEL}"


#_ Test some directories and files
for dir in  $DEBIAN/config/$KARCH \
            $DEBIAN/abi/$KRELEASE-$KPREVISION \
            $DEBIAN2/rules.d/0-common-vars.mk \
            $DEBIAN2/scripts/misc/getabis; do
    [ -e $dir ] || {
        echo_ "'${dir}' does not exist"
        query_git_reset
        exit 1
    }
done


####_ From this point the script is interactive

####_ Reset directory

query_git_reset

####_ Kernel configuration

echo
#_ 1) .config
if [ -f .config ]; then
    echo_ "Configuration: .config"
#_ 2) Backup configuration
elif [ -f ../config-$KRELEASE-$KABINUM-$KFLAVOUR ]; then
    echo_ "Configuration: ../config-$KRELEASE-$KABINUM-$KFLAVOUR"
    cat ../config-$KRELEASE-$KABINUM-$KFLAVOUR > .config
#_ 3) Standard configuration for defaul flavour (Hardy-Jaunty)
elif ubuntu_release lt 9.10 && [ -f $DEBIAN/config/$KARCH/config.$FLAVOUR ]; then
    echo_ "Configuration: $DEBIAN/config/$KARCH/config.$FLAVOUR"
    cat $DEBIAN/config/$KARCH/config >.config
    cat $DEBIAN/config/$KARCH/config.$FLAVOUR >>.config
#_ 3) Standard configuration for default flavour (Karmic-?)
elif ubuntu_release ge 9.10 && [ -f $DEBIAN/config/$KARCH/config.flavour.$FLAVOUR ]; then
    echo_ "Configuration: $DEBIAN/config/$KARCH/config.flavour.$FLAVOUR"
    cat $DEBIAN/config/config.common.ubuntu >.config
    cat $DEBIAN/config/$KARCH/config.common.$KARCH >>.config
    cat $DEBIAN/config/$KARCH/config.flavour.$FLAVOUR >>.config
#_ give up
else
    echo_ "No suitable configuration file found."
    query_git_reset
    exit 1
fi

echo
echo_ "To edit the configuration with other make targets,
the script can be interrupted here."
read_msg "Edit kernel configuration (make $CONFIGPRG)" && {
    if [ $CONFIGPRG ]; then
        make $CONFIGPRG
    else
        echo_ 'Packages for configuration tool not installed'
    fi
}

echo
echo_ "Create copy of the configuration in '../config-$KRELEASE-$KABINUM-$KFLAVOUR'"
mv .config ../config-$KRELEASE-$KABINUM-$KFLAVOUR
#_ Cleaning up (some files hinder compiling)
rm -r include/config/


####_ Create flavour

function deb_control_insert_flavour()
{
    #_ Parameter: $1=original_flavour $2=new_flavour
    python -c "
while True: #loop over Packages
    package = []
    package2 = []
    matched = 0
    while True: #loop over lines
        try:
            line = raw_input()
        except EOFError:
            line = None
            break
        package.append(line)
        if line == '':
            package2.append(line)
            break
        if line.startswith('Package:') and line.endswith('-$1'):
            package2.append(line.replace('-$1','-$2'))
            matched = 1
        elif line.startswith('Package:') and line.endswith('-$2'):
            matched = -1
        else:
            package2.append(line)
    if matched >= 0:
        for l in package:
            print l
    if matched > 0:
        for l in package2:
            print l
    if line is None:
        break
"
}


read_msg 'Create kernel flavour' && {
    if ubuntu_release le 8.04; then
        mkdir debian/binary-custom.d/$KFLAVOUR
        touch debian/binary-custom.d/$KFLAVOUR/rules
        touch debian/binary-custom.d/$KFLAVOUR/vars
        mkdir debian/binary-custom.d/$KFLAVOUR/patchset
        
        deb_control_insert_flavour generic $KFLAVOUR <$DEBIAN/control >$DEBIAN/control.tmp &&
            mv $DEBIAN/control.tmp $DEBIAN/control
        deb_control_insert_flavour generic $KFLAVOUR <$DEBIAN/control.stub >$DEBIAN/control.stub.tmp &&
            mv $DEBIAN/control.stub.tmp $DEBIAN/control.stub
    else
        flavour_dir=$DEBIAN/abi/$KRELEASE-$KPREVISION/$KARCH
        cp $flavour_dir/$FLAVOUR         $flavour_dir/$KFLAVOUR
        cp $flavour_dir/$FLAVOUR.modules $flavour_dir/$KFLAVOUR.modules
        
        if ubuntu_release le 9.10; then
            sed -i "/getall $KARCH/s/ $KFLAVOUR//g"     $DEBIAN2/scripts/misc/getabis
            sed -i "/getall $KARCH/s/^.*$/& $KFLAVOUR/" $DEBIAN2/scripts/misc/getabis
        else
            sed -i "/getall $KARCH/s/ $KFLAVOUR//g"     $DEBIAN/etc/getabis
            sed -i "/getall $KARCH/s/^.*$/& $KFLAVOUR/" $DEBIAN/etc/getabis
        fi
        
        sed -i "/flavours/s/ $KFLAVOUR//g"      $DEBIAN/rules.d/$KARCH.mk
        sed -i "/flavours/s/^.*$/& $KFLAVOUR/"  $DEBIAN/rules.d/$KARCH.mk
        
        cp $DEBIAN/control.d/vars.$FLAVOUR $DEBIAN/control.d/vars.$KFLAVOUR
    fi
}

read_msg 'Update configuration' && {
    if ubuntu_release le 8.04; then
        cp ../config-$KRELEASE-$KABINUM-$KFLAVOUR debian/binary-custom.d/$KFLAVOUR/config.$KARCH
    elif ubuntu_release le 9.04; then
        cp ../config-$KRELEASE-$KABINUM-$KFLAVOUR $DEBIAN/config/$KARCH/config.$KFLAVOUR
    else
        cp ../config-$KRELEASE-$KABINUM-$KFLAVOUR $DEBIAN/config/$KARCH/config.flavour.$KFLAVOUR
    fi
    fakeroot debian/rules clean
    debian/rules updateconfigs
}

####_ Compiling

read_msg 'Compiling' && {
    chmod +x debian/rules
    if ubuntu_release le 8.04; then
        AUTOBUILD=1 NOEXTRAS=1 skipabi=true skipmodule=true fakeroot debian/rules custom-binary-$KFLAVOUR
    else
        fakeroot debian/rules clean
        AUTOBUILD=1 NOEXTRAS=1 skipabi=true skipmodule=true fakeroot debian/rules binary-$KFLAVOUR
        AUTOBUILD=1 NOEXTRAS=1 skipabi=true skipmodule=true fakeroot debian/rules binary-indep 
    fi
}

####_ List results

echo
ls -ld ../*$KRELEASE-$KABINUM*
