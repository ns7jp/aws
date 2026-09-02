# ハンズオンキット: AWS CLI で EC2 Webサーバーを自動構築する

[../README.md](../README.md) の「ハンズオン手順」(フェーズ1〜5)を、マネジメントコンソールの代わりに AWS CLI で一気に構築・削除できるスクリプト集です。まずは本編のドキュメントで「なぜこの順番で通信できるのか」を理解してから、このキットで手を動かしてみてください。

> ⚠️ **注記**: このキットは実際の AWS 環境ではまだ検証していません。実行前に必ず各スクリプトの内容を読み、何をするのか理解したうえで実行してください。また、検証が終わったら `./cleanup.sh` でリソースを必ず削除してください。

## 前提条件

- AWS CLI v2 がインストールされていること(`aws --version` で `aws-cli/2.x.x` と表示されること)
- `aws configure` で認証情報とデフォルトリージョンを設定済みであること
- 使用する IAM ユーザー/ロールに EC2・VPC・SSM パラメータ読み取りの権限があること(学習用途なら `AmazonEC2FullAccess` + `AmazonSSMReadOnlyAccess` 程度で動きます)
- `bash`・`curl` が使える環境(macOS / Linux / WSL など)

## ファイルの役割

| ファイル | 役割 |
|---|---|
| `build.sh` | VPC → サブネット → IGW → ルートテーブル → セキュリティグループ → キーペア → EC2 → Elastic IP の順に作成します |
| `user-data.sh` | EC2 の初回起動時に自動実行され、Apache(httpd)をインストールして `index.html` を配置します |
| `cleanup.sh` | `build.sh` が作ったリソースを逆順にすべて削除します |
| `.handson-state.env` | `build.sh` が作成したリソースIDを記録するファイル(自動生成・`cleanup.sh` が読み込みます) |
| `handson-key.pem` | `build.sh` が作成する SSH 秘密鍵(自動生成・**絶対に共有しないでください**) |
| `.gitignore` | `.pem` と状態ファイルを誤ってコミットしないための設定です |

## 実行手順

### 1. 変数を確認・編集する

`build.sh` の先頭にある変数を確認します。本編ドキュメントと同じ値が初期設定されています。

| 変数 | 初期値 | 説明 |
|---|---|---|
| `REGION` | `ap-northeast-1` | 東京リージョン |
| `VPC_CIDR` | `10.0.0.0/16` | VPC のアドレス範囲 |
| `SUBNET_CIDR` | `10.0.1.0/24` | パブリックサブネットのアドレス範囲 |
| `AZ` | `ap-northeast-1a` | アベイラビリティゾーン |
| `KEY_NAME` | `handson-key` | キーペア名 |
| `MY_IP` | (空=自動取得) | SSH を許可する自分のグローバルIP |
| `INSTANCE_TYPE` | `t3.micro` | インスタンスタイプ |
| `NAME_PREFIX` | `handson` | Name タグの接頭辞 |

`MY_IP` は空のままなら自動取得されますが、手動で確認したい場合は次のコマンドで自分のグローバルIPを調べられます。

```bash
curl -s https://checkip.amazonaws.com
```

表示された IP を `build.sh` の `MY_IP="..."` に書くか、実行時に環境変数で渡します。

```bash
MY_IP=203.0.113.10 ./build.sh
```

### 2. 構築する

```bash
cd projects/02-ec2-web-server/handson
chmod +x build.sh cleanup.sh
./build.sh
```

3〜5分ほどで完了し、最後に Web ページの URL と SSH コマンドが表示されます。

### 3. ブラウザで確認する

表示された `http://<Elastic IP>` をブラウザで開き、「Hello from my first EC2 web server!」とインスタンスIDが表示されれば成功です。`user-data.sh` による httpd のセットアップには起動後 1〜2 分かかるため、表示されない場合は少し待ってから再読み込みしてください。

### 4. SSH で接続する

```bash
ssh -i handson-key.pem ec2-user@<Elastic IP>
```

接続後、`sudo systemctl status httpd` で `active (running)` になっていることを確認できます。つながらない場合は本編の [トラブルシューティング](../README.md#️-トラブルシューティング) を「自分側 → SG → ルートテーブル → IGW」の順に確認してください。

### 5. 削除する

```bash
./cleanup.sh
```

Elastic IP の解放 → EC2 の終了 → ... → VPC の削除 → キーペアの削除まで自動で行い、`.pem` と `.handson-state.env` も消します。最後にマネジメントコンソールで残っているリソースがないか目視で確認してください。

## ⚠️ 課金に関する注意

- 💰 **Elastic IP** は EC2 にアタッチされている間は無料ですが、インスタンスを停止・終了して**未アタッチのまま残すと課金対象**になります。`cleanup.sh` を途中で止めた場合は、必ずコンソールの「EC2 > Elastic IP」で「アドレスの解放」を行ってください。
- 💰 **t3.micro** は AWS 無料利用枠(12か月間・月750時間)の対象ですが、無料枠の期限が切れたアカウントや、他のインスタンスと合算して750時間を超えた場合は課金されます。使い終わったら速やかに削除してください。
- コスト管理の考え方は [../../../docs/03-cost-management.md](../../../docs/03-cost-management.md) も参照してください。

## 関連ドキュメント

- [レベル2 本編: EC2で自分のWebサーバーを構築する](../README.md)
- [コスト管理](../../../docs/03-cost-management.md)
