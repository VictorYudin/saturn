# Copyright (C) 2017 Victor Yudin - All Rights Reserved
#
# This is the Windows build recipe for Pixar USD and its dependencies.
#
# ..\..\..\lib\cmake\bin\cmake.exe --build . --target install --config Debug
# set PATH=C:\Temp\saturn-build\jom\bin;%PATH%
# make MAKE_MODE=debug BOOST_LINK=shared CRT_LINKAGE=shared usd
# make BOOST_LINK=shared llvm_EXTERNAL=C:/usr/llvm usd
# make llvm_EXTERNAL=C:/usr/llvm usd
#
# linux:
# make SOURCES_ROOT=/home/victor/src BUILD_ROOT=/tmp/build PREFIX_ROOT=/home/victor/usr/saturn

SOURCES_ROOT=./src
BUILD_ROOT=./build
PREFIX_ROOT=./lib

ifeq "$(OS)" "Windows_NT"
	CURRENT_OS := windows
else
	CURRENT_OS := linux
endif

ABSOLUTE_SOURCES_ROOT := $(abspath $(SOURCES_ROOT))
ABSOLUTE_BUILD_ROOT := $(abspath $(BUILD_ROOT))
ABSOLUTE_PREFIX_ROOT := $(abspath $(PREFIX_ROOT))
ifeq "$(CURRENT_OS)" "windows"
	WINDOWS_SOURCES_ROOT := $(shell cygpath -w $(ABSOLUTE_SOURCES_ROOT))
	WINDOWS_BUILD_ROOT := $(shell cygpath -w $(ABSOLUTE_BUILD_ROOT))
	WINDOWS_PREFIX_ROOT := $(subst \,/,$(shell cygpath -w $(ABSOLUTE_PREFIX_ROOT)))
	WIN_SDK :=\
		$(shell cat /proc/registry/HKEY_LOCAL_MACHINE/SOFTWARE/WOW6432Node/Microsoft/Microsoft\ SDKs/Windows/v10.0/ProductVersion)
else
	WINDOWS_SOURCES_ROOT := $(ABSOLUTE_SOURCES_ROOT)
	WINDOWS_BUILD_ROOT := $(ABSOLUTE_BUILD_ROOT)
	WINDOWS_PREFIX_ROOT := $(ABSOLUTE_PREFIX_ROOT)
endif

MAKE_MODE := release
CRT_LINKAGE := static

ifeq "$(MAKE_MODE)" "debug"
	CMAKE_BUILD_TYPE := Debug
else
	ifeq "$(CURRENT_OS)" "windows"
		CMAKE_BUILD_TYPE := MinSizeRel
	else
		CMAKE_BUILD_TYPE := Release
	endif
endif

# Save the current directory
THIS_DIR := $(shell pwd)
TOP_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ifeq "$(CURRENT_OS)" "windows"
	WINDOWS_THIS_DIR := $(shell cygpath -w $(THIS_DIR))
else
	WINDOWS_THIS_DIR := $(THIS_DIR)
endif

define PACKAGE_VARS =
ifeq "$($(1)_EXTERNAL)" ""
$(1)_VERSION := $(2)
$(1)_VERSION_FILE := $(ABSOLUTE_PREFIX_ROOT)/built_$(1)
$(1)_PREFIX := $(WINDOWS_PREFIX_ROOT)/$(1)
$(1)_UNIX_PREFIX := $(ABSOLUTE_PREFIX_ROOT)/$(1)
$(1)_SOURCE := $(3)
$(1)_FILE := $(ABSOLUTE_SOURCES_ROOT)/$$(notdir $$($(1)_SOURCE))
$(1): $$($(1)_VERSION_FILE)

$(1)-archive: $(1)-$$($(1)_VERSION).tar.xz
$(1)-$$($(1)_VERSION).tar.xz: $$($(1)_VERSION_FILE)
	@echo Archiving $$@ && \
	tar cfJ $$@ -C $(ABSOLUTE_PREFIX_ROOT) $(1)
else
$(1)_PREFIX := $($(1)_EXTERNAL)
$(1)_UNIX_PREFIX := $$(shell cygpath -u $$($(1)_PREFIX))
endif
endef

define GIT_DOWNLOAD =
$(call PACKAGE_VARS,$(1),$(2),$(3))

$$($(1)_FILE)/HEAD :
ifeq "$$(CURRENT_OS)" "windows"
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	git clone -q --bare $$($(1)_SOURCE) `cygpath -w $$($(1)_FILE)`
else
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	git clone -q --bare $$($(1)_SOURCE) $$($(1)_FILE)
endif
endef

define CURL_DOWNLOAD =
$(call PACKAGE_VARS,$(1),$(2),$(3))

$$($(1)_FILE) :
ifeq "$$(CURRENT_OS)" "windows"
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	curl --tlsv1.2 --retry-connrefused --retry 20 -s -o $$@ -L $$($(1)_SOURCE)
else
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	curl --tlsv1.2 -s -o $$@ -L $$($(1)_SOURCE)
endif
endef

define PYPI_INSTALL =
$(call CURL_DOWNLOAD,$(1),$(2),$(3))

