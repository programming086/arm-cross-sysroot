#!/bin/bash
#
# ARM Cross Sysroot is a script bundle to cross-compile libraries on a 
# host computer for an ARM target. This git repo contains just scripts 
# to build the libraries for an ARM target. It does not contains any 
# of the the source. They will be downloaded during the build process.
#
# Copyright (C) 2014-15  Knut Welzel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 

#clear

##
## Working directory of the Script
##
GV_base_dir=$(cd "${0%/*}" && pwd -P)

## Build start time
GV_total_start=$(date +%s)

## Build platform
GV_build_os=$(uname -s)

## Make some aliases for gnu commands
if [ $GV_build_os = "Darwin" ]; then 
	LIBTOOL=glibtool
	SED=gsed
	AWK=gawk
else
	LIBTOOL=libtool
	SED=sed
	AWK=awk
fi


##
## check if config.cfg exists or exit
##
if ! [ -f "${GV_base_dir}/config.cfg" ]; then
	
	echo "Error: The configuration file could not be found!"
	echo 
	echo "Rename or copy the file config.cfg.sample into config.cfg" \
	     "and customize the variable according to your system settings."
	echo "  $ cp config.cfg.sample config.cfg"
	echo "  $ nano config.cfg"
	echo 
	exit 1
fi


##
## Includ library and configuration files 
##
source "${GV_base_dir}/config.cfg"
source "${GV_base_dir}/include/settings.cfg"
source "${GV_base_dir}/include/system.sh"
source "${GV_base_dir}/include/command.sh"
source "${GV_base_dir}/include/tools.sh"
source "${GV_base_dir}/include/files.sh"
source "${GV_base_dir}/include/build.sh"


##
## Parse the comandline arguments 
##
FU_tools_parse_arguments $@


echo "Start to build an advanced sysroot for ${UV_board}."
echo


##
## test required software for host
##
FU_system_require

##
## Mac OS X needs an case sensitiv diskimage
## !!! libX11 can only build on a case sensitiv filesystem !!!
##
if [ $GV_build_os = "Darwin" ]; then 
	FU_tools_create_source_image
	FU_tools_access_rights
else
	# test access rights for building the sysroot
	FU_tools_access_rights
fi

##
## Build and Version information
##
if ! [ -f "${UV_sysroot_dir}/buildinfo.txt" ]; then
	touch "${UV_sysroot_dir}/buildinfo.txt"
else
	echo >> "${UV_sysroot_dir}/buildinfo.txt"
	echo "*** Rebuild ***" >> "${UV_sysroot_dir}/buildinfo.txt"
	echo >> "${UV_sysroot_dir}/buildinfo.txt"
fi
cat >> "${UV_sysroot_dir}/buildinfo.txt" << EOF
Script Version: $GV_version
Script Date:	$GV_build_date
Build Date:		$(date)
Build User:		$(whoami)
Build Machine:	$(uname -v)

Packages:
EOF


##
## Make sure that we are still in working directory 
##
cd $GV_base_dir


##
## Execute all formulas. The scripts have to be processed in this sequence!
##
for LV_formula in "${GV_build_formulas[@]}"; do 
	
	source "${GV_base_dir}/formula/${LV_formula}.sh"
	
#	rm -rf "${UV_sysroot_dir}"
#	mkdir -p "${UV_sysroot_dir}"
done


echo "Cleanup build directory."

if [ $GV_build_os = "Darwin" ]; then 
	echo -n "Unmount source image... " 
	hdiutil detach $GV_source_dir >/dev/null 2>&1 || exit 1
	rm -rf "${GV_base_dir}/sources.sparseimage"
	echo "done"
else
	rm -rf "${BASE_DIR}/src"
fi


GV_total_end=`date +%s`
GV_total_time=`expr $GV_total_end - $GV_total_start`


echo "" | tee -a "${UV_sysroot_dir}/buildinfo.txt"
echo -n "Sysroot successfully build in " | tee -a "${UV_sysroot_dir}/buildinfo.txt"
echo $GV_total_time | $AWK '{print strftime("%H:%M:%S", $1,1)}' | tee -a "${UV_sysroot_dir}/buildinfo.txt"
echo ""
