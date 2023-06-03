#!/bin/bash
#set -e
# Clone kernel
echo -e "$green << cloning kernel >> \n $white"
git clone --depth=1 https://github.com/OmnitrixKernel/Kernel_Xiaomi_Sweet-ELECTRO 13
cd 13
git submodule init
git submodule update

KERNEL_DEFCONFIG=vendor/sweet_user_defconfig
date=$(date +"%Y-%m-%d-%H%M")
export ARCH=arm64
export SUBARCH=arm64
mkdir -p ZIPOUT

# Tool Chain
echo -e "$green << cloning gcc from arter >> \n $white"
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$HOME"/gcc64
git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$HOME"/gcc32
export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
export KBUILD_COMPILER_STRING=$("$HOME"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)

# Clang
echo -e "$green << cloning clang >> \n $white"
git clone -b 15 --depth=1 https://gitlab.com/PixelOS-Devices/playgroundtc.git "$HOME"/clang
export PATH="$HOME/clang/bin:$PATH"
export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')


# Speed up build process
MAKE="./makeparallel"
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

start_build() {
	echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
	echo -e "$blue***********************************************"
	echo "          BUILDING KERNEL          "
	echo -e "***********************************************$nocol"
	make $KERNEL_DEFCONFIG O=out CC=clang
	make -j$(nproc --all) O=out \
	                              ARCH=arm64 \
	                              LLVM=1 \
	                              LLVM_IAS=1 \
	                              AR=llvm-ar \
	                              NM=llvm-nm \
	                              LD=ld.lld \
	                              OBJCOPY=llvm-objcopy \
	                              OBJDUMP=llvm-objdump \
	                              STRIP=llvm-strip \
	                              CC=clang \
	                              CROSS_COMPILE=aarch64-linux-gnu- \
	                              CROSS_COMPILE_ARM32=arm-linux-gnueabi-  2>&1 | tee error.log
	export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz
	export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
	export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img

	find out/arch/arm64/boot/dts/ -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb
	if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ] && [ -f "out/arch/arm64/boot/dtb" ]; then
		echo "------ Finishing  Build ------"
		git clone -q https://github.com/Sweet-stuff/AnyKernel3
		cp out/arch/arm64/boot/Image.gz AnyKernel3
		cp out/arch/arm64/boot/dtb AnyKernel3
		cp out/arch/arm64/boot/dtbo.img AnyKernel3
		rm -f *zip
		cd AnyKernel3
		sed -i "s/is_slot_device=0/is_slot_device=auto/g" anykernel.sh
		zip -r9 "../${zipname}" * -x '*.git*' README.md *placeholder >> /dev/null
		cd ..
		rm -rf AnyKernel3
		echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
		echo ""
		echo -e ${zipname} " is ready!"
		mv ${zipname} ZIPOUT/
		echo ""
	else
		echo -e "\n Compilation Failed!"
	fi
}

canary_build() {
for ((i=1; i<=4; i++))
do
	case $i in
        	1)
			git reset --hard HEAD
	                echo "Miui Normal"
			export zipname="ElectroKernel-Miui-Canary-sweet-${date}.zip"
			git apply scripts/ElectroKernel/commit/miui.patch
	                git apply scripts/ElectroKernel/commit/normal.patch
			start_build()
	                ;;
	        2)
			git reset --hard HEAD
	                echo "Miui Ksu"
			export zipname="ElectroKernel-KernelSU-Miui-Canary-sweet-${date}.zip"
			git apply scripts/ElectroKernel/commit/miui.patch
			start_build()
	                ;;
	        3)
			git reset --hard HEAD
	                echo "OSS Normal"
			export zipname="ElectroKernel-OSS-Canary-sweet-${date}.zip"
	                git apply scripts/ElectroKernel/commit/normal.patch
			start_build()
	                ;;
	        4)
			git reset --hard HEAD
	                echo "OSS Ksu"
	                export zipname="ElectroKernel-KernelSU-OSS-Canary-sweet-${date}.zip"
			start_build()
	                ;;
	        *)
	                echo "Error"
	                ;;
        esac
done
}

stable_build() {
for ((i=1; i<=4; i++))
do
        case $i in
                1)
                        git reset --hard HEAD
                        echo "Miui Normal"
                        export zipname="ElectroKernel-Miui-Stable-sweet-${date}.zip"
                        git apply scripts/ElectroKernel/commit/miui.patch
                        git apply scripts/ElectroKernel/commit/normal.patch
                        start_build()
                        ;;
                2)
                        git reset --hard HEAD
                        echo "Miui Ksu"
                        export zipname="ElectroKernel-KernelSU-Miui-Stable-sweet-${date}.zip"
                        git apply scripts/ElectroKernel/commit/miui.patch
                        start_build()
                        ;;
                3)
                        git reset --hard HEAD
                        echo "OSS Normal"
                        export zipname="ElectroKernel-OSS-Stable-sweet-${date}.zip"
                        git apply scripts/ElectroKernel/commit/normal.patch
                        start_build()
                        ;;
                4)
                        git reset --hard HEAD
                        echo "OSS Ksu"
                        export zipname="ElectroKernel-KernelSU-OSS-Stable-sweet-${date}.zip"
                        start_build()
                        ;;
                *)
                        echo "Error"
                        ;;
        esac
done
}

canary_upload() {
	echo "Canary"
}

stable_upload() {
	echo "Stable"
}

input=$1

if [ "$input" == "canary" ]; then
	canary_build()
	canary_upload()
elif [ "$input" == "stable" ]; then
	stable_build()
	stable_upload()
else
	echo "Error"
fi
