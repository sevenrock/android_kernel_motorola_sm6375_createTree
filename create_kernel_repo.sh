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
    git fetch origin android-13-release-t1sus33.1-124-6-8-1
    check_rc $? "git fetch"
    git reset origin/android-13-release-t1sus33.1-124-6-8-1 --hard
    check_rc $? "git reset"
else
    git clone https://github.com/MotorolaMobilityLLC/kernel-msm.git --branch android-13-release-t1sus33.1-124-6-8-1 --single-branch
    check_rc $? "git clone"
fi

echoyellow "download codelinaro kernel"
if [ -d $WORK_DIR/kernel-codelinaro-5.4-r3 ]
then
    cd $WORK_DIR/kernel-codelinaro-5.4-r3
    git fetch origin
    check_rc $? "git fetch"
    git reset LA.UM.9.16.r1-17300-MANNAR.QSSI15.0 --hard
    check_rc $? "git reset"
else
    git clone https://git.codelinaro.org/clo/la/kernel/msm-5.4.git --branch kernel.lnx.5.4.r3-rel --single-branch kernel-codelinaro-5.4-r3
    check_rc $? "git clone"
fi
cd $WORK_DIR/kernel-codelinaro-5.4-r3

# revert codelinaro commits to solve rebase conflicts with moto kernel
# moto has slightly different version of codelinaro commit
# https://github.com/MotorolaMobilityLLC/kernel-msm/commit/483961db6f0054b1c75bbc61fa052782826ef382
git revert acf2f0eb6a4aabcfae75f869af836cdc30f29419 --no-edit
check_rc $? "git revert"

# prevent conflict with moto commit
# https://github.com/MotorolaMobilityLLC/kernel-msm/commit/adef11527df8cdeed539fc370ba1ddb09a4c68bd
git revert e46fa2494859f4774f64d067816eedcf10d767d6 --no-edit
check_rc $? "git revert"

# prevent conflict with moto commit
# https://github.com/MotorolaMobilityLLC/kernel-msm/commit/2536b440f3e1da8cdb67a72577dd12f8fa90bebc
git revert ff29a6cf6e84f4ccbab2d0853cf20e6c2821ef38 --no-edit
check_rc $? "git revert"

# prevent conflict with moto commit
# https://github.com/MotorolaMobilityLLC/kernel-msm/commit/fe51fee88a1481e9685fba3833691685488deb38
git revert 9d501ea8822df775478424b196cc9e3f510b35a3 --no-edit
check_rc $? "git revert"

cd $WORK_DIR

echoyellow "init new sm6375 kernel repo"
if [ ! -d $WORK_DIR/android_kernel_motorola_sm6375 ]
then
    git init -b lineage-21 $WORK_DIR/android_kernel_motorola_sm6375
    cd $WORK_DIR/android_kernel_motorola_sm6375
    git remote add codelinaro ../kernel-codelinaro-5.4-r3
    git remote add moto-kernel ../kernel-msm
fi

cd $WORK_DIR/android_kernel_motorola_sm6375
git fetch codelinaro
git fetch moto-kernel
git checkout lineage-21

git reset moto-kernel/android-13-release-t1sus33.1-124-6-8-1 --hard
git rebase codelinaro/kernel.lnx.5.4.r3-rel
check_rc $? "git rebase"

for i in \
    kernel-camera-devicetree \
    kernel-devicetree \
    kernel-display-devicetree \
    kernel-msm-techpack-dataipa \
    kernel-msm-5.4-techpack-audio \
    kernel-msm-5.4-techpack-camera \
    kernel-msm-5.4-techpack-display \
    kernel-msm-5.4-techpack-video \
    motorola-kernel-modules \
    vendor-qcom-opensource-datarmnet \
    vendor-qcom-opensource-datarmnet-ext \
    vendor-qcom-opensource-wlan-fw-api \
    vendor-qcom-opensource-wlan-qcacld-3.0 \
    vendor-qcom-opensource-wlan-qca-wifi-host-cmn \
    ; \
    do
    rm -rf $WORK_DIR/$i
    unset codelinaro_repo filter_repo_subdir
    codelinaro_tag=LA.UM.9.16.r1-17400-MANNAR.QSSI14.0

    case $i in
        kernel-camera-devicetree)
            moto_branch=android-13-release-ttpn
            filter_repo_subdir=arch/arm64/boot/dts/vendor/qcom/camera-legacy/rhodep/
            ;;
        kernel-devicetree)
            moto_branch=android-13-release-t1ssm33.1-121-4
            filter_repo_subdir=arch/arm64/boot/dts/vendor/
            ;;
        kernel-display-devicetree)
            moto_branch=android-13-release-traa
            filter_repo_subdir=arch/arm64/boot/dts/vendor/qcom/
            ;;
        kernel-msm-5.4-techpack-audio)
            moto_branch=android-13-release-t1ssis33.1-75-7-1
            codelinaro_repo=platform/vendor/opensource/audio-kernel
            codelinaro_branch=audio-drivers.lnx.5.0.r2-rel
            filter_repo_subdir=techpack/audio/
            ;;
        kernel-msm-5.4-techpack-camera)
            moto_branch=android-13-release-t1rd33.116-33-3
            filter_repo_subdir=techpack/camera/
            ;;
        kernel-msm-5.4-techpack-display)
