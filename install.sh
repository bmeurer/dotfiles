#!/bin/sh
#
# install.sh - Install these dotfiles into your home directory
#
# Copyright 2012 Benedikt Meurer
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

SYMLINKS=`find * -name '*.symlink'`
for SYMLINK in ${SYMLINKS}; do
	BASENAME=$(basename "${SYMLINK/%.symlink}")
	if [ -n "${BASENAME}" ]; then
		TARGET="${HOME}/.${BASENAME}"
		if [ -e "${TARGET}" -a ! -L "${TARGET}" ]; then
			mv "${TARGET}" "${TARGET}.bak" || exit 1
		fi
		echo "Installing ${SYMLINK} as ~/.${BASENAME}..."
		ln -sf "${PWD#${HOME}/}/${SYMLINK}" "${TARGET}" || exit 1
	fi
done
