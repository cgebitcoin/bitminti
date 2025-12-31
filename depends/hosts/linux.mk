linux_CFLAGS=
linux_CXXFLAGS=

ifneq ($(LTO),)
linux_AR = $(host_toolchain)gcc-ar
linux_NM = $(host_toolchain)gcc-nm
linux_RANLIB = $(host_toolchain)gcc-ranlib
endif

linux_release_CFLAGS=-O2
linux_release_CXXFLAGS=$(linux_release_CFLAGS)

linux_debug_CFLAGS=-O1 -g
linux_debug_CXXFLAGS=$(linux_debug_CFLAGS)

# https://gcc.gnu.org/onlinedocs/libstdc++/manual/debug_mode.html
linux_debug_CPPFLAGS=-D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC

# https://libcxx.llvm.org/Hardening.html
linux_debug_CPPFLAGS+=-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG

ifeq (86,$(findstring 86,$(build_arch)))
i686_linux_CC=gcc
i686_linux_CXX=g++
i686_linux_AR=ar
i686_linux_RANLIB=ranlib
i686_linux_NM=nm
i686_linux_STRIP=strip
i686_linux_CFLAGS=-m32
i686_linux_CXXFLAGS=-m32

x86_64_linux_CC=gcc
x86_64_linux_CXX=g++
x86_64_linux_AR=ar
x86_64_linux_RANLIB=ranlib
x86_64_linux_NM=nm
x86_64_linux_STRIP=strip
x86_64_linux_CFLAGS=-m64
x86_64_linux_CXXFLAGS=-m64
else
i686_linux_CC=$(default_host_CC)
i686_linux_CXX=$(default_host_CXX)
i686_linux_CFLAGS=-m32
i686_linux_CXXFLAGS=-m32
x86_64_linux_CC=$(default_host_CC)
x86_64_linux_CXX=$(default_host_CXX)
x86_64_linux_CFLAGS=-m64
x86_64_linux_CXXFLAGS=-m64
endif

linux_cmake_system_name=Linux
# Refer to doc/dependencies.md for the minimum required kernel.
linux_cmake_system_version=3.17.0
