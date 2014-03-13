#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/RAINMACHINE
        NAME:=RAINMACHINE
endef

define Profile/RAINMACHINE/Description
        Package set optimized for the RAINMACHINE Sprinkler device
endef
$(eval $(call Profile,RAINMACHINE))
