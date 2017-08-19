
SOURCES_ROOT=./src
BUILD_ROOT=./build
PREFIX_ROOT=./lib

ABSOLUTE_SOURCES_ROOT := $(realpath $(SOURCES_ROOT))
ABSOLUTE_BUILD_ROOT := $(realpath $(BUILD_ROOT))
ABSOLUTE_PREFIX_ROOT := $(realpath $(PREFIX_ROOT))
WINDOWS_SOURCES_ROOT := `cygpath -w $(ABSOLUTE_SOURCES_ROOT)`
WINDOWS_BUILD_ROOT := `cygpath -w $(ABSOLUTE_BUILD_ROOT)`
WINDOWS_PREFIX_ROOT := `cygpath -w $(ABSOLUTE_PREFIX_ROOT)`

ifeq "$(MAKE_MODE)" ""
MAKE_MODE := release
endif

ifeq "$(MAKE_MODE)" "debug"
CMAKE_BUILD_TYPE := Debug
else
CMAKE_BUILD_TYPE := Release
endif

# Save the current directory
THIS_DIR := $(shell pwd)
WINDOWS_THIS_DIR := `cygpath -w $(THIS_DIR)`

define GIT_DOWNLOAD =
$(1)_VERSION := $(2)
$(1)_VERSION_FILE := $(ABSOLUTE_PREFIX_ROOT)/built_$(1)
$(1)_SOURCE := $(3)
$(1)_FILE := $(ABSOLUTE_SOURCES_ROOT)/$$(notdir $$($(1)_SOURCE))
$(1): $$($(1)_VERSION_FILE)

$$($(1)_FILE)/HEAD :
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	git clone -q --bare $$($(1)_SOURCE) `cygpath -w $$($(1)_FILE)`
endef

define CURL_DOWNLOAD =
$(1)_VERSION := $(2)
$(1)_VERSION_FILE := $(ABSOLUTE_PREFIX_ROOT)/built_$(1)
$(1)_SOURCE := $(3)
$(1)_FILE := $(ABSOLUTE_SOURCES_ROOT)/$$(notdir $$($(1)_SOURCE))
$(1): $$($(1)_VERSION_FILE)

$$($(1)_FILE) :
	@mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
	echo Downloading $$($(1)_FILE)... && \
	curl -s -o $$@ -L $$($(1)_SOURCE)
endef

