# -*- mode: ruby -*-
# vi: set ft=ruby :

# Assumes a box from https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box

# This sets up 2 instances in a fully mirrored fallback functionality.


fabric_nodes = {
  'node1' => {
    'ip' => '192.168.70.101',
  },
  'node2' => {
    'ip' => '192.168.70.102',
  },
  'node3' => {
    'ip' => '192.168.70.103',
  },
}

VAGRANTFILE_API_VERSION = "2"

#$drdb_part_creator = <<SCRIPT
#echo Creating drbd partition...
#yum install -y parted
#parted /dev/sdb mklabel msdos
#parted /dev/sdb mkpart primary 0% 100%
#SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'minimal/centos6'
  #config.vm.box = 'centos65-x86_64-20140116'
  #config.vm.box_url = 'https://github.com/2creatives/vagrant-centos/releases/download/v6.5.3/centos65-x86_64-20140116.box'
  config.vm.boot_timeout = 600

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--memory", 1024]
  end

  # Create the drbd partition
  #config.vm.provision "shell" do |shell|
  #  shell.inline = $drbd_part_creator
  #end

  # Create all nodes according to their spec
  fabric_nodes.each_pair { |node, node_params|
    config.vm.define node do |node_config|
      node_config.vm.hostname = "#{node}"
      node_config.vm.network :private_network, ip: node_params['ip']
      disk = "extra_disk_#{node}.vdi"
      node_config.vm.provider :virtualbox do |vb|
        unless File.exist?(disk)
          vb.customize ['createhd', '--filename', disk, '--size', 512]
        end
        vb.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
      end
    end
  }
  config.vm.provision :ansible do |ansible|
    ansible.groups = {
      "masters" => ['node1', 'node2'],
      "slaves" => ['node1', 'node2', 'node3'],
      "clients" => ['node1', 'node2']
    }
    ansible.host_vars = {
      "node1" => {"server_id" => 1, "primary" => true},
      "node2" => {"server_id" => 2},
      "node3" => {"server_id" => 3},
    }
    ansible.verbose = 'vv'
    ansible.sudo = true
    ansible.extra_vars = { ansible_ssh_user: 'vagrant' }
    ansible.playbook = 'provisioning/site.yml'
    ansible.host_key_checking = false
    # Disable default limit (required with Vagrant 1.5+)
    ansible.limit = 'all'
  end
end

