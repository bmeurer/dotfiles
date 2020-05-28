#!/bin/bash
#
# install.sh - Install these dotfiles into your home directory
#
# Copyright 2012-2020 Benedikt Meurer
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Initialize the Git submodules
echo "Initializing git submodules..."
git submodule init || exit $?

# Synchronize the Git submodules
echo "Synchonizing git submodules..."
git submodule sync || exit $?

# Update the Git submodules
echo "Updating git submodules..."
git submodule update || exit $?

# Install fzf binary
(cd vim/vim.symlink/bundle/fzf && ./install --bin) || exit $?

# Create the symlinks
SYMLINKS=`find * -name '*.symlink'`
for SYMLINK in ${SYMLINKS}; do
	BASENAME=$(basename "${SYMLINK/%.symlink}")
	if [ -n "${BASENAME}" ]; then
		TARGET="${HOME}/.${BASENAME}"
		if [ -L "${TARGET}" ]; then
			rm -f "${TARGET}" || exit 1
		elif [ -e "${TARGET}"  ]; then
			mv "${TARGET}" "${TARGET}.bak" || exit 1
		fi
		echo "Installing ${SYMLINK} as ~/.${BASENAME}..."
		ln -s "${PWD#${HOME}/}/${SYMLINK}" "${TARGET}" || exit 1
	fi
done

# Update font-config
if [[ -x /usr/bin/fc-cache ]]; then
	echo "Updating font-config cache..."
	/usr/bin/fc-cache -f
fi

# Update gnome-terminal settings
if [[ -x /usr/bin/gsettings ]]; then
	echo "Updating gnome-terminal settings..."
	gprofile=$(/usr/bin/gsettings get org.gnome.Terminal.ProfilesList default)
	gprofile=${gprofile:1:-1}
	gschema=org.gnome.Terminal.Legacy.Profile
	gpath=/org/gnome/terminal/legacy/profiles:/:${gprofile}/
	while read line; do
		key=$(echo $line | cut -f1 -d' ')
		value=$(echo $line | cut -f2- -d' ')
		/usr/bin/gsettings set ${gschema}:${gpath} $key "$value"
	done <<EOF
foreground-color '#D3D7CF'
highlight-foreground-color '#ffffff'
palette ['#2E3436', '#CC0000', '#4E9A06', '#C4A000', '#3465A4', '#75507B', '#06989A', '#D3D7CF', '#555753', '#EF2929', '#8AE234', '#FCE94F', '#729FCF', '#AD7FA8', '#34E2E2', '#EEEEEC']
cursor-background-color '#000000'
scrollbar-policy 'always'
use-system-font false
bold-color '#000000'
cursor-foreground-color '#ffffff'
visible-name 'Benedikt'
scrollback-unlimited true
font 'JetBrains Mono 12'
highlight-colors-set false
use-theme-colors false
background-color 'rgb(0,43,54)'
highlight-background-color '#000000'
EOF
fi
