# 基本・詳細設計書

## 1. 設計方針

合言葉は **入口・本体・出口・見張り** です。

- 入口: Internet Gateway と ALB
- 本体: private subnet の EC2 Auto Scaling
- 出口: NAT Gateway（更新・パッケージ取得用）
- 見張り: CloudWatch と ALB health check

## 2. ネットワーク設計

| 用途 | AZ 1 | AZ 2 | 備考 |
|---|---|---|---|
| VPC | `10.20.0.0/16` | 同左 | DNS hostnames/support 有効 |
| public subnet | `10.20.0.0/24` | `10.20.1.0/24` | ALB、NAT Gateway |
| private subnet | `10.20.10.0/24` | `10.20.11.0/24` | EC2、公開 IPv4 なし |

### 経路表

| Subnet | 宛先 | Target | 意味 |
|---|---|---|---|
| public | VPC CIDR | local | VPC 内通信 |
| public | `0.0.0.0/0` | Internet Gateway | インターネットとの入口・出口 |
| private | VPC CIDR | local | VPC 内通信 |
| private | `0.0.0.0/0` | NAT Gateway | 外向き通信だけ開始可能 |

`lab` は private subnet 2つが同じ NAT を使う。安価だが NAT 所属 AZ の障害に弱い。`production` は各 private subnet が同じ AZ の NAT を使い、可用性を上げる。

## 3. 通信設計

| ID | From | To | Protocol/Port | 許可理由 |
|---|---|---|---|---|
| NW-01 | Internet | ALB SG | TCP/80 | デモサイト閲覧 |
| NW-02 | ALB SG | EC2 SG | TCP/80 | Web 転送と health check |
| NW-03 | EC2 SG | Internet/AWS API | TCP/443 | 更新、SSM、CloudWatch |
| NW-04 | EC2 SG | DNS resolver | UDP/TCP 53 | 名前解決（既定 egress に包含） |

EC2 の TCP/22 inbound は **0件**。管理は IAM で認可された Session Manager を使う。

## 4. リソース設計

| リソース | 設定 | 理由 |
|---|---|---|
| ALB | internet-facing、2 public subnets | AZ 分散と単一入口 |
| Target Group | HTTP:80、`/health`、200 | アプリ正常性を確認 |
| Launch Template | AL2023、`t3.micro`、暗号化 EBS | 学習用の小構成と保存時暗号化 |
| ASG | min/desire=2、max=4、ELB health check | 台数維持と自動置換 |
| IAM role | `AmazonSSMManagedInstanceCore` + 必要な logs/metrics | 鍵なし運用と監視 |
| Log Group | nginx access/error、messages、保持14日 | 調査可能性と保管費の均衡 |
| Alarm | CPU > 80%、ALB 5xx、healthy host < 2 | 容量・入口・可用性を監視 |

## 5. 命名・タグ

名前は `<project>-<environment>-<resource>`。例: `aws-casepack-lab-alb`。

必須タグ: `Project`、`Environment`、`ManagedBy=Terraform`、`Owner`。課金分析・棚卸し・誤削除防止の基本情報にする。

## 6. セキュリティ設計

- IAM ユーザーの長期アクセスキーではなく、短期認証または専用学習ロールを優先。
- EC2 instance metadata は IMDSv2 必須（hop limit 1）。
- EBS は暗号化し、root volume はインスタンス終了時に削除。
- Security Group は ALB→EC2 の参照で限定。
- User data、tfvars、state に秘密情報を入れない。
- CloudTrail、GuardDuty、AWS Config、WAF は発展項目として別途設計する。

## 7. 可用性と故障モード

| 故障 | 想定動作 | 限界 |
|---|---|---|
| EC2 1台停止 | ALB が切り離し、ASG が補充 | 補充まで残り1台に負荷集中 |
| AZ 1つ停止 | もう一方の AZ で応答継続を期待 | `lab` の単一 NAT は出口障害になり得る |
| nginx 停止 | `/health` 失敗、切り離し・置換 | 全台同じ設定ミスなら全台異常 |
| ALB 5xx 増加 | Alarm が検知 | 通知先未設定なら人に届かない |

## 8. lab と production の違い

| 観点 | lab | production の考え方 |
|---|---|---|
| NAT | 1台 | AZ ごとに1台 |
| TLS | HTTP | ACM + HTTPS、HTTP リダイレクト |
| 通知 | 任意 SNS ARN | 運用チームの検証済み通知先 |
| ログ保持 | 14日 | 規程・調査要件で決定 |
| state | local（学習のみ） | S3 backend、暗号化、ロック、権限制御 |
| 保護 | destroy を許容 | deletion protection、変更承認、バックアップ |
