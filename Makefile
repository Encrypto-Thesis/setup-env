DC_CMD=@docker compose -f docker/docker-compose.yml
DC_EXEC=$(DC_CMD) exec dev
MK=@$(MAKE) --

define build_and_install
	$(DC_EXEC) mkdir -p $$HOME/build/$(1)
	$(DC_EXEC) cmake -S /workspace/$(1) -B $$HOME/build/$(1) -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release $(2)
	$(DC_EXEC) cmake --build $$HOME/build/$(1) --config Release
	$(DC_EXEC) sudo cmake --install $$HOME/build/$(1)
endef

default: help 

docker-down: 
	$(DC_CMD) down

docker-build: docker-down
	$(DC_CMD) build
	$(MK) --clean-build-from-host

docker-up:
	$(DC_CMD) up -d dev

init:
	@perl setup.pl
	$(MK) docker-build

shell: docker-up
	$(DC_EXEC) /bin/bash

ash: docker-up
	$(DC_EXEC) /bin/ash

build: docker-up
	$(call build_and_install,optional-lite,-DOPTIONAL_LITE_OPT_BUILD_TESTS=OFF -DOPTIONAL_LITE_OPT_BUILD_EXAMPLES=OFF)
	$(call build_and_install,span-lite,-DSPAN_LITE_OPT_BUILD_TESTS=OFF -DSPAN_LITE_OPT_BUILD_TESTS=OFF)
	$(call build_and_install,variant-lite,-DVARIANT_LITE_OPT_BUILD_TESTS=OFF -DVARIANT_LITE_OPT_BUILD_EXAMPLES=OFF)
	$(call build_and_install,function2,-DFU2_WITH_NO_DEATH_TESTS=OFF -DBUILD_TESTING=OFF)
	$(call build_and_install,macoro,-DMACORO_CPP_VER=17 -DMACORO_PIC=ON)
	$(call build_and_install,relic,-DCOLOR=ON -DVERBS=ON -DWITH=ALL -DMULTI=PTHREAD -DTESTS=0 -DBENCH=0 -DSEED=UDEV \
		-DARITH=easy -DCORES=8)
	$(call build_and_install,bitpolymul,-DBITPOLYMUL_PIC=ON)
	$(call build_and_install,libdivide,-DBUILD_TESTS=OFF -DBUILD_FUZZERS=OFF)
	$(call build_and_install,coproto,-DCOPROTO_CPP_VER=17 -DCOPROTO_PIC=ON -DCOPROTO_ENABLE_BOOST=ON -DCOPROTO_ENABLE_SPAN=ON -DCOPROTO_ENABLE_OPENSSL=ON -DCOPROTO_ENABLE_ASSERTS=ON)
	$(call build_and_install,libOTe,\
		-DENABLE_SILENTOT=ON -DENABLE_BITPOLYMUL=ON -DENABLE_ALL_OT=ON -DLIBOTE_CPP_VER=17 -DBUILD_TESTING=OFF \
		-DCOPROTO_ENABLE_BOOST=ON -DCOPROTO_ENABLE_OPENSSL=ON \
		-DENABLE_INSECURE_SILVER=ON -DLIBOTE_BUILD_TYPE=Release -DLIBOTE_BUILD_DIR=$$HOME/build/libOTe \
		-DENABLE_RELIC=ON -DENABLE_SODIUM=OFF -DENABLE_BOOST=ON -DENABLE_OPENSSL=ON -DENABLE_CIRCUITS=ON -DENABLE_PIC=ON \
		-DSODIUM_MONTGOMERY=false)
# $(MK) --build-libsodium

--clean-build-from-host:
	rm -rf build/*

clean: docker-up
	$(DC_EXEC) bash -c 'rm $$HOME/build/**/CMakeCache.txt'


--build-macoro:
	$(DC_EXEC) echo "Creating path $$HOME/build/macoro"
	$(DC_EXEC) mkdir -p $$HOME/build/macoro
	$(DC_EXEC) cmake -S /workspace/macoro -B $$HOME/build/macoro
	$(DC_EXEC) cd $$HOME/build/macoro
	
--build-libsodium:
	$(DC_EXEC)  mkdir -p $$HOME/build/libsodium
	$(DC_EXEC)  cp  /workspace/libsodium/configure  $$HOME/build/libsodium
	$(DC_EXEC)  bash -c 'cd $$HOME/build/libsodium && \
		./configure --srcdir=/workspace/libsodium && \
		make && sudo make install'

help:
	@echo "Targets:"
	@echo ""
	@echo "    docker-build"
	@echo "    docker-up"
	@echo "    shell" 
	@echo ""
	@echo "    "