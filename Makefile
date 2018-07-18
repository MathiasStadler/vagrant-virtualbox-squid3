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
	cp ../../vagrant/install-disk-on-box-debian.sh ../$(WORK_DIR) && \
	cp ../../vagrant/install_VBoxGuestAdditions_debian_based_linux.sh ../$(WORK_DIR) && \
	cp ../install-squid3-debian*.sh ../$(WORK_DIR)/install-squid3-debian.sh && \
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

ssh-config:
	cd $(PWD)/$(WORK_DIR) && vagrant ssh-config
	cd $(PWD)

status:
	cd $(PWD)/$(WORK_DIR) && vagrant status
	cd $(PWD)

info:
		VBoxManage showvminfo $(VM_NAME)

cc: copy_crawler

copy_crawler:
	cd $(PWD)/$(WORK_DIR) && vagrant scp ../../cache-test/ $(VM_NAME):/home/vagrant
	cd $(PWD)

rcc: run_crawler

run_crawler:
	cd $(PWD)/$(WORK_DIR) && vagrant ssh --command "/home/vagrant/cache-test/crawl.sh  http://www.w3.org/TR/SVG11/feature#BasicStructure 127.0.0.1 3128"
	cd $(PWD)/$(WORK_DIR) && vagrant ssh --command "/usr/bin/squidclient mgr:ipcache"
	cd $(PWD)

round_trip: clean init up clean