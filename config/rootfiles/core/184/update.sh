#!/bin/bash
############################################################################
#                                                                          #
# This file is part of the IPFire Firewall.                                #
#                                                                          #
# IPFire is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation; either version 3 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# IPFire is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with IPFire; if not, write to the Free Software                    #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA #
#                                                                          #
# Copyright (C) 2023 IPFire-Team <info@ipfire.org>.                        #
#                                                                          #
############################################################################
#
. /opt/pakfire/lib/functions.sh
/usr/local/bin/backupctrl exclude >/dev/null 2>&1

core=184

# Remove old core updates from pakfire cache to save space...
for (( i=1; i<=$core; i++ )); do
	rm -f /var/cache/pakfire/core-upgrade-*-$i.ipfire
done

# Stop services
/etc/init.d/squid stop
/etc/init.d/vnstat stop

# Extract files
extract_files

# Remove dropped elfutils addon
rm -vf \
	/opt/pakfire/db/installed/meta-elfutils \
	/opt/pakfire/db/meta/meta-elfutils \
	/opt/pakfire/db/rootfiles/elfutils \
	/usr/bin/eu-addr2line \
	/usr/bin/eu-ar \
	/usr/bin/eu-elfclassify \
	/usr/bin/eu-elfcmp \
	/usr/bin/eu-elfcompress \
	/usr/bin/eu-elflint \
	/usr/bin/eu-findtextrel \
	/usr/bin/eu-make-debug-archive \
	/usr/bin/eu-nm \
	/usr/bin/eu-objdump \
	/usr/bin/eu-ranlib \
	/usr/bin/eu-readelf \
	/usr/bin/eu-size \
	/usr/bin/eu-srcfiles \
	/usr/bin/eu-stack \
	/usr/bin/eu-strings \
	/usr/bin/eu-strip \
	/usr/bin/eu-unstrip

# Remove files

# update linker config
ldconfig

# Update Language cache
/usr/local/bin/update-lang-cache

# Filesytem cleanup
/usr/local/bin/filesystem-cleanup

# fix module compression of rtl8812au
xz -d /lib/modules/6.6.15-ipfire/extra/wlan/8812au.ko.xz
xz --check=crc32 --lzma2=dict=512KiB /lib/modules/6.6.15-ipfire/extra/wlan/8812au.ko

# Apply local configuration to sshd_config
/usr/local/bin/sshctrl

# Start services
telinit u
/etc/init.d/vnstat start
/etc/init.d/collectd restart
/etc/init.d/suricata restart
/etc/init.d/unbound restart
if [ -f /var/ipfire/proxy/enable ]; then
	/etc/init.d/squid start
fi

# This update needs a reboot...
touch /var/run/need_reboot

# Finish
/etc/init.d/fireinfo start
sendprofile

# Update grub config to display new core version
if [ -e /boot/grub/grub.cfg ]; then
	grub-mkconfig -o /boot/grub/grub.cfg
fi

sync

# Don't report the exitcode last command
exit 0
