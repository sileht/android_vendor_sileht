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
#PRODUCT_BUILD_PROP_OVERRIDES += BUILD_ID=FRG83 BUILD_DISPLAY_ID=GRH78C BUILD_FINGERPRINT=tmobile/opal/sapphire/sapphire:2.2.1/FRG83/60505:user/release-keys PRIVATE_BUILD_DESC="opal-user 2.2.1 FRG83 60505 release-keys"
PRODUCT_BUILD_PROP_OVERRIDES += PRODUCT_NAME=dream_sapphire BUILD_ID=GRI40 BUILD_DISPLAY_ID=GRI40 BUILD_FINGERPRINT=google/passion/passion:2.3.3/GRI40/102588:user/release-keys PRIVATE_BUILD_DESC="passion-user 2.3.3 GRI40 102588 release-keys"

# Extra DS overlay
PRODUCT_PACKAGE_OVERLAYS += vendor/cyanogen/overlay/dream_sapphire

# This file is used to install the correct audio profile when booted
PRODUCT_COPY_FILES += \
    vendor/cyanogen/prebuilt/dream_sapphire/etc/init.d/02audio_profile:system/etc/init.d/02audio_profile \
    vendor/sileht/prebuilt/common/etc/init.d/07hsdpafix:system/etc/init.d/07hsdpafix

# Enable Compcache by default on D/S
PRODUCT_PROPERTY_OVERRIDES += \
	media.stagefright.enable-http=true \
	media.stagefright.enable-meta=true \
	media.stagefright.enable-player=true \
	media.stagefright.enable-scan=true \
    ro.compcache.default=18 \
	ro.ril.enable.a53=1 \

PRODUCT_PACKAGES += \
	rzscontrol

#
# Set ro.modversion
#
PRODUCT_PROPERTY_OVERRIDES += \
    	ro.modversion=CyanogenMod-$(CVERSION)$(VERSION_INDEX)

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