$$($(1)_VERSION_FILE) : $$($(1)_FILE)
	@echo Building $(1) $$($(1)_VERSION) && \
	mkdir -p $$(ABSOLUTE_BUILD_ROOT) && cd $$(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $$(notdir $$(basename $$(basename $$($(1)_FILE)))) && \
	tar -xf $$($(1)_FILE) && \
	cd $$(notdir $$(basename $$(basename $$($(1)_FILE)))) && \
	mkdir -p $$(ABSOLUTE_PREFIX_ROOT) && \
	$$(PYTHON_BIN) setup.py \
		install_lib \
		--install-dir=$$($(1)_PREFIX)/python > $$(ABSOLUTE_PREFIX_ROOT)/log_$(1).txt 2>&1 && \
	cd $$(THIS_DIR) && \
	echo $$($(1)_VERSION) > $$@
endef

define QT_DOWNLOAD =
$(call GIT_DOWNLOAD,$(1),$(2),$(3))

$$($(1)_VERSION_FILE) : $$($(4)_VERSION_FILE) $$($(1)_FILE)/HEAD
	@echo Building Qt5 $(1) $$($(1)_VERSION) && \
	mkdir -p $$(ABSOLUTE_BUILD_ROOT) && cd $$(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $$(notdir $$(basename $$($(1)_FILE))) && \
	git clone -q --no-checkout "$$(WINDOWS_SOURCES_ROOT)/$$(notdir $$($(1)_FILE))" $$(notdir $$(basename $$($(1)_FILE))) && \
	cd $$(notdir $$(basename $$($(1)_FILE))) && \
	git checkout -q $$($(1)_VERSION) && \
	export PATH=$$(ABSOLUTE_PREFIX_ROOT)/perl/bin:$$(PYTHON_ABSOLUTE):$$$$PATH && \
	$$(ABSOLUTE_PREFIX_ROOT)/qt5base/bin/qmake > $$(ABSOLUTE_PREFIX_ROOT)/log_$(1).txt 2>&1 && \
	$$(NMAKE) >> $$(ABSOLUTE_PREFIX_ROOT)/log_$(1).txt 2>&1 && \
	$$(NMAKE) install >> $$(ABSOLUTE_PREFIX_ROOT)/log_$(1).txt 2>&1 && \
	cd $$(THIS_DIR) && \
	echo $$($(1)_VERSION) > $$@
endef

QT_VERSION := v5.12.0-beta4
QT_VERSION := v5.11.2

ifeq "$(CURRENT_OS)" "windows"
$(eval $(call CURL_DOWNLOAD,cmake,3.9.1,https://cmake.org/files/v$$(word 1,$$(subst ., ,$$(cmake_VERSION))).$$(word 2,$$(subst ., ,$$(cmake_VERSION)))/cmake-$$(cmake_VERSION)-win64-x64.zip))
else
$(eval $(call CURL_DOWNLOAD,cmake,3.9.1,https://cmake.org/files/v$$(word 1,$$(subst ., ,$$(cmake_VERSION))).$$(word 2,$$(subst ., ,$$(cmake_VERSION)))/cmake-$$(cmake_VERSION).tar.gz))
endif

$(eval $(call CURL_DOWNLOAD,boost,1_61_0,http://sourceforge.net/projects/boost/files/boost/$$(subst _,.,$$(boost_VERSION))/boost_$$(boost_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,cfe,5.0.0,http://releases.llvm.org/$$(cfe_VERSION)/cfe-$$(cfe_VERSION).src.tar.xz))
$(eval $(call CURL_DOWNLOAD,clangtoolsextra,5.0.0,http://releases.llvm.org/$$(clangtoolsextra_VERSION)/clang-tools-extra-$$(clangtoolsextra_VERSION).src.tar.xz))
$(eval $(call CURL_DOWNLOAD,compilerrt,5.0.0,http://releases.llvm.org/$$(compilerrt_VERSION)/compiler-rt-$$(compilerrt_VERSION).src.tar.xz))
$(eval $(call CURL_DOWNLOAD,freetype,2.8,http://download.savannah.gnu.org/releases/freetype/freetype-$$(freetype_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,glew,2.0.0,https://sourceforge.net/projects/glew/files/glew/$$(glew_VERSION)/glew-$$(glew_VERSION).tgz))
$(eval $(call CURL_DOWNLOAD,glut,3.0.0,https://sourceforge.net/projects/freeglut/files/freeglut/$$(glut_VERSION)/freeglut-$$(glut_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,hdf5,1.8.10,https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$$(word 1,$$(subst ., ,$$(hdf5_VERSION))).$$(word 2,$$(subst ., ,$$(hdf5_VERSION)))/hdf5-$$(hdf5_VERSION)/src/hdf5-$$(hdf5_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,ilmbase,2.2.0,http://download.savannah.nongnu.org/releases/openexr/ilmbase-$$(ilmbase_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,llvm,5.0.0,http://releases.llvm.org/$$(llvm_VERSION)/llvm-$$(llvm_VERSION).src.tar.xz))
$(eval $(call CURL_DOWNLOAD,openexr,2.2.0,http://download.savannah.nongnu.org/releases/openexr/openexr-$$(openexr_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,perl,5.26.1,http://www.cpan.org/src/5.0/perl-$$(perl_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,png,1.6.34,https://sourceforge.net/projects/libpng/files/libpng16/$$(png_VERSION)/libpng-$$(png_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,tbb,2017_20161128oss,https://www.threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb$$(tbb_VERSION)_src.tgz))
$(eval $(call CURL_DOWNLOAD,tiff,3.8.2,http://dl.maptools.org/dl/libtiff/tiff-$$(tiff_VERSION).tar.gz))
$(eval $(call GIT_DOWNLOAD,alembic,1.7.1,git://github.com/alembic/alembic.git))
$(eval $(call GIT_DOWNLOAD,cppzmq,v4.3.0,git://github.com/zeromq/cppzmq.git))
$(eval $(call GIT_DOWNLOAD,embree,v2.17.1,git://github.com/embree/embree.git))
$(eval $(call GIT_DOWNLOAD,ffmpeg,n4.1,git://github.com/FFmpeg/FFmpeg.git))
$(eval $(call GIT_DOWNLOAD,glfw,3.2.1,git://github.com/glfw/glfw.git))
$(eval $(call GIT_DOWNLOAD,jom,v1.1.2,git://github.com/qt-labs/jom.git))
$(eval $(call GIT_DOWNLOAD,jpeg,1.5.1,git://github.com/libjpeg-turbo/libjpeg-turbo.git))
$(eval $(call GIT_DOWNLOAD,jsoncpp,1.8.0,git://github.com/open-source-parsers/jsoncpp.git))
$(eval $(call GIT_DOWNLOAD,materialx,v1.36.0,git://github.com/materialx/MaterialX.git))
$(eval $(call GIT_DOWNLOAD,oiio,Release-1.8.5,git://github.com/OpenImageIO/oiio.git))
$(eval $(call GIT_DOWNLOAD,opensubd,v3_2_0,git://github.com/PixarAnimationStudios/OpenSubdiv.git))
$(eval $(call GIT_DOWNLOAD,osl,Release-1.9.9,git://github.com/imageworks/OpenShadingLanguage.git))
$(eval $(call GIT_DOWNLOAD,ptex,v2.3.0,git://github.com/wdas/ptex.git))
$(eval $(call GIT_DOWNLOAD,pyside,${QT_VERSION},git://code.qt.io/pyside/pyside-setup.git))
$(eval $(call GIT_DOWNLOAD,pysidetools,${QT_VERSION},git://code.qt.io/pyside/pyside-tools.git))
$(eval $(call GIT_DOWNLOAD,qt5base,${QT_VERSION},git://github.com/qt/qtbase.git))
$(eval $(call GIT_DOWNLOAD,usd,v19.03,git://github.com/PixarAnimationStudios/USD.git))
$(eval $(call GIT_DOWNLOAD,x264,master,http://git.videolan.org/git/x264.git))
$(eval $(call GIT_DOWNLOAD,zlib,v1.2.8,git://github.com/madler/zlib.git))
$(eval $(call GIT_DOWNLOAD,zmq,v4.3.0,git://github.com/zeromq/libzmq.git))
$(eval $(call PYPI_INSTALL,PyOpenGL,3.1.1,https://files.pythonhosted.org/packages/9c/1d/4544708aaa89f26c97cc09450bb333a23724a320923e74d73e028b3560f9/PyOpenGL-3.1.0.tar.gz))
$(eval $(call QT_DOWNLOAD,qt5creator,v4.5.1,git://github.com/qt-creator/qt-creator.git,qt5base))
$(eval $(call QT_DOWNLOAD,qt5declarative,${QT_VERSION},git://github.com/qt/qtdeclarative.git,qt5base))
$(eval $(call QT_DOWNLOAD,qt5graphicaleffects,${QT_VERSION},git://github.com/qt/qtgraphicaleffects.git,qt5declarative))
$(eval $(call QT_DOWNLOAD,qt5multimedia,${QT_VERSION},git://github.com/qt/qtmultimedia.git,qt5declarative))
$(eval $(call QT_DOWNLOAD,qt5qtxmlpatterns,${QT_VERSION},git://github.com/qt/qtxmlpatterns.git,qt5base))
$(eval $(call QT_DOWNLOAD,qt5quickcontrols,${QT_VERSION},https://github.com/qt/qtquickcontrols2,qt5declarative))
$(eval $(call QT_DOWNLOAD,qt5tools,${QT_VERSION},git://github.com/qt/qttools.git,qt5base))
$(eval $(call QT_DOWNLOAD,qt5webglplugin,${QT_VERSION},git://github.com/qt/qtwebglplugin.git,qt5websockets))
$(eval $(call QT_DOWNLOAD,qt5websockets,${QT_VERSION},git://github.com/qt/qtwebsockets.git,qt5qtxmlpatterns))

# Number or processors
JOB_COUNT := $(shell cat /proc/cpuinfo | grep processor | wc -l)

ifeq "$(CURRENT_OS)" "windows"
	CC := $(shell where cl)
	CXX := $(shell where cl)
	NOENV := env -u MAKE -u MAKEFLAGS
	NMAKE := $(NOENV) jom
	CMD := $(NOENV) cmd /C

	STATICLIB_EXT := .lib
	DYNAMICLIB_EXT := .dll
	BAT_EXT := .bat

	# PySide2 on windows should be preinstalled
	pyside_VERSION_FILE :=
	pysidetools_VERSION_FILE :=
else
	CC := gcc
	CXX := g++
	NMAKE := make

	STATICLIB_EXT := .a
	DYNAMICLIB_EXT := .so
endif

CMAKE := $(NOENV) $(cmake_PREFIX)/bin/cmake

BOOST_LINK := static
ifeq "$(BOOST_LINK)" "shared"
USE_STATIC_BOOST := OFF
BUILD_USD_MAYA_PLUGIN := ON
else
USE_STATIC_BOOST := ON
BUILD_USD_MAYA_PLUGIN := OFF
endif

DEFINES = -DBOOST_ALL_NO_LIB -DPTEX_STATIC

ifeq "$(BOOST_LINK)" "shared"
DEFINES += -DBOOST_ALL_DYN_LINK
else
DEFINES += -DBOOST_ALL_STATIC_LINK
endif

ifeq "$(CRT_LINKAGE)" "static"
	CRT_FLAG := MT
	STATIC_RUNTIME := ON
else
	CRT_FLAG := MD
	STATIC_RUNTIME := OFF
endif

ifeq "$(CURRENT_OS)" "windows"
ifeq "$(MAKE_MODE)" "debug"
	FLAGS := /$(CRT_FLAG)d
else
	FLAGS := /$(CRT_FLAG)
endif
else
	FLAGS := -fPIC
	MAKE_FLAGS := -j$(JOB_COUNT)
	CMAKE_MAKE_FLAGS := -- $(MAKE_FLAGS)
endif

FLAGS += $(DEFINES)

COMMON_CMAKE_FLAGS :=\
	-DCMAKE_BUILD_TYPE:STRING=$(CMAKE_BUILD_TYPE) \
	-DCMAKE_CXX_FLAGS_DEBUG="$(FLAGS)" \
	-DCMAKE_CXX_FLAGS_RELEASE="$(FLAGS)" \
	-DCMAKE_CXX_FLAGS_MINSIZEREL="$(FLAGS)" \
	-DCMAKE_C_FLAGS_DEBUG="$(FLAGS)" \
	-DCMAKE_C_FLAGS_RELEASE="$(FLAGS)" \
	-DCMAKE_C_FLAGS_MINSIZEREL="$(FLAGS)" \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON

ifeq "$(CURRENT_OS)" "windows"
	COMMON_CMAKE_FLAGS += -G "NMake Makefiles JOM"
else
	COMMON_CMAKE_FLAGS += -DCMAKE_SHARED_LINKER_FLAGS=-Wl,--no-undefined
endif

COMPILER_CONF :=\
	CC="$(CC)" \
	CXX="$(CXX)" \
	CFLAGS="$(FLAGS)" \
	CXXFLAGS="$(FLAGS)"

all: usd-archive
qtquick: qt5graphicaleffects qt5quickcontrols qt5multimedia
qtextras: qt5declarative qt5graphicaleffects qt5quickcontrols qt5tools qt5multimedia
.PHONY : all
.DEFAULT_GOAL := all

ifeq "$(CURRENT_OS)" "windows"
	PYTHON_BIN := C:/Python27/python.exe
	PYTHON_ROOT := $(subst \,,$(dir $(PYTHON_BIN)))
	PYTHON_ABSOLUTE := $(shell cygpath -u $(PYTHON_ROOT))
	PYTHON_BIN := $(subst \,,$(PYTHON_BIN))
	PYTHON_INCLUDE := $(PYTHON_ROOT)include
	PYTHON_LIBS := $(PYTHON_ROOT)libs
else
	PYTHON_BIN := $(shell which python)
	PYTHON_INCLUDE := $(shell $(PYTHON_BIN) -c "import sysconfig; print sysconfig.get_paths()['include']")
	PYTHON_LIBS := $(shell $(PYTHON_BIN) -c "import sysconfig; print sysconfig.get_paths()['stdlib']")/..
endif
PYTHON_VERSION_SHORT := 2.7

ifeq "$(BOOST_VERSION)" "1_55_0"
BOOST_USERCONFIG := tools/build/v2/user-config.jam
else
BOOST_USERCONFIG := tools/build/src/user-config.jam
endif
ifeq "$(CURRENT_OS)" "windows"
	BOOST_PLATFORM_FLAGS := runtime-link=$(CRT_LINKAGE) toolset=msvc-14.1
else
	BOOST_PLATFORM_FLAGS := cflags="$(FLAGS)" cxxflags="$(FLAGS)" toolset=gcc-4.8
endif
$(boost_VERSION_FILE) : $(boost_FILE)
	@echo Building boost $(boost_VERSION) link=$(BOOST_LINK) runtime-link=$(CRT_LINKAGE) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(BUILD_ROOT) && \
	rm -rf boost_$(boost_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/boost_$(boost_VERSION).tar.gz && \
	cd boost_$(boost_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( test ! $(CURRENT_OS) == linux || echo 'using gcc : 4.8 : "$(CXX)" ;' >> $(BOOST_USERCONFIG) ) && \
	( test ! $(CURRENT_OS) == windows || echo 'using msvc : 14.1 : "$(CXX)" ;' >> $(BOOST_USERCONFIG) ) && \
	echo 'using python : $(PYTHON_VERSION_SHORT) : "$(PYTHON_BIN)" : "$(PYTHON_INCLUDE)" : "$(PYTHON_LIBS)" ;' >> $(BOOST_USERCONFIG) && \
	( test ! $(CRT_LINKAGE) == static || printf '/handle-static-runtime/\n/EXIT/d\nw\nq' | ed -s Jamroot ) && \
	( test ! $(BOOST_LINK) == static || printf '/BOOST_PYTHON_STATIC_LIB/s/BOOST_PYTHON_STATIC_LIB/disabled_PYTHON_STATIC_LIB/\nw\nq' | ed -s libs/python/build/Jamfile.v2 ) && \
	( test ! $(BOOST_LINK) == static || printf '/BOOST_PYTHON_STATIC_LIB/s/BOOST_PYTHON_STATIC_LIB/disabled_PYTHON_STATIC_LIB/\nw\nq' | ed -s libs/python/build/Jamfile.v2 ) && \
	( test ! $(CURRENT_OS) == windows || \
		cmd /C bootstrap.bat msvc > $(ABSOLUTE_PREFIX_ROOT)/log_boost.txt 2>&1 ) && \
	( test ! $(CURRENT_OS) == linux || \
		$(COMPILER_CONF) TOOLSET=cc \
		./bootstrap.sh > $(ABSOLUTE_PREFIX_ROOT)/log_boost.txt 2>&1 ) && \
	echo Boost bootstrap is OK >> $(ABSOLUTE_PREFIX_ROOT)/log_boost.txt && \
	./b2 \
		--layout=system \
		--prefix=$(boost_PREFIX) \
		-d2 \
		-j $(JOB_COUNT) \
		-s NO_BZIP2=1 \
		address-model=64 \
		link=$(BOOST_LINK) \
		threading=multi \
		$(BOOST_PLATFORM_FLAGS) \
		$(MAKE_MODE) \
		stage \
		install >> $(ABSOLUTE_PREFIX_ROOT)/log_boost.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(BOOST_VERSION) > $@

$(alembic_VERSION_FILE) : $(boost_VERSION_FILE) $(cmake_VERSION_FILE) $(hdf5_VERSION_FILE) $(ilmbase_VERSION_FILE) $(openexr_VERSION_FILE) $(zlib_VERSION_FILE) $(alembic_FILE)/HEAD
	@echo Building Alembic $(alembic_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf alembic && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/alembic.git" alembic && \
	cd alembic && \
	git checkout -q $(alembic_VERSION) && \
	( printf '/Werror/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf "/INSTALL/a\nFoundation.h\n.\nw\nq" | ed -s lib/Alembic/AbcCoreLayer/CMakeLists.txt ) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DHDF5_ROOT="$(hdf5_PREFIX)" \
		-DALEMBIC_ILMBASE_LINK_STATIC:BOOL=ON \
		-DALEMBIC_LIB_USES_BOOST:BOOL=ON \
		-DALEMBIC_SHARED_LIBS:BOOL=OFF \
		-DBOOST_ROOT:STRING="$(boost_PREFIX)" \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX="$(alembic_PREFIX)" \
		-DILMBASE_ROOT="$(ilmbase_PREFIX)" \
		-DUSE_BOOSTREGEX:BOOL=ON \
		-DUSE_HDF5:BOOL=ON \
		-DUSE_MAYA:BOOL=OFF \
		-DUSE_STATIC_BOOST:BOOL=$(USE_STATIC_BOOST) \
		-DUSE_STATIC_HDF5:BOOL=ON \
		-DUSE_TESTS:BOOL=OFF \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_alembic.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_alembic.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(alembic_VERSION) > $@


# cppzmq
ifeq "$(CURRENT_OS)" "windows"
CPPZMQ_PLATFORM_FLAGS := -DZeroMQ_DIR="$(zmq_PREFIX)/CMake"
else
CPPZMQ_PLATFORM_FLAGS := -DZeroMQ_DIR="$(zmq_PREFIX)/share/cmake/ZeroMQ"
endif
$(cppzmq_VERSION_FILE) : $(cmake_VERSION_FILE) $(zmq_VERSION_FILE) $(cppzmq_FILE)/HEAD
	@echo Building cppzmq $(cppzmq_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(cppzmq_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(cppzmq_FILE))" $(notdir $(basename $(cppzmq_FILE))) && \
	cd $(notdir $(basename $(cppzmq_FILE))) && \
	git checkout -q $(cppzmq_VERSION) && \
	( printf 'g/libzmq /s/libzmq /libzmq-static /g\nw\n' | ed -s CMakeLists.txt ) && \
	( printf '/libzmq)/s/libzmq)/libzmq-static)/\nw\n' | ed -s CMakeLists.txt ) && \
	mkdir -p build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(cppzmq_PREFIX)" \
		-DCPPZMQ_BUILD_TESTS=OFF \
		-DENABLE_DRAFTS=OFF \
		$(CPPZMQ_PLATFORM_FLAGS) \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_cppzmq.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_cppzmq.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(cppzmq_VERSION) > $@


$(cmake_VERSION_FILE) : $(cmake_FILE)
ifeq "$(CURRENT_OS)" "windows"
	@echo Unpacking cmake $(cmake_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf cmake-$(cmake_VERSION)-win64-x64 && \
	rm -rf $(ABSOLUTE_PREFIX_ROOT)/cmake && \
	unzip $(ABSOLUTE_SOURCES_ROOT)/cmake-$(cmake_VERSION)-win64-x64.zip > $(ABSOLUTE_PREFIX_ROOT)/log_cmake.txt 2>&1 && \
	mv cmake-$(cmake_VERSION)-win64-x64 $(ABSOLUTE_PREFIX_ROOT)/cmake && \
	chmod -R u+x $(ABSOLUTE_PREFIX_ROOT)/cmake/bin/*.exe && \
	chmod -R u+x $(ABSOLUTE_PREFIX_ROOT)/cmake/bin/*.dll && \
	cd $(THIS_DIR) && \
	echo $(cmake_VERSION) > $@
else
	@echo Building cmake $(cmake_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(cmake_FILE))) && \
	tar -xf $(cmake_FILE) && \
	cd $(notdir $(basename $(basename $(cmake_FILE)))) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(COMPILER_CONF) \
	./configure \
		--prefix="$(cmake_PREFIX)" \
		--parallel=$(JOB_COUNT) \
		--no-qt-gui \
		--no-server \
		--verbose > $(ABSOLUTE_PREFIX_ROOT)/log_cmake.txt 2>&1 && \
	make -j$(JOB_COUNT) \
		MAKE_MODE=$(MAKE_MODE) \
		install >> $(ABSOLUTE_PREFIX_ROOT)/log_cmake.txt 2>&1 && \
	cd .. && \
	cd $(THIS_DIR) && \
	echo $(cmake_VERSION) > $@
endif


$(freetype_VERSION_FILE) : $(cmake_VERSION_FILE) $(freetype_FILE)
	@echo Building FreeType $(freetype_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(basename $(freetype_FILE)))) && \
	tar -xf $(freetype_FILE) && \
	cd $(notdir $(basename $(basename $(freetype_FILE)))) && \
	mkdir -p build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(freetype_PREFIX)" \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_freetype.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_freetype.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(freetype_VERSION) > $@


#embree
$(embree_VERSION_FILE) : $(cmake_VERSION_FILE) $(glut_VERSION_FILE) $(tbb_VERSION_FILE) $(zlib_VERSION_FILE) $(embree_FILE)/HEAD
	@echo Building embree $(embree_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf embree && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(embree_FILE))" embree && \
	cd embree && \
	git checkout -q $(embree_VERSION) && \
	( printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_INCLUDE_DIR $(tbb_PREFIX)/include)\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_LIBRARY $(tbb_PREFIX)/lib/tbb$(STATICLIB_EXT))\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( test ! $(CURRENT_OS) == windows || printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_LIBRARY_MALLOC $(tbb_PREFIX)/lib/tbbmalloc$(STATICLIB_EXT))\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/INSTALL(PROGRAMS/d\nw\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/INSTALL(PROGRAMS/d\nw\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf 'g/WIN32/s/WIN32/0/g\nw\n' | ed -s tutorials/common/tutorial/CMakeLists.txt ) && \
	( printf '/embree.rc/d\nw\n' | ed -s kernels/CMakeLists.txt ) && \
	( printf '/embree.rc/d\nw\n' | ed -s kernels/CMakeLists.txt ) && \
	( printf '/FLAGS_LOWEST/a\nmessage(victor \044{FLAGS_LOWEST})\n.\nw\n' | ed -s kernels/CMakeLists.txt ) && \
	( printf 'set_target_properties(sys PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n' >> common/sys/CMakeLists.txt ) && \
	( printf 'set_target_properties(algorithms PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n' >> common/algorithms/CMakeLists.txt ) && \
	( printf 'set_target_properties(tasking PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n' >> common/tasking/CMakeLists.txt ) && \
	( printf 'set_target_properties(image PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n' >> tutorials/common/image/CMakeLists.txt ) && \
	( printf 'set_target_properties(scenegraph PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n' >> tutorials/common/scenegraph/CMakeLists.txt ) && \
	( printf '/tutorial/a\nset_target_properties(tutorial PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n.\nw\n' | ed -s tutorials/common/tutorial/CMakeLists.txt ) && \
	( printf '/tutorial_device/a\nset_target_properties(tutorial_device PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n.\nw\n' | ed -s tutorials/common/tutorial/CMakeLists.txt ) && \
	( printf '/verify/a\nset_target_properties(verify PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n.\nw\n' | ed -s tutorials/verify/CMakeLists.txt ) && \
	( printf '/SET_PROPERTY/a\nset_target_properties(\044{TUTORIAL_NAME} PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n.\nw\n' | ed -s common/cmake/tutorial.cmake ) && \
	( printf '/bvh_access/a\nset_target_properties(bvh_access PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n.\nw\n' | ed -s tutorials/bvh_access/CMakeLists.txt ) && \
	( printf '/convert/a\nset_target_properties(convert PROPERTIES COMPILE_FLAGS "\044{FLAGS_AVX2}")\n.\nw\n' | ed -s tutorials/convert/CMakeLists.txt ) && \
	( printf '/define/a\n#define EMBREE_STATIC_LIB\n.\nw\n' | ed -s include/embree2/rtcore.h ) && \
	rm -rf tutorials/common/freeglut && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DADDITIONAL_LIBRARIES:PATH=winmm.lib \
		-DCMAKE_INSTALL_PREFIX="$(embree_PREFIX)" \
		-DEMBREE_ISPC_SUPPORT:BOOL=OFF \
		-DEMBREE_STATIC_LIB:BOOL=ON \
		-DEMBREE_STATIC_RUNTIME:BOOL=$(STATIC_RUNTIME) \
		-DEMBREE_TUTORIALS:BOOL=OFF \
		-DGLUT_INCLUDE_DIR:PATH="$(glut_PREFIX)/include" \
		-DGLUT_glut_LIBRARY:PATH="$(glut_PREFIX)/lib/freeglut_static.lib" \
		-DTBB_INCLUDE_DIR="$(tbb_PREFIX)/include" \
		-DTBB_LIBRARY="$(tbb_PREFIX)/lib/tbb$(TBB_SUFFIX).lib" \
		-DTBB_LIBRARY_MALLOC="$(tbb_PREFIX)/lib/tbbmalloc.lib" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_embree.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_embree.txt 2>&1 && \
	( test ! $(CURRENT_OS) == windows || for i in embree_sse42 embree_avx embree_avx2 simd tasking lexers sys math; do cmd /C copy $$i$(STATICLIB_EXT) $(subst /,\\,$(embree_PREFIX)/lib); done ) && \
	( test ! $(CURRENT_OS) == linux || for i in embree_sse42 embree_avx embree_avx2 simd tasking lexers sys math; do cp lib$$i$(STATICLIB_EXT) $(embree_PREFIX)/lib; done ) && \
	cd $(THIS_DIR) && \
	echo $(embree_VERSION) > $@


ifeq "$(CURRENT_OS)" "windows"
FFMPEG_PLATFORM_FLAGS := --enable-d3d11va --enable-dxva2 --target-os=win64 --toolchain=msvc --extra-ldflags="/NODEFAULTLIB:libcmt"
else
FFMPEG_PLATFORM_FLAGS :=
endif
ifeq "$(MAKE_MODE)" "debug"
FFMPEG_PLATFORM_FLAGS += --enable-debug
endif
$(ffmpeg_VERSION_FILE) : $(x264_VERSION_FILE) $(zlib_VERSION_FILE) $(ffmpeg_FILE)/HEAD
	@echo Building ffmpeg $(ffmpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(ffmpeg_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(ffmpeg_FILE))" $(notdir $(basename $(ffmpeg_FILE))) && \
	cd $(notdir $(basename $(ffmpeg_FILE))) && \
	git config core.eol lf && \
	git config core.autocrlf input && \
	git checkout -qf $(ffmpeg_VERSION) && \
	./configure --help > $(ABSOLUTE_PREFIX_ROOT)/log_ffmpeg.txt 2>&1 && \
	echo Configure... >> $(ABSOLUTE_PREFIX_ROOT)/log_ffmpeg.txt 2>&1 && \
	env PKG_CONFIG_PATH=$(x264_UNIX_PREFIX)/lib/pkgconfig:$(zlib_UNIX_PREFIX)/share/pkgconfig:$(zlib_UNIX_PREFIX)/lib/pkgconfig \
	./configure \
		--arch=x86_64 \
		--enable-avisynth \
		--enable-gpl \
		--enable-libx264 \
		--enable-version3 \
		--enable-zlib \
		--extra-cflags="$(FLAGS)" \
		--prefix=$(ffmpeg_UNIX_PREFIX) \
		$(FFMPEG_PLATFORM_FLAGS) >> $(ABSOLUTE_PREFIX_ROOT)/log_ffmpeg.txt 2>&1 && \
	echo Make... >> $(ABSOLUTE_PREFIX_ROOT)/log_ffmpeg.txt 2>&1 && \
	make -j$(JOB_COUNT) >> $(ABSOLUTE_PREFIX_ROOT)/log_ffmpeg.txt 2>&1 && \
	echo Install... >> $(ABSOLUTE_PREFIX_ROOT)/log_ffmpeg.txt 2>&1 && \
	make install >> $(ABSOLUTE_PREFIX_ROOT)/log_ffmpeg.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(ffmpeg_VERSION) > $@


# glew
# Edits:
# - define GLEW_STATIC
# link glewinfo and visualinfo statically
$(glew_VERSION_FILE) : $(cmake_VERSION_FILE) $(glew_FILE)
	@echo Building glew $(glew_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(glew_FILE))) && \
	tar zxf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(glew_FILE)) && \
	cd $(notdir $(basename $(glew_FILE))) && \
	( printf "0a\n#define GLEW_STATIC\n.\nw\nq\n" | ed -s include/GL/glew.h ) && \
	( printf "0a\n#define GLEW_STATIC\n.\nw\nq\n" | ed -s include/GL/wglew.h ) && \
	( printf "/target_link_libraries.*glewinfo/s/glew)/glew_s)/\nw\nq" | ed -s build/cmake/CMakeLists.txt ) && \
	( printf "/target_link_libraries.*visualinfo/s/glew)/glew_s)/\nw\nq" | ed -s build/cmake/CMakeLists.txt ) && \
	( printf "/CMAKE_DEBUG_POSTFIX/d\nw\nq" | ed -s build/cmake/CMakeLists.txt ) && \
	cd build && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(glew_PREFIX)" \
		./cmake > $(ABSOLUTE_PREFIX_ROOT)/log_glew.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_glew.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(glew_VERSION) > $@


# glfw
$(glfw_VERSION_FILE) : $(cmake_VERSION_FILE) $(glfw_FILE)/HEAD
	@echo Building glfw $(glfw_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(glfw_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(glfw_FILE))" $(notdir $(basename $(glfw_FILE))) && \
	cd $(notdir $(basename $(glfw_FILE))) && \
	git checkout -q $(glfw_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DGLFW_BUILD_DOCS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX="$(glfw_PREFIX)" \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_glfw.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_glfw.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(glfw_VERSION) > $@


# glut
$(glut_VERSION_FILE) : $(cmake_VERSION_FILE) $(glut_FILE)
	@echo Building glut $(glut_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(basename $(glut_FILE)))) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(glut_FILE)) && \
	cd $(notdir $(basename $(basename $(glut_FILE)))) && \
	( printf "2a\n#define FREEGLUT_STATIC\n.\nw\n" | ed -s include/GL/freeglut_std.h ) && \
	( printf "2a\n#define FREEGLUT_LIB_PRAGMAS 0\n.\nw\n" | ed -s include/GL/freeglut_std.h ) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(glut_PREFIX)" \
		-DFREEGLUT_BUILD_DEMOS:BOOL=OFF \
		-DFREEGLUT_BUILD_SHARED_LIBS:BOOL=OFF \
		-DINSTALL_PDB:BOOL=OFF \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_glut.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_glut.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(glut_VERSION) > $@


# HDF5
$(hdf5_VERSION_FILE) : $(cmake_VERSION_FILE) $(zlib_VERSION_FILE) $(hdf5_FILE)
	@echo Building HDF5 $(hdf5_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf hdf5-$(hdf5_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/hdf5-$(hdf5_VERSION).tar.gz && \
	cd hdf5-$(hdf5_VERSION) && \
	( test $$CURRENT_OS != linux || if [ -f release_docs/USING_CMake.txt ] ; then cp release_docs/USING_CMake.txt release_docs/Using_CMake.txt ; fi ) && \
	( if [ ! -f release_docs/USING_CMake.txt ] ; then touch release_docs/USING_CMake.txt ; fi ) && \
	( if [ ! -f release_docs/Using_CMake.txt ] ; then touch release_docs/Using_CMake.txt ; fi ) && \
	( printf '/H5_HAVE_TIMEZONE/s/1/0/\nw\nq' | ed -s config/cmake/ConfigureChecks.cmake ) && \
	( test ! $(CRT_LINKAGE) == static || printf '/"\/MD"/s/MD/MT/\nw\nq' | ed -s config/cmake/HDFMacros.cmake ) && \
	( printf '/HDF5_PRINTF_LL/s/(.*)/(HDF5_PRINTF_LL)/\nw\nq' | ed -s config/cmake/ConfigureChecks.cmake ) && \
	mkdir build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX="$(hdf5_PREFIX)" \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		-DZLIB_USE_EXTERNAL:BOOL=ON \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_hdf5.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_hdf5.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(hdf5_VERSION) > $@

# jom
$(jom_VERSION_FILE) : $(cmake_VERSION_FILE) $(qt5base_VERSION_FILE) $(jom_FILE)/HEAD
	@echo Building jom $(jom_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(jom_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(jom_FILE))" $(notdir $(basename $(jom_FILE))) && \
	cd $(notdir $(basename $(jom_FILE))) && \
	git checkout -q $(jom_VERSION) && \
	( printf "/target_link_libraries/s/)/ Winmm Mincore $(subst /,\/,$(qt5base_PREFIX))\/lib\/qtpcre2.lib)/\nw\n" | ed -s CMakeLists.txt ) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-G "NMake Makefiles" \
		-DQt5Core_DIR:PATH="$(qt5base_PREFIX)/lib/cmake/Qt5Core" \
		-DCMAKE_INSTALL_PREFIX="$(jom_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_jom.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_jom.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(jom_VERSION) > $@

# jpeg
$(jpeg_VERSION_FILE) : $(cmake_VERSION_FILE) $(jpeg_FILE)/HEAD
ifeq "$(CURRENT_OS)" "windows"
	@echo Building jpeg $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf jpeg && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/libjpeg-turbo.git" jpeg && \
	cd jpeg && \
	git checkout -q $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DENABLE_SHARED:BOOL=OFF \
		-DENABLE_STATIC:BOOL=ON \
		-DCMAKE_INSTALL_PREFIX="$(jpeg_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_jpeg.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_jpeg.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(jpeg_VERSION) > $@
else
	@echo Building jpeg $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf jpeg && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/libjpeg-turbo.git" jpeg && \
	cd jpeg && \
	git checkout -q $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	autoreconf -fiv > $(ABSOLUTE_PREFIX_ROOT)/log_jpeg.txt 2>&1 && \
	$(COMPILER_CONF) \
	./configure \
		--prefix="$(jpeg_PREFIX)" \
		--enable-shared=no >> $(ABSOLUTE_PREFIX_ROOT)/log_jpeg.txt 2>&1 && \
	make -j$(JOB_COUNT) \
		MAKE_MODE=$(MAKE_MODE) \
		install >> $(ABSOLUTE_PREFIX_ROOT)/log_jpeg.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(jpeg_VERSION) > $@
endif


# jsoncpp
$(jsoncpp_VERSION_FILE) : $(cmake_VERSION_FILE) $(zlib_VERSION_FILE) $(jsoncpp_FILE)/HEAD
	@echo Building jsoncpp $(jsoncpp_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf jsoncpp && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/jsoncpp.git" jsoncpp && \
	cd jsoncpp && \
	git checkout -q $(jsoncpp_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(jsoncpp_PREFIX)" \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_jsoncpp.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_jsoncpp.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(jsoncpp_VERSION) > $@


# MaterialX
$(materialx_VERSION_FILE) : $(cmake_VERSION_FILE) $(materialx_FILE)/HEAD
	@echo Building MaterialX $(materialx_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf materialx && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(materialx_FILE))" materialx && \
	cd materialx && \
	git checkout -q $(materialx_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(materialx_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_materialx.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_materialx.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(materialx_VERSION) > $@


$(ilmbase_VERSION_FILE) : $(cmake_VERSION_FILE) $(ilmbase_FILE)
	@echo Building IlmBase $(ilmbase_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf ilmbase-$(ilmbase_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/ilmbase-$(ilmbase_VERSION).tar.gz && \
	cd ilmbase-$(ilmbase_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX="$(ilmbase_PREFIX)" \
		-DNAMESPACE_VERSIONING:BOOL=ON \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_ilmbase.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_ilmbase.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(ilmbase_VERSION) > $@


# LLVM and clang
$(llvm_VERSION_FILE) : $(llvm_FILE) $(cfe_FILE) $(clangtoolsextra_FILE) $(cmake_VERSION_FILE) $(compilerrt_FILE)
	@echo Building llvm and clang $(llvm_VERS) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(basename $(llvm_FILE)))) && \
	tar xf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(llvm_FILE)) && \
	cd $(notdir $(basename $(basename $(llvm_FILE)))) && \
	cd tools && \
	tar xf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(cfe_FILE)) && \
	mv $(notdir $(basename $(basename $(cfe_FILE)))) clang && \
	cd clang/tools && \
	tar xf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(clangtoolsextra_FILE)) && \
	mv $(notdir $(basename $(basename $(clangtoolsextra_FILE)))) extra && \
	cd ../../../projects && \
	tar xf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(compilerrt_FILE)) && \
	mv $(notdir $(basename $(basename $(compilerrt_FILE)))) compiler-rt && \
	cd .. && \
	mkdir build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(llvm_PREFIX)" \
		-DLLVM_ENABLE_RTTI:BOOL=ON \
		-DLLVM_REQUIRES_RTTI:BOOL=ON \
		-DLLVM_TARGETS_TO_BUILD:STRING=X86 \
		-DPYTHON_EXECUTABLE:STRING="$(PYTHON_BIN)" \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_llvm.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) \
		$(CMAKE_MAKE_FLAGS) >> $(ABSOLUTE_PREFIX_ROOT)/log_llvm.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(llvm_VERSION) > $@


# OpenImageIO
# Edits:
# - Defining OIIO_STATIC_BUILD to avoid specifying it everywhere
# - std::locale segfault fix
# - Python module
ifeq "$(CURRENT_OS)" "windows"
PNG_LIBRARY := $(png_PREFIX)/lib/libpng16_static$(STATICLIB_EXT)
else
PNG_LIBRARY := $(png_PREFIX)/lib/libpng16$(STATICLIB_EXT)
endif
$(oiio_VERSION_FILE) : $(boost_VERSION_FILE) $(cmake_VERSION_FILE) $(freetype_VERSION_FILE) $(ilmbase_VERSION_FILE) $(jpeg_VERSION_FILE) $(openexr_VERSION_FILE) $(png_VERSION_FILE) $(tiff_VERSION_FILE) $(zlib_VERSION_FILE) $(oiio_FILE)/HEAD
	@echo Building OpenImageIO $(oiio_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf oiio && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/oiio.git" oiio && \
	cd oiio && \
	git checkout -q $(oiio_VERSION) && \
	( printf '/pragma once/a\n#ifndef OIIO_STATIC_BUILD\n#define OIIO_STATIC_BUILD\n#endif\n.\nw\nq\n' | ed -s src/include/OpenImageIO/export.h ) && \
	( printf '/libturbojpeg/s/libturbojpeg/turbojpeg-static/\nw\nq' | ed -s src/cmake/modules/FindJPEGTurbo.cmake ) && \
	( printf '/\/W1/s/W1/bigobj/\nw\nq' | ed -s src/cmake/compiler.cmake ) && \
	( printf '/Boost_USE_STATIC_LIBS/d\nw\nq' | ed -s src/cmake/compiler.cmake ) && \
	( printf '/Boost_USE_STATIC_LIBS/d\nw\nq' | ed -s src/cmake/compiler.cmake ) && \
	( printf '/Boost_USE_STATIC_LIBS/d\nw\nq' | ed -s src/cmake/externalpackages.cmake ) && \
	mkdir build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBOOST_ROOT="$(boost_PREFIX)" \
		-DBUILDSTATIC:BOOL=ON \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DCMAKE_INSTALL_PREFIX="$(oiio_PREFIX)" \
		-DFREETYPE_INCLUDE_PATH="$(freetype_PREFIX)/include/freetype2" \
		-DFREETYPE_PATH="$(freetype_PREFIX)" \
		-DILMBASE_HOME="$(ilmbase_PREFIX)" \
		-DJPEGTURBO_PATH="$(jpeg_PREFIX)" \
		-DLINKSTATIC:BOOL=ON \
		-DOIIO_BUILD_TESTS:BOOL=OFF \
		-DOPENEXR_HOME="$(openexr_PREFIX)" \
		-DPNG_LIBRARY="$(PNG_LIBRARY)" \
		-DPNG_PNG_INCLUDE_DIR="$(png_PREFIX)/include" \
		-DSTOP_ON_WARNING:BOOL=OFF \
		-DTIFF_INCLUDE_DIR="$(tiff_PREFIX)/include" \
		-DTIFF_LIBRARY="$(tiff_PREFIX)/lib/libtiff$(STATICLIB_EXT)" \
		-DUSE_FREETYPE:BOOL=ON \
		-DUSE_GIF:BOOL=OFF \
		-DUSE_JPEGTURBO:BOOL=ON \
		-DUSE_NUKE:BOOL=OFF \
		-DUSE_PYTHON:BOOL=OFF \
		-DUSE_QT:BOOL=OFF \
		-DVERBOSE:BOOL=ON \
		-DZLIB_ROOT="$(zlib_PREFIX)" \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_oiio.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_oiio.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(oiio_VERSION) > $@


$(openexr_VERSION_FILE) : $(cmake_VERSION_FILE) $(ilmbase_VERSION_FILE) $(zlib_VERSION_FILE) $(openexr_FILE)
	@echo Building OpenEXR $(openexr_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf openexr-$(openexr_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/openexr-$(openexr_VERSION).tar.gz && \
	cd openexr-$(openexr_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf '/define.*INCLUDED_IMF_DWA_COMRESSOR_H/a\n#include <zlib.h>\n.\nw\n' | ed -s IlmImf/ImfDwaCompressor.h ) && \
	( printf '/define.*INCLUDED_IMF_ZIP_COMPRESSOR_H/a\n#include <zlib.h>\n.\nw\n' | ed -s IlmImf/ImfZipCompressor.h ) && \
	( printf '/define.*INCLUDED_IMF_COMPRESSION_H/a\n#include <zlib.h>\n.\nw\n' | ed -s IlmImf/ImfCompression.h ) && \
	( printf '/define.*INCLUDED_IMF_ZIP_H/a\n#include <zlib.h>\n.\nw\n' | ed -s IlmImf/ImfZip.h ) && \
	( test ! $(CURRENT_OS) == linux || patch -N --no-backup-if-mismatch IlmImf/CMakeLists.txt $(THIS_DIR)/patches/OpenEXR/patch_openexr_cmakelists.diff ) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX="$(openexr_PREFIX)" \
		-DILMBASE_PACKAGE_PREFIX:PATH="$(ilmbase_PREFIX)" \
		-DNAMESPACE_VERSIONING:BOOL=ON \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_openexr.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_openexr.txt 2>&1 && \
	cp $(ABSOLUTE_PREFIX_ROOT)/ilmbase/lib/*$(STATICLIB_EXT) $(ABSOLUTE_PREFIX_ROOT)/openexr/lib && \
	cd $(THIS_DIR) && \
	echo $(openexr_VERSION) > $@


# OpenSubdiv
$(opensubd_VERSION_FILE) : $(cmake_VERSION_FILE) $(glew_VERSION_FILE) $(glfw_VERSION_FILE) $(ptex_VERSION_FILE) $(tbb_VERSION_FILE) $(zlib_VERSION_FILE) $(opensubd_FILE)/HEAD
	@echo Building OpenSubdiv $(opensubd_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(opensubd_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(opensubd_FILE))" $(notdir $(basename $(opensubd_FILE))) && \
	cd $(notdir $(basename $(opensubd_FILE))) && \
	git checkout -q $(opensubd_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf "/osd_dynamic_cpu/s/osd_dynamic_cpu/osd_static_gpu/\nw\nq" | ed -s CMakeLists.txt ) && \
	( printf "/osd_dynamic_gpu/s/osd_dynamic_gpu/osd_static_cpu/\nw\nq" | ed -s CMakeLists.txt ) && \
	( printf "/if.*NOT.*NOT/s/(/( 0 AND /\nw\nq" | ed -s opensubdiv/CMakeLists.txt ) && \
	( printf "/\/WX/d\nw\nq" | ed -s CMakeLists.txt ) && \
	( printf "/glew32s/s/glew32s/libglew32/\nw\nq" | ed -s cmake/FindGLEW.cmake ) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(opensubd_PREFIX)" \
		-DGLFW_LOCATION:PATH="$(glfw_PREFIX)" \
		-DGLEW_LOCATION:PATH="$(glew_PREFIX)" \
		-DNO_GLTESTS:BOOL=ON \
		-DNO_TESTS:BOOL=ON \
		-DNO_TUTORIALS:BOOL=ON \
		-DMSVC_STATIC_CRT:BOOL=$(STATIC_RUNTIME) \
		-DPTEX_LOCATION:PATH="$(ptex_PREFIX)" \
		-DPYTHON_EXECUTABLE=$(PYTHON_BIN) \
		-DTBB_LOCATION:PATH="$(tbb_PREFIX)" \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		-DNO_OMP=1 \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_opensubdiv.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_opensubdiv.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(opensubd_VERSION) > $@

# Open Shading Language
$(osl_VERSION_FILE) : $(boost_VERSION_FILE) $(cmake_VERSION_FILE) $(llvm_VERSION_FILE) $(oiio_VERSION_FILE) $(zlib_VERSION_FILE) $(osl_FILE)/HEAD
	@echo Building OSL $(osl_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(osl_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(osl_FILE))" $(notdir $(basename $(osl_FILE))) && \
	cd $(notdir $(basename $(osl_FILE))) && \
	git checkout -q $(osl_VERSION) && \
	echo OSL: Disable OSL shaders... && \
	( printf "/pragma once/a\n#define OSL_STATIC_BUILD\n.\nw\n" | ed -s src/include/OSL/export.h ) && \
	( printf "/shaders/d\nw\n" | ed -s CMakeLists.txt ) && \
	( printf "/shaders/d\nw\n" | ed -s CMakeLists.txt ) && \
	echo OSL: Linking against static boost... && \
	( printf "/Boost_COMPONENTS/a\nlist (APPEND Boost_COMPONENTS filesystem)\n.\nw\n" | ed -s src/cmake/externalpackages.cmake ) && \
	( printf "/Boost_USE_STATIC_LIBS/d\nw\n" | ed -s src/cmake/externalpackages.cmake ) && \
	( printf "/Boost_USE_STATIC_LIBS/d\nw\n" | ed -s src/cmake/compiler.cmake ) && \
	( printf "/Boost_USE_STATIC_LIBS/d\nw\n" | ed -s src/cmake/compiler.cmake ) && \
	mkdir build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	export PATH=$(PYTHON_ABSOLUTE):$(ABSOLUTE_PREFIX_ROOT)/boost/lib:$$PATH && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBOOST_ROOT="$(boost_PREFIX)" \
		-DBUILDSTATIC:BOOL=ON \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DCMAKE_INSTALL_PREFIX="$(osl_PREFIX)" \
		-DILMBASE_HOME="$(ilmbase_PREFIX)" \
		-DLINKSTATIC:BOOL=ON \
		-DLLVM_DIRECTORY="$(llvm_PREFIX)" \
		-DLLVM_STATIC:BOOL=ON \
		-DOPENEXR_HOME="$(openexr_PREFIX)" \
		-DOPENIMAGEIOHOME="$(oiio_PREFIX)" \
		-DOSL_BUILD_PLUGINS:BOOL=OFF \
		-DOSL_BUILD_TESTS:BOOL=OFF \
		-DUSE_QT:BOOL=OFF \
		-DUSE_SIMD=sse4.2 \
		-DZLIB_ROOT="$(zlib_PREFIX)" \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_osl.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_osl.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(osl_VERSION) > $@

# perl
$(perl_VERSION_FILE) : $(perl_FILE)
ifeq "$(CURRENT_OS)" "windows"
	@echo Building Perl $(perl_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(perl_FILE))) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/perl-$(perl_VERSION).tar.gz && \
	cd perl-$(perl_VERSION)/win32 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	env -u MAKE -u MAKEFLAGS nmake \
		CCTYPE=MSVC141 \
		config.h > $(ABSOLUTE_PREFIX_ROOT)/log_perl.txt 2>&1 && \
	env -u MAKE -u MAKEFLAGS nmake \
		CCTYPE=MSVC141 \
		../perlio.i >> $(ABSOLUTE_PREFIX_ROOT)/log_perl.txt 2>&1 && \
	env -u MAKE -u MAKEFLAGS nmake \
		CCTYPE=MSVC141 \
		INST_TOP="$(subst /,\,$(perl_PREFIX))" \
		install >> $(ABSOLUTE_PREFIX_ROOT)/log_perl.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(perl_VERSION) > $@
else
	@echo Building Perl $(perl_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(perl_FILE))) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/perl-$(perl_VERSION).tar.gz && \
	cd perl-$(perl_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	./Configure \
		-des \
		-Dusethreads \
		-Dprefix=$(perl_PREFIX) > $(ABSOLUTE_PREFIX_ROOT)/log_perl.txt 2>&1 && \
	make -j$(JOB_COUNT) \
		MAKE_MODE=$(MAKE_MODE) >> $(ABSOLUTE_PREFIX_ROOT)/log_perl.txt 2>&1 && \
	make \
		MAKE_MODE=$(MAKE_MODE) \
		install >> $(ABSOLUTE_PREFIX_ROOT)/log_perl.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(perl_VERSION) > $@
endif

# png
$(png_VERSION_FILE) : $(cmake_VERSION_FILE) $(zlib_VERSION_FILE) $(png_FILE)
	@echo Building png $(png_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(basename $(png_FILE)))) && \
	tar -xf $(png_FILE) && \
	cd $(notdir $(basename $(basename $(png_FILE)))) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf "/CMAKE_DEBUG_POSTFIX/d\nw\n" | ed -s CMakeLists.txt ) && \
	( printf "/CheckCSourceCompiles/d\nw\n" | ed -s CMakeLists.txt ) && \
	( printf "/ASM/s/ASM//\nw\n" | ed -s CMakeLists.txt ) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(png_PREFIX)" \
		-DPNG_HARDWARE_OPTIMIZATIONS:BOOL=OFF \
		-DPNG_SHARED:BOOL=OFF \
		-DPNG_TESTS:BOOL=OFF \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		-Dld-version-script:BOOL=OFF \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_png.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_png.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(png_VERSION) > $@


# Ptex
$(ptex_VERSION_FILE) : $(cmake_VERSION_FILE) $(ptex_FILE)/HEAD
	@echo Building Ptex $(ptex_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(ptex_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(ptex_FILE))" $(notdir $(basename $(ptex_FILE))) && \
	cd $(notdir $(basename $(ptex_FILE))) && \
	git checkout -q $(ptex_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf "2a\n#ifndef PTEX_STATIC\n#define PTEX_STATIC\n#endif\n.\nw\nq\n" | ed -s src/ptex/Ptexture.h ) && \
	( printf "g/CMAKE_BUILD_TYPE/s/CMAKE_BUILD_TYPE/USELESS/g\nw\n" | ed -s CMakeLists.txt ) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(ptex_PREFIX)" \
		-DPTEX_BUILD_SHARED_LIBS=OFF \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_ptex.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_ptex.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(ptex_VERSION) > $@


# PySide2
$(pyside_VERSION_FILE) : $(cmake_VERSION_FILE) $(llvm_VERSION_FILE) $(qt5base_VERSION_FILE) $(qt5declarative_VERSION_FILE) $(qt5qtxmlpatterns_VERSION_FILE) $(pyside_FILE)/HEAD $(pysidetools_FILE)/HEAD
	@echo Building PySide2 $(pyside_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(pyside_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(pyside_FILE))" $(notdir $(basename $(pyside_FILE))) && \
	cd $(notdir $(basename $(pyside_FILE))) && \
	git checkout -q $(pyside_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf "/QSslPreSharedKeyAuthenticator/d\nw\n" | ed -s sources/pyside2/PySide2/QtNetwork/CMakeLists.txt ) && \
	( printf "/QSslPreSharedKeyAuthenticator/d\nw\n" | ed -s sources/pyside2/PySide2/QtNetwork/typesystem_network.xml ) && \
	env LLVM_INSTALL_DIR=$(llvm_PREFIX) \
	$(PYTHON_BIN) setup.py \
		build \
		--qmake=$(qt5base_PREFIX)/bin/qmake \
		--cmake=$(cmake_PREFIX)/bin/cmake \
		--jobs=$(JOB_COUNT) > $(ABSOLUTE_PREFIX_ROOT)/log_pyside.txt 2>&1 && \
	rm -rf $(pyside_PREFIX) && \
	mv pyside2_install/py2.7-qt*-64bit-release $(pyside_PREFIX) && \
	cd $(THIS_DIR) && \
	echo $(pyside_VERSION) > $@


# QT BASE
ifeq "$(MAKE_MODE)" "debug"
QT_ADDITIONAL := -debug
else
QT_ADDITIONAL := -release
endif

QT_LINK := static
ifeq "$(QT_LINK)" "static"
QT_ADDITIONAL += -static
endif

ifeq "$(QT_PLATFORM)" "webgl"
QT_ADDITIONAL += -opengl es2
else
ifeq "$(QT_PLATFORM)" "winrt"
QT_ADDITIONAL += -xplatform winrt-x64-msvc2017 -angle
else
ifeq "$(QT_PLATFORM)" "webassembly"
QT_ADDITIONAL += -xplatform wasm-emscripten -nomake examples
else
QT_ADDITIONAL += -opengl desktop
endif
endif
endif

ifeq "$(CURRENT_OS)" "windows"
	QT_CONFIGURE := $(CMD) configure$(BAT_EXT)
else
	QT_CONFIGURE := ./configure$(BAT_EXT)
endif
# TODO: Use this for static CRT for windows:
# https://github.com/IENT/YUView/wiki/Compile-Qt-64-bit-with-OpenSSL-using-VisualStudio-2015-and--MT
$(qt5base_VERSION_FILE) : $(perl_VERSION_FILE) $(qt5base_FILE)/HEAD
	@echo Building Qt5 Base $(qt5base_VERSION) $(QT_ADDITIONAL) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(qt5base_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(qt5base_FILE))" $(notdir $(basename $(qt5base_FILE))) && \
	cd $(notdir $(basename $(qt5base_FILE))) && \
	git checkout -q $(qt5base_VERSION) && \
	( test ! $(qt5base_VERSION) == v5.12.0-beta4 || git apply "$(WINDOWS_THIS_DIR)/patches/Qt/0001-Revert-qendian-Fix-float-conversions.patch" ) && \
	export PATH=$(ABSOLUTE_PREFIX_ROOT)/perl/bin:$$PATH && \
	$(QT_CONFIGURE) \
		$(QT_ADDITIONAL) \
		-verbose \
		-confirm-license \
		-mp \
		-no-cups \
		-no-directwrite \
		-no-gif \
		-no-libjpeg \
		-no-sql-mysql \
		-no-sql-sqlite \
		-no-openssl \
		-nomake tests \
		-opensource \
		-prefix "$(qt5base_PREFIX)" \
		-qt-freetype \
		-qt-libpng \
		-qt-pcre > $(ABSOLUTE_PREFIX_ROOT)/log_qt5base.txt 2>&1 && \
	$(NMAKE) $(MAKE_FLAGS) >> $(ABSOLUTE_PREFIX_ROOT)/log_qt5base.txt 2>&1 && \
	$(NMAKE) install >> $(ABSOLUTE_PREFIX_ROOT)/log_qt5base.txt 2>&1 && \
	printf "[Paths]\nPrefix = .." > qt.conf && \
	cp qt.conf "$(qt5base_PREFIX)\bin" && \
	cd $(THIS_DIR) && \
	echo $(qt5base_VERSION) > $@


# tbb
ifeq "$(MAKE_MODE)" "debug"
TBB_CONFIGURATION := Debug
TBB_SUFFIX := _debug
else
TBB_CONFIGURATION := Release
endif
ifeq "$(CRT_LINKAGE)" "static"
	TBB_CRT_CONF := -MT
endif
$(tbb_VERSION_FILE) : $(tbb_FILE)
ifeq "$(CURRENT_OS)" "windows"
	@echo Building tbb $(tbb_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf tbb$(tbb_VERSION) && \
	tar zxf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(tbb_FILE)) && \
	cd tbb$(tbb_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	cmd /C msbuild build/vs2012/makefile.sln \
		/p:configuration=$(TBB_CONFIGURATION)$(TBB_CRT_CONF) \
		/p:platform=x64 \
		/p:WindowsTargetPlatformVersion=$(WIN_SDK).0 \
		/p:PlatformToolset=v141 > $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tbb/include && \
	cp -R include/tbb $(ABSOLUTE_PREFIX_ROOT)/tbb/include && \
	cmd /C link /lib /machine:x64 /out:tbb$(TBB_SUFFIX).lib \
		build/vs2012/x64/tbb/$(TBB_CONFIGURATION)$(TBB_CRT_CONF)/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	cmd /C link /lib /machine:x64 /out:tbbmalloc$(TBB_SUFFIX).lib \
		build/vs2012/x64/tbbmalloc/$(TBB_CONFIGURATION)$(TBB_CRT_CONF)/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	cmd /C link /lib /machine:x64 /out:tbbmalloc_proxy$(TBB_SUFFIX).lib \
		build/vs2012/x64/tbbmalloc_proxy/$(TBB_CONFIGURATION)$(TBB_CRT_CONF)/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tbb/lib && \
	cp *.lib $(ABSOLUTE_PREFIX_ROOT)/tbb/lib && \
	cd $(THIS_DIR) && \
	echo $(tbb_VERSION) > $@
else
	@echo Building tbb $(tbb_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf tbb$(tbb_VERSION) && \
	tar -xf $(tbb_FILE) && \
	cd tbb$(tbb_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf "/CPLUS/s/g++/$(subst /,\/,$(CXX))/\nw\nq" | ed -s build/linux.gcc.inc ) && \
	( printf "/CONLY/s/gcc/$(subst /,\/,$(CC))/\nw\nq" | ed -s build/linux.gcc.inc ) && \
	( printf "\044a\nCPLUS_FLAGS += $(FLAGS)\n.\nw\nq" | ed -s build/linux.gcc.inc ) && \
	( printf "/ifeq.*OS.*Linux/i\nifeq (\044(OS), linux)\nexport tbb_os=linux\nendif\n.\nw\nq\n" | ed -s build/common.inc ) && \
	make \
		-C src \
		tbb_$(MAKE_MODE) \
		tbbmalloc_$(MAKE_MODE) \
		compiler=gcc \
		-j $(JOB_COUNT) > $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	mkdir -p $(tbb_PREFIX)/include && \
	cp -R include/tbb $(tbb_PREFIX)/include && \
	mkdir -p $(tbb_PREFIX)/lib && \
	ar \
		-rsc $(tbb_PREFIX)/lib/libtbb.a \
		build/*_$(MAKE_MODE)/*.o >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(tbb_VERSION) > $@
endif


$(tiff_VERSION_FILE) : $(tiff_FILE) $(jpeg_VERSION_FILE) $(zlib_VERSION_FILE)
ifeq "$(CURRENT_OS)" "windows"
	@echo Building tiff $(tiff_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf tiff-$(tiff_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/tiff-$(tiff_VERSION).tar.gz && \
	cd tiff-$(tiff_VERSION) && \
	( test ! $(CRT_LINKAGE) == static || printf '/OPTFLAGS/s/MD/MT/\nw\nq' | ed -s nmake.opt ) && \
	env -u MAKE -u MAKEFLAGS nmake /f Makefile.vc \
		JPEG_SUPPORT=1 \
		JPEG_INCLUDE=-I"$(jpeg_PREFIX)/include" \
		JPEG_LIB="$(jpeg_PREFIX)/lib/jpeg-static.lib $(zlib_PREFIX)/lib/zlib.lib" \
		ZLIB_SUPPORT=1 \
		ZLIB_INCLUDE=-I"$(zlib_PREFIX)/include" \
		ZLIB_LIB="$(zlib_PREFIX)/lib/zlib.lib" > $(ABSOLUTE_PREFIX_ROOT)/log_tiff.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tiff/bin && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tiff/include && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp tools/*.exe $(ABSOLUTE_PREFIX_ROOT)/tiff/bin && \
	cp libtiff/libtiff.lib $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp libtiff/libtiff.pdb $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp libtiff/libtiff.ilk $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp libtiff/*.h* $(ABSOLUTE_PREFIX_ROOT)/tiff/include && \
	cd $(THIS_DIR) && \
	echo $(openexr_VERSION) > $@
else
	@echo Building tiff $(tiff_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(tiff_FILE))) && \
	tar -xf $(tiff_FILE) && \
	cd $(notdir $(basename $(basename $(tiff_FILE)))) && \
	( printf "/inflateEnd.*()/d\nw\nq" | ed -s configure ) && \
	( printf "/inflateEnd.*()/d\nw\nq" | ed -s configure ) && \
	$(COMPILER_CONF) \
	./configure \
		--prefix=$(tiff_PREFIX) \
		--with-zlib-include-dir=$(zlib_PREFIX)/include \
		--with-zlib-lib-dir=$(zlib_PREFIX)/lib \
		--enable-shared=no > $(ABSOLUTE_PREFIX_ROOT)/log_tiff.txt 2>&1 && \
	make -j$(JOB_COUNT) \
		MAKE_MODE=$(MAKE_MODE) \
		install >> $(ABSOLUTE_PREFIX_ROOT)/log_tiff.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(tiff_VERSION) > $@
endif


USD_LINK := monolithic
ifeq "$(USD_LINK)" "static"
USD_BUILD_SHARED_LIBS := OFF
PXR_BUILD_MONOLITHIC := OFF
else
ifeq "$(USD_LINK)" "shared"
USD_BUILD_SHARED_LIBS := ON
PXR_BUILD_MONOLITHIC := OFF
else
USD_BUILD_SHARED_LIBS := OFF
PXR_BUILD_MONOLITHIC := ON
endif
endif

BOOST_NAMESPACE := boost


ifeq "$(CURRENT_OS)" "windows"
# Windows
LIB_PREFIX :=
ZLIB_LIBRARY := $(zlib_PREFIX)/lib/zlib$(STATICLIB_EXT)
JPEG_LIBRARY := $(jpeg_PREFIX)/lib/$(LIB_PREFIX)turbojpeg-static$(STATICLIB_EXT)
BOOST_LIB_EXT := .lib

ifeq "$(BOOST_LINK)" "shared"
BOOST_LIB_PREFIX :=
else
BOOST_LIB_PREFIX := lib
endif
else
# Linux
LIB_PREFIX := lib
ZLIB_LIBRARY := $(zlib_PREFIX)/lib/libz$(STATICLIB_EXT)
JPEG_LIBRARY := $(jpeg_PREFIX)/lib/$(LIB_PREFIX)turbojpeg$(STATICLIB_EXT)
BOOST_LIB_PREFIX := lib

ifeq "$(BOOST_LINK)" "shared"
BOOST_LIB_EXT := .so
else
BOOST_LIB_EXT := .a
endif
endif

USD_STATIC_LIBS = \
	"$(openexr_PREFIX)/lib/$(LIB_PREFIX)IlmImf-2_2$(STATICLIB_EXT)" \
	"$(openexr_PREFIX)/lib/$(LIB_PREFIX)Imath-2_2$(STATICLIB_EXT)" \
	"$(openexr_PREFIX)/lib/$(LIB_PREFIX)Iex-2_2$(STATICLIB_EXT)" \
	"$(openexr_PREFIX)/lib/$(LIB_PREFIX)Half$(STATICLIB_EXT)" \
	"$(openexr_PREFIX)/lib/$(LIB_PREFIX)IlmThread-2_2$(STATICLIB_EXT)" \
	"$(PNG_LIBRARY)" \
	"$(JPEG_LIBRARY)" \
	"$(ptex_PREFIX)/lib/$(LIB_PREFIX)Ptex$(STATICLIB_EXT)" \
	"$(ZLIB_LIBRARY)" \
	"$(tiff_PREFIX)/lib/libtiff$(STATICLIB_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_filesystem$(BOOST_LIB_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_regex$(BOOST_LIB_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_system$(STATICLIB_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_thread$(BOOST_LIB_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_chrono$(BOOST_LIB_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_date_time$(BOOST_LIB_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_atomic$(BOOST_LIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)embree_avx$(STATICLIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)embree_avx2$(STATICLIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)embree_sse42$(STATICLIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)lexers$(STATICLIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)math$(STATICLIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)simd$(STATICLIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)sys$(STATICLIB_EXT)" \
	"$(embree_PREFIX)/lib/$(LIB_PREFIX)tasking$(STATICLIB_EXT)" \
	"$(osl_PREFIX)/lib/$(LIB_PREFIX)oslquery$(STATICLIB_EXT)"

USD_CMAKELISTS_WITH_BOOST = \
	pxr/base/lib/plug/CMakeLists.txt \
	pxr/base/lib/tf/CMakeLists.txt \
	pxr/base/lib/trace/CMakeLists.txt \
	pxr/base/lib/vt/CMakeLists.txt \
	pxr/imaging/lib/glf/CMakeLists.txt \
	pxr/usdImaging/lib/usdImagingGL/CMakeLists.txt \
	pxr/usdImaging/lib/usdImaging/CMakeLists.txt \
	pxr/usdImaging/lib/usdviewq/CMakeLists.txt \
	pxr/usd/lib/ar/CMakeLists.txt \
	pxr/usd/lib/ndr/CMakeLists.txt \
	pxr/usd/lib/pcp/CMakeLists.txt \
	pxr/usd/lib/sdf/CMakeLists.txt \
	pxr/usd/lib/sdr/CMakeLists.txt \
	pxr/usd/lib/usdGeom/CMakeLists.txt \
	pxr/usd/lib/usdRi/CMakeLists.txt \
	pxr/usd/lib/usdSkel/CMakeLists.txt \
	pxr/usd/lib/usdUtils/CMakeLists.txt \
	pxr/usd/lib/usd/CMakeLists.txt \
	third_party/maya/lib/usdMaya/CMakeLists.txt \
	third_party/maya/plugin/pxrUsdTranslators/CMakeLists.txt

TBB_LIBRARY := "$(tbb_PREFIX)/lib"
TBB_ROOT_DIR := "$(tbb_PREFIX)/include"
MAYA_ROOT := "C:/Program Files/Autodesk/Maya2018"

ifeq "$(USD_MINIMAL)" "1"
PXR_BUILD_IMAGING := OFF
else
PXR_BUILD_IMAGING := ON
endif

ifeq "$(BOOST_LINK)" "shared"
USD_STATIC_LIBS += \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_python$(BOOST_LIB_EXT)"
endif

$(usd_VERSION_FILE) : $(PyOpenGL_VERSION_FILE) $(boost_VERSION_FILE) $(cmake_VERSION_FILE) $(embree_VERSION_FILE) $(ilmbase_VERSION_FILE) $(materialx_VERSION_FILE) $(oiio_VERSION_FILE) $(openexr_VERSION_FILE) $(opensubd_VERSION_FILE) $(osl_VERSION_FILE) $(ptex_VERSION_FILE) $(pyside_VERSION_FILE) $(tbb_VERSION_FILE) $(usd_FILE)/HEAD
	@echo Building usd $(usd_VERSION) shared:$(USD_BUILD_SHARED_LIBS) monolithic:$(PXR_BUILD_MONOLITHIC) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(usd_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(usd_FILE))" $(notdir $(basename $(usd_FILE))) && \
	cd $(notdir $(basename $(usd_FILE))) && \
	git checkout -q $(usd_VERSION) && \
	( test ! $(CURRENT_OS) == windows || test ! $(USE_STATIC_BOOST) == ON || git apply "$(WINDOWS_THIS_DIR)\patches\0001-Weak-function-_ReadPlugInfoObject.patch" ) && \
	( test ! $(CURRENT_OS) == windows || test ! $(USE_STATIC_BOOST) == ON || git apply "$(WINDOWS_THIS_DIR)\patches\0002-Ability-to-use-custom-log-output.patch" ) && \
	( test ! $(CURRENT_OS) == windows || test ! $(USE_STATIC_BOOST) == OFF || git apply "$(WINDOWS_THIS_DIR)\patches\0003-Install-PDB-files.patch" ) && \
	( test ! $(CURRENT_OS) == windows || git apply "$(WINDOWS_THIS_DIR)\patches\0005-Fixed-maya-crash-when-exporting.patch" ) && \
	( git apply "$(WINDOWS_THIS_DIR)/patches/0006-Bug-in-Intel-implementation-of-GL_ARB_shader_draw_pa.patch" ) && \
	echo USD: Patching for supporting static OIIO... && \
	( for f in $(USD_STATIC_LIBS); do ( printf "\044a\nlist(APPEND OIIO_LIBRARIES \"$$f\")\n.\nw\nq" | ed -s cmake/modules/FindOpenImageIO.cmake ); done ) && \
	( printf "/find_library.*OPENEXR_.*_LIBRARY/a\nNAMES\n\044{OPENEXR_LIB}-2_2\n.\nw\nq" | ed -s cmake/modules/FindOpenEXR.cmake ) && \
	( printf "/HDF5 REQUIRED/+\nd\nd\nd\nw\nq" | ed -s cmake/defaults/Packages.cmake ) && \
	( printf "/BOOST_ALL_DYN_LINK/d\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	( printf "/OPENEXR_DLL/d\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	echo USD: Patching for supporting MSVC2017... && \
	( printf "/glew32s/s/glew32s/libglew32/\nw\nq" | ed -s cmake/modules/FindGLEW.cmake ) && \
	( printf "/Zc:rvalueCast/d\nd\nd\na\nset(_PXR_CXX_FLAGS \"\044{_PXR_CXX_FLAGS} /Zc:rvalueCast /Zc:strictStrings /Zc:inline\")\n.\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	echo USD: Patching for Maya support... && \
	sed -i "/Program Files/d" cmake/modules/FindMaya.cmake && \
	( printf "/find_package_handle_standard_args/\n/MAYA_EXECUTABLE/d\nw\nq" | ed -s cmake/modules/FindMaya.cmake ) && \
	echo USD: Cant irnore Unresolved_external_symbol_error_is_expected_Please_ignore because it always fails... && \
	( printf "/Unresolved_external_symbol_error_is_expected_Please_ignore/d\ni\nint Unresolved_external_symbol_error_is_expected_Please_ignore()\n{return 0;}\n.\nw\nq" | ed -s pxr/base/lib/plug/testenv/TestPlugDsoUnloadable.cpp ) && \
	( test ! $(USE_STATIC_BOOST) == ON || echo USD: Dont skip plugins when building static libraries... ) && \
	( test ! $(USE_STATIC_BOOST) == ON || printf "/Skipping plugin/\nd\nd\na\nset(args_TYPE \"STATIC\")\n.\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	( test ! $(USE_STATIC_BOOST) == ON || printf "/CMAKE_SHARED_LIBRARY_SUFFIX/s/CMAKE_SHARED_LIBRARY_SUFFIX/CMAKE_STATIC_LIBRARY_SUFFIX/\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	echo USD: Removing dependencies on boost_python... && \
	( test ! $(USE_STATIC_BOOST) == ON || for f in $(USD_CMAKELISTS_WITH_BOOST); do ( printf "/Boost_PYTHON_LIBRARY/d\nw\nq" | ed -s $$f ); done ) && \
	( test ! $(USE_STATIC_BOOST) == ON || printf "/WHOLEARCHIVE/a\n\044{Boost_PYTHON_LIBRARY}\n-WHOLEARCHIVE:\044{Boost_PYTHON_LIBRARY}\n.\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	( test ! $(USE_STATIC_BOOST) == ON || printf "/--whole-archive/a\n-Wl,--whole-archive \044{Boost_PYTHON_LIBRARY} -Wl,--no-whole-archive\n.\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	( test ! $(USE_STATIC_BOOST) == ON || printf "/PXR_BUILD_LOCATION=usd/a\nBOOST_PYTHON_SOURCE\n.\nw\nq" | ed -s cmake/macros/Private.cmake ) && \
	echo USD: Skip extra stuff... && \
	( printf "/add_subdirectory(extras)/d\nw\n" | ed -s CMakeLists.txt ) && \
	echo USD: Generate better pxrConfig.cmake... && \
	( test ! $(PXR_BUILD_MONOLITHIC) == ON || printf "/foreach/a\nset_target_properties(\044{lib} PROPERTIES IMPORTED_IMPLIB_MINSIZEREL \"\044{PXR_CMAKE_DIR}/lib/$(LIB_PREFIX)usd_ms$(STATICLIB_EXT)\" IMPORTED_LOCATION_MINSIZEREL \"\044{PXR_CMAKE_DIR}/lib/$(LIB_PREFIX)usd_ms$(DYNAMICLIB_EXT)\")\n.\nw\n" | ed -s pxr/pxrConfig.cmake.in ) && \
	( test ! $(PXR_BUILD_MONOLITHIC) == ON || printf "/foreach/a\nset_property(TARGET \044{lib} APPEND PROPERTY IMPORTED_CONFIGURATIONS MINSIZEREL)\n.\nw\n" | ed -s pxr/pxrConfig.cmake.in ) && \
	( test ! $(PXR_BUILD_MONOLITHIC) == ON || printf "/foreach/a\nset_target_properties(\044{lib} PROPERTIES INTERFACE_COMPILE_DEFINITIONS \"PXR_PYTHON_ENABLED=1;NOMINMAX;BOOST_ALL_NO_LIB\" INTERFACE_INCLUDE_DIRECTORIES \"\044{PXR_CMAKE_DIR}/include;$(boost_PREFIX)/include;$(tbb_PREFIX)/include;$(PYTHON_INCLUDE)\" INTERFACE_LINK_LIBRARIES \"\044{PXR_CMAKE_DIR}/lib/$(LIB_PREFIX)usd_ms$(STATICLIB_EXT);$(tbb_PREFIX)/lib/$(LIB_PREFIX)tbb$(STATICLIB_EXT);$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)boost_python$(STATICLIB_EXT);$(PYTHON_LIBS)/$(LIB_PREFIX)python27$(STATICLIB_EXT)\")\n.\nw\n" | ed -s pxr/pxrConfig.cmake.in ) && \
	( test ! $(PXR_BUILD_MONOLITHIC) == ON || printf "/foreach/a\nadd_library(\044{lib} SHARED IMPORTED)\n.\nw\n" | ed -s pxr/pxrConfig.cmake.in ) && \
	( test ! $(PXR_BUILD_MONOLITHIC) == ON || printf "/pxrTargets/d\nw\n" | ed -s pxr/pxrConfig.cmake.in ) && \
	echo USD: Using static embree... && \
	( printf "/libembree.so/s/so/a/\nw\nq" | ed -s cmake/modules/FindEmbree.cmake ) && \
	mkdir -p build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	export PATH=$(ABSOLUTE_PREFIX_ROOT)/pyside/bin:$$PATH && \
	export LD_LIBRARY_PATH=$(ABSOLUTE_PREFIX_ROOT)/pyside/lib:$(ABSOLUTE_PREFIX_ROOT)/qt5base/lib:$$LD_LIBRARY_PATH && \
	export PYTHONPATH=$(ABSOLUTE_PREFIX_ROOT)/PyOpenGL/python:$(ABSOLUTE_PREFIX_ROOT)/pyside/lib64/python2.7/site-packages && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DALEMBIC_DIR="$(alembic_PREFIX)" \
		-DBOOST_ROOT:PATH="$(boost_PREFIX)" \
		-DBUILD_SHARED_LIBS:BOOL=$(USD_BUILD_SHARED_LIBS) \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DCMAKE_INSTALL_PREFIX="$(usd_PREFIX)" \
		-DEMBREE_LOCATION:PATH="$(embree_PREFIX)" \
		-DGLEW_LOCATION:PATH="$(glew_PREFIX)" \
		-DHDF5_ROOT="$(hdf5_PREFIX)" \
		-DMATERIALX_ROOT="$(materialx_PREFIX)" \
		-DMAYA_LOCATION:PATH=$(MAYA_ROOT) \
		-DOIIO_LOCATION:PATH="$(oiio_PREFIX)" \
		-DOPENEXR_BASE_DIR:PATH="$(ilmbase_PREFIX)" \
		-DOPENEXR_INCLUDE_DIR:PATH="$(ilmbase_PREFIX)\include" \
		-DOPENEXR_LOCATION:PATH="$(openexr_PREFIX)" \
		-DOPENSUBDIV_ROOT_DIR:PATH="$(opensubd_PREFIX)" \
		-DOSL_LOCATION="$(osl_PREFIX)" \
		-DPTEX_LOCATION:PATH="$(ptex_PREFIX)" \
		-DPXR_BUILD_ALEMBIC_PLUGIN:BOOL=OFF \
		-DPXR_BUILD_EMBREE_PLUGIN:BOOL=$(PXR_BUILD_IMAGING) \
		-DPXR_BUILD_IMAGING:BOOL=$(PXR_BUILD_IMAGING) \
		-DPXR_BUILD_MATERIALX_PLUGIN:BOOL=ON \
		-DPXR_BUILD_MAYA_PLUGIN:BOOL=$(BUILD_USD_MAYA_PLUGIN) \
		-DPXR_BUILD_MONOLITHIC:BOOL=$(PXR_BUILD_MONOLITHIC) \
		-DPXR_BUILD_OPENIMAGEIO_PLUGIN:BOOL=ON \
		-DPXR_BUILD_TESTS:BOOL=OFF \
		-DPXR_BUILD_USD_IMAGING:BOOL=$(PXR_BUILD_IMAGING) \
		-DPXR_ENABLE_OSL_SUPPORT:BOOL=ON \
		-DPXR_ENABLE_PYTHON_SUPPORT:BOOL=$(PXR_BUILD_IMAGING) \
		-DPXR_LIB_PREFIX="" \
		-DPYSIDE_BIN_DIR:PATH=$(PYTHON_ROOT)/Scripts \
		-DPYTHON_EXECUTABLE=$(PYTHON_BIN) \
		-DTBB_LIBRARY=$(TBB_LIBRARY) \
		-DTBB_ROOT_DIR=$(TBB_ROOT_DIR) \
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_usd.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) \
		$(CMAKE_MAKE_FLAGS) >> $(ABSOLUTE_PREFIX_ROOT)/log_usd.txt 2>&1 && \
	( test ! $(USE_STATIC_BOOST) == OFF || echo USD: Including boost shared libraries... ) && \
	( test ! $(USE_STATIC_BOOST) == OFF || test ! $(CURRENT_OS) == windows || cmd /C copy $(subst /,\\,$(boost_PREFIX)/lib/*.dll) $(subst /,\\,$(usd_PREFIX)/lib) ) && \
	( test ! $(USE_STATIC_BOOST) == OFF || test ! $(CURRENT_OS) == linux || cp $(boost_PREFIX)/lib/*$(DYNAMICLIB_EXT) $(usd_PREFIX)/lib ) && \
	( test ! $(USE_STATIC_BOOST) == OFF || echo USD: Including Maya mod file... ) && \
	( test ! $(BUILD_USD_MAYA_PLUGIN) == ON || test ! $(CURRENT_OS) == windows || cmd /C copy /Y $(subst \,\\,$(WINDOWS_THIS_DIR)\patches\usd.mod) $(subst /,\\,$(usd_PREFIX)/third_party/maya) ) && \
	( test ! $(CURRENT_OS) == windows || cmd /C copy /Y $(subst \,\\,$(WINDOWS_THIS_DIR)\patches\usd.cmd) $(subst /,\\,$(usd_PREFIX)) ) && \
	( test ! $(BUILD_USD_MAYA_PLUGIN) == ON || test ! $(CURRENT_OS) == linux || 'cp' -r $(THIS_DIR)/patches/usd.mod $(usd_PREFIX)/third_party/maya ) && \
	cd $(THIS_DIR) && \
	echo $(usd_VERSION) > $@


ifeq "$(CURRENT_OS)" "windows"
X264_PLATFORM_ENV := env CC=cl
else
X264_PLATFORM_ENV :=
endif
ifeq "$(MAKE_MODE)" "debug"
X264_PLATFORM_FLAGS := --enable-debug
endif
$(x264_VERSION_FILE) : $(x264_FILE)/HEAD
	@echo Building x264 $(x264_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(x264_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(x264_FILE))" $(notdir $(basename $(x264_FILE))) && \
	cd $(notdir $(basename $(x264_FILE))) && \
	git config core.eol lf && \
	git config core.autocrlf input && \
	git checkout -q $(x264_VERSION) && \
	$(X264_PLATFORM_ENV) \
	./configure \
		--enable-static \
		--extra-cflags="$(FLAGS)" \
		--prefix=$(x264_UNIX_PREFIX) \
		$(X264_PLATFORM_FLAGS) > $(ABSOLUTE_PREFIX_ROOT)/log_x264.txt 2>&1 && \
	make -j$(JOB_COUNT) >> $(ABSOLUTE_PREFIX_ROOT)/log_x264.txt 2>&1 && \
	( test ! $(CURRENT_OS) == windows || printf '/cygdrive/s/\/cygdrive\/c/c:/\nw\n' | ed -s x264.pc ) && \
	make install >> $(ABSOLUTE_PREFIX_ROOT)/log_x264.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(x264_VERSION) > $@


# libz
$(zlib_VERSION_FILE) : $(cmake_VERSION_FILE) $(zlib_FILE)/HEAD
ifeq "$(CURRENT_OS)" "windows"
	@echo Building zlib $(zlib_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(zlib_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(zlib_FILE))" $(notdir $(basename $(zlib_FILE))) && \
	cd $(notdir $(basename $(zlib_FILE))) && \
	git checkout -q $(zlib_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf "/install.*zlib.zlibstatic/s/zlib//\nw\n" | ed -s CMakeLists.txt ) && \
	( printf "/add_library.zlibstatic/a\nset_target_properties(zlib PROPERTIES OUTPUT_NAME \"zlibdynamic\")\n.\nw\n" | ed -s CMakeLists.txt ) && \
	( printf "/add_library.zlibstatic/a\nset_target_properties(zlibstatic PROPERTIES OUTPUT_NAME \"zlib\")\n.\nw\n" | ed -s CMakeLists.txt ) && \
	( printf "/#  define Z_HAVE_UNISTD_H/d\nw\n" | ed -s zconf.h.cmakein ) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX="$(zlib_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_zlib.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) \
		$(CMAKE_MAKE_FLAGS) >> $(ABSOLUTE_PREFIX_ROOT)/log_zlib.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(zlib_VERSION) > $@
else
	@echo Building zlib $(ZLIB_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(zlib_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(zlib_FILE))" $(notdir $(basename $(zlib_FILE))) && \
	cd $(notdir $(basename $(zlib_FILE))) && \
	git checkout -q $(zlib_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(COMPILER_CONF) \
	./configure \
		--const \
		--zprefix \
		--prefix=$(zlib_PREFIX) \
		--static > $(ABSOLUTE_PREFIX_ROOT)/log_zlib.txt 2>&1 && \
	make -j$(JOB_COUNT) \
		MAKE_MODE=$(MAKE_MODE) \
		install >> $(ABSOLUTE_PREFIX_ROOT)/log_zlib.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(zlib_VERSION) > $@
endif

# libzmq
ifeq "$(CURRENT_OS)" "windows"
ZMQ_PLATFORM_FLAGS := -G "NMake Makefiles"
else
ZMG_PLATFORM_FLAGS :=
endif
$(zmq_VERSION_FILE) : $(cmake_VERSION_FILE) $(zmq_FILE)/HEAD
	@echo Building zmq $(zmq_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(zmq_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(zmq_FILE))" $(notdir $(basename $(zmq_FILE))) && \
	cd $(notdir $(basename $(zmq_FILE))) && \
	git checkout -q $(zmq_VERSION) && \
	( printf 'g/libzmq /s/libzmq /libzmq-static /g\nw\n' | ed -s builds/cmake/ZeroMQConfig.cmake.in ) && \
	mkdir -p build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBUILD_SHARED=OFF \
		-DCMAKE_INSTALL_PREFIX="$(zmq_PREFIX)" \
		-DWITH_DOC=OFF \
		-DBUILD_TESTS=OFF \
		$(ZMQ_PLATFORM_FLAGS) \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_zmq.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_zmq.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(zmq_VERSION) > $@
