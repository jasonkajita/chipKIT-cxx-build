#!/bin/bash

MCHP_RESOURCE=A
MCHP_VERSION=1.30


MCHP_RESOURCE="\'${MCHP_RESOURCE}\'"
export MCHP_VERSION
export MCHP_RESOURCE

##############

SUPPORT_HOSTED_LIBSTDCXX="--disable-hosted-libstdcxx"
SUPPORT_SJLJ_EXCEPTIONS="--enable-sjlj-exceptions"

NEWLIB_CONFIGURE_FLAGS="--target=pic32mx --enable-target-optspace --disable-threads --enable-static --disable-libmudflap --disable-libssp --disable-libstdcxx-pch --disable-hosted-libstdcxx --with-arch=pic32mx --enable-sgxx-sde-multilib --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --disable-nls --with-dwarf2 --disable-bootstrap --enable-obsolete --enable-sjlj-exceptions --disable-__cxa_atexit --disable-libfortran --with-bugurl=http://chipkit.org/forum --disable-libgomp --disable-libffi --program-prefix=pic32- --with-newlib --enable-newlib-io-long-long --disable-newlib-multithread --disable-libgloss --disable-newlib-supplied-syscalls --disable-nls --disable-libunwind-exceptions --enable-libstdcxx-allocator=malloc --disable-newlib-atexit-alloc --disable-libstdcxx-verbose -enable-lto --enable-fixed-point --enable-obsolete --disable-sim --disable-checking"

GCC_CONFIGURE_FLAGS="--enable-target-optspace --disable-libunwind-exceptions --enable-sjlj-exceptions --enable-libstdcxx-allocator=malloc --disable-hosted-libstdcxx --target=pic32mx --enable-target-optspace --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --enable-sgxx-sde-multilibs --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --enable-static --with-newlib --disable-nls --disable-libgomp --without-headers --disable-libffi --disable-bootstrap --disable-decimal-float --disable-libquadmath --disable-__cxa_atexit --disable-libfortran --disable-libstdcxx-pch --with-dwarf2 --disable-libstdcxx-verbose --enable-poison-system-directories --enable-lto --enable-fixed-point --enable-obsolete --disable-sim --disable-checking --disable-gofast --with-bugurl=http://www.chipkit.net/forum"

CXX_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET"

CFLAGS_FOR_TARGET="-G 0 -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET"

CCASFLAGS_FOR_TARGET="-G 0 -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET"

XGCC_FLAGS_FOR_TARGET="-G 0 -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET"

echo "$BASH_SOURCE START BUILD..."
# Figure out which MinGW compiler we have. Candidates are:
# i586-mingw32msvc-gcc   (Ubuntu)
# i386-mingw32-gcc       (Fedora)
if [ "x$MINGW32_HOST_PREFIX" == "x" ]; then
 MINGW_GCC=`which i586-mingw32-gcc`
 if [ "x$MINGW_GCC" != "x" ] ; then
  MINGW32_HOST_PREFIX=i586-mingw32
 else
  MINGW32_HOST_PREFIX=i586-mingw32msvc
 fi
 unset MINGW_GCC
fi

unset ARMLINUX32_HOST_PREFIX
ARMLINUX32_HOST_PREFIX=arm-none-linux-gnueabi

# Does notify-send exist?
if [ "x$NOTIFY_SEND" == "x" ] ; then
    WHICH_NOTIFY_SEND=`which notify-send`
    if [ "x$WHICH_NOTIFY_SEND" == "x" ] ; then
        unset NOTIFY_SEND
    else
        NOTIFY_SEND=notify-send
    fi
    unset WHICH_NOTIFY_SEND
fi

# Does growlnotify exist?
if [ "x$GROWL_SEND" == "x" ] ; then
    WHICH_GROWLSEND=`which growlnotify`
    if [ "x$WHICH_GROWLSEND" == "x" ] ; then
        unset GROWL_SEND
    else
        GROWL_SEND="growlnotify"
    fi
    unset WHICH_GROWLSEND
fi

DATE=`date +%Y%m%d`
TIME=`date +%H%M`
TVAL=master
BUILD=chipKIT-cxx
TAG=master
FULL_ONLY=no
CHECKOUT="yes"
SKIPLIBS=""
SKIPNATIVE=""
SKIPLINUX32=""
SKIPWIN32=""
SKIPARMLINUX=""
SKIPGRAPHITE="yes"
SKIPMULTIPLENEWLIB="yes"
SKIPPLIBIMAGE="yes"
NATIVEIMAGE=`uname`
NATIVEIMAGE+="-image"
echo "Native image is $NATIVEIMAGE"

NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm"
RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib"
STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"
AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"
AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as"
LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld"
GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc"
CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc"
CFLAGS="-Os -DCHIPKIT_PIC32"

# Process the arguments
while getopts b:FNt:Q opt
do
    case "$opt" in
      t)
        TVAL=$OPTARG
        TAG="$TVAL"
        ;;
      b)
        TVAL=$OPTARG
        TAG="$TVAL"
        BUILD=pic32-$TVAL-$DATE
        ;;
      N)
        cdecho "No checkout"
        CHECKOUT="no"
        ;;
     \?) show_usage ;;
    esac
done

# Avoid double-date build (YYYYMMDD-YYYYMMDD)

if [[ ${TVAL%%$DATE} = $TVAL ]]; then
    BUILD=chipKIT-cxx-$TVAL
else
    BUILD=chipKIT-cxx-$TVAL
fi

LOGFILE=`pwd`/$BUILD.log

WORKING_DIR=`pwd`/$BUILD
echo WORKING DIR $WORKING_DIR


show_usage()
    {
        # Shows the usage screen
        echo "USAGE:  $0 [-t <tag> | -?]"
        echo "  -b <tag>      Specify the branch for which you would like to build"
        echo "  -t <tag>      Specify the tag for which you would like to build"
        echo "  -N            No svn checkout build only"
        echo "  -Q            Show svn checkout (no quiet)"
        echo "  -?            Show this usage message"
        exit 1
    }

####
# assert_success()
#   If the first parameter is non-zero, print the second parameter
#   and exit the script
####
function assert_success ()
    {
        local RESULT=$1
        local MESSAGE=$2
        if [ $RESULT != 0 ]
        then
            echo "$MESSAGE ($RESULT)"
            if [ "x$GROWL_SEND" != "x" ] ; then
                echo "$GROWL_SEND -s -p1 -t $BASH_SOURCE -m $MESSAGE"
                $GROWL_SEND "-s" "-p1" "-t" "$BASH_SOURCE" "-m" "$MESSAGE"
            elif [ "x$NOTIFY_SEND" != "x" ] ; then
                $NOTIFY_SEND "$MESSAGE" "Build Error"
            fi
            echo "$MESSAGE ($RESULT)" >> $LOGFILE
            unset GCC_FOR_TARGET
            unset CC_FOR_TARGET
            unset CXX_FOR_TARGET
            unset GXX_FOR_TARGET
            unset CPP_FOR_TARGET
            unset CC_FOR_BUILD
            unset CXX_FOR_BUILD
            unset CC
            unset CPP
            unset CXX
            unset LD
            unset AR
            exit $RESULT
        fi
    }

function status_update ()
    {
        local MESSAGE=$1
        if [ "x$GROWL_SEND" != "x" ] ; then
            $GROWL_SEND "-t" "$BASH_SOURCE:" "-m" "$MESSAGE"
        elif [ "x$NOTIFY_SEND" != "x" ] ; then
            $NOTIFY_SEND "$MESSAGE" "$BASH_SOURCE"
        fi
        echo `date` $MESSAGE >> $LOGFILE

    }

### build_xc32_sh()
### $1 name of the directory
### $2 any extra arguments for the make
function build_xc32_sh()
    {
        mkdir -p "$1/pic32-tools/bin/bin"

        XC32_SH_SRC=${WORKING_DIR}/pic30-sh
        cd $XC32_SH_SRC/bin
        echo `pwd`

        #clean
        #necessary since there isn't a separate build directory
        # COMMAND="make clean"
        make clean

        make xc32 $2
        # COMMAND="make xc32 $2"

        #install
        #No need to add the /bin for call below
        export XC32_INSTALL="$1/pic32-tools"
        # COMMAND="make chipkit-install $2"
        make chipkit-install $2

        unset XC32_INSTALL

        cd $WORKING_DIR
    }

### Main script body


# Create the working directory

echo `date` " START PIC32 build." > $LOGFILE
echo `date` " Creating build in $WORKING_DIR..." >> $LOGFILE
if [ -e $WORKING_DIR ]
then
    echo `date` " $WORKING_DIR already exists..." >> $LOGFILE
else
    mkdir $WORKING_DIR
    assert_success $? "ERROR: creating directory $WORKING_DIR"
fi

cd $WORKING_DIR

