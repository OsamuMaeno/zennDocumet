---
title: 【初心者向け】postmanで変数を使ってみた
emoji: "📮"
type: "tech" 
topics: [postman,webapi,初心者向け]
published: true
published_at: 2024-11-11 06:00
publication_name: "secondselection"
---

## はじめに

どうも、セカンドセレクション前野です。

RestAPIの開発にてリクエストするときにBearerトークンが必要で、ユーザー・パスワードを渡したリクエストから返ってくるトークンをコピーして開発中のAPIを呼ぶということをやっていました。

ただ時間が経過するとトークンが無効になるので、再度トークンを取得してコピー・ペーストという行為をやる必要があります。

せめてコピー・ペーストの作業だけでも省力化できないかといろいろと調べるとPostmanの変数を使えばできるということがわかりました。

備忘録がてらに細かいネタとして書いておきます。

## Postmanについて

あまりにもメジャーなんで、こちらなんかを参照ください。

https://zenn.dev/nameless_sn/articles/postman_tutorial

## バージョン

Postman v11.18

## 変数

PostmanにはGlobal変数と環境変数の２つがあります。どちらもコレクション、環境、リクエスト、テストスクリプト全体で変数を参照できます。

### Global変数

環境に関係なく共通の値を使いたいときに使用します。

この画面で追加、変更できます。

![postman_global_var](/images/postman_variable/postman_global_var.png)

### 環境変数

環境を切り替えるごとに切り替わる変数です。

ここでは、開発で使う時の環境は「Test」、リリースで使う時の環境は「Release」に分けて、使用する変数を登録しています。

環境は右上の赤線で囲まれたところをクリックすると変わります。ここでは環境Testが選択されています。

![postman_environments](/images/postman_variable/postman_environments.png)

環境としては「No environment」「Release」「Test」があります。

- 「Release」「Test」はこちらで追加したものです。

- 環境「No environment」では環境変数を設定できません。


![postman_environments_select](/images/postman_variable/postman_environments_select.png)

環境Testには環境変数として「token_key」「base_url」を登録しています。

![postman_var_list_main](/images/postman_variable/postman_var_list_main.png)

右上のvariablesボタンを押すと右側に変数一覧を表示します。

![postman_var_list_right](/images/postman_variable/postman_var_list_right.png)

## 変数を使ってAPIの実行

- 接続先のURLは「base_url」に登録して、環境TestとReleaseで接続先を変更します。
- データ取得APIを実行するためのトークンキーを「token_key」に保存します。

1. トークンキーを取得するリクエストを実行する。(トークンキーを環境変数へ保存)
2. 環境変数のトークンキーを使ってデータ取得のリクエストを実行する。

### URLの設定

- 環境を切り替えて「base_url」を追加して、値を設定します。
- 環境「Test」では`localhost:8877`で設定しています。
- 使う時は`{{base_url}}`と記述すれば、使用できます。
    - ここではトークンキー取得APIとデータ取得APIのURLに使用しています。


### 前準備

前準備として以下の処理を追加します。
1. リクエスト`Get Token`を追加します。

```bash
http://{{base_url}}/authenticate
```

![postman_setting_gettoken](/images/postman_variable/postman_setting_gettoken.png)

2. ScriptsのPost-responseのトークンキーを環境変数「token_key」にセットするスクリプトを追加します。

![postman_setting_gettoken_scripts](/images/postman_variable/postman_setting_gettoken_scripts.png)

``` javascripts

pm.environment.set("token_key", pm.response.json().access_token)

```

3. データ取得するリクエスト`Get Data`を追加します。

```bash
http://{{base_url}}/products/test?id=10000
```

4. リクエスト`Get Data`のAuthorizationのBearer Tokenに`{{token_key}}`をセットします。

今回のシステムでAuth TypeはBearer Tokenを使用していますので、このような設定をしました。

その他のAuth TypeでもGlobal変数と環境変数は使えますので、応用してみてください。

![postman_setting_getdata](/images/postman_variable/postman_setting_getdata.png)

### トークンキー取得APIを実行する

前準備が終わったら実行してみましょう。

1. リクエストGet Tokenを実行する。トークンキーが取得できました。

![postman_get_token](/images/postman_variable/postman_get_token.png)

2. リクエストGet Dataを実行する。データが取得できました。

![postman_getdata](/images/postman_variable/postman_getdata.png)

素晴らしい、トークンキーのコピー・ペーストをする必要がなくなりました。

この後は、1の実行は不要となり2だけでデータは取得できるようになります。

トークンキーの期限が切れたら、再度1を実行して新しいトークンキーを取得してください。

## 補足

### グローバル変数

グローバル変数については細かく書いてありませんが、使い方はほぼ一緒です。

トークンキーをグローバル変数のtoken_keyにセットするには下記のようなスクリプトとなります。

```javascript
pm.globals.set("token_key", pm.response.json().access_token)	
```

### 変数名を間違えた

存在しない変数名を使用すると変数名のところが赤い背景色になります。

ここでは「base_urxx」なんて変数名はありません。

![postman_mistake_varname](/images/postman_variable/postman_mistake_varname.png)

## さいごに

たかがコピー・ペーストされどコピー・ペースト。「塵も積もれば山となる」です。

それに間違いを起こす原因となります。やらなくていいことはなるべく省力化するようにしましょう。

Postmanのバージョンによっては画面のイメージや操作方法が変わりますので、ご容赦ください。
