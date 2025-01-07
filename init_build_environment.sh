#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) ImmortalWrt.org

DEFAULT_COLOR="\033[0m"
BLUE_COLOR="\033[36m"
GREEN_COLOR="\033[32m"
RED_COLOR="\033[31m"
YELLOW_COLOR="\033[33m"

function __error_msg() {
	echo -e "${RED_COLOR}[ERROR]${DEFAULT_COLOR} $*"
}

function __info_msg() {
	echo -e "${BLUE_COLOR}[INFO]${DEFAULT_COLOR} $*"
}

function __success_msg() {
	echo -e "${GREEN_COLOR}[SUCCESS]${DEFAULT_COLOR} $*"
}

function __warning_msg() {
	echo -e "${YELLOW_COLOR}[WARNING]${DEFAULT_COLOR} $*"
}

function check_system() {
	__info_msg "Checking system info..."

	VERSION_CODENAME="$(source /etc/os-release; echo "$VERSION_CODENAME")"

	case "$VERSION_CODENAME" in
	"bionic")
		GCC_VERSION="9"
		NODE_DISTRO="$VERSION_CODENAME"
		NODE_KEY="nodesource.gpg.key"
		NODE_VERSION="18"
		UBUNTU_CODENAME="$VERSION_CODENAME"
		VERSION_PACKAGE="lib32gcc-s1 libpython3.6-dev python2.7 python3.6"
		;;
	"buster")
		BPO_FLAG="-t $VERSION_CODENAME-backports"
		DISTRO_PREFIX="debian-archive/"
		DISTRO_SECUTIRY_PATH="buster/updates"
		GCC_VERSION="8"
		UBUNTU_CODENAME="bionic"
		VERSION_PACKAGE="lib32gcc1 python2"
		;;
	"focal"|\
	"jammy")
		GCC_VERSION="9"
		UBUNTU_CODENAME="$VERSION_CODENAME"
		VERSION_PACKAGE="lib32gcc-s1 python2"
		;;
	"bullseye")
		BPO_FLAG="-t $VERSION_CODENAME-backports"
		GCC_VERSION="9"
		UBUNTU_CODENAME="focal"
		VERSION_PACKAGE="lib32gcc-s1 python2"
		;;
	"bookworm")
		BPO_FLAG="-t $VERSION_CODENAME-backports"
		GCC_VERSION="12"
		UBUNTU_CODENAME="jammy"
		VERSION_PACKAGE="lib32gcc-s1"
		;;
	"noble")
		GCC_VERSION="12"
		UBUNTU_CODENAME="$VERSION_CODENAME"
		VERSION_PACKAGE="lib32gcc-s1"
		;;
	*)
		__error_msg "Unsupported OS, use Ubuntu 20.04 instead."
		exit 1
		;;
	esac

	[ "$(uname -m)" == "x86_64" ] || { __error_msg "Unsupported architecture, use AMD64 instead." && exit 1; }

	[ "$(whoami)" == "root" ] || { __error_msg "You must run this script as root." && exit 1; }
}

function check_network() {
	__info_msg "Checking network..."

	curl -s "myip.ipip.net" | grep -qo "中国" && CHN_NET=1
	curl --connect-timeout 10 "baidu.com" > "/dev/null" 2>&1 || { __warning_msg "Your network is not suitable for compiling OpenWrt!"; }
	curl --connect-timeout 10 "google.com" > "/dev/null" 2>&1 || { __warning_msg "Your network is not suitable for compiling OpenWrt!"; }
}

