#!/bin/sh

WORK_DIR=`realpath $0`
WORK_DIR=`dirname $WORK_DIR`
cd $WORK_DIR

echoyellow () { # $1 = string
    COLOR='\033[1;33m'
    NC='\033[0m'
    printf "${COLOR}$1${NC}\n"
}

echored () { # $1 = string
    COLOR='\033[0;31m'
    NC='\033[0m'
    printf "${COLOR}$1${NC}\n"
}

check_rc () {
    if [ ! -z "$1" -a ! -z "$2" ]; then
        if [ "$1" != "0" ]; then
            echored "$2 failed, exiting..."
            exit 1
        fi
    fi
}

echoyellow "download moto kernel"
if [ -d $WORK_DIR/kernel-msm ]
then
    cd $WORK_DIR/kernel-msm
    git fetch origin android-14-release-u1ugs34.23-110-2-1
    check_rc $? "git fetch"
    git reset origin/android-14-release-u1ugs34.23-110-2-1 --hard
    check_rc $? "git reset"
else
    git clone https://github.com/MotorolaMobilityLLC/kernel-msm.git --branch android-14-release-u1ugs34.23-110-2-1 --single-branch
    check_rc $? "git clone"
    cd $WORK_DIR/kernel-msm
    curl -Lo .git/hooks/commit-msg https://review.lineageos.org/tools/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
fi

# Revert "fs:EROFS:Porting 5.10 erofs to 5.4"
git revert --no-edit 45482ab6d38d 819904916893 fa3b0b74bbcf
check_rc $? "git revert"

# Revert "Penang: resolve kasan panic"
# Revert "Penang: kasan panic"
# Revert "penang: device suspend tests fail"
# Revert "net: qrtr: get svc_id before queueing sk_buff"
git revert --no-edit 836e3b0c9a1c 485bfce7488f 0ab43c2ab514 a65aa65ad1c1
check_rc $? "git revert"

# Revert "af_unix: Fix garbage collector racing against connect()"
# Revert "af_unix: Do not use atomic ops for unix_sk(sk)->inflight."
git revert --no-edit 6487f3d3468b 9ef7c24511b3
check_rc $? "git revert"

# Revert "msm: npu: Fix use after free issue"
git revert --no-edit f6795b4ad6bb
check_rc $? "git revert"

# Add "net/ipv6: release expired exception dst cached in socket" to prevent merge error
wget https://github.com/LineageOS/android_kernel_qcom_sm8350/commit/a95808252e8acc0123bacd2dff8b9af10bc145b7.patch -O - | git am
check_rc $? "git am"

echoyellow "download LineageOS qcom sm8350 kernel"
if [ -d $WORK_DIR/android_kernel_qcom_sm8350 ]
then
    cd $WORK_DIR/android_kernel_qcom_sm8350
    git fetch origin
    check_rc $? "git fetch"
    git reset origin/lineage-20 --hard
    check_rc $? "git reset"
else
    cd $WORK_DIR
    git clone https://github.com/LineageOS/android_kernel_qcom_sm8350.git
    check_rc $? "git clone"
    cd $WORK_DIR/android_kernel_qcom_sm8350
    curl -Lo .git/hooks/commit-msg https://review.lineageos.org/tools/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
fi

# Revert "qseecom: Add flush_work based on flag"
git revert --no-edit 23d03fa257af1da4041b4d6bbf63e63dd5ebc8a1
check_rc $? "git revert"

# Revert "mmc: sdhci-msm: Disable partial_init and clk-scaling to avoid RED error"
git revert --no-edit e46fa2494859f4774f64d067816eedcf10d767d6
check_rc $? "git revert"

# Revert "soc: qcom: smem: Add boundary checks for partitions"
git revert --no-edit 58e401790ae9f1bbaab96eda7d2e21fb4b020247
check_rc $? "git revert"

# Revert "sched: Provide sched_set_fifo()
git revert --no-edit 9044855f697b
check_rc $? "git revert"

