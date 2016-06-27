Configures a host to be the primary amongst the master nodes in a HA Mysql Fabric deployment, and initialises the Fabric deployment.

Requires the following Ansible variables to be set:

* drbd_resource_name - Name of the drbd resource for the Fabric DB filesystem.
* fabric_master_config_template - Location of a fabric configuration file template to instantiate on the host.
* fabric_master_mysql_config_template - Location of a mysql configuration file template to instantiate on the host as the config file for the fabric master DB.