function update_apt_source() {
	__info_msg "Updating apt source lists..."
	set -x

	apt update -y
	apt install -y apt-transport-https gnupg2
	if [ -n "$CHN_NET" ]; then
		mv "/etc/apt/sources.list" "/etc/apt/sources.list.bak"
		if [ "$VERSION_CODENAME" == "$UBUNTU_CODENAME" ]; then
			cat <<-EOF >"/etc/apt/sources.list"
				deb https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME main restricted universe multiverse
				deb-src https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME main restricted universe multiverse

				deb https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-security main restricted universe multiverse
				deb-src https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-security main restricted universe multiverse

				deb https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-updates main restricted universe multiverse
				deb-src https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-updates main restricted universe multiverse

				# deb https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-proposed main restricted universe multiverse
				# deb-src https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-proposed main restricted universe multiverse

				deb https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-backports main restricted universe multiverse
				deb-src https://repo.huaweicloud.com/ubuntu/ $VERSION_CODENAME-backports main restricted universe multiverse
			EOF
		else
			cat <<-EOF > "/etc/apt/sources.list"
				deb https://repo.huaweicloud.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME main contrib
				deb-src https://repo.huaweicloud.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME main contrib

				deb https://repo.huaweicloud.com/debian-security ${DISTRO_SECUTIRY_PATH:-$VERSION_CODENAME-security} main contrib
				deb-src https://repo.huaweicloud.com/debian-security ${DISTRO_SECUTIRY_PATH:-$VERSION_CODENAME-security} main contrib

				deb https://repo.huaweicloud.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME-updates main contrib
				deb-src https://repo.huaweicloud.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME-updates main contrib

				deb https://repo.huaweicloud.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME-backports main contrib
				deb-src https://repo.huaweicloud.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME-backports main contrib
			EOF
		fi
	fi

	mkdir -p "/etc/apt/sources.list.d"

	cat <<-EOF >"/etc/apt/sources.list.d/nodesource.list"
		deb https://deb.nodesource.com/node_${NODE_VERSION:-20}.x ${NODE_DISTRO:-nodistro} main
	EOF
	curl -sL "https://deb.nodesource.com/gpgkey/${NODE_KEY:-nodesource-repo.gpg.key}" -o "/etc/apt/trusted.gpg.d/nodesource.asc"

	cat <<-EOF >"/etc/apt/sources.list.d/yarn.list"
		deb https://dl.yarnpkg.com/debian/ stable main
	EOF
	curl -sL "https://dl.yarnpkg.com/debian/pubkey.gpg" -o "/etc/apt/trusted.gpg.d/yarn.asc"

	if [ "$VERSION_CODENAME" == "bionic" ]; then
		cat <<-EOF >"/etc/apt/sources.list.d/gcc-toolchain.list"
			deb https://ppa.launchpadcontent.net/ubuntu-toolchain-r/test/ubuntu $UBUNTU_CODENAME main
			deb-src https://ppa.launchpadcontent.net/ubuntu-toolchain-r/test/ubuntu $UBUNTU_CODENAME main
		EOF
		curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1e9377a2ba9ef27f" -o "/etc/apt/trusted.gpg.d/gcc-toolchain.asc"
	fi

	cat <<-EOF >"/etc/apt/sources.list.d/git-core-ubuntu-ppa.list"
		deb https://ppa.launchpadcontent.net/git-core/ppa/ubuntu $UBUNTU_CODENAME main
		deb-src https://ppa.launchpadcontent.net/git-core/ppa/ubuntu $UBUNTU_CODENAME main
	EOF
	curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xe1dd270288b4e6030699e45fa1715d88e1df1f24" -o "/etc/apt/trusted.gpg.d/git-core-ubuntu-ppa.asc"

	cat <<-EOF >"/etc/apt/sources.list.d/llvm-toolchain.list"
		deb https://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-18 main
		deb-src https://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-18 main
	EOF
	curl -sL "https://apt.llvm.org/llvm-snapshot.gpg.key" -o "/etc/apt/trusted.gpg.d/llvm-toolchain.asc"

	cat <<-EOF >"/etc/apt/sources.list.d/longsleep-ubuntu-golang-backports-$UBUNTU_CODENAME.list"
		deb https://ppa.launchpadcontent.net/longsleep/golang-backports/ubuntu $UBUNTU_CODENAME main
		deb-src https://ppa.launchpadcontent.net/longsleep/golang-backports/ubuntu $UBUNTU_CODENAME main
	EOF
	curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x52b59b1571a79dbc054901c0f6bc817356a3d45e" -o "/etc/apt/trusted.gpg.d/longsleep-ubuntu-golang-backports-$UBUNTU_CODENAME.asc"

	if [ -n "$CHN_NET" ]; then
		sed -i -e "s,apt.llvm.org,mirrors.tuna.tsinghua.edu.cn/llvm-apt,g" -e "s,^deb-src,# deb-src,g" "/etc/apt/sources.list.d/llvm-toolchain.list"
		sed -i "s,ppa.launchpadcontent.net,launchpad.proxy.ustclug.org,g" "/etc/apt/sources.list.d"/*
	fi

	apt update -y $BPO_FLAG

	set +x
}
function install_dependencies() {
	__info_msg "Installing dependencies..."
	set -x

	apt full-upgrade -y $BPO_FLAG
	apt install -y $BPO_FLAG ack antlr3 asciidoc autoconf automake autopoint binutils bison \
		build-essential bzip2 ccache cmake cpio curl device-tree-compiler ecj fakeroot \
		fastjar flex gawk gettext genisoimage git gnutls-dev gperf haveged help2man \
		intltool jq libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
		libmpc-dev libmpfr-dev libncurses-dev libreadline-dev libssl-dev libtool \
		libyaml-dev libz-dev lrzsz msmtp nano ninja-build p7zip p7zip-full patch \
		pkgconf libpython3-dev python3 python3-pip python3-cryptography python3-docutils \
		python3-ply python3-pyelftools qemu-utils quilt re2c rsync scons sharutils \
		squashfs-tools subversion swig texinfo uglifyjs unzip vim wget xmlto zlib1g-dev \
		zstd xxd $VERSION_PACKAGE

	# fix broken http2 support for curl on buster
	if [ "$VERSION_CODENAME" == "buster"]; then
		apt full-upgrade -y
		apt reinstall -y libcurl3-gnutls/buster
	fi

	if [ -n "$CHN_NET" ]; then
		pip3 config set global.index-url "https://mirrors.aliyun.com/pypi/simple/"
		pip3 config set install.trusted-host "https://mirrors.aliyun.com"
	fi

	apt install -y $BPO_FLAG "gcc-$GCC_VERSION" "g++-$GCC_VERSION" "gcc-$GCC_VERSION-multilib" "g++-$GCC_VERSION-multilib"
	for i in "gcc-$GCC_VERSION" "g++-$GCC_VERSION" "gcc-ar-$GCC_VERSION" "gcc-nm-$GCC_VERSION" "gcc-ranlib-$GCC_VERSION"; do
		ln -svf "$i" "/usr/bin/${i%-$GCC_VERSION}"
	done
	ln -svf "/usr/bin/g++" "/usr/bin/c++"
	[ -e "/usr/include/asm" ] || ln -svf "/usr/include/$(gcc -dumpmachine)/asm" "/usr/include/asm"

	apt install -y $BPO_FLAG clang-18 libclang-18-dev lld-18 liblld-18-dev
	for i in "clang-18" "clang++-18" "clang-cpp-18" "ld.lld-18" "ld64.lld-18" "llc-18" "lld-18" "lld-link-18" "opt-18" "wasm-ld-18"; do
		ln -svf "$i" "/usr/bin/${i%-18}"
	done

	apt install -y $BPO_FLAG llvm-18
	for i in "/usr/bin"/llvm-*-18; do
		ln -svf "$i" "${i%-18}"
	done

	apt install -y $BPO_FLAG nodejs yarn
	if [ -n "$CHN_NET" ]; then
		npm config set registry "https://registry.npmmirror.com" --global
		yarn config set registry "https://registry.npmmirror.com" --global
	fi

	apt install -y $BPO_FLAG golang-1.23-go
	rm -rf "/usr/bin/go" "/usr/bin/gofmt"
	ln -svf "/usr/lib/go-1.23/bin/go" "/usr/bin/go"
	ln -svf "/usr/lib/go-1.23/bin/gofmt" "/usr/bin/gofmt"
	if [ -n "$CHN_NET" ]; then
		go env -w GOPROXY=https://goproxy.cn,direct
	fi

	apt clean -y

	if TMP_DIR="$(mktemp -d)"; then
		pushd "$TMP_DIR"
	else
		__error_msg "Failed to create a tmp directory."
		exit 1
	fi

	UPX_REV="4.2.4"
	curl -fLO "https://github.com/upx/upx/releases/download/v${UPX_REV}/upx-$UPX_REV-amd64_linux.tar.xz"
	tar -Jxf "upx-$UPX_REV-amd64_linux.tar.xz"
	rm -rf "/usr/bin/upx" "/usr/bin/upx-ucl"
	cp -fp "upx-$UPX_REV-amd64_linux/upx" "/usr/bin/upx-ucl"
	chmod 0755 "/usr/bin/upx-ucl"
	ln -svf "/usr/bin/upx-ucl" "/usr/bin/upx"

	git clone --filter=blob:none --no-checkout "https://github.com/openwrt/openwrt.git" "padjffs2"
	pushd "padjffs2"
	git config core.sparseCheckout true
	echo "tools/padjffs2/src" >> ".git/info/sparse-checkout"
	git checkout
	cd "tools/padjffs2/src"
	make
	strip "padjffs2"
	rm -rf "/usr/bin/padjffs2"
	cp -fp "padjffs2" "/usr/bin/padjffs2"
	popd

	git clone --filter=blob:none --no-checkout "https://github.com/openwrt/luci.git" "po2lmo"
	pushd "po2lmo"
	git config core.sparseCheckout true
	echo "modules/luci-base/src" >> ".git/info/sparse-checkout"
	git checkout
	cd "modules/luci-base/src"
	make po2lmo
	strip "po2lmo"
	rm -rf "/usr/bin/po2lmo"
	cp -fp "po2lmo" "/usr/bin/po2lmo"
	popd

	curl -fL "https://build-scripts.immortalwrt.org/modify-firmware.sh" -o "/usr/bin/modify-firmware"
	chmod 0755 "/usr/bin/modify-firmware"

	popd
	rm -rf "$TMP_DIR"

	set +x
	__success_msg "All dependencies have been installed."
}
function main() {
	check_system
	check_network
	update_apt_source
	install_dependencies
}

main
