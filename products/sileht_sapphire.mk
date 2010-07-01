#
# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


# Inherit from those products. Most specific first.
$(call inherit-product, device/htc/sapphire/full_sapphire.mk)

# Inherit some common cyanogenmod stuff.
$(call inherit-product, vendor/cyanogen/products/common.mk)

TARGET_KERNEL_DIR := kernel-msm
TARGET_KERNEL_CONFIG := cyanogen_msm_defconfig


CVERSION := $(shell sed -n '/[[:space:]]*ro.modversion=CyanogenMod-/s///gp' vendor/cyanogen/products/cyanogen_sapphire.mk | tail -1)-mod
TARGET_ZIP := update-sm-$(CVERSION)
VERSION_INDEX := $(shell i=$$(ls -1 $(TARGET_ZIP)*-signed.zip 2>/dev/null | sed -n 's/$(TARGET_ZIP)\([[:digit:]]*\)-signed.zip/\1/gp' | sort -n | tail -1) ; echo $$((i+1)))


PRODUCT_NAME := sileht_sapphire
PRODUCT_BRAND := google
PRODUCT_DEVICE := sapphire
PRODUCT_MODEL := HTC Magic (Sileht)
PRODUCT_MANUFACTURER := HTC
PRODUCT_BUILD_PROP_OVERRIDES += BUILD_ID=FRF83 BUILD_DISPLAY_ID=FRF83 PRODUCT_NAME=passion BUILD_FINGERPRINT=google/passion/passion/mahimahi:2.2/FRF83/42295:user/release-keys TARGET_BUILD_TYPE=userdebug
PRIVATE_BUILD_DESC="passion-user 2.2 FRF83 42295 release-keys"

PRODUCT_PROPERTY_OVERRIDES += \
    ro.modversion=CyanogenMod-$(CVERSION)$(VERSION_INDEX) \
	ro.ril.hep=1 \
	ro.ril.enable.dtm=1 \
	ro.ril.enable.a53=1 \
	ro.ril.hsdpa.category=8 \
	ro.ril.hsupa.category=5 \
	ro.ril.enable.3g.prefix=1
#	ro.ril.htcmaskw1.bitmask = 4294967295 \
#	ro.ril.htcmaskw1 = 14449 \

PRODUCT_COPY_FILES += \
    vendor/sileht/prebuilt/common/etc/bashrc:system/etc/bashrc \
	vendor/cyanogen/prebuilt/dream-sapphire/media/bootanimation.zip:system/media/bootanimation.zip \

USE_CAMERA_STUB := false

FINAL_TARGET_ZIP := $(TARGET_ZIP)$(VERSION_INDEX)-signed.zip
$(FINAL_TARGET_ZIP): bacon
	@echo "Finish $(FINAL_TARGET_ZIP)"
	./vendor/cyanogen/tools/squisher
	cp $$OUT/update-cm-$(CVERSION)$(VERSION_INDEX)-signed.zip $(FINAL_TARGET_ZIP)

it: $(FINAL_TARGET_ZIP)

up: $(FINAL_TARGET_ZIP)
	scp $(FINAL_TARGET_ZIP) site:dl/android/$(FINAL_TARGET_ZIP)

showinfos:
	$(call dump-product,vendor/sileht/products/sileht_sapphire.mk)

