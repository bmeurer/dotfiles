#!/bin/sh
#
# tmux-chromium - Setup tmux session for chromium development
#
# Copyright 2021-2025 Benedikt Meurer
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

# Try to attach to running chromium session
tmux attach-session -t chromium && exit $?

# Spawn new chromium session
exec tmux \
	new-session -c "${HOME}/Projects/chromium/src" -n chromium -s chromium \;\
	new-window -d -c "${HOME}/Projects/devtools/devtools-frontend" -n devtools \;\
	new-window -d -c "${HOME}/Projects/repros" -n repros