# cherry-pick only, rebase is broken
            moto_branch=android-13-release-t1ssm33.1-121-4
            codelinaro_repo=platform/vendor/opensource/display-drivers
            codelinaro_branch=display-kernel.lnx.5.4.r3-rel
            filter_repo_subdir=techpack/display/
            ;;
        kernel-msm-5.4-techpack-video)
            moto_branch=android-13-release-t1ssm33.1-121-4
            codelinaro_repo=platform/vendor/opensource/video-driver
            codelinaro_branch=video-kernel.lahaina.lnx.1.0.r2-rel
            filter_repo_subdir=techpack/video/
            ;;
        kernel-msm-techpack-dataipa)
            moto_branch=android-13-release-t1sus33.1-124-6-7
            codelinaro_repo=platform/vendor/opensource/dataipa
            codelinaro_branch=data-kernel.lnx.1.1.r2-rel
            filter_repo_subdir=techpack/dataipa/
            ;;
        motorola-kernel-modules)
            moto_branch=android-13-release-tra
            ;;
        vendor-qcom-opensource-wlan-fw-api)
            moto_branch=android-13-release-t1sus33.1-124-6-7
            codelinaro_repo=platform/vendor/qcom-opensource/wlan/fw-api
            codelinaro_branch=wlan-api.lnx.1.0.r55-rel
            filter_repo_subdir=drivers/staging/fw-api/
            ;;
        vendor-qcom-opensource-wlan-qcacld-3.0)
            moto_branch=android-13-release-ttpn
            codelinaro_repo=platform/vendor/qcom-opensource/wlan/qcacld-3.0
            codelinaro_branch=wlan-cld3.driver.lnx.2.0.r22-rel
            filter_repo_subdir=drivers/staging/qcacld-3.0/
            ;;
        vendor-qcom-opensource-wlan-qca-wifi-host-cmn)
            moto_branch=android-13-release-ttpn
            codelinaro_repo=platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn
            codelinaro_branch=wlan-cmn.driver.lnx.2.0.r22-rel
            filter_repo_subdir=drivers/staging/qca-wifi-host-cmn/
            ;;
        vendor-qcom-opensource-datarmnet)
            moto_branch=MMI-T3TC33.18-12-3
            codelinaro_repo=platform/vendor/qcom/opensource/datarmnet
            codelinaro_branch=data-kernel.lnx.1.1.r2-rel
            filter_repo_subdir=techpack/datarmnet/
            ;;
        vendor-qcom-opensource-datarmnet-ext)
            moto_branch=MMI-T3TC33.18-12-3
            codelinaro_repo=platform/vendor/qcom/opensource/datarmnet-ext
            codelinaro_branch=data-kernel.lnx.1.1.r2-rel
            filter_repo_subdir=techpack/datarmnet-ext/
            ;;
    esac

    echoyellow "download moto $i"

    cd $WORK_DIR
    rm -rf $codelinaro_tag
    git clone --branch $moto_branch https://github.com/MotorolaMobilityLLC/$i.git
    check_rc $? "git clone"

