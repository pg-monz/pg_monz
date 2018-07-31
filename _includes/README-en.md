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
|Template_App_pgpool-II.xml|Monitoring for pgpool-II (pgpool-II 3.5 or earlier)|
|Template_App_pgpool-II-36.xml|Monitoring for pgpool-II (pgpool-II 3.6 or later)|
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

* [2018/03/30 ver.2.1](https://github.com/pg-monz/pg_monz/releases/tag/2.1)
* [2016/04/21 ver.2.0.1](https://github.com/pg-monz/pg_monz/releases/tag/2.0.1)
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

Since bc command is executed in pg_monz backend scripts,
bc command must be installed on the monitoring target server.

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

### 0. Preparation

#### (1) Configuring Zabbix Agent 

In order to monitor PostgreSQL/pgpool-II with pg_monz, Zabbix Agent must have permisson for :
* Refering PostgreSQL logs and pgpool-II logs  
* Executing pg_monz scripts 

#### (2) Installation of Zabbix Sender

pg_monz use functions of Zabbix Sender in addition to Zabbix Agent. 
If Zabbix Sender hasn't been installed yet, install 'zabbix-sender' package.  

### 1. Deployment of configuration files and scripts

#### (1) Configuration files

Copy pg_monz configuration files to any directory on all of monitored server.
By default, it is assumed that they are installed under /usr/local/etc

{% highlight bash %}
cp usr-local-etc/* /usr/local/etc
{% endhighlight %}

If necessary, modfy the contents of them  

##### pgsql_funcs.conf

{% highlight properties %}
PGHOST=127.0.0.1  
PGPORT=5432  
PGROLE=postgres  
PGDATABASE=postgres
{% endhighlight %}

##### pgpool_funcs.conf

{% highlight properties %}
PGPOOLHOST=127.0.0.1  
PGPOOLPORT=9999  
PGPOOLROLE=postgres  
PGPOOLDATABASE=postgres  
PGPOOLCONF=/usr/local/etc/pgpool.conf 
{% endhighlight %}

If the connection to PostgreSQL requires a password, add "export PGPASSFILE=xx" to pgsql_funcs.conf.

{% highlight properties %}
export PGPASSFILE=/usr/local/etc/pgpass
{% endhighlight %}

Create /usr/local/etc/pgpass file according to the setting values of pgsql_funcs.conf.

##### pgpass

{% highlight bash %}
127.0.0.1:5432:*:postgres:somepassword
{% endhighlight %}

Grant permission only to the start user of zabibx agent.

{% highlight bash %}
chmod 600 /usr/local/etc/pgpass
{% endhighlight %}


#### (2) Scripts

Copy pg_monz scripts to any directory on all of monitored server and add them executable permission.  
By default, it is assumed that they are installed under /usr/local/bin

{% highlight bash %}
cp usr-local-bin/* /usr/local/bin  
chmod +x /usr/local/bin/*.sh
{% endhighlight %}

#### (3) userparameter_pgsql.conf

Copy the User parameter configuration file for Zabbix agent (userparameter_pgsql.conf) to the specified location of the machine that has agent installed.  
For example, if Zabbix agent is installed under /etc/zabbix/, copy the file to the following location:

{% highlight bash %}
/etc/zabbix/zabbix_agentd.conf.d/userparameter_pgsql.conf
{% endhighlight %}

Also, add Include setting to zabbix_agentd.conf so that the above file is loaded.  
(requires restart of zabbix agent to apply the setting)

{% highlight properties %}
Include=/etc/zabbix/zabbix_agentd.conf.d/
{% endhighlight %}

### 2. Import of template
Login to Zabbix Web interface and import the template with the following procedure:

1. Select [Configuration] - [Templates] tab and display templates list.  
2. Click [Import] at the upper right and import all of xml files including pg_monz package in order.  
3. If successful, templates imported will be added on the template list.

### 3. Configuration of template macros
Modify the configuration of tempalte macros according to the system environments by the following procedure:  

1. In Zabbix Web interface, select [Configuration] - [Templates] and display templates list.  
2. Click each template of pg_monz and select [Macros] tab. 
3. Modify the values of each macro according to the system environments and click [Save].

##### Template App PostgreSQL

|Macro name                |Default Value                 |Description                                     |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGCACHEHIT_THRESHOLD}   |90                            |Threshold for trigger of cache hit ratio [%]    |
|{$PGCHECKPOINTS_THRESHOLD}|10                            |Threshold for trigger of Checkpoint count [count/seconds] |
|{$PGCONNECTIONS_THRESHOLD}|95                            |Threshold for trigger of backend connections    |
|{$PGDBSIZE_THRESHOLD}     |1073741824                    |Threshold for trigger of database size [byte]   |
|{$PGDEADLOCK_THRESHOLD}   |0                             |Threshold for trigger of deadlock [count]       |
|{$PGLOGDIR}               |/usr/local/pgsql/data/pg_log  |Directory that contains PostgreSQL log files    |
|{$PGSCRIPTDIR}            |/usr/local/bin                |Directory that contains pg_monz scripts         |
|{$PGSCRIPT_CONFDIR}       |/usr/local/etc                |Directory that contains pg_monz configuration files |
|{$PGSLOWQUERY_TIME_THRESHOLD}  |10                       |Threshold for Defining a long query as "Slow_Query" [seconds] |
|{$PGSLOWQUERY_COUNT_THRESHOLD}  |10                      |Threshold for trigger of Slow_Query [count]    |
|{$PGTEMPBYTES_THRESHOLD}  |8388608                       |Threshold for trigger of temp file size [byte] |
|{$ZABBIX_AGENTD_CONF}     |/etc/zabbix/zabbix_agentd.conf|filepath for zabbix_agentd.conf                  |

##### Template App PostgreSQL SR

|Macro name                |Default Value                 |Description                                     |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGSCRIPTDIR}            |/usr/local/bin                |Directory that contains pg_monz scripts         |
|{$PGSCRIPT_CONFDIR}       |/usr/local/etc                |Directory that contains pg_monz configuration files |

##### Template App pgpool-II

|Macro name                |Default Value                 |Description                                     |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGPOOLLOGDIR}           |/var/log/pgpool               |Directory that contains pgpool-II log files     |
|{$PGPOOLSCRIPTDIR}        |/usr/local/bin                |Directory that contains pg_monz scripts         |
|{$PGPOOLSCRIPT_CONFDIR}   |/usr/local/etc                |Directory that contains pg_monz configuration files |
|{$ZABBIX_AGENTD_CONF}     |/etc/zabbix/zabbix_agentd.conf|filepath for zabbix_agentd.conf                 |

##### Template App pgpool-II watchdog

|Macro name                |Default Value                 |Description                                     |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGPOOL_HOST_GROUP}      |pgpool                        |host group name for pgpool-II hosts             |

##### Template App PostgreSQL SR Cluster

|Macro name                |Default Value                 |Description                                     |
|--------------------------|------------------------------|------------------------------------------------|
|{$PG_HOST_GROUP}          |PostgreSQL                    |host group name for PostgreSQL hosts            |


### 4. Creating host 

#### Relation of Host, Template, and the configuration of the system  
Templates that should be applied varies by the configuration of the monitored system. 
The representative patterns are shown below:

![template_pattern]({{ site.production_url }}/assets/images/template_pattern.png)

*1 apply only to environment using pgpool-II watchdog  

#### Creating PostgreSQL host/host group

1. In Zabbix Web interface ,select [Configuration] - [Hosts]tab and display hosts list.  
2. Click [Create host] at the upper right and configure hostname ,groups etc. of target.  
3. Select [Templates] tab and click [Add].Select template that should be applied and click 'Select' and 'Save'.  
4. Select [Configuration] - [Host Groups] - [Create host group] . 
5. Input group name as "PostgreSQL" and select all hosts of PostgreSQL to input them into parameter of 'Hosts' and click [Save].

#### Creating pgpool-II host/host group

1. In Zabbix Web interface ,select [Configuration] - [Hosts]tab and display hosts list.  
2. Click [Create host] at the upper right and configure hostname ,groups etc. of target.  
3. Select [Templates] tab and click [Add].Select template that should be applied and click 'Select' and 'Save'.  
4. Select [Configuration] - [Host Groups] - [Create host group] . 
5. Input group name as "pgpool" and select all hosts of pgpool-II to input them into parameter of 'Hosts' and click [Save].

#### Creating PostgreSQL Cluster host

1. In Zabbix Web interface ,select [Configuration] - [Hosts]tab and display hosts list.  
2. Click [Create host] at the upper right and Input hostname as "PostgreSQL Cluster" .  
3. Select [Templates] tab and click [Add].Select template that should be applied and click 'Select' and 'Save'.  
4. Select [Configuration] - [Host Groups] - [Create host group] . 
5. Input group name as "PostgreSQL Cluster" and select "PostgreSQL Cluster" host to input it into parameter of 'Hosts' and click [Save].


## Monitoring items {#items}

#### Summaries of Monitoring items

##### Applications for Monitoring PostgreSQL

|Application name   |Summary of monitoring                                                                              |
|:------------------|----------------------------------------------------------------------------------------|
|pg.transactions    |Connection count and state to PostgreSQL ,transactions count                            |
|pg.log             |log monitoring for PostgreSQL                                                           |
|pg.size            |garbage ratio, DB size                                                                  |
|pg.slow_query      |slow query count which exceeds the threshold value                                      |
|pg.status          |PostgreSQL processes working state                                                      |
|pg.stat_database   |state of each database                                                                  |
|pg.stat_table      |state of each table                                                                     |
|pg.bgwriter        |state of background writer process                                                      |
|pg.stat_replication|delay of replication data propagation using Streaming Replication                       |
|pg.sr.status       |conflict count, write block existence or non-existence, process count using Streaming Replication|
|pg.cluster.status  |PostgreSQL processes count as a cluster                                                 |

##### Applications for Monitoring pgpool-II

|Application name   |Summary of monitoring                                                                   |
|:------------------|----------------------------------------------------------------------------------------|
|pgpool.cache       |cash informations using In Memory query Cache                                           |
|pgpool.connections |frontend, backend connection count through pgpool-II                                    |
|pgpool.log         |log monitoring for pgpool-II                                                            |
|pgpool.nodes       |backend state, load balance ratio and replication delay viewed from pgpool-II           |
|pgpool.status      |pgpool-II processes working state, vip existence or non-existence                       |
|pgpool.watchdog    |pgpool-II processes working state, vip existence or non-existence as a cluster          |

#### Details of Monitoring items

* [(pdf)Items_list_en]({{ site.production_url }}/assets/docs/item_list_en.pdf)
* [(pdf)Triggers_list_en]({{ site.production_url }}/assets/docs/trigger_list_en.pdf)

## Contact {#contact}

pg_monz Users Group  
<pg_monz@googlegroups.com>

## License {#license}

pg_monz is distributed under the Apache License Version 2.0. 
The whole text of Apache License Version 2.0 can be referred to [here](http://www.apache.org/licenses/LICENSE-2.0).

Copyright (C) 2013-2018 SRA OSS, Inc. Japan All Rights Reserved.  
Copyright (C) 2013-2018 TIS Inc. All Rights Reserved.
