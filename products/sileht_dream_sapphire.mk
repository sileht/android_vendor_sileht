# Inherit AOSP device configuration for dream_sapphire.
$(call inherit-product, device/htc/dream_sapphire/full_dream_sapphire.mk)

# Inherit some common cyanogenmod stuff.
$(call inherit-product, vendor/cyanogen/products/common.mk)

# Include GSM-only stuff
$(call inherit-product, vendor/cyanogen/products/gsm.mk)

CVERSION := $(shell sed -n '/[[:space:]]*ro.modversion=CyanogenMod-/s///gp' vendor/cyanogen/products/cyanogen_dream_sapphire.mk| tail -1)-mod
TARGET_ZIP := update-sm-$(CVERSION)
VERSION_INDEX := $(shell i=$$(ls -1 $(TARGET_ZIP)*-signed.zip 2>/dev/null | sed -n 's/$(TARGET_ZIP)\([[:digit:]]*\)-signed.zip/\1/gp' | sort -n | tail -1) ; echo $$((i+1)))

#
# Setup device specific product configuration.
#
PRODUCT_NAME := sileht_dream_sapphire
PRODUCT_BRAND := google
PRODUCT_DEVICE := dream_sapphire
PRODUCT_MODEL := Dream/Sapphire
PRODUCT_MANUFACTURER := HTC
PRODUCT_BUILD_PROP_OVERRIDES += BUILD_ID=FRG83 BUILD_DISPLAY_ID=FRG83 BUILD_FINGERPRINT=tmobile/opal/sapphire/sapphire:2.2.1/FRG83/60505:user/release-keys PRIVATE_BUILD_DESC="opal-user 2.2.1 FRG83 60505 release-keys"

# Build kernel
PRODUCT_SPECIFIC_DEFINES += TARGET_PREBUILT_KERNEL=
PRODUCT_SPECIFIC_DEFINES += TARGET_KERNEL_DIR=kernel-msm
PRODUCT_SPECIFIC_DEFINES += TARGET_KERNEL_CONFIG=cyanogen_msm_defconfig

# Extra DS overlay
PRODUCT_PACKAGE_OVERLAYS += vendor/cyanogen/overlay/dream_sapphire

# This file is used to install the correct audio profile when booted
PRODUCT_COPY_FILES += \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/init.d/02audio_profile:system/etc/init.d/02audio_profile \
    vendor/sileht/prebuilt/common/etc/init.d/30tweaks:system/etc/init.d/30tweaks

# Enable Compcache by default on D/S
PRODUCT_PROPERTY_OVERRIDES += \
    ro.compcache.default=0 \
	ro.ril.hep=1 \
	ro.ril.enable.dtm=1 \
	ro.ril.enable.a53=1 \
	ro.ril.hsdpa.category=8 \
	ro.ril.hsupa.category=5 \
	ro.ril.enable.3g.prefix=1
#	ro.ril.htcmaskw1.bitmask = 4294967295 \
#	ro.ril.htcmaskw1 = 14449 \

#
# Set ro.modversion
#
ifdef CYANOGEN_NIGHTLY
    PRODUCT_PROPERTY_OVERRIDES += \
        ro.modversion=CyanogenMod-6-$(shell date +%m%d%Y)-NIGHTLY-DS
else
    PRODUCT_PROPERTY_OVERRIDES += \
    	ro.modversion=CyanogenMod-$(CVERSION)$(VERSION_INDEX)
endif

# Use the audio profile hack
WITH_DS_HTCACOUSTIC_HACK := true

#
# Copy DS specific prebuilt files
#
PRODUCT_COPY_FILES +=  \
    vendor/cyanogen/prebuilt/mdpi/media/bootanimation.zip:system/media/bootanimation.zip \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/AudioPara_dream.csv:system/etc/AudioPara_dream.csv \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/AudioPara_sapphire.csv:system/etc/AudioPara_sapphire.csv

FINAL_TARGET_ZIP := $(TARGET_ZIP)$(VERSION_INDEX)-signed.zip
$(FINAL_TARGET_ZIP): bacon
	@echo "Finish $(FINAL_TARGET_ZIP)"
	cp $${OUT}/update-cm-$(CVERSION)$(VERSION_INDEX)-signed.zip $(FINAL_TARGET_ZIP)

it: $(FINAL_TARGET_ZIP)

up: $(FINAL_TARGET_ZIP)
	scp $(FINAL_TARGET_ZIP) site:dl/android/$(FINAL_TARGET_ZIP)

showinfos:
	$(call dump-product,vendor/sileht/products/sileht_dream_sapphire.mk)

