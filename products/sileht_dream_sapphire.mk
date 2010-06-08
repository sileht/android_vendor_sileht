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
#WITH_JIT := true
#WITH_JIT_TUNING := true

PRODUCT_NAME := sileht_dream_sapphire
PRODUCT_BRAND := htc
PRODUCT_DEVICE := dream_sapphire
PRODUCT_MODEL := Dream/Sapphire
PRODUCT_MANUFACTURER := HTC
PRODUCT_BUILD_PROP_OVERRIDES += BUILD_ID=EPE54B BUILD_DISPLAY_ID=EPE54B BUILD_FINGERPRINT=google/passion/passion/mahimahi:2.1-update1/ERE27/24178:user/release-keys PRIVATE_BUILD_DESC="passion-user 2.1-update1 ERE27 24178 release-keys"

PRODUCT_PACKAGES += \
    Stk

#PRODUCT_LOCALES:=\
#        en_US \
#        fr_FR

PRODUCT_COPY_FILES += \
    vendor/sileht/prebuilt/common/etc/bashrc:system/etc/bashrc \
	vendor/cyanogen/prebuilt/dream_sapphire/media/bootanimation.zip:system/media/bootanimation.zip

CVERSION := $(shell sed -n '/[[:space:]]*ro.modversion=CyanogenMod-/s///gp' vendor/cyanogen/products/cyanogen_dream_sapphire.mk | tail -1)-mod

TARGET_ZIP := update-sm-$(CVERSION)

VERSION_INDEX := $(shell i=$$(ls -1 $(TARGET_ZIP)*-signed.zip 2>/dev/null | sed -n 's/$(TARGET_ZIP)\([[:digit:]]*\)-signed.zip/\1/gp' | sort -n | tail -1) ; echo $$((i+1)))


PRODUCT_PROPERTY_OVERRIDES += \
            ro.modversion=CyanogenMod-$(CVERSION)$(VERSION_INDEX)
            #dalvik.vm.execution-mode=int:jit \


include frameworks/base/data/sounds/AudioPackage4.mk 
include vendor/htc/dream_sapphire/device_dream_sapphire.mk

FINAL_TARGET_ZIP := $(TARGET_ZIP)$(VERSION_INDEX)-signed.zip

$(FINAL_TARGET_ZIP): bacon
	@echo "Finish $(FINAL_TARGET_ZIP)"
	./vendor/cyanogen/tools/squisher
	mv $$OUT/update-cm-$(CVERSION)$(VERSION_INDEX)-signed.zip $(FINAL_TARGET_ZIP)


it: $(FINAL_TARGET_ZIP)

up: it
	scp $(FINAL_TARGET_ZIP) site:dl/android/$(FINAL_TARGET_ZIP)

