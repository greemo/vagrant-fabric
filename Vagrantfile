# -*- mode: ruby -*-
# vi: set ft=ruby :

group_vars = {
  'fabric_master_primary' => {
    "fabric_master_mysql_user" => "fabric_master",
    "fabric_master_mysql_pass" => "f4bric",
    "fabric_master_config_template" => "templates/mysql-fabric-master/fabric.cfg.j2",
    "fabric_master_mysql_config_template" => "templates/mysql-fabric-master/my.cnf.j2",
    "pacemaker_config_file" => "files/pacemaker/cib.xml",
  },
  'fabric_masters' => {
    "drbd_resource_template" => "templates/etc/drbd.d/clusterdb.res.j2",
    "drbd_resource_name" => "clusterdb",
  },
  'cluster_nodes' => {
    "ccs_config_file" => "files/etc/cluster/cluster.conf",
  },
  'fabric_slaves' => {
    "fabric_slave_mysql_user" => "fabric_slave",
    "fabric_slave_mysql_pass" => "f4bric",
    "fabric_slave_subnet" => "192.168.70.0/255.255.255.0",
  },
  'fabric_clients' => {
      "mysqlrouter_ini" => "files/etc/mysqlrouter/mysqlrouter.ini",
      "mysqlrouterd_sysconfig" => "files/etc/sysconfig/mysqlrouterd",
  }
}

nodes = {
  'node1' => {
    'ip' => '192.168.70.101',
    'groups' => ['fabric_masters', 'fabric_master_primary', 'cluster_nodes', 'fabric_slaves'],
    'host_vars' => {
      "server_id" => 1,
    },
  },
  'node2' => {
    'ip' => '192.168.70.102',
    'groups' => ['fabric_masters', 'cluster_nodes', 'fabric_slaves'],
    'host_vars' => {
      "server_id" => 2,
    },
  },
  'node3' => {
    'ip' => '192.168.70.103',
    'groups' => ['cluster_nodes', 'fabric_slaves', 'fabric_clients'],
    'host_vars' => {
      "server_id" => 3,
    },
  }
}

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'minimal/centos6'
  config.vm.boot_timeout = 600

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--memory", 1024]
  end

  # Create all nodes according to their spec
  nodes.each_pair { |node, node_params|
    config.vm.define node do |node_config|
      node_config.vm.hostname = node
      node_config.vm.network :private_network, ip: node_params['ip']
      if node_params['groups'].include?('fabric_master_primary') or node_params['groups'].include?('fabric_masters')
        disk = "extra_disk_#{node}.vdi"
        node_config.vm.provider :virtualbox do |vb|
          unless File.exist?(disk)
            vb.customize ['createhd', '--filename', disk, '--size', 512]
          end
          vb.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
        end
      end
    end
  }
  config.vm.provision :ansible do |ansible|
    ansible.verbose = 'vv'
    ansible.sudo = true
    ansible.groups = Hash.new
    ansible.host_vars = Hash.new
    nodes.each_pair { |node, node_config|
      node_config['groups'].each { |group|
        if ansible.groups.include?(group)
          ansible.groups[group].push(node)
        else
          ansible.groups[group] = [node]
        end
      }
      ansible.host_vars[node] = node_config['host_vars']
    }
    ansible.extra_vars = { ansible_ssh_user: 'vagrant' }
    # Disable default limit (required with Vagrant 1.5+)
    ansible.limit = 'all'
    ansible.playbook = "provisioning/site.yml"
    ansible.host_key_checking = false
  end
end

