pg_monz 2.0
============================
pg_monz (PostgreSQL monitoring template for Zabbix) is a Zabbix template for
monitoring PostgreSQL. It enables various types of monitoring of PostgreSQL
such as alive, resource, performance, etc.
Pg_monz also supports automatic discovery of databases and tables using the
discovery feature of Zabbix and can automatically start monitoring.


Changes from 1.0
----------------
The following is a summary of the major changes.


### Support for monitoring of PostgreSQL Streaming Replication
pg_monz 2.0 now supports monitoring of Streaming Replication which is embedded in PostgreSQL since 9.0.  
Various monitoring items such as Primary / Standby servers alive monitoring, delay of replication data propagation and conflicts occurred by operation to Primary and Standby are available.
It is also that a trigger which can detect the occurence of write block query when useing synchronous replication is provided.


### Support for monitoring of pgpool-II
pg_monz 2.0 now supports monitoring of pgpool-II which is a dedicated middleware for PostgreSQL.  
Various types of monitoring and triggers for the main features of pgpool-II such as Connection Pooling, Replication, In memory query Cache, Load Balance, Automatically Failover of PostgreSQL are provided.

Please see [pgpool-II user manual](http://www.pgpool.net/docs/latest/pgpool-en.html), [pgpool Wiki](http://www.pgpool.net/mediawiki/index.php/Main_Page) for more detailed informations.


### Support for monitoring of cluster system with PostgreSQL + pgpool-II
And more, it make it possible to monitor a cluster system which is configured with PostgreSQL Streaming replication and pgpool-II or pgpol-II watchdog which add high availability to themselves.  
Useful triggers which can detects the occurence of split brain, failover are provided through monitoring of postgres, pgpool-II processes.


### Group items
Monitoring items are grouped by each application to clarify them.  
The following are main applications.


#### Applications | PostgreSQL
|application name   |summary of monitoring                                                                            |
|:------------------|-------------------------------------------------------------------------------------------------|
|pg.transactions    |Connection count, state to PostgreSQL, the number of commited, rolled back transactions          |
|pg.log             |log monitoring for PostgreSQL                                                                    |
|pg.size            |garbage ratio, DB size                                                                           |
|pg.slow_query      |slow query count which exceeds the threshold value                                               |
|pg.sr.status       |conflict count, write block existence or non-existence, process count using Streaming Replication|
|pg.status          |PostgreSQL processes working state                                                               |
|pg.stat_replication|delay of replication data propagation using Streaming Replication                                |
|pg.cluster.status  |PostgreSQL processes count as a cluster                                                          |


#### Applications | pgpool-II
|application name   |summary of monitoring                                                                            |
|:------------------|-------------------------------------------------------------------------------------------------|
|pgpool.cache       |cash informations using In Memory query Cache                                                    |
|pgpool.connections |frontend, backend connection count through pgpool-II                                             |
|pgpool.log         |log monitoring for pgpool-II                                                                     |
|pgpool.nodes       |backend state, load balance ratio viewed from pgpool-II                                          |
|pgpool.status      |pgpool-II processes working state, vip existence or non-existence                                |
|pgpool.watchdog    |pgpool-II processes working state, vip existence or non-existence as a cluster                   |


### Improve performance of gathering monitoring items
Previously, pg_monz accesses the monitoring DB every when gathering one monitoring item about DB, which may affect the performance of monitoring DB.
With this update, to reduce the frequency of DB accesse, pg_monz gathers collectable monitoring items all at once.


System requirements
-------------------
pg_monz requires the following software products:

* Zabbix server, zabbix agent, zabbix sender 2.0 or later
* PostgreSQL 9.2 or later
* pgpool-II 3.4.0 or later


Installation and usage
----------------------
Please see the included quick-install.txt.  
pg_monz 2.0 does not have backward compatibility with the 1.0. When upgrading from 1.0, please install the new version again.


License
-------
pg_monz is distributed under the Apache License Version 2.0.
See the LICENSE file for details.

Copyright (C) 2013-2015 SRA OSS, Inc. Japan All Rights Reserved.  
Copyright (C) 2013-2015 TIS Inc. All Rights Reserved.
