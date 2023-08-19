# piimager
Generates customized 32/64 PiOS images and writes to SD card.

Creates PiOS 32/64 images (version specified in script) with modified /boot/firstrun.sh and /boot/cmdline.txt files that create first user, configures locales/tz/keyboard, installs wifi settings. Process consists of 3 reboots (same as official imager):

Initial boot--will run init line and resize partitions, generate ssh keys

2nd boot--will boot to hostname:rasperrypi and default user (was pi, bypasses recent required user input). Runs firstrun.sh

3nd boot--boots to new configuration.

The reboot process is quick on a RPi4B, seconds on a RPi3B+, and ~3mins on a RPiZeroW

Code tested on RPi4B booting from SSD to use /dev/mmclkb0 (SD card reader) for writing image.
Images tested in RPi4B (64bit), RPi3B (32 & 64bit), and RPiZeroW (32bit).

First GitHub contribution...standing on shoulders of giants here.
