#!/bin/sh

WORK_DIR=`realpath $0`
WORK_DIR=`dirname $WORK_DIR`
cd $WORK_DIR

delete_subrepos () {
    for i in \
        kernel-camera-devicetree \
        kernel-devicetree \
        kernel-display-devicetree \
        kernel-msm-5.4-techpack-audio \
        kernel-msm-5.4-techpack-camera \
        kernel-msm-5.4-techpack-display \
        kernel-msm-5.4-techpack-video \
        kernel-msm-techpack-dataipa \
        motorola-kernel-modules \
        vendor-qcom-opensource-wlan-fw-api \
        vendor-qcom-opensource-wlan-qcacld-3.0 \
        vendor-qcom-opensource-wlan-qca-wifi-host-cmn \
        vendor-qcom-opensource-datarmnet \
        vendor-qcom-opensource-datarmnet-ext \
        ; \
    do
        rm -rfv $WORK_DIR/$i
    done
}

if [ ! -d $WORK_DIR/kernel-msm ]
then
    git clone https://github.com/MotorolaMobilityLLC/kernel-msm.git --branch android-13-release-t1ssms33.1-121-4-5 --single-branch
fi

if [ ! -d $WORK_DIR/kernel-codelinaro-5.4-r3 ]
then
    git clone https://git.codelinaro.org/clo/la/kernel/msm-5.4.git --branch kernel.lnx.5.4.r3-rel --single-branch kernel-codelinaro-5.4-r3
fi

if [ ! -d $WORK_DIR/android_kernel_motorola_sm6375 ]
then
    git init -b lineage-21 $WORK_DIR/android_kernel_motorola_sm6375
    cd $WORK_DIR/android_kernel_motorola_sm6375
    git remote add codelinaro ../kernel-codelinaro-5.4-r3
    git remote add moto-kernel ../kernel-msm
    cd $WORK_DIR
fi

delete_subrepos

git clone --branch android-13-release-t1ssis33.1-75-7-1 https://github.com/MotorolaMobilityLLC/kernel-msm-5.4-techpack-audio.git
git clone --branch android-13-release-t1rd33.116-33-3 https://github.com/MotorolaMobilityLLC/kernel-msm-5.4-techpack-camera.git
git clone --branch android-13-release-t1ssm33.1-121-4 https://github.com/MotorolaMobilityLLC/kernel-msm-5.4-techpack-display.git
git clone --branch android-13-release-t1ssm33.1-121-4 https://github.com/MotorolaMobilityLLC/kernel-msm-5.4-techpack-video.git
git clone --branch android-13-release-ttpn https://github.com/MotorolaMobilityLLC/vendor-qcom-opensource-wlan-qcacld-3.0.git
git clone --branch android-13-release-ttpn https://github.com/MotorolaMobilityLLC/vendor-qcom-opensource-wlan-qca-wifi-host-cmn.git
git clone --branch android-13-release-t1sus33.1-124-6-7 https://github.com/MotorolaMobilityLLC/vendor-qcom-opensource-wlan-fw-api.git
git clone --branch android-13-release-t1ssm33.1-121-4 https://github.com/MotorolaMobilityLLC/kernel-devicetree.git
git clone --branch android-13-release-ttpn https://github.com/MotorolaMobilityLLC/kernel-camera-devicetree.git
git clone --branch android-13-release-traa https://github.com/MotorolaMobilityLLC/kernel-display-devicetree.git
git clone --branch android-13-release-tra https://github.com/MotorolaMobilityLLC/motorola-kernel-modules.git

git clone --branch android-13-release-t1sus33.1-124-6-7 https://github.com/MotorolaMobilityLLC/kernel-msm-techpack-dataipa.git
# bangkk (G84 5G = sm6375)
git clone --branch MMI-T3TC33.18-12-3 https://github.com/MotorolaMobilityLLC/vendor-qcom-opensource-datarmnet.git
git clone --branch MMI-T3TC33.18-12-3 https://github.com/MotorolaMobilityLLC/vendor-qcom-opensource-datarmnet-ext.git

cd $WORK_DIR/kernel-msm-5.4-techpack-audio
git filter-repo --force --to-subdirectory techpack/audio/

cd $WORK_DIR/kernel-msm-5.4-techpack-camera
git filter-repo --force --to-subdirectory techpack/camera/

cd $WORK_DIR/kernel-msm-5.4-techpack-display
git filter-repo --force --to-subdirectory techpack/display/

cd $WORK_DIR/kernel-msm-5.4-techpack-video
git filter-repo --force --to-subdirectory techpack/video/

cd $WORK_DIR/vendor-qcom-opensource-wlan-qcacld-3.0
git filter-repo --force --to-subdirectory drivers/staging/qcacld-3.0/

cd $WORK_DIR/vendor-qcom-opensource-wlan-qca-wifi-host-cmn
git filter-repo --force --to-subdirectory drivers/staging/qca-wifi-host-cmn/

cd $WORK_DIR/vendor-qcom-opensource-wlan-fw-api
git filter-repo --force --to-subdirectory drivers/staging/fw-api/

cd $WORK_DIR/kernel-devicetree
git filter-repo --force --to-subdirectory arch/arm64/boot/dts/vendor/

cd $WORK_DIR/kernel-camera-devicetree
git filter-repo --force --to-subdirectory arch/arm64/boot/dts/vendor/qcom/camera-legacy/rhodep/

cd $WORK_DIR/kernel-display-devicetree
git filter-repo --force --to-subdirectory arch/arm64/boot/dts/vendor/qcom/

cd $WORK_DIR/kernel-msm-techpack-dataipa
git filter-repo --force --to-subdirectory techpack/dataipa/

