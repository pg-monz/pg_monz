# pg_monz とは {#about}

PostgreSQL monitoring template for Zabbix (pg_monz) は、Zabbix で PostgreSQL の各種監視を行うためのテンプレートで、PostgreSQL の死活監視、リソース監視、性能監視などが行えます。  
また、Zabbix のディスカバリ機能を利用し、データベースやテーブルを自動検出し、自動で監視を開始することができます。

pg_monz は以下の内容で構成されています。

|ファイル名                  |役割  　                        |
|-------------------------|-------------------------------|
|pg_monz_template.xml     |監視テンプレート                   |
|userparameter_pgsql.conf |エージェント用ユーザパラメータ設定ファイル  |
|find_dbname.sh           |データベースディスカバリスクリプト         |
|find_dbname_table.sh     |テーブルディスカバリスクリプト            |

# リリースノート {#releases}

* 2013/11/05 ver.1.0

# 動作環境 {#software}

pg_monz を使用するには以下のソフトウェアが必要です。  
なお、PostgreSQL の情報取得に Zabbix Agent の機能を利用するため、
監視対象のサーバーに Zabbix Agent を導入しておく必要があります。

|ソフトウェア名|バージョン|
|----------|-------|
|Zabbix    |2.0 以上|
|PostgreSQL|9.2 以上|

# インストール方法 {#install}

上記ソフトウェアのインストール、設定が既に完了していることを前提とします。

## 1. 設定ファイル、スクリプトのインストール

エージェント用ユーザパラメータ設定ファイル（userparameter_pgsql.conf）を Zabbix エージェントがインストールされているマシンの所定の場所にコピーします。  
例えば、 Zabbix エージェントが /usr/local/zabbix/ にインストールされている場合は、以下の場所にファイルをコピーします。

{% highlight bash %}
/usr/local/zabbix/etc/zabbix_agentd.conf.d/userparameter_pgsql.conf
{% endhighlight %}

また、上記ファイルが読み込まれるよう zabbix_agentd.conf でInclude 設定を追加します。  
※設定の反映には再起動が必要です。

{% highlight properties %}
Include=/usr/local/zabbix/etc/zabbix_agentd.conf.d/
{% endhighlight %}

次にディスカバリで使用するスクリプトをコピーし、実行権限を付加します。  
デフォルトでは /usr/local/bin 以下にインストールされることを想定しています。

{% highlight bash %}
cp find_dbname.sh find_dbname_table.sh /usr/local/bin
chmod +x /usr/local/bin/find_dbname.sh
chmod +x /usr/local/bin/find_dbname_table.sh
{% endhighlight %}

## 2. テンプレートのインポート

Zabbix の Web 管理画面にログインし、以下の手順でテンプレートをインポートします。

タブの「設定 (Configuration)」 - 「テンプレート (Templates)」を選択し、テンプレート一覧を表示します。
![template_list]({{ site.production_url }}/assets/images/template_list.png)
右上の「インポート (Import)」をクリックして表示される画面で、「インポートするファイル (Import file)」に pg_monz_template.xml を選択して「インポート (Import)」をクリックします。
![template_import]({{ site.production_url }}/assets/images/template_import.png)
インポートに成功すると、テンプレート一覧に「PostgreSQL Check」が追加されます。
![template_imported]({{ site.production_url }}/assets/images/template_imported.png)

## 3. テンプレートのマクロの設定

テンプレートを適用する環境にあわせて、以下の手順でテンプレートのマクロの設定を修正します。

タブの「設定 (Configuration)」 - 「テンプレート (Templates)」を選択して表示された
テンプレート一覧から「PostgreSQL Check」をクリックし、「マクロ (Macros)」タブを選択します。
![template_macro]({{ site.production_url }}/assets/images/template_macro.png)
各マクロの値を環境にあわせて修正した後、「保存 (Save)」をクリックします。  
通常修正する必要があるマクロは以下の通りです。

|マクロ名       |設定内容                                                             |
|---------------|---------------------------------------------------------------------|
|{$PGDATABASE}  |接続するデータベース名                                               |
|{$PGHOST}      |PostgreSQL のホスト(Zabbix エージェントと同一ホストの場合 127.0.0.1) |
|{$PGLOGDIR}    |PostgreSQL のログファイルが格納されているディレクトリ                |
|{$PGPORT}      |ポート番号                                                           |
|{$PGROLE}      |PostgreSQL のユーザ名                                                |
|{$PGSCRIPTDIR} |スクリプトを配置したディレクトリ                                     |

# 使用方法 {#usage}

インポートしたテンプレートを使って、実際に監視を行うまでの流れを説明します。

## 1. PostgreSQL ホストの作成

PostgreSQL ホストを作成します。

タブの「設定 (Configuration)」 - 「ホスト (Hosts)」を選択し、ホスト一覧を表示します。
![host_list]({{ site.production_url }}/assets/images/host_list.png)
右上の「ホストの作成 (Create host)」をクリックし、監視対象のホスト名、グループ等を設定します。
![host_config]({{ site.production_url }}/assets/images/host_config.png)
「テンプレート (Templates)」タブを選択して「追加 (Add)」をクリックし、
「PostgreSQL Check」を選択して「選択 (Select)」、「保存 (Save)」をクリックします。
![host_template_select]({{ site.production_url }}/assets/images/host_template_select.png)

