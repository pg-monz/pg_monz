pg_monz 2.0
============================
pg_monz (PostgreSQL monitoring template for Zabbix) は、Zabbix で PostgreSQL の各種監視を行うためのテンプレートで、
PostgreSQL の死活監視、リソース監視、性能監視などが行えます。  
また、Zabbix のディスカバリ機能を利用し、データベースやテーブルを自動検出し、自動で監視を開始することができます。


1.0 からの主な変更点
--------------------
1.0 からの主な変更点は以下の通りです。


### PostgreSQL ストリーミングレプリケーションの監視に対応
PostgreSQL の組み込み機能であるストリーミングレプリケーションを利用した DB 構成の監視がサポートされました。  
Primary / Standby サーバの死活監視や、レプリケーション先へのデータ伝搬の遅延状況、Primary と Standby の DB 操作によって発生する可能性のあるコンフリクト状況などの監視が行えます。
また、同期レプリケーション実行時に Standby サーバの障害によって発生する書き込みブロックを検知するトリガーが設定されています。


### pgpool-II の監視に対応
PostgreSQL 専用ミドルウェアである pgpool-II の監視がサポートされました。  
pgpool-II の主な機能である、コネクションプーリング・レプリケーション・インメモリクエリキャッシュ・負荷分散・PostgreSQL の自動フェイルオーバに対応した各種監視項目およびトリガーが設定されています。

pgpool-II に関する詳細な情報は、[pgpool-II ユーザマニュアル](http://www.pgpool.net/mediawiki/jp/index.php/%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8)、[Pgpool Wiki](http://www.pgpool.net/mediawiki/jp/index.php/%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8) を参照してください。


### PostgresQL + pgpool-II クラスタ構成の監視に対応
PostgreSQL のストリーミングレプリケーション、または pgpool-II や pgpool-II 自身の冗長化を行う watchdog 機能を利用している複数のサーバを 1 つのクラスタ構成とした監視も可能です。
Postgres、pgpoo-II プロセスの監視を通して、スプリットブレインの検知や、フェイルオーバを検知するトリガーが設定されています。


### 監視項目のグルーピング
監視項目がアプリケーション毎にグルーピングし、わかりやすく整理されました。  
主なアプリケーションは以下の通りです。


#### PostgreSQL の監視に関連するアプリケーション
|アプリケーション名 |監視内容の概要                                                                          |
|:------------------|----------------------------------------------------------------------------------------|
|pg.transactions    |PostgreSQL への接続数、接続状態、トランザクションのコミット、ロールバック数             |
|pg.log             |PostgreSQL のログ監視                                                                   |
|pg.size            |各 DB のサイズと不要領域の回収率                                                        |
|pg.slow_query      |設定した閾値を超えたスロークエリ数                                                      |
|pg.sr.status       |ストリーミングレプリケーション構成時のコンフリクト数、書き込むブロックの有無、プロセス数|
|pg.status          |PostgreSQL のプロセス稼働状況                                                           |
|pg.stat_replication|ストリーミングレプリケーション構成時のデータ伝搬の遅延状況                              |
|pg.cluster.status  |クラスタ単位の PostgreSQL プロセス数                                                    |


#### pgpool-II の監視に関連するアプリケーション
|アプリケーション名 |監視内容の概要                                                                          |
|:------------------|----------------------------------------------------------------------------------------|
|pgpool.cache       |インメモリクエリキャッシュ使用時のキャッシュ状況                                        |
|pgpool.connections |pgpool-II を介したフロントエンド、バックエンドのコネクション数                          |
|pgpool.log         |pgpool-II のログ監視                                                                    |
|pgpool.nodes       |pgpool-II から見た各バックエンドの稼働状況、負荷分散の比率                              |
|pgpool.status      |pgpool-II のプロセス稼働状況、仮想 IP 保持状況                                          |
|pgpool.watchdog    |クラスタ単位の pgpool-II のプロセス稼働状況、仮想 IP 保持状況                           |


### アイテム収集時のパフォーマンス改善
1.0 までは、DB に関する監視アイテムのデータを 1 つ取得する都度 DB に接続を行っており、監視対象の DB 負荷に影響を与える可能性がありました。  
2.0 では、まとめて取得可能なデータは 1 度の DB 接続で取得するようになり、DB 接続頻度が減少しました。


動作環境
--------
pg_monz を使用するには以下のソフトウェアが必要です。

* Zabbix server, zabbix agent, zabbix sender 2.0 以上
* PostgreSQL 9.2 以上
* pgpool-II 3.4.0 以上


インストール方法、使用方法
--------------------------
同梱の quick-install.txt を参照してください。  
1.0 との後方互換性は保たれていません。1.0 からアップグレードする場合は 2.0 を再インストールしてください。


ライセンス
----------
pg_monz は Apache License Version 2.0 の元で配布されています。  
ライセンスの内容は LICENSE ファイルを参照して下さい。

Copyright (C) 2013-2015 SRA OSS, Inc. Japan All Rights Reserved.  
Copyright (C) 2013-2015 TIS Inc. All Rights Reserved.
