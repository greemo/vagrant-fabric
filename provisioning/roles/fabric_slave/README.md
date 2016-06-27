Configures a host to be a slave node in a Mysql Fabric deployment.

Requires the following Ansible variables to be set:

* fabric_slave_mysql_user - Name of the mysql user used by fabric on the slave db.
* fabric_slave_mysql_pass - Password for the mysql user used by fabric on the slave db.
* fabric_slave_subnet - Subnet from which to allow connections to the mysql slave db.
