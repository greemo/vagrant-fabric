# I have had heaps of problems with the fabric/drbd/pacemaker/mysql/mysqlrouter stack regarding the state of fabric and state of the slave servers getting out of sync.

# See https://github.com/greemo/mysql-ha-pacemaker-semisync for a much more stable, and simple setup, with the same HA guarantee

Requirements
============

Ansible
-------

URL: http://www.ansible.com/

Install: http://docs.ansible.com/intro_installation.html

If you have pip (https://pypi.python.org/pypi) in your system, the following command should be enough
 
    pip install ansible


VirtualBox
----------

URL: http://www.virtualbox.org

Install: https://www.virtualbox.org/wiki/Downloads

Vagrant
-------

URL: http://www.vagrantup.com/

Download: http://www.vagrantup.com/downloads.html 


Installation
============


    git clone https://github.com/greemo/vagrant-fabric 
    vagrant up --no-provision

Get a cookie and wait until this process finish. We don't provision in the first round, as we need all servers running to provision.

    vagrant provision

Get a coffee and wait until this process finish.
 
Basic commands
==============

Connect to the VM
----------------------

This command will connect you to the server.

    vagrant ssh <vm_name>
 
For example:

    $ vagrant ssh store
    Last login: Wed May  7 16:40:21 2014 from 10.0.2.2
    [vagrant@store ~]$

Destroy a VM
--------------

This command will stop the vm if is running and it will remove the vm files.

    vagrant destroy <vm_name>

For example: 

    $ vagrant destroy node3
    Are you sure you want to destroy the 'node3' VM? [y/N] y
    [node3] Forcing shutdown of VM...
    [node3] Destroying VM and associated drives...
    [node3] Running cleanup tasks for 'ansible' provisioner...
 

Start a VM
--------------

This command will create and start the vm.

    vagrant up <vm_name>

For example: 

    $ vagrant up node3
    Bringing machine 'node3' up with 'virtualbox' provider...
    [node3] Importing base box 'centos65-x86_64-20140116'...
    Progress: 100%
    ...
    PLAY RECAP ********************************************************************
    node3                      : ok=14   changed=11   unreachable=0    failed=0
 
The important one is "failed=0" :)

Provision a VM
--------------

This command will run all the ansible playbooks, the VM must be "UP".

    vagrant provision <vm_name>

For example: 

    $ vagrant provision node1
    [node3] Running provisioner: ansible...
    PLAY [all] ********************************************************************
    ...
    PLAY RECAP ********************************************************************
    node1                      : ok=14   changed=1   unreachable=0    failed=0
 
Again, the important one is "failed=0" :)

Using the System
-------------
Make sure all the resources are configured correctly

    192.168.1.200$ sudo crm_mon --one-shot -V
    Last updated: Tue May 17 00:13:33 2016
    Last change: Tue May 17 00:04:35 2016
    Stack: classic openais (with plugin)
    Current DC: node1 - partition with quorum
    Version: 1.1.11-97629de
    2 Nodes configured, 2 expected votes
    8 Resources configured

    Online: [ node1 node2 ]

    Resource Group: g_mysql
     p_fs_mysql (ocf::heartbeat:Filesystem):    Started node1 
     p_ip_mysql (ocf::heartbeat:IPaddr2):       Started node1 
     p_mysql    (ocf::heartbeat:mysql): Started node1 
     p_fabric_mysql     (ocf::heartbeat:mysql-fabric):  Started node1 
    Master/Slave Set: ms_drbd_mysql [p_drbd_mysql]
     Masters: [ node1 ]
     Slaves: [ node2 ]
    Clone Set: cl_ping [p_ping]
     Started: [ node1 node2 ]

Make sure fabric is running

    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg group lookup_groups
    Fabric UUID:  5ca1ab1e-a007-feed-f00d-cab3fe13249e
    Time-To-Live: 1
    
    group_id description failure_detector master_uuid
    -------- ----------- ---------------- -----------

Create the ha group and add nodes

    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg group create ha
    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg group add ha node1
    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg group add ha node2
    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg group promote ha
    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg group activate ha
    

Check the health of the mysql ha group

    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg group health ha
    Fabric UUID:  5ca1ab1e-a007-feed-f00d-cab3fe13249e
    Time-To-Live: 1
    
    uuid is_alive    status is_not_running is_not_configured io_not_running sql_not_running io_error sql_error
    ------------------------------------ -------- --------- -------------- ----------------- -------------- --------------- -------- ---------
    ad56f523-1bfd-11e6-8962-08002782a589        1   PRIMARY              0                 0              0               0    False     False
    ae0491ad-1bfd-11e6-8962-08002782a589        1 SECONDARY              0                 0              1               1    False     False

    issue
    -----

Moving the Pacemaker resource group to another node
-------------
    sudo pcs resource move g_mysql node1


Changing the fabric master
-------------
    sudo pcs resource move g_mysql node1

Recovering an ok fabric slave
-------------
- move the FAULTY server to SPARE, then to SECONDARY via mysqlfabric

    ```
    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg server set_status <uuid> spare 
    192.168.1.200$ sudo mysqlfabric --config /var/lib/mysql-fabric-master/fabric.cfg server set_status <uuid> secondary
    ```

- If this doesn't work, perform the messed-up slave recovery instructions below.


Recovering a messed-up fabric slave
-------------
- stop the mysql server on the messed-up slave

    ```sudo service mysqld stop```

- remove the mysql data

    ```sudo rm -rf /var/lib/mysql/*```

- comment out the log_bin and gtid_mode entries in /etc/my.cnf
- start the server

    ```sudo service mysqld start```

- add the fabric_slave user:

    ```sudo mysql
    create user 'fabric_slave'@'192.168.70.0/255.255.255.0' IDENTIFIED BY 'f4bric';
    grant ALTER,CREATE,DELETE,DROP,INSERT,SELECT,UPDATE on mysql_fabric.* TO 'fabric_slave'@'192.168.70.0/255.255.255.0';
    grant DELETE,PROCESS,RELOAD,REPLICATION CLIENT,REPLICATION SLAVE,SELECT,SUPER,TRIGGER on *.* to 'fabric_slave'@'192.168.70.0/255.255.255.0';
    commit;
    ```

- un-comment the log_bin and gtid_mode entries in /etc/my.cnf
- restart the mysql server

    ```sudo service mysqld restart```


Percona Webinar command transcript
-------------

Here is a transcript of the commands we use to deliver a Percona Webinar on MySQL Fabric: https://github.com/martinarrieta/vagrant-fabric/blob/sharding/webinar-commands/session-0.org





