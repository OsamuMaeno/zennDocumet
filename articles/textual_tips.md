---
title: textualで作るTUIのTIPS
emoji: "💻"
type: "tech" 
topics: [python,tui,textual]
published: true
published_at: 2025-06-10 06:00
publication_name: "secondselection"
---

## はじめに

どうも、セカンドセレクション前野です。

ここではTextualで画面を作ったときのTipsを書きます。


## 目次
- [はじめに](#はじめに)
- [目次](#目次)
- [1. TIPS集](#1-tips集)
  - [1. composeメソッド](#1-composeメソッド)
  - [2. ウィジェットの追加方法](#2-ウィジェットの追加方法)
    - [(1)インスタンス変数を使う方法](#1インスタンス変数を使う方法)
    - [(2)直接`yield`する方法](#2直接yieldする方法)
    - [どちらを使うべきか？](#どちらを使うべきか)
  - [3. on\_mountメソッド](#3-on_mountメソッド)
  - [4. CSSのようなスタイルシート](#4-cssのようなスタイルシート)
  - [5. プログラムの終了(VSCodeのターミナル)](#5-プログラムの終了vscodeのターミナル)
  - [6. デバッグ](#6-デバッグ)
  - [7. イベント](#7-イベント)
  - [8. クリップボードへのコピー](#8-クリップボードへのコピー)
    - [Linux](#linux)
    - [Windows](#windows)
  - [9. ウィジェット](#9-ウィジェット)
    - [TabbedContent、TabPane](#tabbedcontenttabpane)
    - [MarkdownViewer](#markdownviewer)
    - [Datatable](#datatable)
      - [データの追加、更新の方法](#データの追加更新の方法)
- [2. さいごに](#2-さいごに)

## 1. TIPS集
![textualイメージ](/images/textual_tips/textual_image.png)

画面をいくつか作ってみて、試行錯誤したところや気を付けたほうがいいところを書きます。

### 1. composeメソッド

composeメソッドは、ウィジェットのレイアウトを定義するために使用されます。複数のウィジェットを組み合わせて画面を構成する際に、このメソッド内でyieldを使ってウィジェットを順番に追加します。特に、コンポーネントを再利用したり、動的に画面を構築したりする場合に便利です。

例えば、ヘッダー、ボタン、テーブルを含む画面を作成する場合、以下のようにcomposeメソッドでウィジェットを組み合わせます。

```python
def compose(self) -> ComposeResult:
    yield Header()
    with Vertical():
        yield DataTable(id="note_table")
        yield RichLog(id="logger")
        with Horizontal(id="action"):
            yield Button("Save note", id="save_note_button")
            yield Button("Delete note", id="delete_note_button")

```
このようにcomposeメソッドを活用することで、ウィジェットの構造をシンプルかつ直感的に記述できます。



### 2. ウィジェットの追加方法 

Textualでは、ウィジェットを画面に追加する方法として`compose`メソッドを使用します。ウィジェットの追加には以下の２つの方法があります。  

#### (1)インスタンス変数を使う方法
ウィジェットのインスタンスを`self`に保持し、`yield`でレイアウトに追加する方法です。  

```python
def compose(self) -> ComposeResult:
    self.note_table = DataTable(id="note_table")
    yield self.note_table
```

**メリット:**  
- ウィジェットを`self`に保持することで、他のメソッドからアクセスしやすくなる（例：データ更新時に`self.note_table`を直接操作できる）。  

**デメリット:**  
- 変数が増えるため、コードの可読性が下がる。

#### (2)直接`yield`する方法
ウィジェットのインスタンスを`yield`で直接レイアウトに追加する方法です。  

```python
def compose(self) -> ComposeResult:
    yield DataTable(id="note_table")
```

**メリット:**  
- コードがシンプルになる。  
- 一時的なウィジェットであれば、`self`に保持する必要がない。  

**デメリット:**  
- `self`に保持しないため、他のメソッドからアクセスできない。ウィジェットを更新・操作する場合は`query_one("#note_table")`のように`id`で取得する必要がある。  

```python
table = self.query_one("#note_table", DataTable)
table.add_row("1", "2025-03-24", "Sample note")
```

#### どちらを使うべきか？
- **ウィジェットの状態を変更する場合（ボタンの無効化、データ更新など）** → **インスタンス変数を使う**  
- **シンプルなレイアウトで済む場合（固定ボタンなど）** → **直接`yield`する**  


### 3. on_mountメソッド

`on_mount`メソッドは、画面が構築された直後に呼び出されるメソッドです。ウィジェットがレイアウトに追加された後実行されるため、初期設定やデータの読み込み、イベントリスナーの登録などを行うのに適しています。  

例えば、`on_mount`を使って`DataTable`に列を追加し、データをロードできます。  

```python
def on_mount(self) -> None:
    # 列を追加する
    for key in ["id", "date", "contents"]:
        self.note_table.add_column(key, key=key)
    
    # データのロード
    self._load_data()
```

このように`on_mount`を使うことで、ウィジェットのレイアウトが確定した後に必要な処理を実行できます。

### 4. CSSのようなスタイルシート

id、classes、ウィジェット名(RichLog,Buttonなど)を指定すれば、tcssファイルでサイズや色なんかを設定できます。

- Textualでは、ボタンの高さを３行以上にしないと、枠線や中の文字が正しく表示されません。これは、TUIにおけるUIレイアウトの制限のためです。

- Inputウィジェットは、widthの文字数を指定しないと画面の横幅いっぱい表示されます。

### 5. プログラムの終了(VSCodeのターミナル)

Textualを使い始めたころ、VSCodeのターミナルで動かしたプログラムをどうやって終了すればいいのかわからず困りました。

通常、Textualのプログラムを終了するにはCtrl+Qを押しますが、VSCodeのターミナルでCtrl+Qを押すとVSCodeの機能切り替えが発生し、プログラムが終了しません。
泣く泣くターミナルごと落としました。

ちなみにCtrl+Cで終了しようとすると「Ctrl+Qで終了してね」というメッセージが表示されて終了できません。

で、どうするかと言いますといくつかの方法があります。

1. Quitボタンを追加して、Quitボタンが押されたら`self.exti()`でプログラムを終了します。
1. FooterをTextualの画面に追加しておくと右端に`^p palette`というのを表示します。それをマウスでクリックしてダイアログの`Quit the application`をクリックすると終了します。
1. `ESC + Q`でもアプリケーションを終了できます。
1. アプリケーションのクラス内で`BINDINGS`変数を使ってQuit用のキーをプログラム終了アクションに紐づけます。すると、FooterにQuit用のキーを表示するのでそれをマウスでクリックすると終了します。


```python
class DailyNote(App):
    BINDINGS = [
        Binding("q", "quit_process", "QUIT", show=True, priority=True),
    ]

```
この例ではFooterに「q QUIT」と表示されますので、クリックするとプログラム終了します。

どれが使いやすいかは好みですが、マウスでクリックして終了できるので、私は4番目の方法を使っています。

### 6. デバッグ

Textual以外の開発では、変数の中身をprintで表示させてデバッグしています。
Textualでprintをしてもどこにも表示されません。
logger機能がありますが、できれば実行中に表示したいというのがありました。

で、ウィジェットにRichLogというものがあったので、画面に追加して変数の内容なんかを出力しています。

### 7. イベント

イベントを処理する方法は二種類あります。

1. すでに定義されているイベント処理のメソッドをオーバーライドする形で対応します。
    - on_key(): キー入力イベント
    - on_list_view_selected(): リストボックス選択イベント
    - on_data_table_row_selected(): Datatableの行選択イベント

1. 処理するメソッドを作成して`@on`デコレーターにイベントのクラスとidを指定します。

`@on`デコレーターを使用すると、特定のウィジェットのイベントに対して処理を実行できます。デコレーターには、対象の**イベントクラス**と**ウィジェットのID**を指定します。  

例えば、ボタンが押されたときの処理を定義する場合、次のように記述します。  

```python
@on(Button.Pressed, "#load_note_button")
def load_note_button(self) -> None:
    print("Load Note ボタンが押されました")
```

このコードでは、`Button.Pressed`イベントが`id="load_note_button"`のボタンで発生した際に、`load_note_button`メソッドが実行されます。  

同様に、`DataTable`の行が選択されたときの処理を登録する場合は、以下のように記述します。  

```python
@on(DataTable.RowSelected, "#note_table")
def data_table_row_selected(self, event: DataTable.RowSelected) -> None:
    print(f"選択された行: {event.row_key}")
```

このように`@on`デコレーターを使うことで、特定のウィジェットのイベントに対して明確な処理を記述できます。

### 8. クリップボードへのコピー

#### Linux

画面のコピーボタンを押したらMarkdownViewerの内容をコピーしたかったんですが、pyperclipライブラリを使ってもエラーがでて、上手くいきませんでした。

wsl2だったんで`Clip.exe`でコピーしようとしましたが、文字化けして結局コピーできませんでした。

仕方ないのでTextAreaウィジェットへ対象のテキストを表示させて全体選択→コピーという手段を使っています。

どなたか解決した方は教えてください。


#### Windows

Windows上では画面のコピーボタンでコピーは問題なくコピーできました。


### 9. ウィジェット

#### TabbedContent、TabPane

TUIはあまり表示領域をとれないので、タブを使って切り替えるようにしています。

もっぱらの悩みは、タブを動的に追加できないことです。

動的にタブを追加するをいろいろ試してみたのですが、今のところできていません。

どなたかやり方がわかる方は教えてください。

#### MarkdownViewer

マークダウンテキストをセットすると整形されて表示されます。

![日報](/images/textual_tips/daily_note_001.png)

サンプルソースを見ていると`mount()`でMarkdownViewerの属性にマークダウンテキストをセットするものしかありませんでした。
上の一覧のデータを選択したらマークダウンで表示するにはどうしたらいいかどこにも書いてないんです。

で、下記のようにMarkdownViewerのdocumentに対して`update(マークダウンテキスト)`を実行すると書き換わります。

```python
        self.note_markdown = MarkdownViewer(id="note_markdown")

        md = self.note_markdown.document
        md.update(data)

```

#### Datatable

表形式でデータを表示します。

- 表上でデータの入力や変更はできません。
- 行列は、キー指定と行列インデックスで指定できます。
    - キー指定：列を作成するときと行を追加するときにキー(str)を設定しておきます。キーを指定してデータの取得、更新します。
    - 行列インデックス：Coordinate(columnインデックス,rowインデックス)を指定して、データの取得、更新します。

##### データの追加、更新の方法

1. まず列を追加します。(add_column)
    1. 列にキーを指定しておきます。
1. データ(行)を追加します。
    1. `add_row()`データを一行追加します。(行のキーを指定できます。)
        1. データに一意キーがあって個別データを変更したければ`add_row()`キー付きを勧めます。
    1. `add_rows()`全データを追加します。(行のキーを指定できません。)
        1. 個別データの変更しないで、全データを表示するだけであればこれでOKです。

列と行にキーをつけています。

列の設定である`NOTE_COLUMNS`はソースの先頭で定義しておくと便利です。

```python
NOTE_COLUMNS = ["id", "date", "contents"]


    def compose(self) -> ComposeResult:
        self.note_table = DataTable(id="note_table")
        self.note_table.cursor_type = "row"
        yield Header()
        with Vertical():
            yield self.note_table

    def on_mount(self):
        for key in NOTE_COLUMNS:
            self.note_table.add_column(key, key=key)
        self.note_table.clear(columns=False)
        row = []
        with database.JsonDB(dbname) as db:
            for row in db.get(tblname, sort="desc"):
                id = row["id"]
                daily_dt = data["daily_dt"]
                data = row["data"]
                t_row = [id, daily_dt, data]
                self.note_table.add_row(*t_row, key=id)
```

キーなし列追加方法です。

```python
NOTE_COLUMNS = ["id", "date", "contents"]

    def on_mount(self):
        self.note_table.add_columns(*NOTE_COLUMNS)

```

## 2. さいごに

コピーペーストについては現在、何かいい解決方法がないかを探し中です。
