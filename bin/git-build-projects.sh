#!/bin/sh
#
# git-fetch-projects.sh - Update projects with respect to upstream.
#
# Copyright 2021-2022 Benedikt Meurer
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

# Make sure that depot_tools are up-to-date first.
~/Applications/depot_tools/update_depot_tools || exit $?

# Build devtools-frontend first
(\
	cd "${HOME}/Projects/devtools/devtools-frontend" && \
	git diff --quiet && \
	git checkout "main" && \
	git cl archive -f && \
	git pull && \
	gclient sync && \
	gn gen "out/Default" && \
	autoninja -C "out/Default" \
) || exit $?

# Build v8 next
(\
	cd "${HOME}/Projects/v8/v8" && \
	mkdir -p "/dev/shm/v8_v8_out_Debug_obj" && \
	ln -fsT "/dev/shm/v8_v8_out_Debug_obj" "out/Debug/obj" && \
	mkdir -p "/dev/shm/v8_v8_out_Default_obj" && \
	ln -fsT "/dev/shm/v8_v8_out_Default_obj" "out/Default/obj" && \
	mkdir -p "/dev/shm/v8_v8_out_Release_obj" && \
	ln -fsT "/dev/shm/v8_v8_out_Release_obj" "out/Release/obj" && \
	git diff --quiet && \
	git checkout "main" && \
	git cl archive -f && \
	git pull && \
	gclient sync && \
	gn gen "out/Debug" && \
	autoninja -C "out/Debug" && \
	gn gen "out/Default" && \
	autoninja -C "out/Default" && \
	gn gen "out/Release" && \
	autoninja -C "out/Release" && \
	tools/clang/scripts/generate_compdb.py -p "out/Default" -o "compile_commands.json" \
) || exit $?

# Build chromium last
(\
	cd "${HOME}/Projects/chromium/src" && \
	mkdir -p "/dev/shm/chromium_src_out_Debug_obj" && \
	ln -fsT "/dev/shm/chromium_src_out_Debug_obj" "out/Debug/obj" && \
	mkdir -p "/dev/shm/chromium_src_out_Default_obj" && \
	ln -fsT "/dev/shm/chromium_src_out_Default_obj" "out/Default/obj" && \
	git diff --quiet && \
	git checkout "main" && \
	git cl archive -f && \
	git pull && \
	gclient sync && \
	gn gen "out/Debug" && \
	autoninja -C "out/Debug" blink_tests chrome && \
	gn gen "out/Default" && \
	autoninja -C "out/Default" blink_tests chrome && \
	tools/clang/scripts/generate_compdb.py -p "out/Default" -o "compile_commands.json" \
) || exit $?

