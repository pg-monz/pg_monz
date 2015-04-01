## About pg_monz {#about}

PostgreSQL monitoring template for Zabbix (pg_monz) is a Zabbix template for
monitoring PostgreSQL. 

### Why pg_monz?

pg_monz enables various types of monitoring of PostgreSQL such as alive, resource, performance, etc.
It supports some constitution patterns which includes single PostgreSQL pattern, HA pattern with Streaming Replication and load balancing pattern with pgpool-II.
You can use pg_monz for auto recovery at the time of PostgreSQL system troubles, monitoring long-term changes in PostgreSQL system status, and so on.

### Major changes between 1.0 and 2.0

pg_monz was first released as version 1.0 in December 2013.
At version 1.0, supported pattern had been only single PostgreSQL pattern.
Since version 2.0, it includes the following changes.

#### (1) Add new monitoring features

Support the following PostgreSQL systems pattern in addition to PostgreSQL single pattern.

* High availability pattern by using PostgreSQL Streaming Replication
* Load balancing pattern by using pgpool-II

#### (2) Performance improvement

At version 1.0, pg_monz connects to PostgreSQL server with psql command through Zabbix Agent every monitoring processes.
In this way, in case of more items and shorter monitoring interval, many connections leads to PostgreSQL server high load.
At version 2.0, pg_monz collects monitoring data from PostgreSQL in bulk.

