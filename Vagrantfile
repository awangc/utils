# -*- mode: ruby -*-

# Vagrant file API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

['vagrant-reload', 'vagrant-disksize'].each do |plugin|
  unless Vagrant.has_plugin?(plugin)
    raise "Vagrant plugin #{plugin} is not installed!"
  end
end

$scripts_path = File.dirname(File.realdirpath(__FILE__))

$dproject = "williamofockham"
$dimage = "dpdk-devbind"
$dtag = "17.08.1"

$dimage = ENV.fetch("DIMAGE", "netbricks")
$dtag = ENV.fetch("DTAG", "latest")
$dproject = ENV.fetch("DPROJECT", "williamofockham")
$dpdk_driver = ENV.fetch("DPDK_DRIVER", "uio_pci_generic")
$dpdk_devices = ENV.fetch("DPDK_DEVICES", "0000:00:08.0 0000:00:09.0")

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at https://docs.vagrantup.com.
  config.vm.box = "ubuntu/xenial64"
  config.disksize.size = "30GB"

  # e.g. for wireshark forwarding
  config.ssh.forward_x11 = true
  config.ssh.forward_agent = true

  config.vm.synced_folder ".", "/vagrant", disabled: false
  config.vm.provision "shell", inline: "echo 'cd /vagrant' >> /home/vagrant/.bashrc", run: "always"

  # specific IP. This option is needed because DPDK takes over the NIC.
  config.vm.network "private_network", ip: "10.1.2.2", mac: "BADCAFEBEEF1", nic_type: "virtio"
  config.vm.network "private_network", ip: "10.1.2.3", mac: "BADCAFEBEEF2", nic_type: "virtio"
  config.vm.network "private_network", ip: "fe80::b8dc:afff:feeb:eef3", mac: "BADCAFEBEEF3"
  config.vm.network "private_network", ip: "fe80::b8dc:afff:feeb:eef4", mac: "BADCAFEBEEF4"

  # Setup the VM for DPDK, including binding the extra interface via the fetched
  # container
  config.vm.provision "shell", path: "#{$scripts_path}/vm-kernel-upgrade.sh"
  config.vm.provision "reload"
  config.vm.provision "shell", path: "#{$scripts_path}/vm-setup.sh"

  # Pull and run (then remove) our image in order to do the devbind
  config.vm.provision "docker" do |d|
    d.pull_images "williamofockham/dpdk-devbind:17.08.1"
    d.run "williamofockham/dpdk-devbind:17.08.1",
          auto_assign_name: false,
          args: %W(--rm
                   --privileged
                   --network=host
                   -v /lib/modules:/lib/modules
                   -v /dev/hugepages:/dev/hugepages).join(" "),
          restart: "no",
          daemonize: true,
          cmd: "/bin/bash -c '/dpdk/usertools/dpdk-devbind.py --force -b #{$dpdk_driver} #{$dpdk_devices}'"
  end

  # VirtualBox-specific configuration
  config.vm.provider "virtualbox" do |vb|
    # Set machine name, memory and CPU limits
    vb.name = "ubuntu-xenial-williamofockham"
    vb.memory = 4096
    vb.cpus = 4

    # Configure VirtualBox to enable passthrough of SSE 4.1 and SSE 4.2 instructions,
    # according to this: https://www.virtualbox.org/manual/ch09.html#sse412passthrough
    # This step is fundamental otherwise DPDK won't build. It is possible to verify in
    # the guest OS that these changes took effect by running `cat /proc/cpuinfo` and
    # checking that `sse4_1` and `sse4_2` are listed among the CPU flags.
    vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1", "1"]
    vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2", "1"]

    # Allow promiscuous mode for host-only adapter
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
  end
end
