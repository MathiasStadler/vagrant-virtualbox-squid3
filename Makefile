# handling vagrant

WORK_DIR=work

PWD := $(shell pwd )


VM_NAME := $(shell pwd | sed 's@.*/@@')

FORCE:
	echo "FORCE target"
	if ( ls -l $(PWD)/install-squid3-debian* | grep -c install-squid3-debian ); then \
        echo "ok Makefile found => ";\
		ls -l $(PWD)/install-squid3-debian* ;\
	else \
		echo "Hoppla: install-squid3-debian* NOT found "; \
		echo "change first to configuration directory, please "; \
		echo "usage: e.g. "; \
		echo "cd minimal-configuration "; \
		echo "make -f ../Makefile init "; \
    fi

create_work_dir:
	mkdir -p $(PWD)/$(WORK_DIR)

up:
	$(info VM_NAME = $(VM_NAME))
	cd $(PWD)/$(WORK_DIR) && VM_NAME="$(VM_NAME)" vagrant up
	cd $(PWD)

halt:
	cd $(PWD)/$(WORK_DIR) && vagrant halt
	cd $(PWD)

copy_files:
	cd $(PWD)/$(WORK_DIR) && \
	cp ../../vagrant/Vagrantfile ../$(WORK_DIR)  && \
	cp ../../vagrant/found-bridge-adapter.sh ../$(WORK_DIR) && \
	cp ../../vagrant/install_VBoxGuestAdditions_debian_based_linux.sh ../$(WORK_DIR) && \
	cp ../install-squid3-debian* ../$(WORK_DIR) && \
	mkdir ../$(WORK_DIR)/settings && \
	cp -a ../../settings/* ../$(WORK_DIR)/settings && \
	cd $(PWD)

init: create_work_dir init_vagrant copy_files

init_vagrant:
	cd $(PWD)/$(WORK_DIR) && vagrant init
	cd $(PWD)

destroy: clean_vagrant

clean_vagrant:
	if [ -d "$(PWD)/$(WORK_DIR)/.vagrant" ]; then \
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


ssh:
	cd $(PWD)/$(WORK_DIR) && vagrant ssh
	cd $(PWD)


round_trip: clean init up clean