For more information see [Proccess flow]({{ site.production_url }}/index-en.html#flow).

### Composition of pg_monz

pg_monz consists of the following contents:

|Directory/File name      |Function                                    |
|-------------------------|--------------------------------------------|
|Template                 |Monitoring template                         |
|usr-local-bin/*          |Backend scripts                             |
|usr-local-etc/*          |Configuration files for backend scripts     |
|zabbix-agentd.d/userparameter_pgsql.conf  |UserParameter configuration file for Zabbix Agent |

#### (1) Templates

Template directory includes the following 5 monitoring template xml.


|Template name |Use|
|--------------|----|
|Template_App_PostgreSQL.xml|Monitoring for single PostgreSQL server|
|Template_App_PostgreSQL_SR.xml|Monitoring for Streaming Replication|
|Template_App_PostgreSQL_SR_Cluster.xml|Monitoring for the whole Streaming Replication cluster|
|Template_App_pgpool-II.xml|Monitoring for pgpool-II|
|Template_App_pgpool-II_watchdog.xml|Monitoring for the whole pgpool-II cluster|

#### (2) Backend scripts

Usr-local-bin directory includes some backend scripts.
These scripts are called by UserParameters which are defined at userparameter_pgsql.conf.

#### (3) Configuration files

Usr-local-etc directory includes two configuration files.
These scripts are used to executing backend scripts.

* pgsql_funcs.conf : Configuration file of connection information to PostgreSQL server
* pgpool_funcs.conf : Configuration file of connection information to pgpool-II

__[Note] At version 1.0, this information is set to Zabbix MACRO. But, at version 2.0, this information is set to above files.__

#### (4) UserParameter configuration file

This is the configuration file to define UserParameter.

## Release notes {#releases}

* [2015/03/31 ver.2.0](https://github.com/pg-monz/pg_monz/releases/tag/2.0)
* [2014/11/17 ver.1.0.1](https://github.com/pg-monz/pg_monz/releases/tag/1.0.1)
* [2013/11/05 ver.1.0.0](https://github.com/pg-monz/pg_monz/releases/tag/1.0)

## Download {#download}

[Download from GitHub releases page](https://github.com/pg-monz/pg_monz/releases)

## Requirements {#software}

pg_monz requires the following software products:
Also note that Zabbix Agent and Zabbix Sender must be installed on the monitoring target server
since it utilizes the functions of Zabbix Agent and Zabbix Sender for acquiring PostgreSQL
information.

|Software name|Version|
|----------|------------|
|Zabbix Server,Zabbix Agent,Zabbix Sender |2.0 or later|
|PostgreSQL|9.2 or later|
|pgpool-II|3.4.0 or later|

## Process flow {#flow}

pg_monz v2.0 execute monitoring process under the following process flow.

### Single PostgreSQL pattern

![process_flow_single]({{ site.production_url }}/assets/images/pg_monz_process_flow_single.png)

* (1) Zabbix agent type item(key: psql.get...) executes monitoring information in bulk regularly.
* (2) On the backend, scripts are executed to collect PostgreSQL statistics information according to UserParameter definitions.
* (3) In these scripts, psql commands are executed to collect data from Database.
* (4) The information which is collected at (3) is sent to Zabbix with zabbix_sender command.
* (5) The data which is sent by zabbix_sender is registered to some Zabbix trapper items.

### Streaming Replication pattern

![process_flow_sr]({{ site.production_url }}/assets/images/pg_monz_process_flow_sr.png)

To execute monitoring for Streaming Replication, you should assign the template for Streaming Replicaion to hosts.
Streaming Replication template is linked to the template for single PostgreSQL.
The (1)-(5) processes is similar to single PostgreSQL pattern.

There is only one different point.
In this pattern, you should register the host for the whole Streaming Replication cluster.
And you should assign 'Template App PostgreSQL SR Cluster' template to this host.
So, this template execute aggregating the data to show the whole cluster status.(6)

### pgpool-II pattern

![process_flow_pgpool]({{ site.production_url }}/assets/images/pg_monz_process_flow_pgpool.png)

To execute monitoring for pgpool-II, you should assign the template for pgpool-II to hosts.
To assign this template, the following process is executed.

* (1) Zabbix agent type item(key: pgpool.get...) executes monitoring information in bulk regularly.
* (2) On the backend, scripts are executed to collect PostgreSQL statistics information according to UserParameter definitions.
* (3) In these scripts, psql commands are executed towards pgpool-II to collect data.
* (4) The information which is collected at (3) is sent to Zabbix with zabbix_sender command.
* (5) The data which is sent by zabbix_sender is registered to some Zabbix trapper items.

Like the Streaming Replication pattern, the whole status of pgpool-II cluster is monitored by assigning the template for pgpool-II cluster.(6)

## Installation {#install}

The following instruction assumes that the installation and configuration of
the above software is finished.

### 1. Installation of configuration file and scripts

Copy the User parameter configuration file for agent
(userparameter_pgsql.conf) to the specified location of the machine that
has agent installed.
For example, if Zabbix agent is installed under /usr/local/zabbix/,
copy the file to the following location:

{% highlight bash %}
/usr/local/zabbix/etc/zabbix_agentd.conf.d/userparameter_pgsql.conf
{% endhighlight %}

Also add Include setting to zabbix_agentd.conf so that the above file is
loaded.
(requires restart to apply the setting)

{% highlight properties %}
Include=/usr/local/zabbix/etc/zabbix_agentd.conf.d/
{% endhighlight %}

Next, copy the scripts for discovery and add them executable permission.
By default, it is assumed that they are installed under /usr/local/bin.

{% highlight bash %}
cp find_dbname.sh find_dbname_table.sh /usr/local/bin
chmod +x /usr/local/bin/find_dbname.sh
chmod +x /usr/local/bin/find_dbname_table.sh
{% endhighlight %}

If the user of executing psql need password authentication you should make .pgpass file and put it in the home directory of Zabbix Agent starting user.

### 2. Import of template

Log into the Zabbix Web interface and import the template with the following
procedure:

Select 'Configuration' - 'Templates' tab and display templates list.
![template_list]({{ site.production_url }}/assets/images/template_list.png)
Click 'Import' at the upper right, select pg_monz_template.xml on 'Import file' and click 'Import'.
![template_import]({{ site.production_url }}/assets/images/template_import.png)
If successful, 'Template App PostgreSQL' will be added on the templates list.
![template_imported]({{ site.production_url }}/assets/images/template_imported.png)

### 3. Configuration of template macros

Modify the configuration of template macros according to the system environments by the following procedure:

Select 'Configuration' - 'Templates' tab and display templates list.
Click 'Template App PostgreSQL' and select 'Macros' tab.
![template_macro]({{ site.production_url }}/assets/images/template_macro.png)
Modify the values of each macro according to the system environments and click 'Save'.
Normally following macros will require modifications.

|Macro name     |Description                                                          |
|---------------|---------------------------------------------------------------------|
|{$PGDATABASE}  |Database name to connect                                             |
|{$PGHOST}      |PostgreSQL host (if same host as Zabbix agent: 127.0.0.1)            |
|{$PGLOGDIR}    |Directory that contains PostgreSQL log files                         |
|{$PGPORT}      |Port number                                                          |
|{$PGROLE}      |PostgreSQL user name                                                 |
|{$PGSCRIPTDIR} |Directory that has scripts installed                                 |

## Usage {#usage}

The following instruction describes how to start monitoring using the imported templates.

### 1. Creating PostgreSQL host

Creates PostgreSQL host.

Select 'Configuration' - 'Hosts' tab and display hosts list.
![host_list]({{ site.production_url }}/assets/images/host_list.png)
Click 'Create host' at the upper right and configure host name, groups etc. of target.
![host_config]({{ site.production_url }}/assets/images/host_config.png)
Select 'Templates' tab and click 'Add'.
Select 'Template App PostgreSQL' and click 'Select' and 'Save'.
![host_template_select]({{ site.production_url }}/assets/images/host_template_select.png)

### 2. Check the result of monitoring

If configured correctly, monitoring will be started automatically after a while.
To check the result of monitoring, select 'Monitoring' - 'Latest data' tab.

If monitoring data are succesfully obtained, the registered host is displayed on the list. Click '+' at the left of the host name to display the obtained latest value of each item.
![latest_items]({{ site.production_url }}/assets/images/latest_items.png)
Also note that it takes a while for per-database monitoring items to be displayed because the discovery of database name is executed every hour by default.

## Monitoring items {#items}

### Alive monitoring of PostgreSQL server

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|Number of postgres process|Process check of PostgreSQL server|
|Item|PostgreSQL service is running|SQL response check of PostgreSQL server|
|Trigger|PostgreSQL process is not running.|Number of process of PostgreSQL server is 0|
|Trigger|PostgreSQL service is not running.|SQL execution on PostgreSQL server failed|

### Monitoring of PostgreSQL log

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|Log of $1|Messages that include PANIC,FATAL,ERROR on server log|

### Monitoring of database size

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|\[DB name\] DB Size|Size of target database|
|Trigger|\[DB name\] DB Size is too large|Database size exceeds threshold|
|Graph|\[DB name\] DB Size|Size transition of target database|

### Monitoring of backend process

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|Connections|Number of backend process (total)|
|Item|Active (SQL processing) connections|Number of backend process (SQL processing)|
|Item|Idle connections|Number of backend process (waiting for query from clients)|
|Item|Idle in transaction connections|Number of backend process (waiting for commands in transaction)|
|Item|Lock waiting connections|Number of backend process (waiting for locks in transaction)|
|Trigger|Many connections are forked.|Number of backend process exceeds threshold|
|Graph|Connection count|Transition of number of backend process|

### Monitoring of execution of checkpoints

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|Checkpoint count (by checkpoint_segments)|Checkpoint count by checkpoint_segments|
|Item|Checkpoint count (by checkpoint_timeout)|Checkpoint count by checkpoint_timeout|
|Trigger|Checkpoints are occurring too frequently|Checkpoint count in a specific period exceeds threshold|
|Graph|Checkpoint count|Transition of Checkpoint count|

### Monitoring of cache hit ratio

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|\[DB name\] Cache Hit Ratio|Cache hit ratio of target database|
|Trigger|\[DB name\] Cache hit ratio is too low|Cache hit ratio of target database is less than its threshold|
|Graph|\[DB name\] Cache Hit Ratio|Transition of cache hit ratio of target database|

### Monitoring of deadlocks

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|\[DB name\] Deadlocks|Number of deadlocks on target database|
|Trigger|\[DB name\] Deadlocks occurred too frequently|Deadlocks occurred more than threshold on target database|
|Graph|\[DB name\] Deadlocks|Transition of number of deadlocks on target database|

### Monitoring of transaction processes

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|\[DB name\] Commited transactions|Number of COMMIT on target database|
|Item|\[DB name\] Rolled back transactions|Number of ROLLBACK on target database|
|Graph|\[DB name\] Number of commited/rolled back transactions|Transition of number of COMMIT/ROLLBACK|

### Monitoring of temporary file generation

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|\[DB name\] Temp bytes|Bytes of data written to temporary files on target database|
|Trigger|\[DB name\] Too many temp bytes|Temporary file output on target database exceeds threshold|
|Graph|\[DB name\] Temp file size|Transition of amount of temporary files on target database|

### Monitoring of retained backend processes

|Type|Name on Zabbix|Information of item and graph, trigger condition|
|--|--|--|
|Item|Slow queries|Number of backend processes which take more than specified time (active)|
|Item|Slow DML queries|Number of backend processes which take more than specified time (DML processing)|
|Item|Slow select queries|Number of backend processes which take more than specified time (SELECT processing)|
|Trigger|Too many slow queries|Number of backend processes which take more than specified time exceeds threshold|

## Contact {#contact}

pg_monz Users Group  
<pg_monz@googlegroups.com>

## License {#license}

pg_monz is distributed under the Apache License Version 2.0. 
The whole text of Apache License Version 2.0 can be referred to [here](http://www.apache.org/licenses/LICENSE-2.0).

Copyright (C) 2013-2015 SRA OSS, Inc. Japan All Rights Reserved.  
Copyright (C) 2013-2015 TIS Inc. All Rights Reserved.