# Check out the source code
GITHUB_ACCOUNT=jasonkajita
GITHUB_CXX_BRANCH=dev_1_43_update
GIT_ROOT=https://api.github.com/repos/$GITHUB_ACCOUNT
GIT_PIC32_NEWLIB_REPO=https://api.github.com/repos/$GITHUB_ACCOUNT/pic32-newlib/tarball/master
GIT_CHIPKIT_CXX_REPO=$GIT_ROOT/chipKIT-cxx/tarball/$GITHUB_CXX_BRANCH
GIT_PIC32_PART_SUPPORT_REPO=$GIT_ROOT/pic32-part-support/tarball/master
GIT_PIC32_SH_REPO_ROOT=$GIT_ROOT/pic32-sh
GIT_PIC32_FDLIBM_REPO_ROOT=$GIT_ROOT/pic32-fdlibm

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_PIC32_NEWLIB_REPO"
    echo `date` " Downloading source from $GIT_PIC32_NEWLIB_REPO..." >> $LOGFILE
    if [ -e pic32-newlib ]
    then
        rm -rf pic32-newlib
    fi
    curl -L $GIT_PIC32_NEWLIB_REPO | tar zx
    assert_success $? "ERROR: Downloading source from $GIT_PIC32_NEWLIB_REPO"
    mv *-pic32-newlib-* pic32-newlib
    assert_success $? "Normalize pic32-newlib directory name"
fi

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_PIC32_PART_SUPPORT_REPO."
    echo `date` "Downloading part support from $GIT_PIC32_PART_SUPPORT_REPO..." >> $LOGFILE
    if [ -e pic32-part-support ]
    then
        rm -rf pic32-part-support
    fi
    curl -L $GIT_PIC32_PART_SUPPORT_REPO | tar zx
    assert_success $? "Downloading part support from $GIT_PIC32_PART_SUPPORT_REPO"
    mv *-pic32-part-support-* pic32-part-support
    assert_success $? "Normalize pic32-part-support directory name"
fi

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_CHIPKIT_CXX_REPO."
    echo `date` "Downloading compiler source from $GIT_CHIPKIT_CXX_REPO..." >> $LOGFILE
    if [ -e chipKIT-cxx ]
    then
        rm -rf chipKIT-cxx
    fi
    curl -L $GIT_CHIPKIT_CXX_REPO | tar zx
    assert_success $? "Downloading compiler source from $GIT_CHIPKIT_CXX_REPO"
    mv *-chipKIT-cxx-* chipKIT-cxx
    assert_success $? "Normalize chipKIT-cxx directory name"
fi

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_PIC32_SH_REPO_ROOT"
    echo `date` " Downloading source from $GIT_PIC32_SH_REPO_ROOT..."
    if [ -e pic30-sh ]
    then
        rm -rf pic30-sh
    fi
    curl -L $GIT_PIC32_SH_REPO_ROOT/tarball/$TAG | tar zx
    assert_success $? "ERROR: Downloading source from $GIT_PIC32_SH_REPO_ROOT"
    mv *-pic32-sh-* pic30-sh
    assert_success $? "Normalize pic32-sh directory name"
fi

if [ "$CHECKOUT" = "yes" ]
then
    echo "Downloading $GIT_PIC32_FDLIBM_REPO_ROOT"
    echo `date` " Downloading source from $GIT_PIC32_FDLIBM_REPO_ROOT..."
    if [ -e fdlibm ]
    then
        rm -rf fdlibm
    fi
    curl -L $GIT_PIC32_FDLIBM_REPO_ROOT/tarball/$TAG | tar zx
    assert_success $? "ERROR: Downloading source from $GIT_PIC32_FDLIBM_REPO_ROOT"
    mv *-pic32-fdlibm-* fdlibm
    assert_success $? "Normalize pic32-fdlibm directory name"
fi


if [ "x$NATIVEIMAGE" == "xDarwin-image" ]
then
    LINUX32IMAGE="Linux32-image"

    # Figure out which Linux compiler we have.
    if [ "x$LINUX32_HOST_PREFIX" == "x" ]; then
        LINUX_GCC=`which i586-pc-linux-gcc`
        if [ "x$LINUX_GCC" == "x" ] ; then
            LINUX32_HOST_PREFIX=i386-linux
        else
            LINUX32_HOST_PREFIX=i586-pc-linux
        fi
        unset LINUX_GCC
    fi
    BUILDMACHINE="--build=i686-apple-darwin10"
    if [ -e "/Developer-old" ]
    then
        DEVELOPERDIR="/Developer-old"
    else
        DEVELOPERDIR="/Developer"
    fi

    if [ "x$SKIPNATIVE" == "x" ] ; then

        HOSTMACHINE="--host=i686-apple-darwin10"
        COMPATIBILITY_FLAGS="-isysroot $DEVELOPERDIR/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -m32 -arch i386 -I$DEVELOPERDIR/SDKs/MacOSX10.5.sdk/usr/include/malloc"
        export CXX_FOR_BUILD="$DEVELOPERDIR/usr/bin/g++-4.2 $COMPATIBILITY_FLAGS"
        export CC_FOR_BUILD="$DEVELOPERDIR/usr/bin/gcc-4.2 $COMPATIBILITY_FLAGS"
        export CC="$DEVELOPERDIR/usr/bin/gcc-4.2 $COMPATIBILITY_FLAGS"
        export CPP="$DEVELOPERDIR/usr/bin/cpp-4.2 $COMPATIBILITY_FLAGS"
        export CXX="$DEVELOPERDIR/usr/bin/g++-4.2 $COMPATIBILITY_FLAGS"
        export LD="$DEVELOPERDIR/usr/bin/gcc-4.2 $COMPATIBILITY_FLAGS"
        export AR="$DEVELOPERDIR/usr/bin/ar"
    fi  # SKIPNATIVE
    LIBHOST=""
else
    LINUX32IMAGE=""
    LINUX32_HOST_PREFIX=""
    HOSTMACHINE=""
    BUILDMACHINE=""
    LIBHOST="--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"
fi

cd pic32-part-support

# Install headers into cross compiler's install image directory
echo "Making library headers for cross-compiler"
echo `date` "Making library headers for cross compiler's install image..." >> $LOGFILE

echo "make DESTROOT=\"$WORKING_DIR/$NATIVEIMAGE/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's $NATIVEIMAGE install image directory"

if [ "x$LINUX32IMAGE" != "x" ] ; then
    echo "make DESTROOT=\"$WORKING_DIR/$LINUX32IMAGE/pic32-tools\" install-headers"
    make DESTROOT="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" install-headers
    assert_success $? "ERROR: Making headers into cross compiler's $LINUXIMAGE install image directory"
fi

echo "make DESTROOT=\"$WORKING_DIR/export-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/export-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's export-image install image directory"

echo "make DESTROOT=\"$WORKING_DIR/win32-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/win32-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's win32-image install image directory"

echo "make DESTROOT=\"$WORKING_DIR/arm-linux-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/arm-linux-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's arm-linux-image install image directory"

if [ "x$LINUX32IMAGE" != "x" ]; then
    make DESTROOT="$WORKING_DIR/$LINUX32IMAGE" install-headers
    assert_success $? "ERROR: Making headers into cross compiler's $LINUX32IMAGE install image directory"
fi

# Install fdlibm headers
cd $WORKING_DIR/fdlibm/src/xc32

echo "Making fdlibm headers for cross-compiler"
echo `date` "Making fdlibm library headers for cross compiler's install image..." >> $LOGFILE

echo "make DESTROOT=\"$WORKING_DIR/$NATIVEIMAGE/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's $NATIVEIMAGE install image directory"

if [ "x$LINUX32IMAGE" != "x" ] ; then
    echo "make DESTROOT=\"$WORKING_DIR/$LINUX32IMAGE/pic32-tools\" install-headers"
    make DESTROOT="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" install-headers
    assert_success $? "ERROR: Making headers into cross compiler's $LINUXIMAGE install image directory"
fi

echo "make DESTROOT=\"$WORKING_DIR/export-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/export-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's export-image install image directory"

echo "make DESTROOT=\"$WORKING_DIR/win32-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/win32-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's win32-image install image directory"

echo "make DESTROOT=\"$WORKING_DIR/arm-linux-image/pic32-tools\" install-headers"
make DESTROOT="$WORKING_DIR/arm-linux-image/pic32-tools" install-headers
assert_success $? "ERROR: Making headers into cross compiler's arm-linux-image install image directory"

cd $WORKING_DIR

