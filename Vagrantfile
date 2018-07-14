# -*- mode: ruby -*-
# vi: set ft=ruby :

# local_shell
# from here
# https://superuser.com/questions/701735/run-script-on-host-machine-during-vagrant-up

# provide the Virtualbox host version to file
system("
    if [ #{ARGV[0]} = 'up' ]; then
        echo 'Provide the VirtualBox Host version to file'
        VBoxManage --version | sed -E 's/r[^r]\*$//' >/tmp/VirtualBoxHostVersion.txt
    fi
")



module LocalCommand
  class Config < Vagrant.plugin("2", :config)
      attr_accessor :command
  end

  class Plugin < Vagrant.plugin("2")
      name "local_shell"

      config(:local_shell, :provisioner) do
          Config
      end

      provisioner(:local_shell) do
          Provisioner
      end
  end

  class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
          result = system "#{config.command}"
      end
  end
end

# end module




COMMAND=ARGV[0]

# VM_NAME = "vagrant-stretch64-docker-jenkins"
VAGRANT_BOX_NAME = "debian/contrib-stretch64"
VAGRANT_HOME_PATH = ENV["VAGRANT_HOME"] ||= "~/.vagrant.d"
VIRTUALBOX_MEMORY = "4096"
VIRTUALBOX_CPU = "4"
VIRTUALBOX_DISKSIZE = '20GB'
VAGRANT_VERSION = "2.1"
VAGRANTFILE_API_VERSION = "2"

# Overwrite host locale in ssh session
ENV["LC_ALL"] = "en_US.UTF-8"




# from here https://github.com/popstas/ansible-server/blob/master/Vagrantfile
# VM_NAME = ENV.has_key?('VM_NAME') ? ENV['VM_NAME'] : "exit-VM-NAME-not-setlocal"


VM_NAME="default-not-set"

def ensure_VM_NAME(_VM_NAME)
logger = Vagrant::UI::Colored.new
if COMMAND == "up" then
  if ENV.has_key?('VM_NAME') then

    _VM_NAME = ENV['VM_NAME']

    File.open('vm_name.info', 'w') { |file| file.write("#{_VM_NAME}") }


else
  logger.error("VM_NAME not set")
  logger.info("Please set env VM_NAME")
  logger.info("e.g. VM_NAME=\"vagrant-virtualbox-squid3\" vagrant up")
  exit

end
else
  # not up
   _VM_NAME = File.open('vm_name.info', &:readline)
  logger.info ("We used #{_VM_NAME}")
end
return _VM_NAME
end

VM_NAME=ensure_VM_NAME(VM_NAME)

# ensure tmp files
system("
  echo 'touch /tmp/VM_NAME.vminfo'
  if ! [ -e /tmp/#{VM_NAME}.vminfo ]; then
    touch /tmp/#{VM_NAME}.vminfo
  fi
")







# from here https://github.com/fdemmer/vagrant-stretch64-docker/blob/master/Vagrantfile

plugins = ["vagrant-disksize",
"vagrant-vbguest",
"vagrant-scp",
"vagrant-proxyconf"]
puts plugins.length

# Install vagrant plugin
#
# @param: plugin type: Array[String] desc: The desired plugin to install
def ensure_plugins(plugins)
    logger = Vagrant::UI::Colored.new
    logger.info("Start Installing plugin #{plugins}")
    result = false
    plugins.each do |p|
      pm = Vagrant::Plugin::Manager.new(
        Vagrant::Plugin::Manager.user_plugins_file
      )
      plugin_hash = pm.installed_plugins
      next if plugin_hash.has_key?(p)
      result = true
      logger.warn("Installing plugin #{p}")
      pm.install_plugin(p)
    end
    if result
      logger.warn('Re-run vagrant up now that plugins are installed')
      exit
    else
      logger.info('Not additional plugins installed')
    end
    # logger.info("Finish Installing plugin #{plugins}")
    logger.info("Finish Installing plugin")
  end

ensure_plugins(plugins)

# used share cache directory
# from here https://gist.github.com/juanje/3797297
# usage:
# Vagrant::Config.run do |config|
#  config.vm.box = "opscode-ubuntu-12.04"
#  config.vm.box_url = "https://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-12.04.box"
#  cache_dir = local_cache(config.vm.box)
#  config.vm.share_folder "v-cache",
#                         "/var/cache/apt/archives/",
#                         cache_dir
# end

def local_cache(basebox_name)
  cache_dir = Vagrant::Environment.new.home_path.join('cache', 'apt', basebox_name)
  # Vagrant::Environment.new.home_path
  print cache_dir
  cache_dir.mkpath unless cache_dir.exist?
  partial_dir = cache_dir.join('partial')
  partial_dir.mkdir unless partial_dir.exist?
  cache_dir
end

require "open3"
#set internet device name to the world
worldwideinterfaces=%x(ip route get  $(dig +short google.com | tail -1) | grep $(dig +short google.com | tail -1)| awk '{print $5}').chomp

# ensure vagrant vdersion
Vagrant.require_version ">= #{VAGRANT_VERSION}"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
# network
    # What box should we base this build on?
    # from here
    # https://stackoverflow.com/questions/17845637/how-to-change-vagrant-default-machine-name
    config.vm.box = VAGRANT_BOX_NAME
    config.vm.hostname = VM_NAME
    config.vm.define VM_NAME
    cache_dir = local_cache(config.vm.box)

    # disable vgguest plugin to start before cache dir is mounted
    config.vbguest.auto_update = false

    # from here
    # https://serverfault.com/questions/487862/vagrant-os-x-host-nfs-share-permissions-error-failed-to-set-owner-to-1000
    if (/darwin/ =~ RUBY_PLATFORM) != nil
      config.vm.synced_folder cache_dir, "/var/cache/apt/archives/", nfs: true, :bsd__nfs_options => ["-maproot=0:0"]
    else
      #config.vm.synced_folder cache_dir, "/var/cache/apt/archives/", nfs: true, :linux__nfs_options => ["no_root_squash"]
      #org config.vm.synced_folder cache_dir, "/var/cache/apt/archives/", nfs: true, :bsd__nfs_options => ["-maproot=0:0"]
      # from here
      # https://www.vagrantup.com/docs/synced-folders/basic_usage.html
      # with vagrant user in the /etc/export
      # with nfs flag
      # config.vm.synced_folder cache_dir, "/var/cache/apt/archives/",  mount_options: ["uid=0", "gid=0"], nfs: true, :bsd__nfs_options => ["-maproot=0:0"]
      # without nfs flag
      config.vm.synced_folder cache_dir, "/var/cache/apt/archives/", owner: "_apt",
      group: "nogroup", :bsd__nfs_options => ["-maproot=0:0"]

    end

    # set disksize to 20GB
    config.disksize.size = VIRTUALBOX_DISKSIZE

     # Add 2nd network adapter
    if (/darwin/ =~ RUBY_PLATFORM) != nil
    # Add 2nd network adapter
      config.vm.network "public_network", :type =>"dhcp" ,:bridge => 'en0: Wi-Fi (AirPort)'
    # Hint for you morre than one interfaces :bridge => 'en1: Wi-Fi (AirPort)'
    else
      config.vm.network "public_network", :type =>"dhcp" ,:bridge => "#{worldwideinterfaces}"
    end

    config.ssh.insert_key = false
    #######################################################################
    # THIS REQUIRES YOU TO INSTALL A PLUGIN. RUN THE COMMAND BELOW...
    #
    #   $ vagrant plugin install vagrant-disksize
    #
    # Default images are not big enough to build .
    # config.disksize.size = '8GB'
    # forward terminal type for better compatibility with Dialog - disabled on Ubuntu by default
    config.ssh.forward_env = ["TERM"]
    # default user name is "ubuntu", please do not change it

    # SSH password auth is disabled by default, uncomment to enable and set the password
    #config.ssh.password = "armbian"
    config.vm.provider "virtualbox" do |vb|
        #name of VM in virtualbox
        vb.name = VM_NAME
        # uncomment this to enable the VirtualBox GUI
        #vb.gui = true
        # Tweak these to fit your needs.
        vb.memory = VIRTUALBOX_MEMORY
        vb.cpus = VIRTUALBOX_CPU
        vb.linked_clone = true
     end

    # approach for mount share volume on command line
    # mount share folders before provision
    # from here
    # https://github.com/hashicorp/vagrant/issues/936
    # DISABLE
    # config.vm.provision :shell do |shell|
    #  shell.inline = "sudo mount -t vboxsf -o uid=$(id -u vagrant),gid=$(id -g vagrant) var_cache_apt_archives_ /var/cache/apt/archives"
    # end

    # set VirtualBox version to file
    config.vm.provision "file", source: "/tmp/VirtualBoxHostVersion.txt", destination: "/home/vagrant/VirtualBoxHostVersion.txt"

    # test of localshell
    config.vm.provision "create-vminfo", type: "local_shell", command: "VBoxManage showvminfo #{VM_NAME} --machinereadable > /tmp/#{VM_NAME}.vminfo"

    # set VirtualBox version to file
    # not working because source not avaible at vagrant validate
    # config.vm.provision "file", source: "/tmp/#{VM_NAME}.vminfo", destination: "/home/vagrant/vm.info"
    config.vm.provision "copy_vminfog", type: "local_shell", command: "vagrant scp /tmp/#{VM_NAME}.vminfo #{VM_NAME}:/home/vagrant/vm.info"

    # shell scripts
    shell_scripts = ["found-bridge-adapter.sh",
    "install_VBoxGuestAdditions_debian_based_linux.sh"
    ]

    puts shell_scripts.length

    logger = Vagrant::UI::Colored.new
    logger.info("run provisioner for scripts ")

    # loop over all script
    shell_scripts.each do |s|
      # install script
      config.vm.provision "shell", path: s

    end

    logger.info("finish provisioner")

=begin
    # install install_VBoxGuestAdditions_debian_based_linux.sh
    config.vm.provision "shell", path: "install_VBoxGuestAdditions_debian_based_linux.sh"

    # install ansible use external script
    config.vm.provision "shell", path: "ansible_install_from_source.sh"

    # install jenkins use external script
    config.vm.provision "shell", path: "install_ansible_jenkins_docker_role.sh"

=end


    # test of localshell
    config.vm.provision "list-files", type: "local_shell", command: "ls >/tmp/test_out.out"


    # Not work for multi instances
    # Set the name of the VM. See: http://stackoverflow.com/a/17864388/100134
    # config.vm.define :VM_NAME do |vm_define|
    # end

    # # Ansible provisioner.
    # config.vm.provision "ansible" do |ansible|
    #    ansible.playbook = "provisioning/main.yml"
    #    ansible.verbose = "v"
    # end

  end
