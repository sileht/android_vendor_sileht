# Inherit from those products. Most specific first.
$(call inherit-product, device/htc/dream_sapphire/full_dream_sapphire.mk)

DEFAULT_LAUNCHER := true
#CYANOGEN_WITH_GOOGLE := true

# Inherit some common cyanogenmod stuff.
$(call inherit-product, vendor/cyanogen/products/common.mk)

# Include GSM-only stuff
$(call inherit-product, vendor/cyanogen/products/gsm.mk)



CVERSION := $(shell sed -n '/[[:space:]]*ro.modversion=CyanogenMod-/s///gp' vendor/cyanogen/products/cyanogen_dream_sapphire.mk| tail -1)-mod
TARGET_ZIP := update-sm-$(CVERSION)
VERSION_INDEX := $(shell i=$$(ls -1 $(TARGET_ZIP)*-signed.zip 2>/dev/null | sed -n 's/$(TARGET_ZIP)\([[:digit:]]*\)-signed.zip/\1/gp' | sort -n | tail -1) ; echo $$((i+1)))

PRODUCT_NAME := sileht_dream_sapphire
PRODUCT_BRAND := google
PRODUCT_DEVICE := dream_sapphire
PRODUCT_MODEL := HTC Magic (Sileht)
PRODUCT_MANUFACTURER := HTC
PRODUCT_BUILD_PROP_OVERRIDES += BUILD_ID=FRF91 BUILD_DISPLAY_ID=FRF91 BUILD_FINGERPRINT=google/passion/passion/mahimahi:2.2/FRF91/43546:user/release-keys
PRIVATE_BUILD_DESC="sapphire-user 2.2 FRF91 43546 release-keys"

PRODUCT_SPECIFIC_DEFINES += TARGET_PRELINKER_MAP=$(TOP)/vendor/cyanogen/prelink-linux-arm-ds.map

# Build kernel
PRODUCT_SPECIFIC_DEFINES += TARGET_PREBUILT_KERNEL=
PRODUCT_SPECIFIC_DEFINES += TARGET_KERNEL_DIR=kernel-msm
PRODUCT_SPECIFIC_DEFINES += TARGET_KERNEL_CONFIG=cyanogen_msm_defconfig

# Extra DS overlay
PRODUCT_PACKAGE_OVERLAYS += vendor/cyanogen/overlay/dream_sapphire

# This file is used to install the correct audio profile when booted
PRODUCT_COPY_FILES += \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/init.d/02audio_profile:system/etc/init.d/02audio_profile


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

# Use the audio profile hack
WITH_DS_HTCACOUSTIC_HACK := true

# Use Windows Media
WITH_WINDOWS_MEDIA := true

PRODUCT_COPY_FILES += \
    vendor/sileht/prebuilt/common/etc/bashrc:system/etc/bashrc \
	vendor/cyanogen/prebuilt/dream_sapphire/media/bootanimation.zip:system/media/bootanimation.zip \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/init.d/02audio_profile:system/etc/init.d/02audio_profile \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/AudioPara_dream.csv:system/etc/AudioPara_dream.csv \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/AudioPara_sapphire.csv:system/etc/AudioPara_sapphire.csv

FINAL_TARGET_ZIP := $(TARGET_ZIP)$(VERSION_INDEX)-signed.zip
$(FINAL_TARGET_ZIP): bacon
	@echo "Finish $(FINAL_TARGET_ZIP)"
	./vendor/cyanogen/tools/squisher
	cp $$OUT/update-cm-$(CVERSION)$(VERSION_INDEX)-signed.zip $(FINAL_TARGET_ZIP)

it: $(FINAL_TARGET_ZIP)

up: $(FINAL_TARGET_ZIP)
	scp $(FINAL_TARGET_ZIP) site:dl/android/$(FINAL_TARGET_ZIP)

showinfos:
	$(call dump-product,vendor/sileht/products/sileht_dream_sapphire.mk)

