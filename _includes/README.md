## pg_monz とは {#about}

PostgreSQL monitoring template for Zabbix (pg_monz) は、ZabbixでPostgreSQLの各種監視を行うためのテンプレートです。

### pg_monzの目的

pg_monzを導入することで、PostgreSQLの死活監視、リソース監視、性能監視などが行えます。
PostgreSQL単体で稼働するシングル構成の状態、PostgreSQLのStreaming Replicationを使った冗長構成の状態、pgpool-IIを使った負荷分散構成の状態の監視を行うことができ、PostgreSQLを運用する様々な環境の監視を行うことができます。
PostgreSQL環境の監視を行えるようにすることで、障害発生時の自動復旧処理に活用できたり、長期的な運用時の状態の変化の認知に有効に働きます。

### pg_monz version 1.0からの変更点

pg_monzはversion 1.0として2013年12月に初期版をリリースしました。
version 1.0では、単一のPostgreSQLの状態の死活監視、リソース監視、性能監視にのみ対応していました。
2015年4月にリリースしたversion2.0では以下の変更を含んでいます。

#### （1）機能面での変更

version 1.0では、単一のPostgreSQLの監視のみをサポートしていましたが、2.0では、単一のPostgreSQLの監視に加えてStreaming Replicationを使った冗長構成環境の監視やpgpool-IIを使った負荷分散構成環境の監視にも対応しています。

#### （2）性能面での変更

version 1.0では、各監視項目の監視処理の実行の都度Zabbix AgentがPostgreSQLサーバにpsqlコマンドを用いてコネクションを張り、SQL文を実行するというアーキテクチャでした。
この方法では監視項目が増えた時や監視間隔を短く設定した際に非常に多くのコネクションが発生しPostgreSQLの通常の稼働に影響を及ぼし兼ねない構成となっていました。
そこで、version 2.0では一度のコネクションで監視対象の値を一括取得できるようバックエンド処理を改善しています。

具体的な処理のイメージは[pg_monzの動作イメージ]の項目を参照して下さい。

### pg_monzの構成

pg_monz は以下の内容で構成されています。

