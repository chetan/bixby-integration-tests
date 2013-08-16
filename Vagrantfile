# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu-12.04-x86_64"
  config.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/opscode_ubuntu-12.04_provisionerless.box"

  config.vm.provision :shell, :path => "shim.sh"

  # for vagrant-vbguest plugin
  # https://github.com/dotless-de/vagrant-vbguest
  config.vbguest.iso_path = "#{ENV['HOME']}/downloads/VBoxGuestAdditions_%{version}.iso"

  # mount our source
  dir = File.expand_path(File.dirname(__FILE__))
  config.vm.synced_folder dir, "/opt/bixby-integration"

  # Enable SSH agent forwarding for git clones
  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.gui = false # Boot headless
    vb.customize [
      "modifyvm", :id,
      "--memory", "2048",
      "--cpus", "2",
      "--usb", "off",
      "--usbehci", "off",
      "--audio", "none"
    ]
  end

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  config.vm.network :public_network

end
