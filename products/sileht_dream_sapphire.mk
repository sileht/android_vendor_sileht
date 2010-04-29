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

# This is the top-level configuration for a US-configured CyanogenMod build

$(call inherit-product, vendor/cyanogen/products/cyanogen.mk)

USE_CAMERA_STUB := false

PRODUCT_NAME := sileht_dream_sapphire
PRODUCT_BRAND := htc
PRODUCT_DEVICE := dream_sapphire
PRODUCT_MODEL := Dream/Sapphire
PRODUCT_MANUFACTURER := HTC
PRODUCT_BUILD_PROP_OVERRIDES += BUILD_ID=EPE54B BUILD_DISPLAY_ID=EPE54B BUILD_FINGERPRINT=google/passion/passion/mahimahi:2.1-update1/ERE27/24178:user/release-keys PRIVATE_BUILD_DESC="passion-user 2.1-update1 ERE27 24178 release-keys"

PRODUCT_PACKAGES += \
    Stk

PRODUCT_LOCALES:=\
        en_US \
        fr_FR

PRODUCT_COPY_FILES += \
    vendor/sileht/prebuilt/common/etc/bashrc:system/etc/bashrc 

UNWANTED_PRODUCT_COPY_FILES := \
	vendor/cyanogen/proprietary/Maps.apk:system/app/Maps.apk \
	vendor/cyanogen/proprietary/com.amazon.mp3.apk:system/app/com.amazon.mp3.apk

PRODUCT_COPY_FILES := $(filter-out $(UNWANTED_PRODUCT_COPY_FILES), $(PRODUCT_COPY_FILES))

PRODUCT_PROPERTY_OVERRIDES += \
          ro.modversion=CyanogenMod-5.0.7-sileht0 \
            ro.ril.hep=1 \
            ro.ril.enable.dtm=1 \
            ro.ril.hsdpa.category=8 \
            ro.ril.enable.a53=1 \
            ro.ril.enable.3g.prefix=1 \
            ro.ril.htcmaskw1.bitmask = 4294967295 \
            ro.ril.htcmaskw1 = 14449 \
            ro.ril.hsupa.category = 5

include frameworks/base/data/sounds/AudioPackage4.mk 
include vendor/htc/dream_sapphire/device_dream_sapphire.mk
