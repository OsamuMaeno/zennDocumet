---
title: Dockerイメージをオフライン配布する際の「export/import」活用とログ肥大化対策
emoji: "💻"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python","docker","arm"]
published: true
published_at: 2026-01-13 06:00
publication_name: "secondselection"
---


- [はじめに](#はじめに)
- [WSL(X64)でARMのDockerイメージを作成する](#wslx64でarmのdockerイメージを作成する)
  - [tonistiigi/binfmt とは？](#tonistiigibinfmt-とは)
  - [Docker イメージ作成スクリプト](#docker-イメージ作成スクリプト)
  - [サンプル Dockerfile](#サンプル-dockerfile)
- [Dockerイメージをインポートする](#dockerイメージをインポートする)
  - [Docker イメージインポートスクリプト](#docker-イメージインポートスクリプト)
- [Dockerイメージをエクスポートする](#dockerイメージをエクスポートする)
  - [Docker イメージエクスポートスクリプト](#docker-イメージエクスポートスクリプト)
- [Dockerのログファイルのローテートを設定する](#dockerのログファイルのローテートを設定する)
  - [docker runコマンドのサンプル](#docker-runコマンドのサンプル)

## はじめに

「WSL(x64)環境で開発しているが、デプロイ先はRaspberry Pi(ARM)だ」というケースは多いはずです。  
 本記事では、**x64環境でのARMイメージのビルド方法**から、レジストリを使わない**イメージのインポート／エクスポート（軽量化）**、忘れがちな**ログローテーション設定**まで、実務で躓きやすいポイントをTIPSとしてまとめました。

---

## WSL(X64)でARMのDockerイメージを作成する

WSL上でDockerをインストールした直後は、x64のイメージしか作れません。Raspberry PiなどARM環境向けのイメージをビルドするには、`buildx` と `binfmt` を使った設定が必要です。

`buildx`したDockerイメージは、WSLの`docker image`上には作成されません。

`docker export`した時のファイルイメージと同じものです。

ビルド対象のプラットフォームにて、[Dockerイメージをインポートする](#dockerイメージをインポートする)を参照にインポートしてください。

Raspberry PiのOSが32ビットと64ビットではターゲットが変わってきますのでお気を付けください。

- 32ビット：`linux/arm/v7`
- 64ビット：`linux/arm64`

※32ビットでは確認したのですが、64ビットでは確認していません。もし64ビットで不具合があったらコメントで教えてください。

### tonistiigi/binfmtとは？

`tonistiigi/binfmt`は、マルチアーキテクチャの実行環境を追加するための仕組みです。これを導入することで、x64環境でもARM用のバイナリをクロスビルドできます。

```bash
# 各種アーキテクチャのサポートを追加
docker run --rm --privileged tonistiigi/binfmt:latest \
  --install linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/386,linux/arm/v7,linux/arm/v6

# buildx を有効化
docker buildx use default

# 利用可能なプラットフォームを確認
docker buildx ls
```

ここで`linux/arm/v7`または`linux/arm64`が表示されればRaspberry Pi用のビルドが可能です。

---

### Dockerイメージ作成スクリプト

以下のスクリプトで、ARM向けのイメージをビルドします。

![docker TIPS](/images/docker_tips/docker_tips.drawio.png)

```bash
#!/usr/bin/env bash

EXPORT_FILE="app_container.tar"
IMAGE_NAME="app-image"

# Raspberry Pi 32ビット(arm/v7) 用にビルド
docker buildx build --no-cache --platform linux/arm/v7 \
  --output type=tar,dest=$EXPORT_FILE \
  -t $IMAGE_NAME . -f Dockerfile

```

---

### サンプルDockerfile

```dockerfile
FROM python:3.12.2-slim-bullseye
USER root

RUN apt-get update && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --upgrade pip

WORKDIR /opt/app

COPY requirement.txt ./

RUN pip install -r requirement.txt
```

---

## Dockerイメージをインポートする

別環境から持ち込んだイメージを取り込む場合は、`docker import` を使います。

### Dockerイメージインポートスクリプト

```bash
#!/usr/bin/env bash

IMPORT_FILE="app_container.tar"
IMAGE_NAME="app-image"

# イメージをインポート
docker import $IMPORT_FILE $IMAGE_NAME:latest
BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
  echo "Docker import failed with status code $BUILD_STATUS"
  exit 1
else
  echo "インポート完了：$IMPORT_ZIP_FILE"
fi
```

---

## Dockerイメージをエクスポートする

インポートしたイメージを、再度ファイルとしてエクスポートできます。これにより、別の環境へ配布できます。
`save`でもイメージを保存できますが、ビルドしたときのメタ情報も保存されますので、`save`より`export`の方が保存されるファイルのサイズが小さくなります。

### Dockerイメージエクスポートスクリプト

```bash
#!/usr/bin/env bash

IMAGE_NAME="app-image"
EXPORT_FILE="app_container.tar"

# イメージをエクスポート
docker export $IMAGE_NAME:latest > $EXPORT_FILE

BUILD_STATUS=$?
if [ $BUILD_STATUS -ne 0 ]; then
  echo "Docker export failed with status code $BUILD_STATUS"
  exit 1
else
  echo "Docker export succeeded."
fi

echo "Dockerイメージが $EXPORT_FILE にエクスポートされました。"
```

`docker save`を使うことで、現在ローカルにあるイメージを`.tar.gz`形式に変換できます。

---

## Dockerのログファイルのローテートを設定する

コンテナのログはデフォルトでは肥大化しやすいため、ローテーションを設定するのがおすすめです。
前述のものとは毛色が違いますが、これを知らずにいたためお客様へご迷惑をおかけしましたので、教訓として入れました。

### docker runコマンドのサンプル

```bash
#!/usr/bin/env bash

INSTALL_SOURCE="/opt/app"
IMAGE_NAME="app-image"

docker run -d \
  --restart always \
  -p 80:8000 \
  --name app \
  -e TZ=Asia/Tokyo \
  -w $INSTALL_SOURCE \
  -v $INSTALL_SOURCE:$INSTALL_SOURCE \
  -v /dev/shm:$INSTALL_SOURCE/logs \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  $IMAGE_NAME:latest \
  python main.py
```

ここでは`--log-driver=json-file`と`--log-opt`を使い、**1ファイルあたり最大10MB・最大3ファイル保持**という設定にしています。

---

👉 この流れを押さえることで、**x64 環境から ARM デバイス向けにイメージをビルドし、配布・運用まで行う** 一連の手順を再現できます。

後、プログラムの実行は自己責任でお願いします。