if [ "x$SKIPNATIVE" == "x" ] ; then

    build_xc32_sh "$WORKING_DIR/$NATIVEIMAGE"

    # Build native cross compiler
    echo `date` " Creating cross build in $WORKING_DIR/native-build..." >> $LOGFILE

    status_update "Beginning native pic32 build"

    if [ -e native-build ]
    then
        rm -rf native-build
    fi
    mkdir native-build
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build"

    cd native-build

    if [ -e binutils ]
    then
        rm -rf binutils
    fi
    mkdir binutils
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/binutils"

    cd binutils

    # Configure cross binutils
    echo `date` " Configuring cross binutils build in $WORKING_DIR/native-build..." >> $LOGFILE
    ../../chipKIT-cxx/src48x/binutils/configure $HOSTMACHINE --target=pic32mx --prefix="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" --bindir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --disable-nls --disable-tui --disable-gdbtk --disable-shared --enable-static --disable-threads --disable-bootstrap --with-dwarf2 --enable-multilib --without-newlib --disable-sim --with-lib-path=: --enable-poison-system-directories --program-prefix=pic32- --with-bugurl=http://chipkit.net/forum/ --disable-werror

    assert_success $? "ERROR: configuring cross binutils build"

    # Make cross binutils and install it
    echo `date` " Making all in $WORKING_DIR/native-build/binutils and installing..." >> $LOGFILE
    make CFLAGS="-O2 -DCHIPKIT_PIC32 -DMCHP_VERSION=${MCHP_VERSION}" all -j4
    assert_success $? "ERROR: making/installing cross binutils build"
    make install
    assert_success $? "ERROR: making/installing cross binutils build"

    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm"
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib"
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as"
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld"

    cd ..

    if [ -e gmp ]
    then
        rm -rf gmp
    fi
    mkdir gmp
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gmp"

    cd gmp
    
    echo `date` " Configuring native gmp build in $WORKING_DIR/native-build/gmp..." >> $LOGFILE
    ../../chipKIT-cxx/src48x/gmp/configure $HOSTMACHINE $BUILDMACHINE --enable-cxx --prefix=$WORKING_DIR/native-build/host-libs --disable-shared --enable-static --disable-nls --with-gnu-ld --disable-debug --disable-rpath --enable-fft --enable-hash-synchronization > gmp-make-log.txt

    # Make native gmp and install it
    echo `date` " Making all in $WORKING_DIR/native-build/gmp and installing..." >> $LOGFILE
    make all -j4 >> gmp-make-log.txt
    assert_success $? "ERROR: making/installing gmp build"
    make install
    assert_success $? "ERROR: making/installing gmp build"

    cd ..

    if [ "x$SKIPGRAPHITE" == "x" ]; then
        if [ -e ppl ]
        then
            rm -rf ppl
        fi
        mkdir ppl
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/ppl"

        cd ppl
        echo `date` " Configuring native ppl build in $WORKING_DIR/native-build/ppl..." >> $LOGFILE
        ../../chipKIT-cxx/src48x/ppl/configure --prefix=$WORKING_DIR/native-build/host-libs --disable-shared --enable-static --with-gnu-ld $HOSTMACHINE --target=pic32mx --disable-nls --with-libgmp-prefix=$WORKING_DIR/native-build/host-libs --with-gmp=$WORKING_DIR/native-build/host-libs

        # Make native ppl and install it
        echo `date` " Making all in $WORKING_DIR/native-build/ppl and installing..." >> $LOGFILE
        make all -j4 
        assert_success $? "ERROR: making/installing ppl build"
        make install
        assert_success $? "ERROR: making/installing ppl build"

        cd ..

        USE_PPL="--with-ppl=$WORKING_DIR/native-build/host-libs --with-isl=$WORKING_DIR/native-build/host-libs"

        if [ -e cloog ]
        then
            rm -rf cloog
        fi
        mkdir cloog
        assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/cloog"

        cd cloog

        echo `date` " Configuring native cloog build in $WORKING_DIR/native-build/cloog..." >> $LOGFILE
        ../../chipKIT-cxx/src48x/cloog/configure $BUILDMACHINE --enable-optimization=speed --with-gnu-ld '--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm' --prefix=$WORKING_DIR/native-build/host-libs--with-gmp=$WORKING_DIR/native-build/host-libs --with-ppl=$WORKING_DIR/native-build/host-libs --target=pic32mx --disable-shared --enable-static --disable-shared

        # Make native cloog and install it
        echo `date` " Making all in $WORKING_DIR/native-build/cloog and installing..." >> $LOGFILE
        make all -j4
        assert_success $? "ERROR: making/installing cloog build"
        make install
        assert_success $? "ERROR: making/installing cloog build"

        cd ..
        USE_CLOOG="--with-cloog=$WORKING_DIR/native-build/host-libs"
    else
        USE_CLOOG="--without-cloog"
        USE_PPL="--without-isl"
    fi


    if [ -e libelf ]
    then
        rm -rf libelf
    fi
    mkdir libelf
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/libelf"

    cd libelf
    echo `date` " Configuring native libelf build in $WORKING_DIR/native-build/libelf..." >> $LOGFILE
    ../../chipKIT-cxx/src48x/libelf/configure  --prefix=$WORKING_DIR/native-build/host-libs $HOSTMACHINE --target=pic32mx --disable-shared --disable-debug --disable-nls

    # Make native libelf and install it
    echo `date` " Making all in $WORKING_DIR/native-build/libelf and installing..." >> $LOGFILE
    make all -j4
    assert_success $? "ERROR: making/installing libelf build"
    make install
    assert_success $? "ERROR: making/installing libelf build"
    cd ..

    if [ -e zlib ]
    then
        rm -rf zlib
    fi
    cp -r ../chipKIT-cxx/src48x/zlib .

    assert_success $? "ERROR: copy src48x/zlib directory to $WORKING_DIR/native-build/zlib"

    cd zlib
    echo `date` " Configuring native zlib build in $WORKING_DIR/native-build/zlib..." >> $LOGFILE
    ./configure --prefix=$WORKING_DIR/native-build/host-libs

    # Make native zlib and install it
    echo `date` " Making all in $WORKING_DIR/native-build/zlib and installing..." >> $LOGFILE
    make all -j4
    assert_success $? "ERROR: making/installing zlib build"
    make install
    assert_success $? "ERROR: making/installing zlib build"

    cd ..

    if [ -e gcc ]
    then
        rm -rf gcc
    fi
    mkdir gcc
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gcc"

    cd gcc

    # Configure cross compiler
    echo `date` " Configuring cross compiler build in $WORKING_DIR/native-build..." >> $LOGFILE
    echo AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" ../../chipKIT-cxx/src48x/gcc/configure --target=pic32mx --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --enable-sgxx-sde-multilibs --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --enable-static --with-newlib --disable-nls --disable-libgomp --without-headers --disable-libffi --disable-bootstrap --disable-decimal-float --disable-libquadmath --disable-__cxa_atexit --disable-libfortran --disable-libstdcxx-pch --prefix="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" --bindir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --with-dwarf2 --with-gmp="$WORKING_DIR/native-build/host-libs" $USE_CLOOG $USE_PPL "$LIBHOST" --enable-lto --enable-fixed-point --with-bugurl=http://chipkit.net/forum/  XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-enforce-eh-specs" --enable-cxx-flags="-fno-exceptions -ffunction-sections" $SUPPORT_SJLJ_EXCEPTIONS --enable-obsolete --disable-sim --disable-checking $SUPPORT_HOSTED_LIBSTDCXX > gcc-native-log.txt

    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" ../../chipKIT-cxx/src48x/gcc/configure --target=pic32mx --program-prefix=pic32- --disable-threads --disable-libmudflap --disable-libssp --enable-sgxx-sde-multilibs --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-shared --enable-static --with-newlib --disable-nls --disable-libgomp --without-headers --disable-libffi --disable-bootstrap --disable-decimal-float --disable-libquadmath --disable-__cxa_atexit --disable-libfortran --disable-libstdcxx-pch --prefix="$WORKING_DIR/$NATIVEIMAGE/pic32-tools" --bindir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --with-dwarf2 --with-gmp="$WORKING_DIR/native-build/host-libs" $USE_CLOOG $USE_PPL "$LIBHOST" --enable-lto --enable-fixed-point --with-bugurl=http://chipkit.net/forum/  XGCC_FLAGS_FOR_TARGET="-frtti -fexceptions -fno-enforce-eh-specs" CXXFLAGS="-g3" $SUPPORT_SJLJ_EXCEPTIONS --enable-obsolete --disable-sim --disable-checking $SUPPORT_HOSTED_LIBSTDCXX >> gcc-native-log.txt
    assert_success $? "ERROR: configuring cross build"

    # Make cross compiler and install it
    echo `date` " Making all in $WORKING_DIR/native-build/gcc and installing..." >> $LOGFILE
    make all-gcc CFLAGS="-O2 -DCHIPKIT_PIC32" CXXFLAGS="-g3 -DCHIPKIT_PIC32 -DTARGET_IS_PIC32MX" \
    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"  \
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"  \
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" -j2 >> gcc-native-log.txt
    make all-gcc CFLAGS="-O2 -DCHIPKIT_PIC32" CXXFLAGS="-g3 -DCHIPKIT_PIC32 -DTARGET_IS_PIC32MX" \
    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"  \
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"  \
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" -j2
    assert_success $? "ERROR: making/installing cross build all-gcc"

    make CFLAGS="-O2 -DCHIPKIT_PIC32 -DTARGET_IS_PIC32MX" CXXFLAGS="-O2 -DCHIPKIT_PIC32 -DTARGET_IS_PIC32MX" install-gcc
    assert_success $? "ERROR: making/installing cross build install-gcc"

    cd ..

    if [ -e newlib ]
    then
        rm -rf newlib
    fi
    mkdir newlib
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gcc"

    cd newlib
    status_update "Building newlib"

    #build newlib here
    GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../pic32-newlib/configure $NEWLIB_CONFIGURE_FLAGS  --prefix=$WORKING_DIR/$NATIVEIMAGE/pic32-tools --bindir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" CFLAGS_FOR_TARGET="-fno-short-double -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-short-double -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-short-double -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-short-double -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"
    assert_success $? "ERROR: Configure Newlib for native build"

    make all -j2 CFLAGS_FOR_TARGET="-fno-short-double -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-short-double -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-short-double -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"
    assert_success $? "ERROR: Make newlib for native build"
    make install
    assert_success $? "ERROR: Install newlib for native build"

    cd $WORKING_DIR
    if [ "x$NATIVEIMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" export-image/pic32-tools/ $NATIVEIMAGE/pic32-tools/
      assert_success $? "ERROR: Install newlib in $NATIVEIMAGE"
    fi
    if [ "x$INUX32IMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" export-image/pic32-tools/ $LINUX32IMAGE/pic32-tools/
      assert_success $? "ERROR: Install newlib in $LINUX32IMAGE"
    fi
    if [ -e win32-image ]
    then
      rsync -qavzC --include "*/" --include "*" export-image/pic32-tools/ win32-image/pic32-tools/
      assert_success $? "ERROR: Install newlib in win32-image"
    fi
    if [ -e arm-linux-image ]
    then
      rsync -qavzC --include "*/" --include "*" export-image/pic32-tools/ arm-linux-image/pic32-tools/
      assert_success $? "ERROR: Install newlib in arm-linux-image"
    fi
    cd native-build

    if [ -e gcc ]
    then
        rm -rf gcc
    fi
    mkdir gcc
    assert_success $? "ERROR: creating directory $WORKING_DIR/native-build/gcc"

    cd gcc

    GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../chipKIT-cxx/src48x/gcc/configure $GCC_CONFIGURE_FLAGS --prefix=$WORKING_DIR/$NATIVEIMAGE/pic32-tools --bindir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin" --with-gmp="$WORKING_DIR/native-build/host-libs" $USE_CLOOG $USE_PPL "$LIBHOST" CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" CFLAGS_FOR_BUILD="-Os"
    assert_success $? "ERROR: Configure gcc after Newlib for native build"

    make all \
    CXXFLAGS="$CXXFLAGS_FOR_TARGET -Os -DCHIPKIT_PIC32" \
    NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
    RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
    STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip"  \
    AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar"  \
    AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
    LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" -j2
    assert_success $? "ERROR: making/installing cross build all"
    make install
    assert_success $? "ERROR: making/installing cross build install"

    status_update "Cross build complete"

    cd ../..

    # strip native-image
    cd $NATIVEIMAGE/pic32-tools
    if [ "x$NATIVEIMAGE" == "xDarwin-image" ] ; then
        find . -type f -perm -g+x -follow | xargs file | grep Mach-O | cut -d: -f1 | xargs $DEVELOPERDIR/usr/bin/strip
    elif [ "x$LINUX32_HOST_PREFIX" != "x" ] ; then
        find . -type f -perm -g+x -follow | xargs file | grep ELF | cut -d: -f1 | xargs $LINUX32_HOST_PREFIX-strip
    fi
    cd $WORKING_DIR
    # end strip native-image

fi # skipping native


# end build native toolchain

unset  CC
unset  CPP
unset  CXX
unset  LD
unset  AR

# Set up path so that we can build the libraries and the win32 cross
# compiler using the cross compiler we just built
OLDPATH=$PATH
PATH=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin:$PATH

if [ "x$SKIPLIBS" == "x" ] ; then

    cd pic32-part-support

    # Build cross compiler libraries
    echo `date` " Making and installing cross-compiler libraries to $WORKING_DIR/$NATIVEIMAGE/pic32-tools..." >> $LOGFILE

    make DESTROOT=$WORKING_DIR/$NATIVEIMAGE/pic32-tools all
    assert_success $? "ERROR: making libraries for cross build"

    make DESTROOT=$WORKING_DIR/$NATIVEIMAGE/pic32-tools install -j2
    assert_success $? "ERROR: making libraries for $NATIVEIMAGE cross build"

    if [ "x$LINUX32IMAGE" != "x" ] ; then
        make DESTROOT="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" install -j2
        assert_success $? "ERROR: making libraries for linux32-image cross build"
    fi

    make DESTROOT="$WORKING_DIR/export-image/pic32-tools" install -j2
    assert_success $? "ERROR: making libraries for export-image cross build"
    make DESTROOT="$WORKING_DIR/win32-image/pic32-tools" install -j2
    assert_success $? "ERROR: making libraries for win32-image cross build"
    make DESTROOT="$WORKING_DIR/arm-linux-image/pic32-tools" install -j2
    assert_success $? "ERROR: making libraries for arm-linux-image cross build"

    status_update "cross-compiler library build complete"

    cd ..

    # Build and install fdlibm
    cd $WORKING_DIR/fdlibm/src/xc32

    # Build fdlibm once
    echo `date` " Making and installing cross-compiler fdlibm libraries to $WORKING_DIR/$NATIVEIMAGE..." >> $LOGFILE
    make DESTROOT=$WORKING_DIR/$NATIVEIMAGE/pic32-tools all
    assert_success $? "ERROR: making fdlibm  libraries for cross build"

    # Then install
    make DESTROOT=$WORKING_DIR/$NATIVEIMAGE/pic32-tools install -j2
    assert_success $? "ERROR: making installing fdlibm for $NATIVEIMAGE cross build"

    if [ "x$LINUX32IMAGE" != "x" ] ; then
        make DESTROOT="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" install -j2
        assert_success $? "ERROR: making fdlibm libraries for Linux32-image cross build"
    fi
    make DESTROOT="$WORKING_DIR/export-image/pic32-tools" install -j2
    assert_success $? "ERROR: making fdlibm libraries for export-image cross build"

    make DESTROOT="$WORKING_DIR/win32-image/pic32-tools" install -j2
    assert_success $? "ERROR: making fdlibm libraries for win32-image cross build"

    make DESTROOT="$WORKING_DIR/arm-linux-image/pic32-tools" install -j2
    assert_success $? "ERROR: making fdlibm libraries for arm-linux-image cross build"

    status_update "cross-compiler fdlibm library build complete"

fi # skip library build

# Build linux compiler

if [ "x$SKIPLINUX32" == "x" ] ; then

    if [ "x$LINUX32IMAGE" != "x" ] ; then
        
        unset CC
        unset CPP
        unset CXX

        build_xc32_sh "$WORKING_DIR/$LINUX32IMAGE" "TARGET=linux"

        echo `date` " Creating linux cross build in $WORKING_DIR/linux32-build..." >> $LOGFILE
        cd $WORKING_DIR
        if [ -e linux32-build ]
        then
            rm -rf linux32-build
        fi
        mkdir linux32-build
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build"

        cd linux32-build

        if [ -e binutils ]
        then
            rm -rf binutils
        fi
        mkdir binutils
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/binutils"

        cd binutils

        # Configure linux-cross binutils
        echo `date` " Configuring linux32 binutils build in $WORKING_DIR/linux32-build..." >> $LOGFILE
        ../../chipKIT-cxx/src48x/binutils/configure $BUILDMACHINE --target=pic32mx --prefix="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" --bindir="$WORKING_DIR/$LINUX32IMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$LINUX32IMAGE/pic32-tools/bin/bin" --host=$LINUX32_HOST_PREFIX --disable-nls --disable-tui --disable-gdbtk --disable-shared --enable-static --disable-threads --disable-bootstrap  --with-dwarf2 --enable-multilib --without-newlib --disable-sim --with-lib-path=: --enable-poison-system-directories --program-prefix=pic32- --with-bugurl=http://chipkit.net/forum/ --disable-werror
        assert_success $? "ERROR: configuring linux32 binutils build"

        # Make linux-cross binutils and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/binutils and installing..." >> $LOGFILE
        make all CFLAGS="-O2 -DCHIPKIT_PIC32 -DMCHP_VERSION=${MCHP_VERSION}" -j4
        assert_success $? "ERROR: making/installing linux32 Canadian-cross binutils build"
        make CFLAGS="-O2 -DCHIPKIT_PIC32" install
        assert_success $? "ERROR: making/installing linux32 Canadian-cross binutils build"

        cd ..

        if [ -e gmp ]
        then
            rm -rf gmp
        fi
        mkdir gmp
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/gmp"

        cd gmp

        echo `date` " Configuring linux gmp build in $WORKING_DIR/linux32-build/gmp..." >> $LOGFILE
        CFLAGS="-fexceptions" ../../chipKIT-cxx/src48x/gmp/configure --enable-cxx  --prefix=$WORKING_DIR/linux32-build/linux-libs --disable-shared --target=$LINUX32_HOST_PREFIX --host=$LINUX32_HOST_PREFIX --disable-nls --with-gnu-ld --disable-debug --disable-rpath --enable-fft --enable-hash-synchronization "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"

        # Make linux gmp and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/gmp and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing gmp build"
        make install
        assert_success $? "ERROR: making/installing gmp build"

        cd ..

        if [ "x$SKIPGRAPHITE" == "x" ]; then
            if [ -e ppl ]
            then
                rm -rf ppl
            fi
            mkdir ppl
            assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/ppl"

            cd ppl
            echo `date` " Configuring linux32 ppl build in $WORKING_DIR/linux32-build/ppl..." >> $LOGFILE
            ../../chipKIT-cxx/src48x/ppl/configure  --prefix=$WORKING_DIR/linux32-build/linux-libs --disable-shared --enable-static --with-gnu-ld --host=$LINUX32_HOST_PREFIX --target=pic32mx --disable-nls --with-libgmp-prefix=$WORKING_DIR/linux32-build/linux-libs --with-gmp=$WORKING_DIR/linux32-build/linux-libs

            # Make native ppl and install it
            echo `date` " Making all in $WORKING_DIR/linux32-build/ppl and installing..." >> $LOGFILE
            make all -j2
            assert_success $? "ERROR: making/installing ppl build"
            make install
            assert_success $? "ERROR: making/installing ppl build"

            cd ..

            if [ -e cloog ]
            then
                rm -rf cloog
            fi
            mkdir cloog
            assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/cloog"

            cd cloog

            echo `date` " Configuring linux cloog build in $WORKING_DIR/linux32-build/cloog..." >> $LOGFILE
            ../../chipKIT-cxx/src48x/cloog/configure $BUILDMACHINE --enable-optimization=speed --with-gnu-ld '--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm' --prefix=$WORKING_DIR/linux32-build/linux-libs --host=$LINUX32_HOST_PREFIX --with-gmp=$WORKING_DIR/linux32-build/linux-libs --with-ppl=$WORKING_DIR/linux32-build/linux-libs --target=pic32mx --disable-shared --enable-static --disable-shared

            # Make native cloog and install it
            echo `date` " Making all in $WORKING_DIR/linux32-build/cloog and installing..." >> $LOGFILE
            make all -j2
            assert_success $? "ERROR: making/installing cloog build"
            make install
            assert_success $? "ERROR: making/installing cloog build"

            cd ..
        else
            USE_CLOOG="--without-cloog"
            USE_PPL="--without-isl"
        fi

        if [ -e libelf ]
        then
            rm -rf libelf
        fi
        mkdir libelf
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/libelf"

        cd libelf
        echo `date` " Configuring native libelf build in $WORKING_DIR/linux32-build/libelf..." >> $LOGFILE
        ../../chipKIT-cxx/src48x/libelf/configure  --prefix=$WORKING_DIR/linux32-build/linux-libs --host=$LINUX32_HOST_PREFIX --target=pic32mx --disable-shared --disable-debug --disable-nls

        # Make native libelf and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/libelf and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing libelf build"
        make install
        assert_success $? "ERROR: making/installing libelf build"
        cd ..

        if [ -e zlib ]
        then
            rm -rf zlib
        fi
        cp -r ../chipKIT-cxx/src48x/zlib .
        assert_success $? "ERROR: copy src48x/zlib directory to $WORKING_DIR/linux32-build/zlib"

        cd zlib
        echo `date` " Configuring linux zlib build in $WORKING_DIR/linux32-build/zlib..." >> $LOGFILE
        CC=$LINUX32_HOST_PREFIX-gcc AR="$LINUX32_HOST_PREFIX-ar" RANLIB=$LINUX32_HOST_PREFIX-ranlib ./configure --prefix=$WORKING_DIR/linux32-build/linux-libs

        # Make linux zlib and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/zlib and installing..." >> $LOGFILE
        make all -j2
        assert_success $? "ERROR: making/installing zlib build - all"
        make install
        assert_success $? "ERROR: making/installing zlib build - install"
        cd ..

        if [ -e gcc ]
        then
            rm -rf gcc
        fi
        mkdir gcc
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/gcc"

        cd gcc

        # Configure linux cross compiler
        echo `date` " Configuring linux cross compiler build in $WORKING_DIR/linux32-build..." >> $LOGFILE

        AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" CXX_FOR_TARGET='pic32-gcc' target_alias=pic32- ../../chipKIT-cxx/src48x/gcc/configure $GCC_CONFIGURE_FLAGS $BUILDMACHINE --prefix="$WORKING_DIR/$LINUX32IMAGE/pic32-tools" --bindir="$WORKING_DIR/$LINUX32IMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$LINUX32IMAGE/pic32-tools/bin/bin" --host=$LINUX32_HOST_PREFIX "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" --with-libelf=$WORKING_DIR/linux32-build/linux-libs --with-gmp=$WORKING_DIR/linux32-build/linux-libs $USE_CLOOG $USE_PPL CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" $SUPPORT_HOSTED_LIBSTDCXX
        assert_success $? "ERROR: configuring linux32 cross build"

        # Make cross compiler and install it
        echo `date` " Making all in $WORKING_DIR/linux32-build/gcc and installing..." >> $LOGFILE
        make CFLAGS="-O2 -DCHIPKIT_PIC32" CXXFLAGS="-O2 -DCHIPKIT_PIC32" all-gcc \
        NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
        RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
        STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip" \
        AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar" \
        AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
        LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" \
        GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" \
        CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" -j4
        assert_success $? "ERROR: making/installing linux Canadian-cross compiler build"
        make CFLAGS="-O2 -DCHIPKIT_PIC32" CXXFLAGS="-O2 -DCHIPKIT_PIC32" install-gcc
        assert_success $? "ERROR: making/installing linux Canadian-cross compiler build"

        cd ..

        if [ "xSKIPMULTIPLENEWLIB" != x ]; then

        if [ -e newlib ]
        then
            rm -rf newlib
        fi
        mkdir newlib
        assert_success $? "ERROR: creating directory $WORKING_DIR/LINUXIMAGE/newlib"

        cd newlib

        echo `date` " Configure newlib for $LINUX32IMAGE..." >> $LOGFILE

        #build newlib here
        GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../pic32-newlib/configure  $NEWLIB_CONFIGURE_FLAGS --prefix=$WORKING_DIR/$LINUX32IMAGE/pic32-tools --bindir="$WORKING_DIR/LINUX32IMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$LINUX32IMAGE/pic32-tools/bin/bin" CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"

        echo `date` " Make newlib for $LINUX32IMAGE..." >> $LOGFILE

         make all -j4 CFLAGS_FOR_TARGET="-DCHIPKIT_PIC32 -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"

        assert_success $? "ERROR: Make newlib for cross build"
        make install
        assert_success $? "ERROR: Install newlib for cross build"

        cd ..
        fi

        if [ -e gcc ]
        then
            rm -rf gcc
        fi
        mkdir gcc
        assert_success $? "ERROR: creating directory $WORKING_DIR/linux32-build/gcc"

        cd gcc

        echo `date` " Configure gcc after making Newlib for $LINUX32IMAGE..." >> $LOGFILE
        GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../chipKIT-cxx/src48x/gcc/configure $GCC_CONFIGURE_FLAGS $BUILDMACHINE --host=$LINUX32_HOST_PREFIX --prefix=$WORKING_DIR/$LINUX32IMAGE/pic32-tools --bindir="$WORKING_DIR/$LINUX32IMAGE/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/$LINUX32IMAGE/pic32-tools/bin/bin" --with-dwarf2 "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" --with-libelf=$WORKING_DIR/linux32-build/linux-libs --with-gmp=$WORKING_DIR/linux32-build/linux-libs $USE_CLOOG $USE_PPL CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" $SUPPORT_HOSTED_LIBSTDCXX
        assert_success $? "ERROR: configuring linux32 cross build 2"

        make CFLAGS="-O2 -DCHIPKIT_PIC32" CXXFLAGS="-O2 -DCHIPKIT_PIC32" all \
        GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld  -j4
        make CFLAGS="-O2 -DCHIPKIT_PIC32" CXXFLAGS="-O2 -DCHIPKIT_PIC32" install
        assert_success $? "ERROR: installing linux Canadian-cross compiler build"

        cd ../..
        status_update "Make linux32 Canadian cross build complete"

        unset CC
        unset CPP
        unset CXX

        # strip Linux32-image
        cd $WORKING_DIR/$LINUX32IMAGE/pic32-tools
        find ./bin -type f -perm -g+x -follow | xargs file | grep ELF | cut -d: -f1 | xargs $LINUX32_HOST_PREFIX-strip
        find ./pic32mx/bin -type f -perm -g+x -follow | xargs file | grep ELF | cut -d: -f1 | xargs $LINUX32_HOST_PREFIX-strip
        cd $WORKING_DIR

    fi
fi

unset CC
unset CPP
unset CXX

cd $WORKING_DIR

################ end build linux compiler ##############

################ Begin build win32 compiler ##############

if [ "x$SKIPWIN32" == "x" ] ; then

# Build xc32 shell
build_xc32_sh "$WORKING_DIR/win32-image" "TARGET=mingw"

# Build mingw32 cross compiler
echo `date` " Creating cross build in $WORKING_DIR/win32-build..." >> $LOGFILE
if [ -e win32-build ]
then
    rm -rf win32-build
fi
mkdir win32-build
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build"

cd win32-build

if [ -e binutils ]
then
    rm -rf binutils
fi
mkdir binutils
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/binutils"

cd binutils

# Configure mingw32-cross binutils
echo `date` " Configuring win32 binutils build in $WORKING_DIR/win32-build..." >> $LOGFILE
../../chipKIT-cxx/src48x/binutils/configure --target=pic32mx --prefix=$WORKING_DIR/win32-image/pic32-tools --bindir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" --host=$MINGW32_HOST_PREFIX --disable-nls --disable-tui --disable-gdbtk --disable-shared --enable-static --disable-threads --disable-bootstrap  --with-dwarf2 --enable-multilib --without-newlib --disable-sim --with-lib-path=: --enable-poison-system-directories --program-prefix=pic32- --with-bugurl=http://chipkit.net/forum/ --disable-werror
assert_success $? "ERROR: configuring win32 binutils build"

# Make MinGW32-cross binutils and install it
echo `date` " Making all in $WORKING_DIR/win32-build/binutils and installing..." >> $LOGFILE
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501 -DMCHP_VERSION=${MCHP_VERSION}" all -j4
assert_success $? "ERROR: making/installing win32 Canadian-cross binutils build"
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501 -DMCHP_VERSION=${MCHP_VERSION}" install
assert_success $? "ERROR: making/installing win32 Canadian-cross binutils build"
cd ..

if [ -e gmp ]
then
    rm -rf gmp
fi
mkdir gmp
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/gmp"

cd gmp

echo `date` " Configuring win32 gmp build in $WORKING_DIR/win32-build/gmp..." >> $LOGFILE
CPPFLAGS="-fexceptions" ../../chipKIT-cxx/src48x/gmp/configure --enable-cxx --prefix=$WORKING_DIR/win32-build/host-libs --disable-shared --host=$MINGW32_HOST_PREFIX --disable-nls --with-gnu-ld --disable-debug --disable-rpath --enable-fft "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"

# Make win32 gmp and install it
echo `date` " Making all in $WORKING_DIR/win32-build/gmp and installing..." >> $LOGFILE
make CPPFLAGS="-fexceptions" all -j
assert_success $? "ERROR: making/installing gmp build"
make install
assert_success $? "ERROR: making/installing gmp build"

cd ..

if [ "x$SKIPGRAPHITE" == "x" ]; then

    if [ -e ppl ]
    then
        rm -rf ppl
    fi
    mkdir ppl
    assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/ppl"

    cd ppl
    echo `date` " Configuring native ppl build in $WORKING_DIR/win32-build/ppl..." >> $LOGFILE
    ../../chipKIT-cxx/src48x/ppl/configure --prefix=$WORKING_DIR/win32-build/host-libs --disable-shared --enable-static --with-gnu-ld --host=$MINGW32_HOST_PREFIX --target=pic32mx --disable-nls --enable-optimization=speed --disable-rpath --with-gmp-=$WORKING_DIR/win32-build/host-libs --with-libgmp-prefix=$WORKING_DIR/win32-build/host-libs

    # Make native ppl and install it
    echo `date` " Making all in $WORKING_DIR/win32-build/ppl and installing..." >> $LOGFILE
    make all -j2
    assert_success $? "ERROR: making/installing ppl build"
    make install
    assert_success $? "ERROR: making/installing ppl build"

    cd ..

    if [ -e cloog ]
    then
        rm -rf cloog
    fi
    mkdir cloog
    assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/cloog"

    cd cloog

    echo `date` " Configuring win32 cloog build in $WORKING_DIR/win32-build/cloog..." >> $LOGFILE
    ../../chipKIT-cxx/src48x/cloog/configure $BUILDMACHINE --with-gnu-ld --prefix=$WORKING_DIR/win32-build/host-libs --host=$MINGW32_HOST_PREFIX --target=pic32mx --with-gmp=$WORKING_DIR/win32-build/host-libs --with-ppl=$WORKING_DIR/win32-build/host-libs --target=pic32mx --disable-shared --enable-static --disable-shared

    # Make native cloog and install it
    echo `date` " Making all in $WORKING_DIR/win32-build/cloog and installing..." >> $LOGFILE
    make all -j2
    assert_success $? "ERROR: making/installing cloog build"
    make install
    assert_success $? "ERROR: making/installing cloog build"

    cd ..
else
    USE_CLOOG="--without-cloog"
    USE_PPL="--without-isl"
fi

if [ -e libelf ]
then
    rm -rf libelf
fi
mkdir libelf
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/libelf"

cd libelf
echo `date` " Configuring native libelf build in $WORKING_DIR/win32-build/libelf..." >> $LOGFILE
GCC_FOR_TARGET='pic32-gcc' CC_FOR_TARGET='pic32-gcc' CPP_FOR_TARGET='pic32-g++' AS_FOR_TARGET=pic32-as LD_FOR_TARGET=pic32-ld CFLAGS_FOR_BUILD="-Os" ../../chipKIT-cxx/src48x/libelf/configure  --prefix=$WORKING_DIR/win32-build/host-libs --host=$MINGW32_HOST_PREFIX $BUILDMACHINE --target=pic32mx --disable-shared --disable-debug --disable-nls

# Make native libelf and install it
echo `date` " Making all in $WORKING_DIR/win32-build/libelf and installing..." >> $LOGFILE
make all -j4
assert_success $? "ERROR: making/installing libelf build"
make install
assert_success $? "ERROR: making/installing libelf build"
cd ..

if [ -e zlib ]
then
    rm -rf zlib
fi
cp -r ../chipKIT-cxx/src48x/zlib .
assert_success $? "ERROR: copy src48x/zlib directory to $WORKING_DIR/win32-build/zlib"

cd zlib
echo `date` " Configuring win32 zlib build in $WORKING_DIR/win32-build/zlib..." >> $LOGFILE
CC=$MINGW32_HOST_PREFIX-gcc AR="$MINGW32_HOST_PREFIX-ar" RANLIB=$MINGW32_HOST_PREFIX-ranlib ./configure --prefix=$WORKING_DIR/win32-build/host-libs

# Make win32 zlib and install it
echo `date` " Making all in $WORKING_DIR/win32-build/zlib and installing..." >> $LOGFILE
make all -j4
assert_success $? "ERROR: making/installing zlib build - all"
make install
assert_success $? "ERROR: making/installing zlib build - install"
cd ..

if [ -e gcc ]
then
    rm -rf gcc
fi
mkdir gcc
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/gcc"

cd gcc

# Configure win32 cross compiler
echo `date` " Configuring win32 cross compiler build in $WORKING_DIR/win32-build..." >> $LOGFILE

AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" CXX_FOR_TARGET='pic32-gcc' target_alias=pic32- ../../chipKIT-cxx/src48x/gcc/configure $GCC_CONFIGURE_FLAGS $BUILDMACHINE --host=$MINGW32_HOST_PREFIX "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm" --prefix=$WORKING_DIR/win32-image/pic32-tools --bindir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" --with-libelf=$WORKING_DIR/win32-build/host-libs --with-gmp=$WORKING_DIR/win32-build/host-libs $USE_CLOOG $USE_PPL CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" $SUPPORT_HOSTED_LIBSTDCXX

assert_success $? "ERROR: configuring win3232 cross build"

# Make cross compiler and install it
echo `date` " Making all in $WORKING_DIR/win32-build/gcc and installing..." >> $LOGFILE
make CFLAGS="-Os -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" CXXFLAGS="-Os -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all-gcc \
NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip" \
AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar" \
AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" \
GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" \
CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" -j4 CXXFLAGS="$CXXFLAGS_FOR_TARGET -Os -DCHIPKIT_PIC32"
assert_success $? "ERROR: making/installing win32 Canadian-cross compiler build"
make CFLAGS="-Os -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install-gcc
assert_success $? "ERROR: making/installing win32 Canadian-cross compiler build"

cd ..

if [ "xSKIPMULTIPLENEWLIB" != x ]; then

if [ -e newlib ]
then
    rm -rf newlib
fi
mkdir newlib
assert_success $? "ERROR: creating directory $WORKING_DIR/win32IMAGE/newlib"

cd newlib

echo `date` " Configure newlib for win32-image..." >> $LOGFILE

#build newlib here

GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../pic32-newlib/configure $NEWLIB_CONFIGURE_FLAGS --prefix=$WORKING_DIR/win32-image/pic32-tools --bindir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"

echo `date` " Make newlib for win32-image..." >> $LOGFILE

make all -j4 CFLAGS_FOR_TARGET="-DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501 -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"
assert_success $? "ERROR: Make newlib for cross build"
make install
assert_success $? "ERROR: Install newlib for cross build"

cd ..
fi

if [ -e gcc ]
then
    rm -rf gcc
fi
mkdir gcc
assert_success $? "ERROR: creating directory $WORKING_DIR/win32-build/gcc"

cd gcc

echo `date` " Configure gcc after making Newlib for win32-image..." >> $LOGFILE
GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../chipKIT-cxx/src48x/gcc/configure $GCC_CONFIGURE_FLAGS $BUILDMACHINE --host=$MINGW32_HOST_PREFIX --prefix=$WORKING_DIR/win32-image/pic32-tools --bindir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/win32-image/pic32-tools/bin/bin" --with-libelf=$WORKING_DIR/win32-build/host-libs --with-gmp=$WORKING_DIR/win32-build/host-libs $USE_CLOOG $USE_PPL CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" $SUPPORT_HOSTED_LIBSTDCXX
#"--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"
assert_success $? "ERROR: configuring win32 cross build 2"


make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" CXXFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" all \
GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld -j4
assert_success $? "ERROR: making win32 Canadian-cross compiler build"
make CFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" CXXFLAGS="-O2 -DCHIPKIT_PIC32 -D_WIN32_WINNT=0x0501 -DWINVER=0x501" install
assert_success $? "ERROR: installing win32 Canadian-cross compiler build"

cd ../..
status_update "Make win32 Canadian cross build complete"

unset CC
unset CPP
unset CXX

cd $WORKING_DIR/win32-image/pic32-tools
find . -type f -name "*.exe" | xargs $MINGW32_HOST_PREFIX-strip

status_update "Make minGW32 Canadian cross build complete"

fi

cd $WORKING_DIR


####### End win32 build ###############

if [ "x$SKIPARMLINUX" == "x" ]; then
####### Begin arm-linux build ############

# Build xc32 shell
build_xc32_sh "$WORKING_DIR/arm-linux-image" "TARGET=arm"

################ Begin build arm-linux compiler ##############
# Build ARMLINUX32 cross compiler
echo `date` " Creating cross build in $WORKING_DIR/arm-linux-build..." >> $LOGFILE
if [ -e arm-linux-build ]
then
    rm -rf arm-linux-build
fi
mkdir arm-linux-build
assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build"

cd arm-linux-build

if [ -e binutils ]
then
    rm -rf binutils
fi
mkdir binutils
assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build/binutils"

cd binutils

# Configure ARMLINUX32-cross binutils
echo `date` " Configuring arm-linux binutils build in $WORKING_DIR/arm-linux-build..." >> $LOGFILE
../../chipKIT-cxx/src48x/binutils/configure  --target=pic32mx --prefix=$WORKING_DIR/arm-linux-image/pic32-tools --bindir="$WORKING_DIR/arm-linux-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/arm-linux-image/bin/bin" --host=$ARMLINUX32_HOST_PREFIX --disable-nls --disable-tui --disable-gdbtk --disable-shared --enable-static --disable-threads --disable-bootstrap  --with-dwarf2 --enable-multilib --without-newlib --disable-sim --with-lib-path=: --enable-poison-system-directories --program-prefix=pic32- --with-bugurl=http://chipkit.net/forum/ --disable-werror
assert_success $? "ERROR: configuring arm-linux binutils build"

# Make ARMLINUX32-cross binutils and install it
echo `date` " Making all in $WORKING_DIR/arm-linux-build/binutils and installing..." >> $LOGFILE
make CFLAGS="-Os -DCHIPKIT_PIC32 -DMCHP_VERSION=${MCHP_VERSION}" all -j4
assert_success $? "ERROR: making/installing arm-linux Canadian-cross binutils build"
make CFLAGS="-Os -DCHIPKIT_PIC32 -DMCHP_VERSION=${MCHP_VERSION}"  install
assert_success $? "ERROR: making/installing arm-linux Canadian-cross binutils build"
cd ..

if [ -e gmp ]
then
    rm -rf gmp
fi
mkdir gmp
assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build/gmp"

cd gmp

echo `date` " Configuring arm-linux gmp build in $WORKING_DIR/arm-linux-build/gmp..." >> $LOGFILE
CPPFLAGS="-fexceptions" ../../chipKIT-cxx/src48x/gmp/configure --enable-cxx --prefix=$WORKING_DIR/arm-linux-build/host-libs --disable-shared --host=$ARMLINUX32_HOST_PREFIX --disable-nls --with-gnu-ld --disable-debug --disable-rpath --enable-fft "--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"

# Make arm-linux gmp and install it
echo `date` " Making all in $WORKING_DIR/arm-linux-build/gmp and installing..." >> $LOGFILE
make CPPFLAGS="-fexceptions" all -j4
assert_success $? "ERROR: making/installing gmp build"
make install
assert_success $? "ERROR: making/installing gmp build"

cd ..

if [ "x$SKIPGRAPHITE" == "x" ]; then

    if [ -e ppl ]
    then
        rm -rf ppl
    fi
    mkdir ppl
    assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build/ppl"

    cd ppl
    echo `date` " Configuring native ppl build in $WORKING_DIR/arm-linux-build/ppl..." >> $LOGFILE
    ../../chipKIT-cxx/src48x/ppl/configure --prefix=$WORKING_DIR/arm-linux-build/host-libs --disable-shared --enable-static --with-gnu-ld --host=$ARMLINUX32_HOST_PREFIX --target=pic32mx --disable-nls --enable-optimization=speed --disable-rpath --with-gmp-=$WORKING_DIR/arm-linux-build/host-libs --with-libgmp-prefix=$WORKING_DIR/arm-linux-build/host-libs

    # Make native ppl and install it
    echo `date` " Making all in $WORKING_DIR/arm-linux-build/ppl and installing..." >> $LOGFILE
    make all -j4
    assert_success $? "ERROR: making/installing ppl build"
    make install
    assert_success $? "ERROR: making/installing ppl build"

    cd ..

    if [ -e cloog ]
    then
        rm -rf cloog
    fi
    mkdir cloog
    assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build/cloog"

    cd cloog

    echo `date` " Configuring arm-linux cloog build in $WORKING_DIR/arm-linux-build/cloog..." >> $LOGFILE
    ../../chipKIT-cxx/src48x/cloog/configure $BUILDMACHINE --with-gnu-ld --prefix=$WORKING_DIR/arm-linux-build/host-libs --host=$ARMLINUX32_HOST_PREFIX --target=pic32mx --with-gmp=$WORKING_DIR/arm-linux-build/host-libs --with-ppl=$WORKING_DIR/arm-linux-build/host-libs --target=pic32mx --disable-shared --enable-static --disable-shared

    # Make native cloog and install it
    echo `date` " Making all in $WORKING_DIR/arm-linux-build/cloog and installing..." >> $LOGFILE
    make all -j4
    assert_success $? "ERROR: making/installing cloog build"
    make install
    assert_success $? "ERROR: making/installing cloog build"

    cd ..
else
    USE_CLOOG="--without-cloog"
    USE_PPL="--without-isl"
fi

if [ -e libelf ]
then
    rm -rf libelf
fi
mkdir libelf
assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build/libelf"

cd libelf
echo `date` " Configuring native libelf build in $WORKING_DIR/arm-linux-build/libelf..." >> $LOGFILE
GCC_FOR_TARGET='pic32-gcc' CC_FOR_TARGET='pic32-gcc' CPP_FOR_TARGET='pic32-g++' AS_FOR_TARGET=pic32-as LD_FOR_TARGET=pic32-ld CFLAGS_FOR_BUILD="-Os" ../../chipKIT-cxx/src48x/libelf/configure  --prefix=$WORKING_DIR/arm-linux-build/host-libs --host=$ARMLINUX32_HOST_PREFIX $BUILDMACHINE --target=pic32mx --disable-shared --disable-debug --disable-nls

# Make native libelf and install it
echo `date` " Making all in $WORKING_DIR/arm-linux-build/libelf and installing..." >> $LOGFILE
make all -j4
assert_success $? "ERROR: making/installing libelf build"
make install
assert_success $? "ERROR: making/installing libelf build"
cd ..

if [ -e zlib ]
then
    rm -rf zlib
fi
cp -r ../chipKIT-cxx/src48x/zlib .
assert_success $? "ERROR: copy src48x/zlib directory to $WORKING_DIR/arm-linux-build/zlib"

cd zlib
echo `date` " Configuring arm-linux zlib build in $WORKING_DIR/arm-linux-build/zlib..." >> $LOGFILE
CC=$ARMLINUX32_HOST_PREFIX-gcc AR="$ARMLINUX32_HOST_PREFIX-ar" RANLIB=$ARMLINUX32_HOST_PREFIX-ranlib ./configure --prefix=$WORKING_DIR/arm-linux-build/host-libs

# Make arm-linux zlib and install it
echo `date` " Making all in $WORKING_DIR/arm-linux-build/zlib and installing..." >> $LOGFILE
make all -j4
assert_success $? "ERROR: making/installing zlib build - all"
make install
assert_success $? "ERROR: making/installing zlib build - install"
cd ..

if [ -e gcc ]
then
    rm -rf gcc
fi
mkdir gcc
assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build/gcc"

cd gcc

# Configure arm-linux cross compiler
echo `date` " Configuring arm-linux cross compiler build in $WORKING_DIR/arm-linux-build..." >> $LOGFILE

AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ar" AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" CXX_FOR_TARGET='pic32-gcc' target_alias=pic32- ../../chipKIT-cxx/src48x/gcc/configure $GCC_CONFIGURE_FLAGS $BUILDMACHINE --host=$ARMLINUX32_HOST_PREFIX --prefix=$WORKING_DIR/arm-linux-image/pic32-tools --bindir="$WORKING_DIR/arm-linux-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/arm-linux-image/pic32-tools/bin/bin" --with-libelf=$WORKING_DIR/arm-linux-build/host-libs --with-gmp=$WORKING_DIR/arm-linux-build/host-libs $USE_CLOOG $USE_PPL CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" $SUPPORT_HOSTED_LIBSTDCXX

assert_success $? "ERROR: configuring arm-linux32 cross build"

# Make cross compiler and install it
echo `date` " Making all in $WORKING_DIR/arm-linux-build/gcc and installing..." >> $LOGFILE
make CFLAGS="-Os -DCHIPKIT_PIC32" all-gcc \
NM_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-nm" \
RANLIB_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib" \
STRIP_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip" \
AR_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar" \
AS_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as" \
LD_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld" \
GCC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" \
CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc" -j4 CXXFLAGS="$CXXFLAGS_FOR_TARGET -Os -DCHIPKIT_PIC32"
assert_success $? "ERROR: making/installing arm-linux Canadian-cross compiler build"
make CFLAGS="-Os -DCHIPKIT_PIC32" install-gcc
assert_success $? "ERROR: making/installing arm-linux Canadian-cross compiler build"

cd ..

if [ "xSKIPMULTIPLENEWLIB" != x ]; then

if [ -e newlib ]
then
    rm -rf newlib
fi
mkdir newlib
assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linuxIMAGE/newlib"

cd newlib

echo `date` " Configure newlib for arm-linux-image..." >> $LOGFILE

#build newlib here

GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../pic32-newlib/configure $NEWLIB_CONFIGURE_FLAGS --prefix=$WORKING_DIR/arm-linux-image/pic32-tools --bindir="$WORKING_DIR/arm-linux-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/arm-linux-image/pic32-tools/bin/bin" CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"

echo `date` " Make newlib for arm-linux-image..." >> $LOGFILE

make all -j4 CFLAGS_FOR_TARGET="-DCHIPKIT_PIC32 -fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" CCASFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections -DSMALL_MEMORY -D_NO_GETLOGIN -D_NO_GETPWENT -D_NO_GETUT -D_NO_GETPASS -D_NO_SIGSET" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"
assert_success $? "ERROR: Make newlib for cross build"
make install
assert_success $? "ERROR: Install newlib for cross build"

cd ..
fi

if [ -e gcc ]
then
    rm -rf gcc
fi
mkdir gcc
assert_success $? "ERROR: creating directory $WORKING_DIR/arm-linux-build/gcc"

cd gcc

echo `date` " Configure gcc after making Newlib for arm-linux-image..." >> $LOGFILE
GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld ../../chipKIT-cxx/src48x/gcc/configure $GCC_CONFIGURE_FLAGS $BUILDMACHINE --host=$ARMLINUX32_HOST_PREFIX --prefix=$WORKING_DIR/arm-linux-image/pic32-tools --bindir="$WORKING_DIR/arm-linux-image/pic32-tools/bin/bin" --libexecdir="$WORKING_DIR/arm-linux-image/pic32-tools/bin/bin"  --with-libelf=$WORKING_DIR/arm-linux-build/host-libs --with-gmp=$WORKING_DIR/arm-linux-build/host-libs $USE_CLOOG $USE_PPL CFLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer  PREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" XGCC_FLAGS_FOR_TARGET="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections" --enable-cxx-flags="-fno-rtti -fno-exceptions -fomit-frame-pointer -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Os -fshort-wchar -fno-unroll-loops -fno-enforce-eh-specs -ffunction-sections -fdata-sections"  $SUPPORT_HOSTED_LIBSTDCXX
#"--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"
assert_success $? "ERROR: configuring arm-linux32 cross build 2"

make CFLAGS="-Os -DCHIPKIT_PIC32" CXXFLAGS="-Os -DCHIPKIT_PIC32" all \
GCC_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc CC_FOR_TARGET="$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-gcc -I$WORKING_DIR/chipKIT-cxx/src48x/gcc/gcc/ginclude" CXX_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ CPP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-g++ AR_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ar RANLIB_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-ranlib READELF_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-readelf STRIP_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/bin/pic32-strip AS_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/as LD_FOR_TARGET=$WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/bin/ld  -j4 CXXFLAGS="$CXXFLAGS_FOR_TARGET -Os -DCHIPKIT_PIC32"

make CFLAGS="-Os -DCHIPKIT_PIC32" CXXFLAGS="-Os -DCHIPKIT_PIC32" install
assert_success $? "ERROR: installing arm-linux Canadian-cross compiler build"

cd ../..
status_update "Make arm-linux Canadian cross build complete"

unset CC
unset CPP
unset CXX

cd $WORKING_DIR/arm-linux-image/pic32-tools
find . -type f -name "*.exe" | xargs $ARMLINUX32_HOST_PREFIX-strip

status_update "Make ARMLINUX32 Canadian cross build complete"

fi # SKIPARMLINUX

cd $WORKING_DIR

############   End Arm-Linux build #############

###
# In the resultant install directory, there are a few extra directories
# that we don"t want for our Windows build.
###
echo `date` " Removing unecessary directories from build..." >> $LOGFILE
echo "Directory clean up for pic-tools"

rmdir  $WORKING_DIR/win32-image/pic32-tools/include
rm -rf $WORKING_DIR/win32-image/pic32-tools/man
rm -rf $WORKING_DIR/win32-image/pic32-tools/info
rm -rf $WORKING_DIR/win32-image/pic32-tools/share
rm -rf $WORKING_DIR/win32-image/pic32-tools/pic32mx/share
rm -rf $WORKING_DIR/win32-image/pic32-tools/libsrc

rmdir  $WORKING_DIR/arm-linux-image/pic32-tools/include
rm -rf $WORKING_DIR/arm-linux-image/pic32-tools/man
rm -rf $WORKING_DIR/arm-linux-image/pic32-tools/info
rm -rf $WORKING_DIR/arm-linux-image/pic32-tools/share
rm -rf $WORKING_DIR/arm-linux-image/pic32-tools/pic32mx/share
rm -rf $WORKING_DIR/arm-linux-image/pic32-tools/libsrc

rmdir  $WORKING_DIR/$NATIVEIMAGE/pic32-tools/include
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/man
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/info
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/share
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/pic32mx/share
rm -rf $WORKING_DIR/$NATIVEIMAGE/pic32-tools/libsrc

rm -rf $WORKING_DIR/export-image/pic32-tools/man
rm -rf $WORKING_DIR/export-image/pic32-tools/info
rm -rf $WORKING_DIR/export-image/pic32-tools/share
rm -rf $WORKING_DIR/export-image/pic32-tools/libsrc

if [ "x$LINUX32IMAGE" != "x" ] ; then
    rmdir  $WORKING_DIR/$LINUX32IMAGE/pic32-tools/include
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/man
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/info
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/share
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/pic32mx/share
    rm -rf $WORKING_DIR/$LINUX32IMAGE/pic32-tools/libsrc
fi

if [ "x$SKIPPLIBIMAGE" == "x" ]
then
    cd $WORKING_DIR

    echo "Downloading $HTTP_PLIB_IMAGE_TAR."
    echo `date` "Downloading $HTTP_PLIB_IMAGE_TAR..." >> $LOGFILE
    if [ -e plib-image ]
    then
        rm -rf plib-image
    fi
    curl -L $HTTP_PLIB_IMAGE_TAR | tar jx
    assert_success $? "Downloading the peripheral-library image from $HTTP_PLIB_IMAGE_TAR"

    if [ "x$NATIVEIMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" plib-image/ $NATIVEIMAGE/pic32-tools/
      assert_success $? "ERROR: Install plib in $NATIVEIMAGE"
    fi
    if [ "x$LINUX32IMAGE" != "x" ]
    then
      rsync -qavzC --include "*/" --include "*" plib-image/ $LINUX32IMAGE/pic32-tools/
      assert_success $? "ERROR: Install plib in $LINUX32IMAGE"
    fi
    if [ -e win32-image ]
    then
      rsync -qavzC --include "*/" --include "*" plib-image/ win32-image/pic32-tools/
      assert_success $? "ERROR: Install plib in win32-image"
    fi
    if [ -e arm-linux-image ]
    then
      rsync -qavzC --include "*/" --include "*" plib-image/ arm-linux-image/pic32-tools/
      assert_success $? "ERROR: Install plib in arm-linux-image"
    fi
fi

cd $WORKING_DIR

echo "Making zip files"
#ZIP installation directory.

echo `date` " Tar components to $WORKING_DIR/zips directory..." >> $LOGFILE
echo `date` " Tar installation directory..." >> $LOGFILE
cd $WORKING_DIR
if [[ ! -e zips ]] ; then
    mkdir zips
fi

cd $WORKING_DIR

REV=${BUILD##pic32-}
#tar cjf $WORKING_DIR/zips/pic32-tools-$REV-win32-image.tar.bz2 win32-image
#tar cjf $WORKING_DIR/zips/pic32-tools-$REV-$NATIVEIMAGE.tar.bz2 $NATIVEIMAGE
#tar cjf $WORKING_DIR/zips/pic32-tools-$REV-export-image.tar.bz2 export-image
#if [ "x$LINUX32IMAGE" != "x" ]; then
#    tar cjf $WORKING_DIR/zips/pic32-tools-$REV-$LINUX32IMAGE.tar.bz2 #$LINUX32IMAGE
#fi

cd win32-image
zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-win32-image.zip pic32-tools
cd ../$NATIVEIMAGE
zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-$NATIVEIMAGE.zip pic32-tools
cd ../export-image
zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-export-image.zip pic32-tools
cd ../arm-linux-image
zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-arm-linux-image.zip pic32-tools
cd ..
if [ "x$LINUX32IMAGE" != "x" ]; then
    cd $LINUX32IMAGE
    zip -9 -r $WORKING_DIR/zips/pic32-tools-$REV-$LINUX32IMAGE.zip pic32-tools
    cd ..
fi

unset GCC_FOR_TARGET
unset CC_FOR_TARGET
unset CXX_FOR_TARGET
unset GXX_FOR_TARGET
unset CPP_FOR_TARGET
unset CC_FOR_BUILD
unset CXX_FOR_BUILD
unset CC
unset CPP
unset CXX
unset LD
unset AR

PATH=$OLDPATH
echo `date` " DONE..." >> $LOGFILE
echo DONE.
status_update "DONE"

exit 0
