# Tera Term STG Log Macro

Tera Termで手動ログイン済みの踏み台から、アプリ操作ホスト、Kubernetes Nodeを順にたどり、front/backごとの固定ログを確認するためのマクロです。

## ファイル

- `stg_log_auto.ttl`: Tera Termで実行するマクロ本体
- `LINE_BY_LINE.md`: `stg_log_auto.ttl`の行番号ベース解説

この版は、踏み台、アプリ操作ホスト、Nodeへhelper fileを置きません。  
Tera Termマクロが、開いているterminalへ必要なコマンドを送るだけです。

## Sendlnとは

`sendln`はTera Term Macroの命令です。

```ttl
sendln 'ssh host1'
```

これは、Tera Termの画面に`ssh host1`と入力してEnterを押すのと同じです。
このマクロでは、SSHコマンド、`su - rcuser`、`kubectl`確認用のshell断片を順番に送るために使っています。

## 実行前に設定する場所

`stg_log_auto.ttl`の先頭にある以下の値を、会社PC上で実環境の値に置き換えます。
公開repoでは、値の意味が外から読みにくいように短い符号にしています。

```ttl
APP_HOST = '<H_A>'
FRONT_NAMESPACE = '<N_F>'
BACK_NAMESPACE = '<N_B>'
FRONT_LOG_DIR = '<D_F>'
BACK_LOG_DIR = '<D_B>'
FRONT_LOG_GLOB = '<G_F>'
BACK_LOG_GLOB = '<G_B>'
```

パスワードはファイルに書きません。実行時に入力します。

符号の意味:

- `H_A`: 踏み台からSSHする操作用ホスト
- `N_F` / `N_B`: front/backのnamespace
- `D_F` / `D_B`: front/backのログディレクトリ
- `G_F` / `G_B`: front/backのログファイルglob

## 処理の流れ

1. Tera Termを手動で開く
2. 既に入力されているホストでLDAPログインし、踏み台のshell promptまで進む
3. Tera Termメニューの`Control -> Macro`から`stg_log_auto.ttl`を実行
4. マクロが踏み台からアプリ操作ホストへSSH接続
5. `su - rcuser`でユーザー切り替え
6. `front`または`back`に応じて固定のnamespace、ログディレクトリ、ログglobを選ぶ
7. `kubectl get pod -n <namespace> -o wide`でPod一覧を表示
8. ユーザーが`NODE`列のNode名を入力
9. NodeへSSH
10. 固定ログディレクトリへ移動
11. 最新の`.log`を`tail -n 120`

## Node入力

Podが複数ある前提ですが、マクロはPod名の解決までは行いません。

`kubectl get pod -n <namespace> -o wide`の出力を見て、対象Podの`NODE`列の値をinputboxへ入力します。

Node名さえ分かれば、その後のログディレクトリとログファイル名はfront/backごとに固定です。

## 以前の読みにくい記述について

前の版では、サーバ上で実行するshell scriptをbase64文字列としてTTL内に埋め込んでいました。
これは引用符の壊れやすさを避けるためでしたが、人間には読みにくいので廃止しました。

今の版では、サーバへファイルを置かず、TTLが必要なコマンドを順番に送信します。
