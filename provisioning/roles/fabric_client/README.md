Configures a host to be a client of a Mysql Fabric deployment.

Requires the following Ansible variables to be set:

- mysqlrouterd_sysconfig: Location of a sysconfig file containing user and password for the mysqlrouterd service
- mysqlrouter_ini: Location of the mysqlrouter ini file used to configure the mysqlrouter that is installed.