cd $WORK_DIR/vendor-qcom-opensource-datarmnet
git filter-repo --force --to-subdirectory techpack/datarmnet/

cd $WORK_DIR/vendor-qcom-opensource-datarmnet-ext
git filter-repo --force --to-subdirectory techpack/datarmnet-ext/

cd $WORK_DIR/android_kernel_motorola_sm6375
git fetch codelinaro
git fetch moto-kernel
git checkout lineage-21

# reset to second to last Motorola commit, the newest one is already included in codelinaro kernel
git reset ee5fdf4a678a87f3e73fa60dbe8654a8549a5baf --hard

# neuester gemeinsamer commit 32d82a6c05ae628b0bca227aa13311b686c1799f vom 08.06.2023
git rebase codelinaro/kernel.lnx.5.4.r3-rel

git remote add techpack-audio ../kernel-msm-5.4-techpack-audio
git fetch techpack-audio --no-tags
git merge --no-edit --allow-unrelated-histories techpack-audio/android-13-release-t1ssis33.1-75-7-1
git remote remove techpack-audio

git remote add techpack-camera ../kernel-msm-5.4-techpack-camera/
git fetch techpack-camera --no-tags
git merge --no-edit --allow-unrelated-histories techpack-camera/android-13-release-t1rd33.116-33-3
git remote remove techpack-camera

git remote add techpack-dataipa ../kernel-msm-techpack-dataipa/
git fetch techpack-dataipa --no-tags
git merge --no-edit --allow-unrelated-histories techpack-dataipa/android-13-release-t1sus33.1-124-6-7
git remote remove techpack-dataipa

git remote add techpack-display ../kernel-msm-5.4-techpack-display/
git fetch techpack-display --no-tags
git merge --no-edit --allow-unrelated-histories techpack-display/android-13-release-t1ssm33.1-121-4
git remote remove techpack-display

git remote add techpack-video ../kernel-msm-5.4-techpack-video/
git fetch techpack-video --no-tags
git merge --no-edit --allow-unrelated-histories techpack-video/android-13-release-t1ssm33.1-121-4
git remote remove techpack-video

git remote add vendor-qcom-opensource-wlan-qcacld-3.0 ../vendor-qcom-opensource-wlan-qcacld-3.0/
git fetch vendor-qcom-opensource-wlan-qcacld-3.0 --no-tags
git merge --no-edit --allow-unrelated-histories vendor-qcom-opensource-wlan-qcacld-3.0/android-13-release-ttpn
git remote remove vendor-qcom-opensource-wlan-qcacld-3.0

git remote add vendor-qcom-opensource-wlan-qca-wifi-host-cmn ../vendor-qcom-opensource-wlan-qca-wifi-host-cmn/
git fetch vendor-qcom-opensource-wlan-qca-wifi-host-cmn --no-tags
git merge --no-edit --allow-unrelated-histories vendor-qcom-opensource-wlan-qca-wifi-host-cmn/android-13-release-ttpn
git remote remove vendor-qcom-opensource-wlan-qca-wifi-host-cmn

git remote add vendor-qcom-opensource-wlan-fw-api ../vendor-qcom-opensource-wlan-fw-api/
git fetch vendor-qcom-opensource-wlan-fw-api --no-tags
git merge --no-edit --allow-unrelated-histories vendor-qcom-opensource-wlan-fw-api/android-13-release-t1sus33.1-124-6-7
git remote remove vendor-qcom-opensource-wlan-fw-api

git remote add kernel-devicetree ../kernel-devicetree
git fetch kernel-devicetree --no-tags
git merge --no-edit --allow-unrelated-histories kernel-devicetree/android-13-release-t1ssm33.1-121-4
git remote remove kernel-devicetree

git remote add kernel-camera-devicetree ../kernel-camera-devicetree
git fetch kernel-camera-devicetree --no-tags
git merge --no-edit --allow-unrelated-histories kernel-camera-devicetree/android-13-release-ttpn
git remote remove kernel-camera-devicetree

git remote add kernel-display-devicetree ../kernel-display-devicetree
git fetch kernel-display-devicetree --no-tags
git merge --no-edit --allow-unrelated-histories kernel-display-devicetree/android-13-release-traa
git remote remove kernel-display-devicetree

git remote add motorola-kernel-modules ../motorola-kernel-modules/
git fetch motorola-kernel-modules --no-tags
git rm sound/soc/codecs/Makefile include/linux/input/synaptics_tcm.h fs/exfat/Makefile fs/exfat/Kconfig drivers/misc/Makefile drivers/leds/trigger/Makefile Documentation/devicetree/bindings
git commit -m "remove files to prevent merge errors with motorola-kernel-modules"
git merge --no-edit --allow-unrelated-histories motorola-kernel-modules/android-13-release-tra
git remote remove motorola-kernel-modules

git tag -d MMI-T3TC33.18-12-3
git remote add techpack-datarmnet ../vendor-qcom-opensource-datarmnet/
git fetch techpack-datarmnet --tags
git merge --no-edit --allow-unrelated-histories MMI-T3TC33.18-12-3
git remote remove techpack-datarmnet

git tag -d MMI-T3TC33.18-12-3
git remote add techpack-datarmnet-ext ../vendor-qcom-opensource-datarmnet-ext/
git fetch techpack-datarmnet-ext --tags
git merge --no-edit --allow-unrelated-histories MMI-T3TC33.18-12-3
git remote remove techpack-datarmnet-ext
git tag -d MMI-T3TC33.18-12-3

delete_subrepos

find . -name "Android.mk" -delete
git commit -a -m "treewide: remove Android.mk"

for i in $WORK_DIR/_patches/*; do echo "--- patching $i"; git am --keep-cr $i || break; done
