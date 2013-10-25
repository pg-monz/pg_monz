PostgreSQL monitoring template for Zabbix (pg_monz) とは
========================================================

PostgreSQL monitoring template for Zabbix (pg_monz) は、Zabbix で PostgreSQL の各種監視を行うためのテンプレートで、
PostgreSQL の死活監視、リソース監視、性能監視などが行えます。  
また、Zabbix のディスカバリ機能を利用し、データベースやテーブルを自動検出し、自動で監視を開始することができます。

pg_monz は以下の内容で構成されています。

|ファイル名               |役割                                       |
|-------------------------|-------------------------------------------|
|pg_monz_template.xml     |監視テンプレート                           |
|userparameter_pgsql.conf |エージェント用ユーザパラメータ設定ファイル |
|find_dbname.sh           |データベースディスカバリスクリプト         |
|find_dbname_table.sh     |テーブルディスカバリスクリプト             |

リリースノート
==========

* 2013/11/05 ver.1.0

動作環境
========

pg_monz を使用するには以下のソフトウェアが必要です。

* Zabbix 2.0 以上
* PostgreSQL 9.2 以上

インストール方法
================

上記ソフトウェアのインストール、設定が既に完了していることを前提とします。

1. 設定ファイル、スクリプトのインストール
-----------------------------------------

userparameter_pgsql.conf 設定ファイルを Zabbix エージェントがインストールされているマシンの所定の場所にコピーします。  
例えば、 Zabbix エージェントが /usr/local/zabbix/ にインストールされている場合は、以下の場所にファイルをコピーします。

    /usr/local/zabbix/etc/zabbix_agentd.conf.d/userparameter_pgsql.conf

また、上記ファイルが読み込まれるよう zabbix_agentd.conf でInclude 設定を追加します。  
※設定の反映には再起動が必要です。

    Include=/usr/local/zabbix/etc/zabbix_agentd.conf.d/

次に、ディスカバリで使用するスクリプトをコピーし、実行権限を付加します。  
デフォルトでは /usr/local/bin 以下にインストールされることを想定しています。

    # cp find_dbname.sh find_dbname_table.sh /usr/local/bin
    # chmod +x /usr/local/bin/find_dbname.sh
    # chmod +x /usr/local/bin/find_dbname_table.sh

2. テンプレートのインポート
---------------------------

Zabbix の Web 管理画面にログインし、テンプレートをインポートします。

タブの「設定 (Configuration)」 - 「テンプレート (Templates)」を選択し、
テンプレート一覧を表示します。

右上の「インポート (Import)」をクリックします。

「インポートするファイル (Import file)」に pg_monz_template.xml を指定し、
「インポート (Import)」をクリックします。

インポートに成功すると、テンプレート一覧に「PostgreSQL Check」が追加されます。

3. テンプレートのマクロの設定
-----------------------------

実際の環境にあわせて、テンプレートのマクロの設定を修正します。

テンプレート一覧の「PostgreSQL Check」をクリックし、「マクロ (Macros)」タブを選択します。

各マクロの値を環境にあわせて修正し、「保存 (Save)」をクリックします。

通常修正する必要があるマクロは以下の通りです。

|マクロ名       |設定内容                                                             |
|---------------|---------------------------------------------------------------------|
|{$PGDATABASE}  |接続するデータベース名                                               |
|{$PGHOST}      |PostgreSQL のホスト(Zabbix エージェントと同一ホストの場合 127.0.0.1) |
|{$PGLOGDIR}    |PostgreSQL のログファイルが格納されているディレクトリ                |
|{$PGPORT}      |ポート番号                                                           |
|{$PGROLE}      |PostgreSQL のユーザ名                                                |
|{$PGSCRIPTDIR} |スクリプトを配置したディレクトリ                                     |

使用方法
========

実際に監視を行うまでの流れを説明します。

1. PostgreSQL ホストの作成
--------------------------

PostgreSQL ホストを作成します。

タブの「設定 (Configuration)」 - 「ホスト (Hosts)」を選択し、ホスト一覧を表示します。

右上の「ホストの作成 (Create host)」をクリックし、ホスト名、グループ等を適切に設定します。

「テンプレート (Templates)」タブを選択して「追加 (Add)」をクリックし、
「PostgreSQL Check」を選択して「選択 (Select)」をクリックします。

「保存 (Save)」をクリックします。

2. 監視結果の確認
-----------------

正しく設定された場合、しばらくすると自動的に監視が開始されます。

タブの「監視データ (Monitoring)」 - 「最新データ (Latest data)」を選択します。  
監視データが取得できている場合、上記で登録したホストが一覧に表示されます。  
左の「+」をクリックすると、取得した各項目の最新の値が表示されます。

なお、データベース名のディスカバリはデフォルトで1時間ごとに実行されるため、  
データベース単位の監視項目の反映にはしばらく時間がかかります。


各アイテムの説明
================


ライセンス
==========

pg_monz は Apache License Version 2.0 の元で配布されています。  
ライセンスの内容は LICENSE ファイルを参照して下さい。
