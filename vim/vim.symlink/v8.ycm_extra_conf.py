# Copyright (c) 2014 Benedikt Meurer <bmeurer@google.com>.
# All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Autocompletion config for YouCompleteMe in V8.
#
# USAGE:
#
#   1. Install YCM [https://github.com/Valloric/YouCompleteMe]
#          (Googlers should check out [go/ycm])
#
#   2. Point to this config file in your .vimrc:
#          let g:ycm_global_ycm_extra_conf =
#              '~/.vim/v8.ycm_extra_conf.py'
#
#   3. Profit
#
#
# Usage notes:
#
#   * You must use ninja & clang to build V8.
#
#   * You must have run gyp_v8 and built V8 recently.
#
#
# Hacking notes:
#
#   * The purpose of this script is to construct an accurate enough command line
#     for YCM to pass to clang so it can build and extract the symbols.
#
#   * Right now, we only pull the -I and -D flags. That seems to be sufficient
#     for everything I've used it for.
#
#   * That whole ninja & clang thing? We could support other configs if someone
#     were willing to write the correct commands and a parser.
#
#   * This has only been tested on gPrecise.


import os
import subprocess


# Flags from YCM's default config.
flags = [
'-std=c++11',
'-x',
'c++',
]


def PathExists(*args):
  return os.path.exists(os.path.join(*args))


def FindV8SrcFromFilename(filename):
  """Searches for the root of the V8 checkout.

  Simply checks parent directories until it finds .gclient and src/.

  Args:
    filename: (String) Path to source file being edited.

  Returns:
    (String) Path of 'src/', or None if unable to find.
  """
  curdir = os.path.normpath(os.path.dirname(filename))
  while not (PathExists(curdir, 'src')
             and PathExists(curdir, '.git')
             and PathExists(curdir, 'build')
             and PathExists(curdir, 'out')):
    nextdir = os.path.normpath(os.path.join(curdir, '..'))
    if nextdir == curdir:
      return None
    curdir = nextdir
  return os.path.join(curdir)


# Largely copied from ninja-build.vim (guess_configuration)
def GetNinjaOutputDirectory(v8_root):
  """Returns either <v8_root>/out/Release or <v8_root>/out/Debug.

  The configuration chosen is the one most recently generated/built."""
  root = os.path.join(v8_root, 'out')
  debug_path = os.path.join(root, 'Debug')
  release_path = os.path.join(root, 'Release')

  def is_release_15s_newer(test_path):
    try:
      debug_mtime = os.path.getmtime(os.path.join(debug_path, test_path))
    except os.error:
      debug_mtime = 0
    try:
      rel_mtime = os.path.getmtime(os.path.join(release_path, test_path))
    except os.error:
      rel_mtime = 0
    return rel_mtime - debug_mtime >= 15

  if is_release_15s_newer('build.ninja') or is_release_15s_newer('protoc'):
    return release_path
  return debug_path


def GetClangCommandFromNinjaForFilename(v8_root, filename):
  """Returns the command line to build |filename|.

  Asks ninja how it would build the source file. If the specified file is a
  header, tries to find its companion source file first.

  Args:
    v8_root: (String) Path to src/.
    filename: (String) Path to source file being edited.

  Returns:
    (List of Strings) Command line arguments for clang.
  """
  if not v8_root:
    return []

  # Generally, everyone benefits from including V8's src/, because all of
  # V8's includes are relative to that.
  v8_flags = ['-I' + os.path.join(v8_root)]

  # Header files can't be built. Instead, try to match a header file to its
  # corresponding source file.
  if filename.endswith('.h'):
    alternates = ['.cc', '.cpp']
    for alt_extension in alternates:
      alt_name = filename[:-2] + alt_extension
      if os.path.exists(alt_name):
        filename = alt_name
        break
    else:
      # If this is a standalone .h file with no source, the best we can do is
      # try to use the default flags.
      return v8_flags

  # Ninja needs the path to the source file from the output build directory.
  # Cut off the common part and /.
  subdir_filename = filename[len(v8_root)+1:]
  rel_filename = os.path.join('..', '..', subdir_filename)

  out_dir = GetNinjaOutputDirectory(v8_root)

  # Ask ninja how it would build our source file.
  p = subprocess.Popen(['ninja', '-v', '-C', out_dir, '-t',
                        'commands', rel_filename + '^'],
                       stdout=subprocess.PIPE)
  stdout, stderr = p.communicate()
  if p.returncode:
    return v8_flags

  # Ninja might execute several commands to build something. We want the last
  # clang command.
  clang_line = None
  for line in reversed(stdout.split('\n')):
    if 'clang' in line:
      clang_line = line
      break
  else:
    return v8_flags

  # Parse out the -I and -D flags. These seem to be the only ones that are
  # important for YCM's purposes.
  for flag in clang_line.split(' '):
    if flag.startswith('-I'):
      # Relative paths need to be resolved, because they're relative to the
      # output dir, not the source.
      if flag[2] == '/':
        v8_flags.append(flag)
      else:
        abs_path = os.path.normpath(os.path.join(out_dir, flag[2:]))
        v8_flags.append('-I' + abs_path)
    elif flag.startswith('-') and flag[1] in 'DWFfmO':
      if flag == '-Wno-deprecated-register' or flag == '-Wno-header-guard':
        # These flags causes libclang (3.3) to crash. Remove it until things
        # are fixed.
        continue
      v8_flags.append(flag)

  return v8_flags


def FlagsForFile(filename):
  """This is the main entry point for YCM. Its interface is fixed.

  Args:
    filename: (String) Path to source file being edited.

  Returns:
    (Dictionary)
      'flags': (List of Strings) Command line flags.
      'do_cache': (Boolean) True if the result should be cached.
  """
  v8_root = FindV8SrcFromFilename(filename)
  v8_flags = GetClangCommandFromNinjaForFilename(v8_root, filename)
  final_flags = flags + v8_flags

  return {
    'flags': final_flags,
    'do_cache': True
  }
