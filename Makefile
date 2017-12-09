# Copyright (C) 2017 Victor Yudin - All Rights Reserved
#
# This is the Windows build recipe for Pixar USD and its dependencies.
#

SOURCES_ROOT=./src
BUILD_ROOT=./build
PREFIX_ROOT=./lib

ABSOLUTE_SOURCES_ROOT := $(abspath $(SOURCES_ROOT))
ABSOLUTE_BUILD_ROOT := $(abspath $(BUILD_ROOT))
ABSOLUTE_PREFIX_ROOT := $(abspath $(PREFIX_ROOT))
WINDOWS_SOURCES_ROOT := $(shell cygpath -w $(ABSOLUTE_SOURCES_ROOT))
WINDOWS_BUILD_ROOT := $(shell cygpath -w $(ABSOLUTE_BUILD_ROOT))
WINDOWS_PREFIX_ROOT := $(subst \,/,$(shell cygpath -w $(ABSOLUTE_PREFIX_ROOT)))

ifeq "$(MAKE_MODE)" ""
MAKE_MODE := release
endif

ifeq "$(MAKE_MODE)" "debug"
CMAKE_BUILD_TYPE := Debug
else
CMAKE_BUILD_TYPE := MinSizeRel
endif

# Save the current directory
THIS_DIR := $(shell pwd)
TOP_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
WINDOWS_THIS_DIR := $(shell cygpath -w $(THIS_DIR))

define PACKAGE_VARS =
ifeq "$($(1)_EXTERNAL)" ""
$(1)_VERSION := $(2)
$(1)_VERSION_FILE := $(ABSOLUTE_PREFIX_ROOT)/built_$(1)
$(1)_PREFIX := $(WINDOWS_PREFIX_ROOT)/$(1)
$(1)_SOURCE := $(3)
$(1)_FILE := $(ABSOLUTE_SOURCES_ROOT)/$$(notdir $$($(1)_SOURCE))
$(1): $$($(1)_VERSION_FILE)

$(1)-archive: $(1)-$$($(1)_VERSION).tar.xz
$(1)-$$($(1)_VERSION).tar.xz: $$($(1)_VERSION_FILE)
	@echo Archiving $$@ && \
	tar cfJ $$@ -C $(ABSOLUTE_PREFIX_ROOT) $(1)
else
$(1)_PREFIX := $($(1)_EXTERNAL)
endif
endef

define GIT_DOWNLOAD =
$(call PACKAGE_VARS,$(1),$(2),$(3))

$$($(1)_FILE)/HEAD :
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	git clone -q --bare $$($(1)_SOURCE) `cygpath -w $$($(1)_FILE)`
endef

define CURL_DOWNLOAD =
$(call PACKAGE_VARS,$(1),$(2),$(3))

$$($(1)_FILE) :
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	curl --tlsv1.2 --retry 10 -s -o $$@ -L $$($(1)_SOURCE)
endef

