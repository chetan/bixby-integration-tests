# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu-12.04-x86_64"
  config.vm.hostname = "bixbytest"

  config.vm.provision :shell, :path => "scripts/bootstrap.sh", :privileged => false

  # mount our source
  dir = File.expand_path(File.dirname(__FILE__))
  config.vm.synced_folder dir, "/opt/bixby-integration", :nfs => true

  # Enable SSH agent forwarding for git clones
  config.ssh.forward_agent = true

  # bridged network - set in global Vagrantfile in order to select correct interface
  # config.vm.network :public_network


  ##############################################################################
  # VMWARE FUSION

  config.vm.provider :vmware_fusion do |vm, override|
    override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"
    override.vm.network :private_network, ip: "192.168.51.5"

    vm.vmx["memsize"]  = "1024"
    vm.vmx["numvcpus"] = "2"
  end
  #
  ##############################################################################

  ##############################################################################
  # VIRTUALBOX

  # for vagrant-vbguest plugin
  # https://github.com/dotless-de/vagrant-vbguest
  # config.vbguest.iso_path = "#{ENV['HOME']}/downloads/VBoxGuestAdditions_%{version}.iso"

  config.vm.provider :virtualbox do |vb, override|
    # NOTE: does not contain nfs-common
    override.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/opscode_ubuntu-12.04_provisionerless.box"
    override.vm.network :private_network, ip: "192.168.50.5"
    vb.gui = false # Boot headless
    vb.customize [
      "modifyvm", :id,
      "--memory", "1024",
      "--cpus", "2",
      "--usb", "off",
      "--usbehci", "off",
      "--audio", "none"
    ]
  end
  #
  ##############################################################################

end
