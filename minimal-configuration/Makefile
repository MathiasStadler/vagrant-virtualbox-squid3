# handling vagrant
WORK_DIR=work

makfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))

PWD := $(shell pwd )

VM_NAME := $(shell pwd | sed 's@.*/@@')

CHDIR_SHELL := $(SHELL)
define chdir
   $(eval _D=$(firstword $(1) $(@D)))
   $(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

create_work_dir:
	$(info $(shell mkdir -p $(WORK_DIR)))

up:
	$(info VM_NAME = $(VM_NAME))
	$(call chdir,work) VM_NAME=$(VM_NAME) vagrant up
	cd $(PWD)

halt:
	$(call chdir,work) vagrant halt
	cd $(PWD)

copy_files:
	$(call chdir,work)
	cp ../../vagrant/Vagrantfile ../work
	cp ../../vagrant/found-bridge-adapter.sh ../work
	cp ../../vagrant/install_VBoxGuestAdditions_debian_based_linux.sh ../work
	cp ../install-squid3-debian.sh ../work
	cd $(PWD)

init: create_work_dir init_vagrant copy_files

init_vagrant:
	$(call chdir,work) vagrant init
	cd $(PWD)

destroy: clean_vagrant

clean_vagrant:
	$(call chdir,work) vagrant destroy -f
	cd $(PWD)

clean_work_dir:
	cd $(PWD) && rm -rf ./work

clean: clean_vagrant clean_work_dir
	cd $(PWD)
