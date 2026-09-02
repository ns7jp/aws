# レベル3 ハンズオンキット: AWS CLI で3層Webシステムを構築・削除する

[../README.md](../README.md) で解説している構成(ALB + Auto Scaling + Multi-AZ RDS)を、マネジメントコンソールの代わりに AWS CLI のスクリプトで一括構築・一括削除するためのキットです。サブネット設計・セキュリティグループ名・リソース名は解説ドキュメントと同じ値を使っています。

> ⚠️ **注記**: このキットは実際の AWS 環境では未検証です。構文チェック(`bash -n`)のみ実施しています。実行時にエラーが出た場合は、表示されたメッセージをもとに該当行を確認・修正してください。

## 前提

- AWS CLI v2 がインストールされ、`aws configure` で認証情報(アクセスキーまたは SSO)が設定済みであること
- 使用する IAM ユーザー/ロールに VPC・EC2・ELB・Auto Scaling・RDS・SSM(パラメータ読み取り)の操作権限があること
- bash が動作する環境(macOS / Linux / WSL / CloudShell)
- リージョンは東京(`ap-northeast-1`)、AZ は `ap-northeast-1a` と `ap-northeast-1c` を使用します

## ファイルの役割

| ファイル | 役割 |
|---|---|
| `build.sh` | VPC から RDS まで全リソースを順番に作成します。作成した ID は `.handson-state.env` に保存します |
| `cleanup.sh` | `.handson-state.env` を読み込み、依存関係の逆順で全リソースを削除します |
| `user-data.sh` | EC2 起動時に実行されるスクリプト。httpd の導入、`/health.html`、インスタンス ID を表示する `index.html` を配置します |
| `.handson-state.env` | `build.sh` が自動生成する状態ファイル(ID の一覧)。`.gitignore` で除外済みです |
| `.gitignore` | 状態ファイルをコミット対象から外します |

## 作成されるリソース(解説ドキュメントとの対応)

| 種別 | 名前 / 値 |
|---|---|
| VPC | `ha-three-tier-vpc`(10.0.0.0/16) |
| サブネット | public-1a 10.0.1.0/24、public-1c 10.0.2.0/24、private-app-1a 10.0.11.0/24、private-app-1c 10.0.12.0/24、private-db-1a 10.0.21.0/24、private-db-1c 10.0.22.0/24 |
| IGW / ルートテーブル | `ha-three-tier-igw`、`ha-public-rt`、`ha-private-app-rt` |
| NATゲートウェイ | public-1a に配置(Elastic IP 付き) |
| セキュリティグループ | `ha-alb-sg`(80/443 ← 0.0.0.0/0)、`ha-app-sg`(80 ← ha-alb-sg)、`ha-db-sg`(3306 ← ha-app-sg) |
| 起動テンプレート | `ha-app-launch-template`(Amazon Linux 2023、t3.micro) |
| ターゲットグループ / ALB | `ha-app-tg`(ヘルスチェック `/health.html`)、`ha-app-alb`(インターネット向け) |
| Auto Scaling Group | `ha-app-asg`(最小2・希望2・最大4、平均CPU 70% のターゲット追跡) |
| RDS | `ha-db-subnet-group`、`ha-mysql-db`(MySQL、db.t3.micro、Multi-AZ、gp3 20GiB、パブリックアクセスなし) |

## 実行手順

### 1. 準備

```bash
cd projects/03-ha-three-tier/handson
chmod +x build.sh cleanup.sh

# RDS の管理者ユーザー名とパスワードは環境変数で渡します(スクリプトには書きません)
export DB_USERNAME=admin
export DB_PASSWORD='8文字以上の強いパスワード'
```

必要に応じて `build.sh` 先頭の変数(`REGION`、`INSTANCE_TYPE`、`DB_INSTANCE_CLASS` など)を書き換えてください。

### 2. 構築する

```bash
./build.sh
```

NATゲートウェイの起動待ち、ALB の起動待ち、RDS Multi-AZ の起動待ちが含まれるため、完了までに **10〜15分程度** かかります。最後に ALB の DNS 名と RDS のエンドポイントが表示されます。

### 3. 動作確認する

1. 表示された `http://<ALBのDNS名>` をブラウザで開きます(ターゲットが healthy になるまで、構築完了から数分かかることがあります)。
2. `Hello from Auto Scaling! Instance ID: i-xxxx` が表示されることを確認します。
3. 何度かリロードし、Instance ID が2台の間で切り替わることを確認します。これが ALB による負荷分散です。
4. 発展として、EC2 コンソールから片方のインスタンスを終了し、数分後に ASG が自動で新しいインスタンスを補充することも確認できます。

### 4. 削除する

```bash
./cleanup.sh
```

RDS の削除待ち、ASG のインスタンス終了待ち、NATゲートウェイの削除待ちが含まれるため、こちらも 10分前後かかります。完了後、マネジメントコンソールで NATゲートウェイ・ALB・RDS・Elastic IP が残っていないことを必ず目視確認してください。

## 💰 コストに関する強い注意

**NATゲートウェイ・ALB・RDS Multi-AZ は、アクセスがゼロでも「存在しているだけ」で時間課金が発生し続けます。いずれも無料利用枠の対象外です。** 加えて、ASG が常時 2 台の EC2 を起動し続けます。

- 検証が終わったら、その日のうちに必ず `./cleanup.sh` を実行してください
- `build.sh` が途中で失敗した場合も、途中まで作られたリソースは課金されます。`.handson-state.env` が残っていれば `./cleanup.sh` で削除できます(存在しないリソースはスキップされます)
- 削除後は請求ダッシュボードで翌日以降の課金が止まっていることを確認してください

コスト管理の考え方は [../../../docs/03-cost-management.md](../../../docs/03-cost-management.md) を参照してください。

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `DB_USERNAME を設定してください` と表示される | 手順1の `export` を実行してから `./build.sh` を再実行してください |
| `.handson-state.env が既に存在します` と表示される | 前回のリソースが残っています。先に `./cleanup.sh` を実行してください |
| ブラウザで 503 が返る | ターゲットがまだ healthy になっていません。EC2 コンソール「ターゲットグループ」で状態を確認し、数分待ってください |
| `cleanup.sh` で SG や VPC が削除できない | ENI の解放待ちの可能性があります。数分後にもう一度 `./cleanup.sh` を実行するか、コンソールから手動で削除してください |

## 関連ドキュメント

- [レベル3 解説ドキュメント](../README.md)
- [コスト管理](../../../docs/03-cost-management.md)
