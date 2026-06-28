# Tera Term STG Log Macro

Tera Termで手動ログイン済みの踏み台から、アプリ操作ホスト、Kubernetes Nodeを順にたどり、選択したPodに対応するNode上の最新ログを確認するためのマクロです。

## ファイル

- `stg_log_auto.ttl`: Tera Termで実行するマクロ本体
- `LINE_BY_LINE.md`: `stg_log_auto.ttl`の行番号ベース解説

この版は、踏み台やアプリ操作ホストへhelper fileを置きません。  
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
FRONT_POD_PATTERN = '<P_F>'
BACK_POD_PATTERN = '<P_B>'
FRONT_LOG_DIR = '<D_F>'
BACK_LOG_DIR = '<D_B>'
FRONT_LOG_GLOB = '<G_F>'
BACK_LOG_GLOB = '<G_B>'
```

パスワードはファイルに書きません。実行時に入力します。

符号の意味:

- `H_A`: 踏み台からSSHする操作用ホスト
- `N_F` / `N_B`: front/backのnamespace
- `P_F` / `P_B`: front/backのPod名を絞るキーワード
- `D_F` / `D_B`: front/backのログディレクトリ
- `G_F` / `G_B`: front/backのログファイルglob

## 処理の流れ

1. Tera Termを手動で開く
2. 既に入力されているホストでLDAPログインし、踏み台のshell promptまで進む
3. Tera Termメニューの`Control -> Macro`から`stg_log_auto.ttl`を実行
4. マクロが踏み台からアプリ操作ホストへSSH接続
5. `su - rcuser`でユーザー切り替え
6. `front`または`back`の設定値をshell変数としてexport
7. `kubectl get pod -n <namespace> -o wide`でPod一覧を表示
8. Running Pod候補を番号付きで表示
9. ユーザーが番号、Pod名、またはPod名の一部を入力
10. 選択Podから`.spec.nodeName`を取得
11. NodeへSSH
12. ログディレクトリへ移動
13. 最新の`.log`を`tail -n 120`

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

今の版では、サーバへファイルを置かず、TTLから必要なshell断片を標準入力で`sh`へ渡しています。
