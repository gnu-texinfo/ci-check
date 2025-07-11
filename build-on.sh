#!/bin/sh

# Copyright (C) 2024-2025 Free Software Foundation, Inc.
#
# This file is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This script builds a tarball of the package on a single platform.
# Usage: build-on.sh PACKAGE CONFIGURE_OPTIONS MAKE

package="$1"
configure_options="$2"
make="$3"

set -x

case "$configure_options" in
  --host=riscv*) cross_compiling=true ;;
  *)             cross_compiling=false ;;
esac

# Unpack the tarball.
tarfile=`echo "$package"-*.tar.gz`
packagedir=`echo "$tarfile" | sed -e 's/\.tar\.gz$//'`
tar xfz "$tarfile"
cd "$packagedir" || exit 1

# Work around a /bin/sh bug on Solaris 11 OmniOS.
if test "`uname -s`" = SunOS && ! grep 'Oracle Solaris' /etc/release >/dev/null; then
  sed -i -e '1s|/bin/sh|/usr/bin/bash|' tta/tests/run_parser_all.sh
fi

mkdir build
cd build

echo "TEXINFO_XS_CONVERT: '$TEXINFO_XS_CONVERT'"

# Configure.
../configure --config-cache $configure_options > log1 2>&1; rc=$?; cat log1; test $rc = 0 || exit 1

# Build.
$make > log2 2>&1; rc=$?; cat log2; test $rc = 0 || { $make -k > log2a 2>&1; $make -k > log2b 2>&1; cat log2b; exit 1; }

if ! $cross_compiling; then
  # show information on the XS modules used
  (
  TEXINFO_DEV_SOURCE=1
  export TEXINFO_DEV_SOURCE
  TEXINFO_XS=debug
  export TEXINFO_XS

  t2a_builddir=./tta
  export t2a_builddir
  t2a_srcdir=../tta
  export t2a_srcdir

  # shows the XS modules loading for HTML
  ./tta/perl/texi2any --html --no-split -o - ${t2a_srcdir}/perl/t/input_files/simplest.texi
  # shows the XS modules loading for Info
  ./tta/perl/texi2any -o - ${t2a_srcdir}/perl/t/input_files/simplest.texi
  ) > log3 2>&1
  rc=$?; cat log3; test $rc = 0 || exit 1

  # Run the tests.
  $make check > log4 2>&1; rc=$?; cat log4; test $rc = 0 || exit 1
fi

cd ..
