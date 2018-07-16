# handling vagrant
WORK_DIR=work

makfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))

PWD := $(shell pwd )

VM_NAME := $(shell pwd | sed 's@.*/@@')

CHDIR_SHELL := $(SHELL)
define chdir
   $(eval _D=$(firstword $(1) $(@D)))
   $(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D) $(CHDIR_SHELL))
endef

create_work_dir:
	mkdir -p $(PWD)/$(WORK_DIR)

up:
	$(info VM_NAME = $(VM_NAME))
	cd $(PWD)/$(WORK_DIR) && VM_NAME=$(VM_NAME) vagrant up
	cd $(PWD)

halt:
	$(call chdir,$(PWD)/$(WORK_DIR)) vagrant halt
	cd $(PWD)

copy_files:
	$(call chdir,$(PWD)/$(WORK_DIR))
	cp ../../vagrant/Vagrantfile ../work
	cp ../../vagrant/found-bridge-adapter.sh ../work
	cp ../../vagrant/install_VBoxGuestAdditions_debian_based_linux.sh ../work
	cp ../install-squid3-debian.sh ../work
	cd $(PWD)

init: create_work_dir init_vagrant copy_files

init_vagrant:
	cd $(PWD)/$(WORK_DIR) && vagrant init
	cd $(PWD)

destroy: clean_vagrant

clean_vagrant:
	if [ -d "$(PWD)/$(WORK_DIR)/.vagrant)" ]; then \
        cd $(PWD)/$(WORK_DIR) && vagrant destroy -f ; \
	else \
		echo "vagrant was not running"; \
		echo "run => make init"; \
    fi
	cd $(PWD)

clean_work_dir:
	if [ -d "$(PWD)/$(WORK_DIR)" ]; then \
        echo "clean_work_dir: WORK_DIR exists => delete"; \
		cd $(PWD) && rm -rf ./work; \
	else \
		echo "Directory not avaible => $(PWD)/$(WORK_DIR)"; \
    fi

clean: clean_vagrant clean_work_dir
	cd $(PWD)
