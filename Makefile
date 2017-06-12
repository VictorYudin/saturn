
SOURCES_ROOT=./src
BUILD_ROOT=./build
PREFIX_ROOT=./lib

ABSOLUTE_SOURCES_ROOT := $(realpath $(SOURCES_ROOT))
ABSOLUTE_BUILD_ROOT := $(realpath $(BUILD_ROOT))
ABSOLUTE_PREFIX_ROOT := $(realpath $(PREFIX_ROOT))

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

define GIT_DOWNLOAD =
$(1)_VERSION := $(2)
$(1)_VERSION_FILE := $(ABSOLUTE_PREFIX_ROOT)/built_$(1)
$(1)_SOURCE := $(3)
$(1)_FILE := $(ABSOLUTE_SOURCES_ROOT)/$$(notdir $$($(1)_SOURCE))
$(1): $$($(1)_VERSION_FILE)

$$($(1)_FILE)/HEAD :
	mkdir -p $(ABSOLUTE_SOURCES_ROOT) && \
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
$(eval $(call CURL_DOWNLOAD,ilmbase,2.2.0,http://download.savannah.nongnu.org/releases/openexr/ilmbase-$$(ilmbase_VERSION).tar.gz))
$(eval $(call CURL_DOWNLOAD,openexr,2.2.0,http://download.savannah.nongnu.org/releases/openexr/openexr-$$(openexr_VERSION).tar.gz))
$(eval $(call GIT_DOWNLOAD,zlib,v1.2.8,git://github.com/madler/zlib.git))

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

COMMON_CMAKE_FLAGS :=\
	-DCMAKE_BUILD_TYPE:STRING=$(CMAKE_BUILD_TYPE) \
	-DCMAKE_CXX_FLAGS_DEBUG=/MTd \
	-DCMAKE_CXX_FLAGS_RELEASE=/MT \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON

PYTHON_BIN := c:/Python27/python.exe
PYTHON_VERSION_SHORT := 2.7
PYTHON_ROOT := $(dir $(PYTHON_BIN))

ifeq "$(BOOST_VERSION)" "1_55_0"
BOOST_USERCONFIG := tools/build/v2/user-config.jam
else
BOOST_USERCONFIG := tools/build/src/user-config.jam
endif
BOOST_LINK := static
ifeq "$(BOOST_LINK)" "shared"
USE_STATIC_BOOST := OFF
else
USE_STATIC_BOOST := ON
endif
$(boost_VERSION_FILE) : $(boost_FILE)
	@echo Building boost $(boost_VERSION) && \
	mkdir -p $(ABSOLUTE_BUILD_ROOT) && cd $(BUILD_ROOT) && \
	echo rm -rf boost_$(boost_VERSION) && \
	echo tar -xf $(ABSOLUTE_SOURCES_ROOT)/boost_$(boost_VERSION).tar.gz && \
	cd boost_$(boost_VERSION) && \
	mkdir -p $(ABSOLUTE_PREFIX_ROOT) && \
	echo 'using msvc : 14.1 : "$(CXX)" ;' > $(BOOST_USERCONFIG) && \
	echo 'using python : $(PYTHON_VERSION_SHORT) : "$(PYTHON_BIN)" : "$(PYTHON_ROOT)/include" : "$(PYTHON_ROOT)/libs" ;' >> $(BOOST_USERCONFIG) && \
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
		-DCMAKE_INSTALL_PREFIX=`cygpath -w $(ABSOLUTE_PREFIX_ROOT)/openexr` \
		-DILMBASE_PACKAGE_PREFIX:PATH=`cygpath -w $(ABSOLUTE_PREFIX_ROOT)/ilmbase` \
		-DNAMESPACE_VERSIONING:BOOL=ON \
		-DZLIB_ROOT:PATH=`cygpath -w $(ABSOLUTE_PREFIX_ROOT)/zlib` \
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