$(eval $(call CURL_DOWNLOAD,boost,1_61_0,http://sourceforge.net/projects/boost/files/boost/$$(subst _,.,$$(boost_VERSION))/boost_$$(boost_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,cmake,3.7.2,https://cmake.org/files/v$$(word 1,$$(subst ., ,$$(cmake_VERSION))).$$(word 2,$$(subst ., ,$$(cmake_VERSION)))/cmake-$$(cmake_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,cmakebin,3.7.2,https://cmake.org/files/v$$(word 1,$$(subst ., ,$$(cmakebin_VERSION))).$$(word 2,$$(subst ., ,$$(cmakebin_VERSION)))/cmake-$$(cmakebin_VERSION)-win64-x64.zip))
$(eval $(call CURL_DOWNLOAD,glew,2.0.0,https://sourceforge.net/projects/glew/files/glew/$$(glew_VERSION)/glew-$$(glew_VERSION).tgz))
$(eval $(call CURL_DOWNLOAD,glut,3.0.0,https://sourceforge.net/projects/freeglut/files/freeglut/$$(glut_VERSION)/freeglut-$$(glut_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,hdf5,1.8.10,https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$$(hdf5_VERSION)/src/hdf5-$$(hdf5_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,ilmbase,2.2.0,http://download.savannah.nongnu.org/releases/openexr/ilmbase-$$(ilmbase_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,openexr,2.2.0,http://download.savannah.nongnu.org/releases/openexr/openexr-$$(openexr_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,tbb,2017_20161128oss,https://www.threadingbuildingblocks.org/sites/default/files/software_releases/source/tbb$$(tbb_VERSION)_src.tgz))
$(eval $(call CURL_DOWNLOAD,tiff,3.8.2,http://dl.maptools.org/dl/libtiff/tiff-$$(tiff_VERSION).tar.gz))
$(eval $(call GIT_DOWNLOAD,alembic,1.7.1,git://github.com/alembic/alembic.git))
$(eval $(call GIT_DOWNLOAD,glfw,3.2.1,git://github.com/glfw/glfw.git))
$(eval $(call GIT_DOWNLOAD,jpeg,1.5.1,git://github.com/libjpeg-turbo/libjpeg-turbo.git))
$(eval $(call GIT_DOWNLOAD,jsoncpp,1.8.0,git://github.com/open-source-parsers/jsoncpp.git))
$(eval $(call GIT_DOWNLOAD,oiio,Release-1.7.14,git://github.com/OpenImageIO/oiio.git))
$(eval $(call GIT_DOWNLOAD,opensubd,v3_2_0,git://github.com/PixarAnimationStudios/OpenSubdiv.git))
$(eval $(call GIT_DOWNLOAD,png,2b667e4,git://git.code.sf.net/p/libpng/code))
$(eval $(call GIT_DOWNLOAD,ptex,v2.1.28,git://github.com/wdas/ptex.git))
$(eval $(call GIT_DOWNLOAD,usd,v0.7.6,git://github.com/PixarAnimationStudios/USD))
$(eval $(call GIT_DOWNLOAD,zlib,v1.2.8,git://github.com/madler/zlib.git))
$(eval $(call GIT_DOWNLOAD,embree,v2.16.4,git://github.com/madler/embree.git))

# Number or processors
ifeq "$(OS)" "Darwin"
JOB_COUNT := $(shell sysctl -n machdep.cpu.thread_count)
endif
ifeq "$(OS)" "linux"
JOB_COUNT := $(shell cat /sys/devices/system/cpu/cpu*/topology/thread_siblings | wc -l)
endif
ifeq "$(OS)" "Windows_NT"
JOB_COUNT := $(shell cat /proc/cpuinfo | grep processor | wc -l)
endif

CC := $(shell where cl)
CXX := $(shell where cl)
CMAKE := C:/Temp/saturn-build/lib/cmake/bin/cmake

BOOST_LINK := static
ifeq "$(BOOST_LINK)" "shared"
USE_STATIC_BOOST := OFF
BUILD_MAYA_PLUGIN := ON
else
USE_STATIC_BOOST := ON
BUILD_MAYA_PLUGIN := OFF
endif

DEFINES = /DBOOST_ALL_NO_LIB /DPTEX_STATIC

ifeq "$(BOOST_LINK)" "shared"
DEFINES += /DBOOST_ALL_DYN_LINK
else
DEFINES += /DBOOST_ALL_STATIC_LINK
DEFINES += /DBOOST_PYTHON_STATIC_LIB
endif

COMMON_CMAKE_FLAGS :=\
	-G "Visual Studio 15 2017 Win64" \
	-DCMAKE_BUILD_TYPE:STRING=$(CMAKE_BUILD_TYPE) \
	-DCMAKE_CXX_FLAGS_DEBUG="/MTd $(DEFINES)" \
	-DCMAKE_CXX_FLAGS_RELEASE="/MT $(DEFINES)" \
	-DCMAKE_C_FLAGS_DEBUG="/MTd $(DEFINES)" \
	-DCMAKE_C_FLAGS_RELEASE="/MT $(DEFINES)" \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON

all: usd

ifeq "$(BOOST_LINK)" "shared"
PYTHON_BIN := "C:\Program Files\Autodesk\Maya2016\bin\mayapy.exe"
else
PYTHON_BIN := C:/Python27/python.exe
endif
PYTHON_VERSION_SHORT := 2.7
PYTHON_ROOT := $(dir $(PYTHON_BIN))

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
	echo 'using python : $(PYTHON_VERSION_SHORT) : "$(PYTHON_BIN)" : "$(PYTHON_ROOT)/include" : "$(PYTHON_ROOT)/libs" ;' >> $(BOOST_USERCONFIG) && \
	( printf '/handle-static-runtime/\n/EXIT/d\nw\nq' | ed -s Jamroot ) && \
	cmd /C bootstrap.bat msvc && \
	./b2 \
		--layout=system \
		--prefix=`cygpath -w $(ABSOLUTE_PREFIX_ROOT)/boost` \
		-j $(JOB_COUNT) \
		link=$(BOOST_LINK) \
		threading=multi \
		runtime-link=static \
		address-model=64 \
		toolset=msvc-14.1 \
		$(MAKE_MODE) \
		stage \
		install && \
	cd .. && \
	rm -rf boost_$(boost_VERSION) && \
	cd $(THIS_DIR) && \
	echo $(BOOST_VERSION) > $@

$(alembic_VERSION_FILE) : $(boost_VERSION_FILE) $(CMAKE) $(hdf5_VERSION_FILE) $(ilmbase_VERSION_FILE) $(openexr_VERSION_FILE) $(zlib_VERSION_FILE) $(alembic_FILE)/HEAD
	@echo Building Alembic $(alembic_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf alembic && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/alembic.git alembic && \
	cd alembic && \
	git checkout -q $(alembic_VERSION) && \
	( printf '/Werror/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf "/INSTALL/a\nFoundation.h\n.\nw\nq" | ed -s lib/Alembic/AbcCoreLayer/CMakeLists.txt ) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DHDF5_ROOT=$(WINDOWS_PREFIX_ROOT)/hdf5 \
		-DALEMBIC_ILMBASE_LINK_STATIC:BOOL=ON \
		-DALEMBIC_LIB_USES_BOOST:BOOL=ON \
		-DALEMBIC_SHARED_LIBS:BOOL=OFF \
		-DBOOST_ROOT:STRING=$(WINDOWS_PREFIX_ROOT)/boost \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/alembic \
		-DILMBASE_ROOT=$(WINDOWS_PREFIX_ROOT)/ilmbase \
		-DUSE_BOOSTREGEX:BOOL=ON \
		-DUSE_HDF5:BOOL=ON \
		-DUSE_MAYA:BOOL=OFF \
		-DUSE_STATIC_BOOST:BOOL=$(USE_STATIC_BOOST) \
		-DUSE_STATIC_HDF5:BOOL=ON \
		-DUSE_TESTS:BOOL=OFF \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_alembic.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_alembic.txt 2>&1 && \
	cd .. && \
	rm -rf alembic && \
	cd $(THIS_DIR) && \
	echo $(alembic_VERSION) > $@

$(cmake_VERSION_FILE) : $(cmake_FILE) $(cmakebin_FILE)
	echo Unpacking cmake $(cmake_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	echo rm -rf cmake-$(cmake_VERSION) && \
	echo rm -rf cmake-$(cmakebin_VERSION)-win64-x64 && \
	echo tar -xf $(ABSOLUTE_SOURCES_ROOT)/cmake-$(cmake_VERSION).tar.gz && \
	echo Unpacking cmake-bin $(cmakebin_VERSION) && \
	echo unzip $(ABSOLUTE_SOURCES_ROOT)/cmake-$(cmakebin_VERSION)-win64-x64.zip && \
	echo Building cmake $(cmake_VERSION) && \
	cd cmake-$(cmake_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(ABSOLUTE_BUILD_ROOT)/cmake-$(cmakebin_VERSION)-win64-x64/bin/cmake \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX=`cygpath -w $(ABSOLUTE_PREFIX_ROOT)/cmake` \
		. && \
	$(ABSOLUTE_BUILD_ROOT)/cmake-$(cmakebin_VERSION)-win64-x64/bin/cmake \
		--build . \
		--target install \
		--config Release && \
	echo done

#embree 
$(embree_VERSION_FILE) : $(CMAKE) $(zlib_VERSION_FILE) $(embree_FILE)/HEAD
	@echo Building embree $(embree_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf embree && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/embree.git embree && \
	cd embree && \
	git checkout -q $(embree_VERSION) && \
	( printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_INCLUDE_DIR $(WINDOWS_PREFIX_ROOT)/tbb/include)\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_LIBRARY $(WINDOWS_PREFIX_ROOT)/tbb/lib/tbb.lib)\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/FIND_PACKAGE_HANDLE_STANDARD_ARGS/-\na\nSET(TBB_LIBRARY_MALLOC $(WINDOWS_PREFIX_ROOT)/tbb/lib/tbbmalloc.lib)\n.\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/INSTALL(PROGRAMS/d\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	( printf '/INSTALL(PROGRAMS/d\nw\nq\n' | ed -s common/cmake/FindTBB.cmake ) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DEMBREE_STATIC_LIB:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/embree \
		-DTBB_INCLUDE_DIR=$(WINDOWS_PREFIX_ROOT)/tbb/include \
		-DTBB_LIBRARY=$(WINDOWS_PREFIX_ROOT)/tbb/lib/tbb.lib \
		-DTBB_LIBRARY_MALLOC=$(WINDOWS_PREFIX_ROOT)/tbb/lib/tbbmalloc.lib \
		. && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) && \
	cd .. && \
	rm -rf embree && \
	cd $(THIS_DIR) && \
	echo $(embree_VERSION) > $@

# glew
# Edits:
# - define GLEW_STATIC
# link glewinfo and visualinfo statically
$(glew_VERSION_FILE) : $(CMAKE) $(glew_FILE)
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
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/glew \
		./cmake > $(ABSOLUTE_PREFIX_ROOT)/log_glew.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_glew.txt 2>&1 && \
	cd ../.. && \
	rm -rf $(notdir $(basename $(glew_FILE))) && \
	cd $(THIS_DIR) && \
	echo $(glew_VERSION) > $@


# glfw
$(glfw_VERSION_FILE) : $(CMAKE) $(glfw_FILE)/HEAD
	@echo Building glfw $(glfw_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(glfw_FILE))) && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/$(notdir $(glfw_FILE)) $(notdir $(basename $(glfw_FILE))) && \
	cd $(notdir $(basename $(glfw_FILE))) && \
	git checkout -q $(glfw_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DGLFW_BUILD_DOCS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/glfw \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_glfw.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_glfw.txt 2>&1 && \
	cd .. && \
	rm -rf $(notdir $(basename $(glfw_FILE))) && \
	cd $(THIS_DIR) && \
	echo $(glfw_VERSION) > $@


# glut
$(glut_VERSION_FILE) : $(CMAKE) $(glut_FILE)
	@echo Building glut $(glut_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(basename $(glut_FILE)))) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(glut_FILE)) && \
	cd $(notdir $(basename $(basename $(glut_FILE)))) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/glut \
		-DFREEGLUT_BUILD_DEMOS:BOOL=OFF \
		-DFREEGLUT_BUILD_SHARED_LIBS:BOOL=OFF \
		-DINSTALL_PDB:BOOL=ON \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_glut.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_glut.txt 2>&1 && \
	cd .. && \
	rm -rf $(notdir $(basename $(basename $(glut_FILE)))) && \
	cd $(THIS_DIR) && \
	echo $(glut_VERSION) > $@


# HDF5
$(hdf5_VERSION_FILE) : $(CMAKE) $(zlib_VERSION_FILE) $(hdf5_FILE)
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
	mkdir build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/hdf5 \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		-DZLIB_USE_EXTERNAL:BOOL=ON \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_hdf5.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_hdf5.txt 2>&1 && \
	cd ../.. && \
	rm -rf hdf5-$(hdf5_VERSION) && \
	cd $(THIS_DIR) && \
	echo $(hdf5_VERSION) > $@

# jpeg
$(jpeg_VERSION_FILE) : $(CMAKE) $(jpeg_FILE)/HEAD
	@echo Building jpeg $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf jpeg && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/libjpeg-turbo.git jpeg && \
	cd jpeg && \
	git checkout -q $(jpeg_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-G "NMake Makefiles" \
		-DENABLE_SHARED:BOOL=OFF \
		-DENABLE_STATIC:BOOL=ON \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/jpeg \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_jpeg.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_jpeg.txt 2>&1 && \
	cd .. && \
	rm -rf jpeg && \
	cd $(THIS_DIR) && \
	echo $(jpeg_VERSION) > $@


# jsoncpp
$(jsoncpp_VERSION_FILE) : $(CMAKE) $(zlib_VERSION_FILE) $(jsoncpp_FILE)/HEAD
	@echo Building jsoncpp $(jsoncpp_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf jsoncpp && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/jsoncpp.git jsoncpp && \
	cd jsoncpp && \
	git checkout -q $(jsoncpp_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/jsoncpp \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_jsoncpp.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_jsoncpp.txt 2>&1 && \
	cd .. && \
	rm -rf jsoncpp && \
	cd $(THIS_DIR) && \
	echo $(jsoncpp_VERSION) > $@

$(ilmbase_VERSION_FILE) : $(CMAKE) $(ilmbase_FILE)
	@echo Building IlmBase $(ilmbase_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf ilmbase-$(ilmbase_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/ilmbase-$(ilmbase_VERSION).tar.gz && \
	cd ilmbase-$(ilmbase_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX=`cygpath -w $(ABSOLUTE_PREFIX_ROOT)/ilmbase` \
		-DNAMESPACE_VERSIONING:BOOL=ON \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_ilmbase.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_ilmbase.txt 2>&1 && \
	cd .. && \
	rm -rf ilmbase-$(ilmbase_VERSION) && \
	cd $(THIS_DIR) && \
	echo $(ilmbase_VERSION) > $@


# OpenImageIO
# Edits:
# - Defining OIIO_STATIC_BUILD to avoid specifying it everywhere
# - std::locale segfault fix
# - Python module
$(oiio_VERSION_FILE) : $(boost_VERSION_FILE) $(CMAKE) $(ilmbase_VERSION_FILE) $(jpeg_VERSION_FILE) $(openexr_VERSION_FILE) $(png_VERSION_FILE) $(tiff_VERSION_FILE) $(zlib_VERSION_FILE) $(oiio_FILE)/HEAD
	@echo Building OpenImageIO $(oiio_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf oiio && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/oiio.git oiio && \
	cd oiio && \
	git checkout -q $(oiio_VERSION) && \
	( printf '/define OPENIMAGEIO_EXPORT_H/a\n#ifndef OIIO_STATIC_BUILD\n#define OIIO_STATIC_BUILD\n#endif\n.\nw\n' | ed -s src/include/OpenImageIO/export.h ) && \
	( printf '/boost::algorithm::iequals/s/loc/std::locale::classic()/\nw\nq' | ed -s src/libutil/strutil.cpp ) && \
	( printf '/USE_PYTHON OFF/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf '/Boost_USE_STATIC_LIBS/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf '/Boost_USE_STATIC_LIBS/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf '/Boost_USE_STATIC_LIBS/d\nw\nq' | ed -s src/cmake/externalpackages.cmake ) && \
	( printf '/CMAKE_FIND_LIBRARY_SUFFIXES .a/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf '/CMAKE_FIND_LIBRARY_SUFFIXES .a/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf '/libturbojpeg/s/libturbojpeg/turbojpeg-static/\nw\nq' | ed -s src/cmake/modules/FindJPEGTurbo.cmake ) && \
	( printf '/OPENEXR_DLL/d\nw\nq' | ed -s CMakeLists.txt ) && \
	( printf '/\/W1/d\nw\nq' | ed -s CMakeLists.txt ) && \
	mkdir build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBOOST_ROOT=$(WINDOWS_PREFIX_ROOT)/boost \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DBUILDSTATIC:BOOL=ON \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/oiio \
		-DILMBASE_HOME=$(WINDOWS_PREFIX_ROOT)/ilmbase \
		-DJPEG_PATH=$(WINDOWS_PREFIX_ROOT)/jpeg \
		-DLINKSTATIC:BOOL=ON \
		-DOIIO_BUILD_TESTS:BOOL=OFF \
		-DOPENEXR_HOME=$(WINDOWS_PREFIX_ROOT)/openexr \
		-DPNG_LIBRARY=$(WINDOWS_PREFIX_ROOT)/png/lib/libpng16_static.lib \
		-DPNG_PNG_INCLUDE_DIR=$(WINDOWS_PREFIX_ROOT)/png/include \
		-DTIFF_INCLUDE_DIR=$(WINDOWS_PREFIX_ROOT)/tiff/include \
		-DTIFF_LIBRARY=$(WINDOWS_PREFIX_ROOT)/tiff/lib/libtiff.lib \
		-DUSE_FREETYPE:BOOL=OFF \
		-DUSE_GIF:BOOL=OFF \
		-DVERBOSE:BOOL=ON \
		-DUSE_NUKE=OFF \
		-DZLIB_ROOT=$(WINDOWS_PREFIX_ROOT)/zlib \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_oiio.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_oiio.txt 2>&1 && \
	cd ../.. && \
	rm -rf oiio && \
	cd $(THIS_DIR) && \
	echo $(oiio_VERSION) > $@


$(openexr_VERSION_FILE) : $(CMAKE) $(ilmbase_VERSION_FILE) $(zlib_VERSION_FILE) $(openexr_FILE)
	@echo Building OpenEXR $(openexr_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf openexr-$(openexr_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/openexr-$(openexr_VERSION).tar.gz && \
	cd openexr-$(openexr_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/openexr \
		-DILMBASE_PACKAGE_PREFIX:PATH=$(WINDOWS_PREFIX_ROOT)/ilmbase \
		-DNAMESPACE_VERSIONING:BOOL=ON \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_openexr.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_openexr.txt 2>&1 && \
	cd .. && \
	rm -rf openexr-$(openexr_VERSION) && \
	cp $(ABSOLUTE_PREFIX_ROOT)/ilmbase/lib/*.lib $(ABSOLUTE_PREFIX_ROOT)/openexr/lib && \
	cd $(THIS_DIR) && \
	echo $(openexr_VERSION) > $@


# OpenSubdiv
$(opensubd_VERSION_FILE) : $(CMAKE) $(glew_VERSION_FILE) $(glfw_VERSION_FILE) $(ptex_VERSION_FILE) $(tbb_VERSION_FILE) $(zlib_VERSION_FILE) $(opensubd_FILE)/HEAD
	@echo Building OpenSubdiv $(opensubd_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(opensubd_FILE))) && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/$(notdir $(opensubd_FILE)) $(notdir $(basename $(opensubd_FILE))) && \
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
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/opensubdiv \
		-DGLFW_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/glfw \
		-DGLEW_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/glew \
		-DNO_GLTESTS:BOOL=ON \
		-DNO_TESTS:BOOL=ON \
		-DNO_TUTORIALS:BOOL=ON \
		-DMSVC_STATIC_CRT:BOOL=ON \
		-DPTEX_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/ptex \
		-DPYTHON_EXECUTABLE=$(PYTHON_BIN) \
		-DTBB_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/tbb \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		-DNO_OMP=1 \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_opensubdiv.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_opensubdiv.txt 2>&1 && \
	cd .. && \
	rm -rf $(notdir $(basename $(opensubd_FILE))) && \
	cd $(THIS_DIR) && \
	echo $(opensubd_VERSION) > $@


# png
$(png_VERSION_FILE) : $(CMAKE) $(zlib_VERSION_FILE) $(png_FILE)/HEAD
	@echo Building png $(png_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf png && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/code png && \
	cd png && \
	git checkout -q $(png_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DPNG_SHARED:BOOL=OFF \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/png \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_png.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_png.txt 2>&1 && \
	cd .. && \
	rm -rf png && \
	cd $(THIS_DIR) && \
	echo $(png_VERSION) > $@


# Ptex
$(ptex_VERSION_FILE) : $(CMAKE) $(ptex_FILE)/HEAD
	@echo Building Ptex $(ptex_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(ptex_FILE))) && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/$(notdir $(ptex_FILE)) $(notdir $(basename $(ptex_FILE))) && \
	cd $(notdir $(basename $(ptex_FILE))) && \
	git checkout -q $(ptex_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	( printf "2a\n#define PTEX_STATIC\n.\nw\nq\n" | ed -s src/ptex/Ptexture.h ) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/ptex \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		. > $(ABSOLUTE_PREFIX_ROOT)/log_ptex.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_ptex.txt 2>&1 && \
	cd .. && \
	rm $(ABSOLUTE_PREFIX_ROOT)/ptex/lib/*.dll && \
	rm -rf $(notdir $(basename $(ptex_FILE))) && \
	cd $(THIS_DIR) && \
	echo $(ptex_VERSION) > $@


# tbb
$(tbb_VERSION_FILE) : $(tbb_FILE)
	@echo Building tbb $(tbb_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf tbb$(tbb_VERSION) && \
	tar zxf $(ABSOLUTE_SOURCES_ROOT)/$(notdir $(tbb_FILE)) && \
	cd tbb$(tbb_VERSION) && \
	cmd /C msbuild build/vs2012/makefile.sln \
		/p:configuration=$(CMAKE_BUILD_TYPE)-MT \
		/p:platform=x64 \
		/p:PlatformToolset=v141 > $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tbb/include && \
	cp -R include/tbb $(ABSOLUTE_PREFIX_ROOT)/tbb/include && \
	cmd /C link /lib /machine:x64 /out:tbb.lib \
		build/vs2012/x64/tbb/$(CMAKE_BUILD_TYPE)-MT/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	cmd /C link /lib /machine:x64 /out:tbbmalloc.lib \
		build/vs2012/x64/tbbmalloc/$(CMAKE_BUILD_TYPE)-MT/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	cmd /C link /lib /machine:x64 /out:tbbmalloc_proxy.lib \
		build/vs2012/x64/tbbmalloc_proxy/$(CMAKE_BUILD_TYPE)-MT/*.obj >> $(ABSOLUTE_PREFIX_ROOT)/log_tbb.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tbb/lib && \
	cp *.lib $(ABSOLUTE_PREFIX_ROOT)/tbb/lib && \
	cd .. && \
	rm -rf tbb$(tbb_VERSION) && \
	cd $(THIS_DIR) && \
	echo $(tbb_VERSION) > $@


$(tiff_VERSION_FILE) : $(ZLIB_VERSION_FILE) $(tiff_FILE) $(jpeg_VERSION_FILE) $(zlib_VERSION_FILE)
	@echo Building tiff $(tiff_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf tiff-$(tiff_VERSION) && \
	tar -xf $(ABSOLUTE_SOURCES_ROOT)/tiff-$(tiff_VERSION).tar.gz && \
	cd tiff-$(tiff_VERSION) && \
	( printf '/OPTFLAGS/s/MD/MT/\nw\nq' | ed -s nmake.opt ) && \
	nmake /f Makefile.vc \
		JPEG_SUPPORT=1 \
		JPEG_INCLUDE=-I$(WINDOWS_PREFIX_ROOT)/jpeg/include \
		JPEG_LIB="$(WINDOWS_PREFIX_ROOT)/jpeg/lib/jpeg-static.lib $(WINDOWS_PREFIX_ROOT)/zlib/lib/z.lib" \
		ZLIB_SUPPORT=1 \
		ZLIB_INCLUDE=-I$(WINDOWS_PREFIX_ROOT)/zlib/include \
		ZLIB_LIB=$(WINDOWS_PREFIX_ROOT)/zlib/lib/z.lib > $(ABSOLUTE_PREFIX_ROOT)/log_tiff.txt 2>&1 && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tiff/bin && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tiff/include && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp tools/*.exe $(ABSOLUTE_PREFIX_ROOT)/tiff/bin && \
	cp libtiff/libtiff.lib $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp libtiff/libtiff.pdb $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp libtiff/libtiff.ilk $(ABSOLUTE_PREFIX_ROOT)/tiff/lib && \
	cp libtiff/*.h* $(ABSOLUTE_PREFIX_ROOT)/tiff/include && \
	cd .. && \
	rm -rf tiff-$(tiff_VERSION) && \
	cd $(THIS_DIR) && \
	echo $(openexr_VERSION) > $@

DYNAMIC_EXT := .lib
BOOST_NAMESPACE := boost
ifeq "$(BOOST_LINK)" "shared"
BOOST_PREFIX :=
else
BOOST_PREFIX := lib
endif
OIIO_LIBS := \
	C:/Temp/saturn-build/lib/png/lib/libpng16_static.lib \
	C:/Temp/saturn-build/lib/tiff/lib/libtiff.lib \
	C:/Temp/saturn-build/lib/jpeg/lib/turbojpeg-static.lib \
	C:/Temp/saturn-build/lib/openexr/lib/IlmImf-2_2.lib \
	C:/Temp/saturn-build/lib/openexr/lib/Imath-2_2.lib \
	C:/Temp/saturn-build/lib/openexr/lib/Iex-2_2.lib \
	C:/Temp/saturn-build/lib/openexr/lib/Half.lib \
	C:/Temp/saturn-build/lib/openexr/lib/IlmThread-2_2.lib \
	C:/Temp/saturn-build/lib/ptex/lib/Ptex.lib \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_python$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_filesystem$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_regex$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_system$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_thread$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_chrono$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_date_time$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/boost/lib/$(BOOST_PREFIX)$(BOOST_NAMESPACE)_atomic$(DYNAMIC_EXT) \
	C:/Temp/saturn-build/lib/zlib/lib/z.lib

TBB_LIBRARY := $(WINDOWS_PREFIX_ROOT)/tbb/lib
TBB_ROOT_DIR := $(WINDOWS_PREFIX_ROOT)/tbb/include
MAYA_ROOT := "C:/Program Files/Autodesk/Maya2016"

$(usd_VERSION_FILE) : $(alembic_VERSION_FILE) $(boost_VERSION_FILE) $(CMAKE) $(glut_VERSION_FILE) $(ilmbase_VERSION_FILE) $(oiio_VERSION_FILE) $(openexr_VERSION_FILE) $(opensubd_VERSION_FILE) $(ptex_VERSION_FILE) $(tbb_VERSION_FILE) $(usd_FILE)/HEAD
	@echo Building usd $(usd_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(ABSOLUTE_BUILD_ROOT) && \
	rm -rf $(notdir $(basename $(usd_FILE))) && \
	git clone -q --no-checkout $(WINDOWS_SOURCES_ROOT)/$(notdir $(usd_FILE)) $(notdir $(basename $(usd_FILE))) && \
	cd $(notdir $(basename $(usd_FILE))) && \
	git checkout -q $(usd_VERSION) && \
	( for f in $(OIIO_LIBS); do ( printf "\044a\nlist(APPEND OIIO_LIBRARIES $$f)\n.\nw\nq" | ed -s cmake/modules/FindOpenImageIO.cmake ); done ) && \
	( printf "/find_library.*OPENEXR_.*_LIBRARY/a\nNAMES\n\044{OPENEXR_LIB}-2_2\n.\nw\nq" | ed -s cmake/modules/FindOpenEXR.cmake ) && \
	( printf "/HDF5 REQUIRED/+\nd\nd\nd\nw\nq" | ed -s cmake/defaults/Packages.cmake ) && \
	( printf "/BOOST_ALL_DYN_LINK/d\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	( printf "/OPENEXR_DLL/d\nw\nq" | ed -s cmake/defaults/msvcdefaults.cmake ) && \
	( printf "/Program Files.*Maya2017/d\nw\nq" | ed -s cmake/modules/FindMaya.cmake ) && \
	( printf "/Unresolved_external_symbol_error_is_expected_Please_ignore/d\ni\nint Unresolved_external_symbol_error_is_expected_Please_ignore()\n{return 0;}\n.\nw\nq" | ed -s pxr/base/lib/plug/testenv/TestPlugDsoUnloadable.cpp ) && \
	( printf "/glew32s/s/glew32s/libglew32/\nw\nq" | ed -s cmake/modules/FindGLEW.cmake ) && \
	echo Dont skip plugins when building static libraries... && \
	( printf "/Skipping plugin/\nd\nd\na\nset(args_TYPE \"STATIC\")\n.\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	( printf "/CMAKE_SHARED_LIBRARY_SUFFIX/s/CMAKE_SHARED_LIBRARY_SUFFIX/CMAKE_STATIC_LIBRARY_SUFFIX/\nw\nq" | ed -s cmake/macros/Public.cmake ) && \
	echo ">>>" Catmull-Clark is default subdivision scheme for all the alembics. It's temporary, while Hydra doesn't consider normals... && \
	( printf "/UsdGeomTokens->subdivisionScheme/+2\ns/none/catmullClark/\nw\nq" | ed -s pxr/usd/plugin/usdAbc/alembicReader.cpp ) && \
	mkdir -p build && cd build && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	$(CMAKE) \
		$(COMMON_CMAKE_FLAGS) \
		-DALEMBIC_DIR=$(WINDOWS_PREFIX_ROOT)/alembic \
		-DBOOST_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/boost \
		-DBUILD_SHARED_LIBS:BOOL=OFF \
		-DBoost_USE_STATIC_LIBS:BOOL=$(USE_STATIC_BOOST) \
		-DCMAKE_INSTALL_PREFIX=$(WINDOWS_PREFIX_ROOT)/usd \
		-DGLEW_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/glew \
		-DGLFW_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/glfw \
		-DGLUT_Xmu_LIBRARY= \
		-DHDF5_ROOT=$(WINDOWS_PREFIX_ROOT)/hdf5 \
		-DMAYA_LOCATION:PATH=$(MAYA_ROOT) \
		-DPYSIDE_BIN_DIR:PATH=$(MAYA_ROOT)/bin \
		-DOIIO_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/oiio \
		-DOPENEXR_BASE_DIR:PATH=$(WINDOWS_PREFIX_ROOT)/ilmbase \
		-DOPENEXR_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/openexr \
		-DOPENSUBDIV_ROOT_DIR:PATH=$(WINDOWS_PREFIX_ROOT)/opensubdiv \
		-DPTEX_LOCATION:PATH=$(WINDOWS_PREFIX_ROOT)/ptex \
		-DPXR_BUILD_ALEMBIC_PLUGIN:BOOL=ON \
		-DPXR_BUILD_IMAGING:BOOL=ON \
		-DPXR_BUILD_MAYA_PLUGIN:BOOL=$(BUILD_MAYA_PLUGIN) \
		-DPXR_BUILD_MONOLITHIC:BOOL=$(BUILD_MAYA_PLUGIN) \
		-DPXR_BUILD_TESTS:BOOL=OFF \
		-DPXR_BUILD_USD_IMAGING:BOOL=ON \
		-DPYTHON_EXECUTABLE=$(PYTHON_BIN) \
		-DTBB_LIBRARY=$(TBB_LIBRARY) \
		-DTBB_ROOT_DIR=$(TBB_ROOT_DIR) \
		-DZLIB_ROOT:PATH=$(WINDOWS_PREFIX_ROOT)/zlib \
		-D_GLUT_INC_DIR:PATH=$(WINDOWS_PREFIX_ROOT)/glut/include \
		-D_GLUT_glut_LIB_DIR:PATH=$(WINDOWS_PREFIX_ROOT)/glut/lib \
		.. > $(ABSOLUTE_PREFIX_ROOT)/log_usd.txt 2>&1 && \
	$(CMAKE) \
		--build . \
		--target install \
		--config $(CMAKE_BUILD_TYPE) >> $(ABSOLUTE_PREFIX_ROOT)/log_usd.txt && \
	cd ../.. && \
	rm -rf $(notdir $(basename $(usd_FILE))) && \
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