$(eval $(call CURL_DOWNLOAD,boost,1_61_0,http://sourceforge.net/projects/boost/files/boost/$$(subst _,.,$$(boost_VERSION))/boost_$$(boost_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,cfe,5.0.0,http://releases.llvm.org/$$(cfe_VERSION)/cfe-$$(cfe_VERSION).src.tar.xz))
$(eval $(call CURL_DOWNLOAD,clangtoolsextra,5.0.0,http://releases.llvm.org/$$(clangtoolsextra_VERSION)/clang-tools-extra-$$(clangtoolsextra_VERSION).src.tar.xz))
$(eval $(call CURL_DOWNLOAD,cmake,3.9.1,https://cmake.org/files/v$$(word 1,$$(subst ., ,$$(cmake_VERSION))).$$(word 2,$$(subst ., ,$$(cmake_VERSION)))/cmake-$$(cmake_VERSION)-win64-x64.zip))
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
$(eval $(call GIT_DOWNLOAD,embree,v2.17.1,git://github.com/embree/embree.git))
$(eval $(call GIT_DOWNLOAD,glfw,3.2.1,git://github.com/glfw/glfw.git))
$(eval $(call GIT_DOWNLOAD,jom,v1.1.2,git://github.com/qt-labs/jom.git))
$(eval $(call GIT_DOWNLOAD,jpeg,1.5.1,git://github.com/libjpeg-turbo/libjpeg-turbo.git))
$(eval $(call GIT_DOWNLOAD,jsoncpp,1.8.0,git://github.com/open-source-parsers/jsoncpp.git))
$(eval $(call GIT_DOWNLOAD,oiio,Release-1.8.5,git://github.com/OpenImageIO/oiio.git))
$(eval $(call GIT_DOWNLOAD,opensubd,v3_2_0,git://github.com/PixarAnimationStudios/OpenSubdiv.git))
$(eval $(call GIT_DOWNLOAD,ptex,v2.1.28,git://github.com/wdas/ptex.git))
$(eval $(call GIT_DOWNLOAD,qt5base,v5.9.2,git://github.com/qt/qtbase.git))
$(eval $(call GIT_DOWNLOAD,usd,v0.8.2,git://github.com/PixarAnimationStudios/USD))
$(eval $(call GIT_DOWNLOAD,zlib,v1.2.8,git://github.com/madler/zlib.git))

# Number or processors
JOB_COUNT := $(shell cat /proc/cpuinfo | grep processor | wc -l)

CC := $(shell where cl)
CXX := $(shell where cl)
CMAKE := env -u MAKE -u MAKEFLAGS $(ABSOLUTE_PREFIX_ROOT)/cmake/bin/cmake

BOOST_LINK := static
ifeq "$(BOOST_LINK)" "shared"
USE_STATIC_BOOST := OFF
BUILD_USD_MAYA_PLUGIN := ON
else
USE_STATIC_BOOST := ON
BUILD_USD_MAYA_PLUGIN := OFF
# Disable embree
embree_VERSION_FILE :=
embree_PREFIX :=
endif

DEFINES = /DBOOST_ALL_NO_LIB /DPTEX_STATIC

ifeq "$(BOOST_LINK)" "shared"
DEFINES += /DBOOST_ALL_DYN_LINK
else
DEFINES += /DBOOST_ALL_STATIC_LINK
DEFINES += /DBOOST_PYTHON_STATIC_LIB
endif

COMMON_CMAKE_FLAGS :=\
	-G "NMake Makefiles JOM" \
	-DCMAKE_BUILD_TYPE:STRING=$(CMAKE_BUILD_TYPE) \
	-DCMAKE_CXX_FLAGS_DEBUG="/MTd $(DEFINES)" \
	-DCMAKE_CXX_FLAGS_RELEASE="/MT $(DEFINES)" \
	-DCMAKE_CXX_FLAGS_MINSIZEREL="/MT $(DEFINES)" \
	-DCMAKE_C_FLAGS_DEBUG="/MTd $(DEFINES)" \
	-DCMAKE_C_FLAGS_RELEASE="/MT $(DEFINES)" \
	-DCMAKE_C_FLAGS_MINSIZEREL="/MT $(DEFINES)" \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON

all: usd-archive
.PHONY : all
.DEFAULT_GOAL := all

PYTHON_BIN := C:/Python27/python.exe
PYTHON_VERSION_SHORT := 2.7
PYTHON_ROOT := $(subst \,,$(dir $(PYTHON_BIN)))
PYTHON_BIN := $(subst \,,$(PYTHON_BIN))
PYTHON_INCLUDE := $(PYTHON_ROOT)include
PYTHON_LIBS := $(PYTHON_ROOT)libs

ifeq "$(BOOST_VERSION)" "1_55_0"
BOOST_USERCONFIG := tools/build/v2/user-config.jam
else
BOOST_USERCONFIG := tools/build/src/user-config.jam
endif
$(boost_VERSION_FILE) : $(boost_FILE)
	@echo Building boost $(boost_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(BUILD_ROOT) && \
	rm -rf boost_$(boost_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/boost_$(boost_VERSION).tar.gz && \
	cd boost_$(boost_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	echo 'using msvc : 14.1 : "$(CXX)" ;' > $(BOOST_USERCONFIG) && \
	echo 'using python : $(PYTHON_VERSION_SHORT) : "$(PYTHON_BIN)" : "$(PYTHON_INCLUDE)" : "$(PYTHON_LIBS)" ;' && \
	echo 'using python : $(PYTHON_VERSION_SHORT) : "$(PYTHON_BIN)" : "$(PYTHON_INCLUDE)" : "$(PYTHON_LIBS)" ;' >> $(BOOST_USERCONFIG) && \
	( printf '/handle-static-runtime/\n/EXIT/d\nw\nq' | ed -s Jamroot ) && \
	cmd /C bootstrap.bat msvc > $(ABSOLUTE_PREFIX_ROOT)/log_boost.txt 2>&1 && \
	./b2 \
		--layout=system \
		--prefix=$(boost_PREFIX) \
		-j $(JOB_COUNT) \
		link=$(BOOST_LINK) \
		threading=multi \
		runtime-link=static \
		address-model=64 \
		toolset=msvc-14.1 \
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

$(cmake_VERSION_FILE) : $(cmake_FILE)
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
	( printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_LIBRARY $(tbb_PREFIX)/lib/tbb.lib)\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_LIBRARY_MALLOC $(tbb_PREFIX)/lib/tbbmalloc.lib)\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
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
		-DEMBREE_STATIC_RUNTIME:BOOL=ON \
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
	( for i in embree_sse42.lib embree_avx.lib embree_avx2.lib simd.lib tasking.lib lexers.lib sys.lib math.lib; do cmd /C copy $$i $(subst /,\\,$(embree_PREFIX)/lib); done ) && \
	cd $(THIS_DIR) && \
	echo $(embree_VERSION) > $@

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
		-G "NMake Makefiles" \
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
		-DINSTALL_PDB:BOOL=ON \
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
	( test $$OS != linux || if [ -f release_docs/USING_CMake.txt ] ; then cp release_docs/USING_CMake.txt release_docs/Using_CMake.txt ; fi ) && \
	( if [ ! -f release_docs/USING_CMake.txt ] ; then touch release_docs/USING_CMake.txt ; fi ) && \
	( if [ ! -f release_docs/Using_CMake.txt ] ; then touch release_docs/Using_CMake.txt ; fi ) && \
	( printf '/H5_HAVE_TIMEZONE/s/1/0/\nw\nq' | ed -s config/cmake/ConfigureChecks.cmake ) && \
	( printf '/"\/MD"/s/MD/MT/\nw\nq' | ed -s config/cmake/HDFMacros.cmake ) && \
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
	@echo Building jpeg $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf jpeg && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/libjpeg-turbo.git" jpeg && \
	cd jpeg && \
	git checkout -q $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-G "NMake Makefiles" \
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
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_llvm.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(llvm_VERSION) > $@

# OpenImageIO
# Edits:
# - Defining OIIO_STATIC_BUILD to avoid specifying it everywhere
# - std::locale segfault fix
# - Python module
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
		-DPNG_LIBRARY="$(png_PREFIX)/lib/libpng16_static.lib" \
		-DPNG_PNG_INCLUDE_DIR="$(png_PREFIX)/include" \
		-DTIFF_INCLUDE_DIR="$(tiff_PREFIX)/include" \
		-DTIFF_LIBRARY="$(tiff_PREFIX)/lib/libtiff.lib" \
		-DUSE_FREETYPE:BOOL=ON \
		-DUSE_GIF:BOOL=OFF \
		-DUSE_JPEGTURBO:BOOL=ON \
		-DUSE_NUKE:BOOL=OFF \
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
	cp $(ABSOLUTE_PREFIX_ROOT)/ilmbase/lib/*.lib $(ABSOLUTE_PREFIX_ROOT)/openexr/lib && \
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
		-DMSVC_STATIC_CRT:BOOL=ON \
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

# perl
$(perl_VERSION_FILE) : $(perl_FILE)
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
		-DZLIB_ROOT:PATH="$(zlib_PREFIX)" \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_ptex.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_ptex.txt 2>&1 && \
	rm $(ABSOLUTE_PREFIX_ROOT)/ptex/lib/*.dll && \
	cd $(THIS_DIR) && \
	echo $(ptex_VERSION) > $@

$(qt5base_VERSION_FILE) : $(perl_VERSION_FILE) $(qt5base_FILE)/HEAD
	@echo Building Qt5 Base $(qt5base_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(qt5base_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(qt5base_FILE))" $(notdir $(basename $(qt5base_FILE))) && \
	cd $(notdir $(basename $(qt5base_FILE))) && \
	git checkout -q $(qt5base_VERSION) && \
	( printf "g/-MD/s/-MD/-MT/g\nw\n" | ed -s mkspecs/common/msvc-desktop.conf ) && \
	export PATH=$(ABSOLUTE_PREFIX_ROOT)/perl/bin:$$PATH && \
	env -u MAKE -u MAKEFLAGS cmd /C configure.bat \
		-confirm-license \
		-no-cups \
		-no-directwrite \
		-no-gif \
		-no-gui \
		-no-libjpeg \
		-no-openssl \
		-no-qml-debug \
		-no-sql-mysql \
		-no-sql-sqlite \
		-no-widgets \
		-nomake examples \
		-nomake tests \
		-nomake tools \
		-opengl desktop \
		-opensource \
		-prefix "$(qt5base_PREFIX)" \
		-qt-freetype \
		-qt-libpng \
		-qt-pcre \
		-release \
		-static \
		-mp > $(ABSOLUTE_PREFIX_ROOT)/log_gt5base.txt 2>&1 && \
	env -u MAKE -u MAKEFLAGS nmake >> $(ABSOLUTE_PREFIX_ROOT)/log_gt5base.txt 2>&1 && \
	env -u MAKE -u MAKEFLAGS nmake install >> $(ABSOLUTE_PREFIX_ROOT)/log_gt5base.txt 2>&1 && \
	cd $(THIS_DIR) && \
	echo $(qt5base_VERSION) > $@

# tbb
ifeq "$(MAKE_MODE)" "debug"
TBB_CONFIGURATION := Debug
TBB_SUFFIX := _debug
else
TBB_CONFIGURATION := Release
endif
$(tbb_VERSION_FILE) : $(tbb_FILE)
	@echo Building tbb $(tbb_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf tbb$(tbb_VERSION) && \
	tar zxf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(tbb_FILE)) && \
	cd tbb$(tbb_VERSION) && \
	cmd /C msbuild build/vs2012/makefile.sln \
		/p:configuration=$(TBB_CONFIGURATION)-MT \
		/p:platform=x64 \
		/p:PlatformToolset=v141 > $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tbb/include && \
	cp -R include/tbb $(ABSOLUTE_PREFIX_ROOT)/tbb/include && \
	cmd /C link /lib /machine:x64 /out:tbb$(TBB_SUFFIX).lib \
		build/vs2012/x64/tbb/$(TBB_CONFIGURATION)-MT/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	cmd /C link /lib /machine:x64 /out:tbbmalloc$(TBB_SUFFIX).lib \
		build/vs2012/x64/tbbmalloc/$(TBB_CONFIGURATION)-MT/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	cmd /C link /lib /machine:x64 /out:tbbmalloc_proxy$(TBB_SUFFIX).lib \
		build/vs2012/x64/tbbmalloc_proxy/$(TBB_CONFIGURATION)-MT/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tbb/lib && \
	cp *.lib $(ABSOLUTE_PREFIX_ROOT)/tbb/lib && \
	cd $(THIS_DIR) && \
	echo $(tbb_VERSION) > $@


$(tiff_VERSION_FILE) : $(ZLIB_VERSION_FILE) $(tiff_FILE) $(jpeg_VERSION_FILE) $(zlib_VERSION_FILE)
	@echo Building tiff $(tiff_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf tiff-$(tiff_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/tiff-$(tiff_VERSION).tar.gz && \
	cd tiff-$(tiff_VERSION) && \
	( printf '/OPTFLAGS/s/MD/MT/\nw\nq' | ed -s nmake.opt ) && \
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

DYNAMIC_EXT := .lib
BOOST_NAMESPACE := boost
ifeq "$(BOOST_LINK)" "shared"
BOOST_LIB_PREFIX :=
else
BOOST_LIB_PREFIX := lib
endif
OIIO_LIBS = \
	"$(embree_PREFIX)/lib/embree_avx.lib" \
	"$(embree_PREFIX)/lib/embree_avx2.lib" \
	"$(embree_PREFIX)/lib/embree_sse42.lib" \
	"$(embree_PREFIX)/lib/lexers.lib" \
	"$(embree_PREFIX)/lib/math.lib" \
	"$(embree_PREFIX)/lib/simd.lib" \
	"$(embree_PREFIX)/lib/sys.lib" \
	"$(embree_PREFIX)/lib/tasking.lib" \
	"$(png_PREFIX)/lib/libpng16_static.lib" \
	"$(tiff_PREFIX)/lib/libtiff.lib" \
	"$(jpeg_PREFIX)/lib/turbojpeg-static.lib" \
	"$(openexr_PREFIX)/lib/IlmImf-2_2.lib" \
	"$(openexr_PREFIX)/lib/Imath-2_2.lib" \
	"$(openexr_PREFIX)/lib/Iex-2_2.lib" \
	"$(openexr_PREFIX)/lib/Half.lib" \
	"$(openexr_PREFIX)/lib/IlmThread-2_2.lib" \
	"$(ptex_PREFIX)/lib/Ptex.lib" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_python$(DYNAMIC_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_filesystem$(DYNAMIC_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_regex$(DYNAMIC_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_system$(DYNAMIC_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_thread$(DYNAMIC_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_chrono$(DYNAMIC_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_date_time$(DYNAMIC_EXT)" \
	"$(boost_PREFIX)/lib/$(BOOST_LIB_PREFIX)$(BOOST_NAMESPACE)_atomic$(DYNAMIC_EXT)" \
	"$(zlib_PREFIX)/lib/zlib.lib"

TBB_LIBRARY := "$(tbb_PREFIX)/lib"
TBB_ROOT_DIR := "$(tbb_PREFIX)/include"
MAYA_ROOT := "C:/Program Files/Autodesk/Maya2016"

$(usd_VERSION_FILE) : $(boost_VERSION_FILE) $(embree_VERSION_FILE) $(cmake_VERSION_FILE) $(ilmbase_VERSION_FILE) $(oiio_VERSION_FILE) $(openexr_VERSION_FILE) $(opensubd_VERSION_FILE) $(ptex_VERSION_FILE) $(tbb_VERSION_FILE) $(usd_FILE)/HEAD
	@echo Building usd $(usd_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(usd_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(usd_FILE))" $(notdir $(basename $(usd_FILE))) && \
	cd $(notdir $(basename $(usd_FILE))) && \
	git checkout -q $(usd_VERSION) && \
	echo Patching for supporting static OIIO... && \
	( for f in $(OIIO_LIBS); do ( printf "\044a\nlist(APPEND OIIO_LIBRARIES \"$$f\")\n.\nw\nq" | ed -s cmake/modules/FindOpenImageIO.cmake ); done ) && \
	( printf "/find_library.*OPENEXR_.*_LIBRARY/a\nNAMES\n\044{OPENEXR_LIB}-2_2\n.\nw\nq" | ed -s cmake/modules/FindOpenEXR.cmake ) && \
	( printf "/HDF5 REQUIRED/+\nd\nd\nd\nw\nq" | ed -s cmake/defaults/Packages.cmake ) && \
	( printf "/BOOST_ALL_DYN_LINK/d\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	( printf "/OPENEXR_DLL/d\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	echo Patching for supporting MSVC2017... && \
	( printf "/glew32s/s/glew32s/libglew32/\nw\nq" | ed -s cmake/modules/FindGLEW.cmake ) && \
	( printf "/Zc:rvalueCast/d\nd\nd\na\nset(_PXR_CXX_FLAGS \"\044{_PXR_CXX_FLAGS} /Zc:rvalueCast /Zc:strictStrings /Zc:inline\")\n.\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	echo Patching for Maya 2016 support... && \
	( printf "/Program Files.*Maya2017/d\nw\nq" | ed -s cmake/modules/FindMaya.cmake ) && \
	( printf "/find_package_handle_standard_args/\n/MAYA_EXECUTABLE/d\nw\nq" | ed -s cmake/modules/FindMaya.cmake ) && \
	echo Cant irnore Unresolved_external_symbol_error_is_expected_Please_ignore because it always fails... && \
	( printf "/Unresolved_external_symbol_error_is_expected_Please_ignore/d\ni\nint Unresolved_external_symbol_error_is_expected_Please_ignore()\n{return 0;}\n.\nw\nq" | ed -s pxr/base/lib/plug/testenv/TestPlugDsoUnloadable.cpp ) && \
	( test ! $(USE_STATIC_BOOST) == ON || echo Dont skip plugins when building static libraries... ) && \
	( test ! $(USE_STATIC_BOOST) == ON || printf "/Skipping plugin/\nd\nd\na\nset(args_TYPE \"STATIC\")\n.\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	( test ! $(USE_STATIC_BOOST) == ON || printf "/CMAKE_SHARED_LIBRARY_SUFFIX/s/CMAKE_SHARED_LIBRARY_SUFFIX/CMAKE_STATIC_LIBRARY_SUFFIX/\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	echo Set Catmull-Clark as default subdivision scheme for all the alembics. It's temporary, while Hydra doesn't consider normals... && \
	( printf "/UsdGeomTokens->subdivisionScheme/+2\ns/none/catmullClark/\nw\nq" | ed -s pxr/usd/plugin/usdAbc/alembicReader.cpp ) && \
	echo Skip extra stuff because it fails... && \
	( printf "/add_subdirectory(extras)/d\nw\n" | ed -s CMakeLists.txt ) && \
	echo Fixed WHOLEARCHIVE bug in Visual Studio 15.4... && \
	( printf "/TARGET_FILE:usd_m/s/<.*>/{USD_M_TARGET}/\nw\n" | ed -s cmake/macros/Public.cmake ) && \
	( printf "/MSVC/a\nset(USD_M_TARGET pxr\\\\\\\\usd_m.lib)\n.\nw\n" | ed -s cmake/macros/Public.cmake ) && \
	mkdir -p build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DALEMBIC_DIR="$(alembic_PREFIX)" \
		-DBOOST_ROOT:PATH="$(boost_PREFIX)" \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DCMAKE_INSTALL_PREFIX="$(usd_PREFIX)" \
		-DEMBREE_LOCATION:PATH="$(embree_PREFIX)" \
		-DGLEW_LOCATION:PATH="$(glew_PREFIX)" \
		-DHDF5_ROOT="$(hdf5_PREFIX)" \
		-DMAYA_LOCATION:PATH=$(MAYA_ROOT) \
		-DOIIO_LOCATION:PATH="$(oiio_PREFIX)" \
		-DOPENEXR_BASE_DIR:PATH="$(ilmbase_PREFIX)" \
		-DOPENEXR_LOCATION:PATH="$(openexr_PREFIX)" \
		-DOPENSUBDIV_ROOT_DIR:PATH="$(opensubd_PREFIX)" \
		-DPTEX_LOCATION:PATH="$(ptex_PREFIX)" \
		-DPXR_BUILD_ALEMBIC_PLUGIN:BOOL=OFF \
		-DPXR_BUILD_EMBREE_PLUGIN:BOOL=$(BUILD_USD_MAYA_PLUGIN) \
		-DPXR_BUILD_IMAGING:BOOL=ON \
		-DPXR_BUILD_MAYA_PLUGIN:BOOL=$(BUILD_USD_MAYA_PLUGIN) \
		-DPXR_BUILD_MONOLITHIC:BOOL=$(BUILD_USD_MAYA_PLUGIN) \
		-DPXR_BUILD_TESTS:BOOL=OFF \
		-DPXR_BUILD_USD_IMAGING:BOOL=ON \
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
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_usd.txt 2>&1 && \
	( test ! $(USE_STATIC_BOOST) == OFF || echo Including boost shared libraries... ) && \
	( test ! $(USE_STATIC_BOOST) == OFF || cmd /C copy $(subst /,\\,$(boost_PREFIX)/lib/*.dll) $(subst /,\\,$(usd_PREFIX)/lib) ) && \
	cd $(THIS_DIR) && \
	echo $(usd_VERSION) > $@

# libz
$(zlib_VERSION_FILE) : $(zlib_FILE)/HEAD
	@echo Building zlib $(zlib_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(zlib_FILE))) && \
	git clone -q --no-checkout "$(WINDOWS_SOURCES_ROOT)/$(notdir $(zlib_FILE))" $(notdir $(basename $(zlib_FILE))) && \
	cd $(notdir $(basename $(zlib_FILE))) && \
	git checkout -q $(zlib_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	env -u MAKE -u MAKEFLAGS nmake -f win32/Makefile.msc all > $(ABSOLUTE_PREFIX_ROOT)/log_zlib.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/zlib/include && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/zlib/lib && \
	cp *.h $(ABSOLUTE_PREFIX_ROOT)/zlib/include && \
	cp zlib.lib $(ABSOLUTE_PREFIX_ROOT)/zlib/lib && \
	cd $(THIS_DIR) && \
	echo $(zlib_VERSION) > $@