# CodeLinaro repo available for rebase/cherry-pick
    if [ ! "x"$codelinaro_repo = "x" ]
    then
        echoyellow "download codelinaro $codelinaro_repo"
        git clone https://git.codelinaro.org/clo/la/$codelinaro_repo.git --branch $codelinaro_branch --single-branch $codelinaro_tag
        check_rc $? "git clone"

        case $i in
            vendor-qcom-opensource-wlan-qca-wifi-host-cmn)
                cd $WORK_DIR/$codelinaro_tag/
                git revert --no-edit 5336f4036a3acc2509ba6750b6422e65f613b8e8
                check_rc $? "git revert"
                git revert --no-edit d400de634f2666cf9ecab0aaef302edf4a3165a4
                check_rc $? "git revert"
                git revert --no-edit 05fbfac24f62e5c426c13022383397327c0510e2
                check_rc $? "git revert"
                ;;
        esac

        cd $WORK_DIR/$i
        git remote add codelinaro ../$codelinaro_tag/
        git fetch codelinaro
        check_rc $? "git fetch"

        echoyellow "rebase moto $i on codelinaro $codelinaro_repo"
        case $i in
            kernel-msm-5.4-techpack-display)
                git cherry-pick a4fdef4c120bbdf44f54156013d25a6a3af795e4
                check_rc $? "git cherry-pick"
                git cherry-pick 9c77f40c14bc397a759337e1880e0edf08a858df
                check_rc $? "git cherry-pick"
                git cherry-pick 2653c8e8139284d752cd63ce0dd12f51611527e5
                check_rc $? "git cherry-pick"
                git cherry-pick 9d53b47d4ea10ab1cdcfec5237b413a6ae0539ee
                check_rc $? "git cherry-pick"
                ;;
            vendor-qcom-opensource-wlan-qca-wifi-host-cmn)
                git rebase codelinaro/$codelinaro_branch
                check_rc $? "git rebase"
                git cherry-pick 5336f4036a3acc2509ba6750b6422e65f613b8e8
                check_rc $? "git cherry-pick"
                ;;
            *)
                git rebase codelinaro/$codelinaro_branch
                check_rc $? "git rebase"
                ;;
        esac
    fi

# move files to subdirectory to prepare for merge with unified kernel
    if [ ! "x"$filter_repo_subdir = "x" ]
    then
        cd $WORK_DIR/$i
        git filter-repo --force --to-subdirectory $filter_repo_subdir
        check_rc $? "git filter-repo"
    fi

    echoyellow "merge rebased moto $i to sm6375 kernel"
    cd $WORK_DIR/android_kernel_motorola_sm6375
    case $i in
        vendor-qcom-opensource-datarmnet | vendor-qcom-opensource-datarmnet-ext)
            git tag -d MMI-T3TC33.18-12-3
            ;;
    esac

    git remote add $i ../$i

    case $i in
        vendor-qcom-opensource-datarmnet | vendor-qcom-opensource-datarmnet-ext)
            git tag -d MMI-T3TC33.18-12-3
            git fetch $i --tags
            ;;
        *)
            git fetch $i --no-tags
            check_rc $? "git fetch"
            ;;
    esac

    case $i in
        motorola-kernel-modules)
            git rm sound/soc/codecs/Makefile include/linux/input/synaptics_tcm.h fs/exfat/Makefile fs/exfat/Kconfig drivers/misc/Makefile drivers/leds/trigger/Makefile Documentation/devicetree/bindings
            check_rc $? "git rm"
            git commit -m "remove files to prevent merge errors with motorola-kernel-modules"
            ;;
    esac

    case $i in
        vendor-qcom-opensource-datarmnet | vendor-qcom-opensource-datarmnet-ext)
            git merge --no-edit --allow-unrelated-histories $moto_branch
            check_rc $? "git merge $moto_branch"
            git tag -d MMI-T3TC33.18-12-3
            ;;
        *)
            git merge --no-edit --allow-unrelated-histories $i/$moto_branch
            check_rc $? "git merge $i/$moto_branch"
            ;;
    esac

    git remote remove $i
    rm -rf $WORK_DIR/$codelinaro_tag
    rm -rf $WORK_DIR/$i

done

cd $WORK_DIR/android_kernel_motorola_sm6375
echoyellow "applying local patches to sm6375 kernel"

find . -name "Android.mk" -delete
git commit -a -m "treewide: remove Android.mk"

for i in $WORK_DIR/_patches/*; do echo "--- patching $i"; git am --keep-cr $i || break; done
check_rc $? "git am"
git checkout -b lineage-21_no_fp_no_nfc
for i in $WORK_DIR/_patches_no_fp_no_nfc/*; do echo "--- patching $i"; git am --keep-cr $i || break; done
check_rc $? "git am"