## 2. 監視結果の確認

正しく設定されていれば、しばらくすると自動的に監視が開始されます。  
監視結果を確認するには、タブの「監視データ (Monitoring)」 - 「最新データ (Latest data)」を選択します。

監視データが取得できている場合、上記で登録したホストが一覧に表示され、
ホスト名の左の「+」をクリックすると、取得した各項目の最新の値が表示されます。
![latest_items]({{ site.production_url }}/assets/images/latest_items.png)
なお、データベース名のディスカバリはデフォルトで1時間ごとに実行されるため、
データベース単位の監視項目の反映にはしばらく時間がかかります。

# 監視項目 {#items}

##　PostgreSQLサーバーの死活監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|Number of postgres process|PostgreSQLサーバーのプロセス稼働確認|
|アイテム|PostgreSQL service is running|PostgreSQLサーバーのSQL応答確認|
|トリガー|PostgreSQL process is not running.|PostgreSQLサーバーのプロセス数が0|
|トリガー|PostgreSQL service is not running.|PostgreSQLサーバーへのSQL実行に失敗|

## PostgreSQLのログ監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|Log of $1|サーバーログで PANIC,FATAL,ERROR を含むメッセージ|

## データベースサイズの監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|\[DB名\] DB Size|対象データベースの容量|
|トリガー|\[DB名\] DB Size is too large|データベース容量が閾値を超過|
|グラフ|\[DB名\] DB Size|対象データベースの容量遷移|

##　バックエンドプロセスの監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|Connections|バックエンドプロセス数（合計）|
|アイテム|Active (SQL processing) connections|パックエンドプロセス数（SQL処理中）|
|アイテム|Idle connections|バックエンドプロセス数（クライアントからの問い合わせ待ち）|
|アイテム|Idle in transaction connections|バックエンドプロセス数(トランザクション内でコマンド待ち状態)|
|アイテム|Lock waiting connections|バックエンドプロセス数(トランザクション内でロック待ち状態)|
|トリガー|Many connections are forked.|バックエンドプロセス数が閾値を超過|
|グラフ|Connection count|バックエンドプロセス数の遷移|

##　チェックポイント実行状況の監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|Checkpoint count (by checkpoint_segments)|checkpoint_segments超過によるチェックポイント実行回数|
|アイテム|Checkpoint count (by checkpoint_timeout)|checkpoint_timeout時間経過によるチェックポイント実行回数|
|トリガー|Checkpoints are occurring too frequently|一定期間のチェックポイント発生回数が閾値を超過|
|グラフ|Checkpoint count|チェックポイント発生回数の遷移|

## キャッシュヒット率の監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|\[DB名\] Cache Hit Ratio|対象データベースのキャッシュヒット率|
|トリガー|\[DB名\] Cache hit ratio is too low|対象データベースのキャッシュヒット率が閾値以下に低下|
|グラフ|\[DB名\] Cache Hit Ratio|対象データベースのキャッシュヒット率の遷移|

## デッドロックの発生状況監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|\[DB名\] Deadlocks|対象データベースでのデッドロック発生回数|
|トリガー|\[DB名\] Deadlocks occurred too frequently|対象データベースで閾値以上のデッドロックが発生|
|グラフ|\[DB名\] Deadlocks|対象データベースでのデッドロック発生回数の遷移|

## トランザクション処理状況の監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|\[DB名\] Commited transactions|対象データベースでのCOMMIT回数|
|アイテム|\[DB名\] Rolled back transactions|対象データベースでのROLLBACK回数|
|グラフ|\[DB名\] Number of commited/rolled back transactions|対象データベースでのCOMMIT/ROLLBACK回数の遷移|

## 一時ファイル発生状況の監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|\[DB名\] Temp bytes|対象データベースで一時ファイルに書き込んだデータのバイト数|
|トリガー|\[DB名\] Too many temp bytes|対象データベースでの一時ファイル出力が閾値を超過|
|グラフ|\[DB名\] Temp file size|対象データベースでの一時ファイル出力データ量の遷移|

## 滞留バックエンド処理の監視

|種別|Zabbixでの名前|アイテム,グラフの取得情報、トリガーの発生条件|
|--|--|--|
|アイテム|Slow queries|一定時間経過したバックエンドプロセス数(処理中)|
|アイテム|Slow DML queries|一定時間経過したバックエンドプロセス数(DML処理中)|
|アイテム|Slow select queries|一定時間経過したバックエンドプロセス数(SELECT処理中)|
|トリガー|Too many slow queries|一定時間経過したバックエンドプロセス数が閾値を超過|

# 問い合わせ先 {#contact}

pg_monzユーザーグループ
<pg_monz@googlegroups.com>

# ライセンス {#license}

pg_monz は Apache License Version 2.0 の元で配布されています。  
ライセンスの内容は LICENSE ファイルを参照して下さい。