for i in $WORK_DIR/_patches_prepare_sm8350/*; do echo "--- patching $i"; git am --keep-cr $i || break; done
check_rc $? "git am"

cd $WORK_DIR

echoyellow "init new sm6375 kernel repo"
if [ ! -d $WORK_DIR/android_kernel_motorola_sm6375 ]
then
    git init -b lineage-22.1 $WORK_DIR/android_kernel_motorola_sm6375
    cd $WORK_DIR/android_kernel_motorola_sm6375
    curl -Lo .git/hooks/commit-msg https://review.lineageos.org/tools/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
    git remote add LineageOS/android_kernel_qcom_sm8350 ../android_kernel_qcom_sm8350
    git remote add moto-kernel ../kernel-msm
fi

echoyellow "prepare new sm6375 kernel repo"
cd $WORK_DIR/android_kernel_motorola_sm6375
git fetch LineageOS/android_kernel_qcom_sm8350
check_rc $? "git fetch"
git fetch moto-kernel
check_rc $? "git fetch"
git checkout -b lineage-22.1
git reset LineageOS/android_kernel_qcom_sm8350/lineage-20 --hard
check_rc $? "git reset"

echoyellow "merge moto kernel"
git merge moto-kernel/android-14-release-u1ugs34.23-110-2-1 -m "Merge remote-tracking branch 'moto-kernel/android-14-release-u1ugs34.23-110-2-1' into lineage-22.1

MMI-U1UGS34.23-110-23-2"
check_rc $? "git merge"

for i in \
    kernel-camera-devicetree \
    kernel-devicetree \
    kernel-display-devicetree \
    kernel-msm-5.4-techpack-audio \
    kernel-msm-5.4-techpack-camera \
    kernel-msm-5.4-techpack-display \
    kernel-msm-5.4-techpack-video \
    motorola-kernel-modules \
    ; \
    do
    rm -rf $WORK_DIR/$i

    unset subtree_prefix_subdir
    moto_branch=android-14-release-u1ug34.23-23-3

    case $i in
        kernel-camera-devicetree)
            subtree_prefix_subdir=arch/arm64/boot/dts/vendor/qcom/camera/
            ;;
        kernel-devicetree)
            subtree_prefix_subdir=arch/arm64/boot/dts/vendor/
            ;;
        kernel-display-devicetree)
            moto_branch=android-13-release-t2sn33.73-22-3
            subtree_prefix_subdir=arch/arm64/boot/dts/vendor/qcom/
            ;;
        kernel-msm-5.4-techpack-audio)
            subtree_prefix_subdir=techpack/audio/
            ;;
        kernel-msm-5.4-techpack-camera)
            subtree_prefix_subdir=techpack/camera/
            ;;
        kernel-msm-5.4-techpack-display)
            subtree_prefix_subdir=techpack/display/
            ;;
        kernel-msm-5.4-techpack-video)
            subtree_prefix_subdir=techpack/video/
            ;;
        motorola-kernel-modules)
            moto_branch=android-13-release-tsc
            ;;
    esac

    echoyellow "download moto $i"

    cd $WORK_DIR
    git clone --branch $moto_branch https://github.com/MotorolaMobilityLLC/$i.git
    check_rc $? "git clone"

    case $i in
        kernel-msm-5.4-techpack-camera)
            cd $WORK_DIR/$i
            git am $WORK_DIR/_patches_prepare_techpack_camera/*
            check_rc $? "git am"
            ;;
    esac

    echoyellow "merge rebased moto $i to sm6375 kernel"
    cd $WORK_DIR/android_kernel_motorola_sm6375

    git remote add $i ../$i
    git fetch $i --no-tags
    check_rc $? "git fetch"

    case $i in
        motorola-kernel-modules)
            git rm sound/soc/codecs/Makefile include/linux/input/synaptics_tcm.h fs/exfat/Makefile fs/exfat/Kconfig fs/exfat/README.md drivers/misc/Makefile drivers/leds/trigger/Makefile Documentation/devicetree/bindings
            check_rc $? "git rm"
            git commit -m "remove files to prevent merge errors with motorola-kernel-modules"
            git merge --no-edit --allow-unrelated-histories $i/$moto_branch
            check_rc $? "git merge $i/$moto_branch"
            ;;
        *)
            git subtree pull --prefix $subtree_prefix_subdir $i $moto_branch -m "Merge remote-tracking branch '$i/$moto_branch' into lineage-22.1"
            check_rc $? "git merge $i/$moto_branch"
            ;;
    esac

    git remote remove $i
    rm -rf $WORK_DIR/$i

done

cd $WORK_DIR/android_kernel_motorola_sm6375

# Revert "rhodep/rhodec: update camera device tree path"
git revert --no-edit 7b0a2deb4201932773e9d9e51fffd097c6370a38
check_rc $? "git revert"

find . -name "Android.mk" -delete
git restore Android.mk
git commit -a -m "treewide: remove Android.mk"

echoyellow "applying local patches to sm6375 kernel"
for i in $WORK_DIR/_patches/*; do echo "--- patching $i"; git am --keep-cr $i || break; done
check_rc $? "git am"
