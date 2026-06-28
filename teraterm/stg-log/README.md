# Tera Term STG Log Macro

Tera Termで踏み台、アプリ操作ホスト、Kubernetes Nodeを順にたどり、選択したPodに対応するNode上の最新ログを確認するためのマクロです。

## ファイル

- `stg_log_auto.ttl`: Tera Termで実行するマクロ本体
- `remote_stg_log.sh`: サーバ上へ一時アップロードされ、Pod選択とログ確認を行うshell

## Sendlnとは

`sendln`はTera Term Macroの命令です。

```ttl
sendln 'ssh host1'
```

これは、Tera Termの画面に`ssh host1`と入力してEnterを押すのと同じです。  
このマクロでは、SSHコマンド、`su - rcuser`、helper scriptの実行コマンドを順番に送るために使っています。

## 実行前に設定する場所

`stg_log_auto.ttl`の先頭にある以下の値を、会社PC上で実環境の値に置き換えます。

```ttl
BASTION_HOST = '<BASTION_HOST>'
APP_HOST = '<APP_HOST>'
FRONT_NAMESPACE = '<FRONT_NAMESPACE>'
BACK_NAMESPACE = '<BACK_NAMESPACE>'
FRONT_POD_PATTERN = '<FRONT_POD_NAME_KEYWORD>'
BACK_POD_PATTERN = '<BACK_POD_NAME_KEYWORD>'
FRONT_LOG_DIR = '<FRONT_LOG_DIR>'
BACK_LOG_DIR = '<BACK_LOG_DIR>'
FRONT_LOG_GLOB = '<FRONT_LOG_FILE_GLOB>'
BACK_LOG_GLOB = '<BACK_LOG_FILE_GLOB>'
```

パスワードはファイルに書きません。実行時に入力します。

## 処理の流れ

1. Tera Termから踏み台ホストへSSH接続
2. 踏み台からアプリ操作ホストへSSH接続
3. `su - rcuser`でユーザー切り替え
4. `remote_stg_log.sh`を`/tmp/stg_log_auto.sh`へアップロード
5. `front`または`back`の設定でhelper scriptを実行
6. `kubectl get pod -n <namespace> -o wide`でPod一覧を表示
7. Running Pod候補を番号付きで表示
8. ユーザーが番号、Pod名、またはPod名の一部を入力
9. 選択Podから`.spec.nodeName`を取得
10. NodeへSSH
11. ログディレクトリへ移動
12. 最新の`.log`を`tail -n 120`

## Pod選択

Podが複数ある前提です。マクロは勝手に1つへ決め切りません。

実行中に候補が表示されたあと、次のどれかを入力できます。

- `1`: 表示された1番目のPod
- 完全なPod名
- Pod名の一部

Pod名の一部が複数に一致した場合は、曖昧として止まります。

## 以前の読みにくい記述について

前の版では、サーバ上で実行するshell scriptをbase64文字列としてTTL内に埋め込んでいました。  
これは引用符の壊れやすさを避けるためでしたが、人間には読みにくいので廃止しました。

今の版では、Tera Term側の手続きは`stg_log_auto.ttl`、サーバ側の手続きは`remote_stg_log.sh`に分離しています。
