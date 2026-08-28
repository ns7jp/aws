# 要件定義書

## 1. 案件シナリオ

架空企業 Example 株式会社の採用情報 Web サイトを AWS へ移行する。平常時は小規模だが、更新直後のアクセス増加に備える。インフラ担当者は少なく、標準化された手順と監視が必要である。

## 2. スコープ

### 対象

- VPC、2 AZ、public/private subnet、経路
- ALB、EC2 Auto Scaling、nginx
- IAM ロール、SSM Session Manager
- CloudWatch Logs、メトリクス、アラーム
- Terraform、試験、運用・障害手順、証跡

### 対象外

- 独自ドメイン、Route 53、ACM、WAF（発展課題）
- RDS やアプリケーションDB
- CI/CD によるアプリ配布
- Organizations、Control Tower、複数アカウント統制

## 3. 機能要件

| ID | 要件 | 受入条件 |
|---|---|---|
| FR-01 | 利用者が Web ページを閲覧できる | ALB URL が HTTP 200 を返す |
| FR-02 | サーバーを一元管理できる | Session Manager で接続できる |
| FR-03 | アクセス・OSログを確認できる | CloudWatch Logs に新規イベントが届く |
| FR-04 | 構成を再現できる | Terraform のコードと入力値から構築できる |

## 4. 非機能要件

| ID | 分類 | 要件 | 設計・試験への対応 |
|---|---|---|---|
| NFR-01 | 可用性 | 単一 AZ 障害で全停止しにくい | 2 AZ、ASG 最小2台、配置確認 |
| NFR-02 | セキュリティ | EC2 を直接インターネット公開しない | private subnet、公開IPなし、外部から22番なし |
| NFR-03 | 監視 | 5xx、CPU高騰、正常台数不足を検知 | CloudWatch Alarm の状態・擬似障害試験 |
| NFR-04 | 保守性 | 手作業差分を減らす | Terraform、タグ、変更手順 |
| NFR-05 | 復旧性 | EC2 異常時に自動置換できる | ELB health check、ASG、置換試験 |
| NFR-06 | コスト | 学習時の無駄な継続課金を防ぐ | `lab` は NAT 1台、終了時 destroy・残存確認 |

## 5. 前提・制約

- 学習環境は単一 AWS アカウント・単一 Region。
- Amazon Linux 2023 の最新 AMI を SSM Parameter から参照する。
- デモは HTTP。実案件では ACM 証明書を用いた HTTPS と HTTP→HTTPS リダイレクトを必須候補とする。
- `lab` は費用優先で NAT Gateway を1台にするため、NAT の AZ 障害は許容する。
- `production` は可用性優先で AZ ごとに NAT Gateway を配置する。

## 6. 要件トレーサビリティ

「要件 → 設計 → Terraform リソース → 試験 → 証跡」の順に追跡する。

例: `NFR-02 → docs/02 の通信設計 → aws_security_group.web → ST-03 → evidence/security-groups.json`

## 7. 未決事項（実案件なら顧客へ確認）

- 目標稼働率、RTO（復旧目標時間）、RPO（許容データ損失量）
- 同時アクセス数、レスポンスタイム目標、ログ保存年数
- 通知先、運用時間、一次・二次対応者、エスカレーション時間
- 本番ドメイン、TLS、WAF、バックアップ、脆弱性管理の基準