|ディレクトリ/ファイル                  |役割  　                        |
|-------------------------|-------------------------------|
|Template     |pg_monz監視設定テンプレート                   |
|usr-local-bin/* |pg_monzのバックエンド処理スクリプト群  |
|usr-local-etc/* |pg_monzのバックエンド処理用設定ファイル群   |
|zabbix-agentd.d/userparameter_pgsql.conf |ZabbixAgentに追加するUserParameter定義ファイル |

#### （1）テンプレート

Templateディレクトリには以下の5つの監視テンプレートxmlが含まれています。

|テンプレート名|用途|
|--------------|----|
|Template_App_PostgreSQL.xml|PostgreSQLサーバ単体の稼働監視用|
|Template_App_PostgreSQL_SR.xml|Streaming Replication稼働監視用|
|Template_App_PostgreSQL_SR_Cluster.xml|Streaming Replicationのクラスタ全体での稼働状況監視用|
|Template_App_pgpool-II.xml|pgpool-II稼働監視用|
|Template_App_pgpool-II_watchdog.xml|pgpool-IIのクラスタ全体での稼働状況監視用|

#### （2）バックエンド処理スクリプト

usr-local-binディレクトリにはpg_monzによる監視処理に必要なバックエンド処理用スクリプトが含まれています。
後述するZabbix Agentに追加定義されたUserParameterから呼び出されます。

#### （3）バックエンド処理用設定ファイル

上記バックエンド処理を実行する際に必要となる監視先のPostgreSQLのホストIPアドレスやポート番号等の設定を行います。
含まれるファイルは以下の2ファイル。

* pgsql_funcs.conf : PostgreSQLサーバへの接続情報設定ファイル
* pgpool_funcs.conf : pgpool-IIへの接続情報設定ファイル

__【注意】 Version1.0ではZabbixのマクロにて設定していた項目ですが、Version2.0からは設定ファイルに定義する形に仕様変更となっています。環境にあわせて上記設定ファイルの変更が必要となります。__

#### （4）UserParameter定義設定ファイル

pg_monz用監視テンプレートに含まれる監視アイテムキーに対するUserParameter定義設定ファイルです。

## リリースノート {#releases}

* [2015/03/31 ver.2.0](https://github.com/pg-monz/pg_monz/releases/tag/2.0)
* [2014/11/17 ver.1.0.1](https://github.com/pg-monz/pg_monz/releases/tag/1.0.1)
* [2013/11/05 ver.1.0.0](https://github.com/pg-monz/pg_monz/releases/tag/1.0)

## ダウンロード {#download}

[Download from GitHub releases page](https://github.com/pg-monz/pg_monz/releases)

## 動作環境 {#software}

pg_monz は以下のソフトウェアバージョンをサポートしています。 
なお、監視には Zabbix AgentおよびZabbix Senderの機能を利用するため、
監視対象のサーバーに Zabbix AgentおよびZabbix Sender を導入しておく必要があります。

|ソフトウェア名|バージョン|
|----------|-------|
|Zabbix Server,Zabbix Agent, Zabbix Sender|2.0 以上|
|PostgreSQL|9.2 以上|
|pgpool-II|3.4.0以上|

## 動作イメージ {#flow}

pg_monz version2は各パターン毎に以下のようなアーキテクチャで監視処理を実施します。

### PostgreSQLサーバ単体の監視パターン

![process_flow_single]({{ production_url }}/assets/images/pg_monz_process_flow_single.png)

* (1) Zabbix agentタイプのアイテム(アイテムキー: psql.get.～のアイテム)により監視データ一括取得の処理が定期的に実行されます。
* (2) バックエンドではUserParameterの定義内容に従い、情報一括収集用のpg_monzスクリプトが実行されます。
* (3) スクリプト内ではpsqlコマンドを実行しDBから情報収集します。
* (4) (3)で収集した情報をzabbix_senderコマンドに渡して実行します。
* (5) zabbix_senderにより送られてきたデータをZabbix trapperアイテムに登録します。

この繰り返しにより監視を実現します。

### PostgreSQL Streaming Replication監視パターン

![process_flow_sr]({{ production_url }}/assets/images/pg_monz_process_flow_sr.png)

Streaming Replication監視を実施するには、Streaming Replication監視用のテンプレートをホストに割り当てます。  
Streaming Replication監視用のテンプレートはPostgreSQLサーバ単体の稼働監視用テンプレートの内容をリンクしているため、
(1)～(5)のバックエンドの処理方式は単体の監視パターンと同様です。

1点単体の時と異なるのは、クラスタ全体の状態を示す監視結果を格納するホストを1つ追加登録し、クラスタ監視用のテンプレート(Template App PostgreSQL Cluster)を割り当てることです。
このテンプレートを割り当てることで定期的に各PostgreSQLサーバの監視結果の情報をアグリゲート(6)してクラスタの状態を示すデータとして管理します。


### pgpool-II監視パターン

![process_flow_pgpool]({{ production_url }}/assets/images/pg_monz_process_flow_pgpool.png)

pgpool-II監視を実施するには、各pgpool-IIサーバに対するホストを登録し、pgpool-II監視用テンプレート(Template App pgpool-II)を割り当てます。
このテンプレートを登録することで以下の監視処理が行われます。

* (1) Zabbix agentタイプのアイテム(アイテムキー: pgpool.get.～のアイテム)により監視データ一括取得の処理が定期的に実行されます。
* (2) バックエンドではUserParameterの定義内容に従い、情報一括収集用のpg_monzスクリプトが実行されます。
* (3) スクリプト内ではpgpool-IIに対してpsqlコマンドを実行し、情報を収集します。
* (4) (3)で収集した情報をzabbix_senderコマンドに渡して実行します。
* (5) zabbix_senderにより送られてきたデータをZabbix trapperアイテムに登録します。

Streaming Replication監視パターンと同様、クラスタ全体の状況を監視するテンプレート(Template App pgpool-II watchdog)を割り当てることで各pgpool-IIの稼働状況を監視した結果をアグリゲート(6)して管理することができます。

##インストール手順 {#install}

###0.事前準備

####（1）Zabbixエージェントの設定

pg-monzでは監視対象サーバにおいて、Zabbixエージェントが以下を実行します。  

* PostgreSQLログ、pgpoolログの参照  
* スクリプトの実行  

Zabbixエージェントがこれらを実行可能なように監視対象サーバおよびZabbixエージェントの権限を適切に設定してください。  


####（2）Zabbix Senderの導入

「動作環境」に記したとおり、pg-monzではZabbix Agentの他、Zabbix Senderを利用します。
監視対象サーバにZabbix Senderがインストールされていない場合、「zabbix-sender」パッケージをインストールしてください。  


###1. 設定ファイル、スクリプトの配置

####（1）設定ファイルの配置

pg-monzパッケージに含まれる「usr-local-etc」フォルダ配下にある設定ファイルを、監視対象サーバ上の任意の場所にコピーします。  
デフォルトでは/usr/local/etc/ 以下にインストールされることを想定しています。

{% highlight bash %}
cp usr-local-etc/* /usr/local/etc
{% endhighlight %}

必要に応じて設定ファイルの値を修正します。  

#####pgsql_func.conf

{% highlight properties %}
PGHOST=127.0.0.1  
PGPORT=5432  
PGROLE=postgres  
PGDATABASE=postgres
{% endhighlight %}

#####pgpool_func.conf

{% highlight properties %}
PGPOOLHOST=127.0.0.1  
PGPOOLPORT=9999  
PGPOOLROLE=postgres  
PGPOOLDATABASE=postgres  
PGPOOLCONF=/usr/local/etc/pgpool.conf 
{% endhighlight %}


####（2）スクリプトの配置

pg-monzパッケージに含まれる「usr-local-bin」フォルダ配下にあるスクリプトを、監視対象サーバ上の任意の場所にコピーし、実行権限を付与します。  
デフォルトでは/usr/local/bin/ 以下にインスールされることを想定しています。

{% highlight bash %}
cp usr-local-bin/* /usr/local/bin  
chmod +x /usr/local/bin/*.sh
{% endhighlight %}

####（3）userparameter_pgsql.confの配置

エージェント用ユーザパラメータ設定ファイル（userparameter_pgsql.conf）を、監視対象サーバ上の所定の場所にコピーします。  
例えば、 Zabbixエージェントが /etc/zabbix/にインストールされている場合は、以下の場所にファイルをコピーします。

{% highlight bash %}
/etc/zabbix/zabbix_agentd.conf.d/userparameter_pgsql.conf
{% endhighlight %}


また、上記ファイルが読み込まれるよう zabbix_agentd.conf でInclude 設定を追加します。
※設定の反映には再起動が必要です。

{% highlight properties %}
Include=/etc/zabbix/zabbix_agentd.conf.d/
{% endhighlight %}

###2. テンプレートインポート
ZabbixのWebインターフェースにログインし、以下の手順でテンプレートをインポートします。

1. [設定] - [テンプレート]を選択し、テンプレート一覧を表示します。
2. 画面右上の[インポート]をクリックして表示される画面で、xmlファイルを順番にインポートします。  
   対象のxmlファイルはpg-monzパッケージの「Template」ディレクトリの配下に格納されている全てのxmlファイルです。  
3. インポートに成功すると、テンプレート一覧にpgmonzのtemplate類が追加されます。

### 3.マクロの設定
テンプレートに定義されているマクロの値を必要に応じて修正します。  
ZabbixのWebインターフェースの[設定]→[テンプレート]→[マクロ]を選択し、値を修正後、[保存]をクリックします。 

#####Template App PostgreSQL

|マクロ                    |デフォルト値                  |説明                                            |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGCACHEHIT_THRESHOLD}   |90                            |キャッシュヒット率トリガー閾値（%)              |
|{$PGCHECKPOINTS_THRESHOLD}|10                            |checkpoint発生頻度トリガー閾値（回数/監視間隔） |
|{$PGCONNECTIONS_THRESHOLD}|95                            |バックエンドコネクション数トリガー閾値          |
|{$PGDBSIZE_THRESHOLD}     |1073741824                    |データベースサイズトリガー閾値（byte）          |
|{$PGDEADLOCK_THRESHOLD}   |0                             |デッドロック発生トリガー閾値（回数）            |
|{$PGLOGDIR}               |/usr/local/pgsql/data/pg_log  |PostgreSQLログディレクトリ                      |
|{$PGSCRIPTDIR}            |/usr/local/bin                |pg-monzスクリプト配置ディレクトリ               |
|{$PGSCRIPT_CONFDIR}       |/usr/local/etc                |pg-monz設定ファイル配置ディレクトリ             |
|{$PGSLOWQUERY_TIME_THRESHOLD}  |10                       |何秒以上のクエリをSlow_Queryとするか（秒）      |
|{$PGSLOWQUERY_COUNT_THRESHOLD}  |10                      |slow_queryトリガー閾値（件数）                  |
|{$PGTEMPBYTES_THRESHOLD}  |8388608                       |一次ファイルサイズトリガー閾値（byte）          |
|{$ZABBIX_AGENTD_CONF}     |/etc/zabbix/zabbix_agentd.conf|zabbix_agentd.confファイルパス                  |

#####Template App PostgreSQL SR

|マクロ                    |デフォルト値                  |説明                                            |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGSCRIPTDIR}            |/usr/local/bin                |pg-monzスクリプト配置ディレクトリ               |
|{$PGSCRIPT_CONFDIR}       |/usr/local/etc                |pg-monz設定ファイル配置ディレクトリ             |

#####Template App pgpool-II

|マクロ                    |デフォルト値                  |説明                                            |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGPOOLLOGDIR}           |/var/log/pgpool               |pgpool-IIログディレクトリ                       |
|{$PGPOOLSCRIPTDIR}        |/usr/local/bin                |pg-monzスクリプト配置ディレクトリ               |
|{$PGPOOLSCRIPT_CONFDIR}   |/usr/local/etc                |pg-monz設定ファイル配置ディレクトリ             |
|{$ZABBIX_AGENTD_CONF}     |/etc/zabbix/zabbix_agentd.conf|zabbix_agentd.confファイルパス                  |

#####Template App pgpool-II watchdog

|マクロ                    |デフォルト値                  |説明                                            |
|--------------------------|------------------------------|------------------------------------------------|
|{$PGPOOL_HOST_GROUP}      |pgpool                        |pgpoolホストグループ名                          |

#####Template App PostgreSQL SR Cluster

|マクロ                    |デフォルト値                  |説明                                            |
|--------------------------|------------------------------|------------------------------------------------|
|{$PG_HOST_GROUP}          |PostgreSQL                    |PostgreSQLホストグループ名                      |


###4. ホストの作成
ZabbixのWebインターフェース上で監視対象となるホストおよびホストグループを作成します。

####ホストーテンプレートーシステム構成の関係
監視対象システムのシステム構成によって適用するテンプレートが異なります。
以下に示すシステム構成毎の適用パターンに沿ってzabbixフロントエンドでホストを作成します。

![template_pattern]({{ production_url }}/assets/images/template_pattern.png)

####PostgreSQLホスト・ホストグループの作成

1. [設定] - [ホスト]を選択し、ホスト一覧を表示します。 
2. 右上の[ホストの作成]をクリックしPostgreSQLサーバのホスト名等を設定します。 
3. [テンプレート] - [新規テンプレートをリンク]より、適用するテンプレート(※）を検索して[追加]、[保存]をクリックします。  
   ※「Template App PostgreSQL」か「Template App PostgreSQL SR」のいずれか  
4. [設定] - [ホストグループ] - [ホストグループの作成]をクリックし、グループ名に「PostgreSQL」、グループに含まれるホストに作成したPostgreSQLホストを追加し、[保存]をクリックします。

####pgpool-IIホスト・ホストグループの作成

1. [設定] - [ホスト]を選択し、ホスト一覧を表示します。 
2. 右上の[ホストの作成]をクリックし、pgpool-IIサーバのホスト名等を設定します。 
3. [テンプレート] - [新規テンプレートをリンク]より、「Template App pgpool-II」を検索して[追加]、[保存]をクリックします。  
4. [設定] - [ホストグループ] - [ホストグループの作成]をクリックし、グループ名に「pgpool」、グループに含まれるホストに作成したpgpool-IIホストを追加し、[保存]をクリックします。

####PostgreSQL Clusterホストの作成

1. [設定] - [ホスト]を選択し、ホスト一覧を表示します。 
2. 右上の[ホストの作成]をクリックし、ホスト名に「PostgreSQL Cluster」と入力します。 
3. [テンプレート] - [新規テンプレートをリンク]より、適用するテンプレート（※）検索して[追加]、[保存]をクリックします。 
   ※「Template App pgpool-II watchdog」、「Template App PostgreSQL SR Cluster」の両方、またはいずれか
4. [設定] - [ホストグループ] - [ホストグループの作成]をクリックし、グループ名に「PostgreSQL Cluster」、グループに含まれるホストに作成したホストを追加し、[保存]をクリックします。


## 監視項目 {#items}

####監視項目概要

##### PostgreSQL の監視に関連するアプリケーション

|アプリケーション名 |監視内容の概要                                                                          |
|:------------------|----------------------------------------------------------------------------------------|
|pg.transactions    |PostgreSQL への接続数、接続状態、トランザクション量                                     |
|pg.log             |PostgreSQL のログ監視                                                                   |
|pg.size            |各 DB のサイズと不要領域の回収率                                                        |
|pg.slow_query      |設定した閾値を超えたスロークエリ数                                                      |
|pg.status          |PostgreSQL のプロセス稼働状況                                                           |
|pg.stat_database   |データベース単位の稼働状況                                                              |
|pg.stat_table      |テーブル単位の稼働状況                                                                  |
|pg.bgwriter        |バッファの書き出し状況                                                                  |
|pg.stat_replication|ストリーミングレプリケーション構成時のデータ伝搬の遅延状況                              |
|pg.sr.status       |ストリーミングレプリケーション構成時のコンフリクト数、書き込みブロックの有無、プロセス数|
|pg.cluster.status  |クラスタ単位の PostgreSQL プロセス数                                                    |

##### pgpool-II の監視に関連するアプリケーション

|アプリケーション名 |監視内容の概要                                                                          |
|:------------------|----------------------------------------------------------------------------------------|
|pgpool.cache       |インメモリクエリキャッシュ使用時のキャッシュ状況                                        |
|pgpool.connections |pgpool-II を介したフロントエンド、バックエンドのコネクション数                          |
|pgpool.log         |pgpool-II のログ監視                                                                    |
|pgpool.nodes       |pgpool-II から見た各バックエンドの稼働状況、負荷分散の比率                              |
|pgpool.status      |pgpool-II のプロセス稼働状況、仮想 IP 保持状況                                          |
|pgpool.watchdog    |クラスタ単位の pgpool-II のプロセス稼働状況、仮想 IP 保持状況                           |

####監視項目詳細

* [監視アイテム一覧]({{ production_url }}/assets/docs/item_list.pdf)
* [トリガー一覧]({{ production_url }}/assets/docs/trigger_list.pdf)

## 問い合わせ先 {#contact}

pg_monzユーザーグループ  
<pg_monz@googlegroups.com>

## ライセンス {#license}

pg_monz は Apache License Version 2.0 の元で配布されています。  
Apache License Version 2.0 の全文は [こちら](http://www.apache.org/licenses/LICENSE-2.0) からご覧頂くことが可能です。

Copyright (C) 2013-2015 SRA OSS, Inc. Japan All Rights Reserved.  
Copyright (C) 2013-2015 TIS Inc. All Rights Reserved.
