# レベル5 ハンズオンキット: セキュリティ監視・ガバナンス基盤を CLI で構築する

[レベル5 の課題ドキュメント](../README.md)で説明している IAM 設計・CloudTrail・AWS Config・GuardDuty・WAF の構成を、AWS CLI のスクリプトで一括構築・削除するためのキットです。

## 位置づけ

レベル2〜4 が「特定のシステムを作る」課題だったのに対し、このキットは**AWS アカウント全体に横断的に適用する**ものです。IAM グループ、証跡、構成監視、脅威検知はどのシステムにも共通して必要なため、1 度構築すればレベル2〜4 のすべての環境がその恩恵を受けます。

WAF だけは保護対象の ALB が必要です。[レベル3](../../03-ha-three-tier/README.md) で構築した ALB の ARN を環境変数 `ALB_ARN` で渡すと Web ACL を作成して関連付けます。省略した場合、WAF フェーズはスキップされます。

> ⚠️ **注記**: このキットは**実 AWS 環境では未検証**です。コマンドの構文は AWS CLI v2 のドキュメントに沿って記述していますが、実行前に必ず内容を読み、ご自身のアカウント設定に合わせて確認してください。

> ⚠️ **IAM 変更について**: `build.sh` はアカウント全体に影響する IAM グループ・ポリシーを作成します。ルートユーザーまたは `AdministratorAccess` 相当の権限で、**本番アカウントではなく学習用アカウントで**慎重に実行してください。特に `ForceMFA` ポリシーは MFA 未登録ユーザーの操作をほぼすべて拒否するため、既存ユーザーをグループに追加する前に MFA デバイスを登録しておく必要があります。

## ファイルの役割

| ファイル | 役割 |
|---|---|
| `build.sh` | フェーズ1〜5 を順番に構築するスクリプト。作成したリソース ID を `.handson-state.env` に保存します |
| `cleanup.sh` | `.handson-state.env` を読み込み、`build.sh` と逆順にリソースを削除します |
| `policies/require-mfa-policy.json` | `aws:MultiFactorAuthPresent` 条件で MFA 未認証セッションの操作を Deny するカスタムポリシー(MFA デバイスの登録操作は許可) |
| `policies/cloudtrail-bucket-policy.template.json` | CloudTrail がログを書き込むための S3 バケットポリシーの雛形。`sed` でバケット名・アカウント ID などを埋めます |
| `policies/config-bucket-policy.template.json` | AWS Config が構成スナップショットを配信するための S3 バケットポリシーの雛形 |
| `policies/config-trust-policy.json` | Config サービスロールの信頼ポリシー(`config.amazonaws.com` に AssumeRole を許可) |
| `policies/sns-topic-policy.template.json` | EventBridge(`events.amazonaws.com`)から SNS トピックへの Publish を許可するトピックポリシーの雛形 |
| `policies/guardduty-eventbridge-pattern.json` | GuardDuty Finding(severity 4 以上)を拾う EventBridge のイベントパターン |
| `.gitignore` | リソース ID を含む `.handson-state.env` をコミット対象から除外します |

## build.sh が作成するリソース

課題ドキュメントと同じ名前を使っています。

| フェーズ | リソース | 名前 |
|---|---|---|
| 1 | IAM グループ | `Administrators`(AdministratorAccess)/ `Developers`(PowerUserAccess)/ `ReadOnly`(ReadOnlyAccess) |
| 1 | IAM カスタムポリシー | `ForceMFA`(Developers と ReadOnly に付与) |
| 2 | CloudTrail 証跡 + S3 | `org-management-trail` / `cloudtrail-logs-<アカウントID>`(全リージョン・ログファイル検証有効) |
| 3 | Config レコーダー・配信チャネル・ロール + S3 | `default` / `sec-config-role` / `config-bucket-<アカウントID>` |
| 3 | Config マネージドルール | `s3-bucket-public-read-prohibited` / `restricted-ssh` / `root-account-mfa-enabled` |
| 4 | GuardDuty ディテクター | (自動採番) |
| 4 | SNS トピック + EventBridge ルール | `security-alerts` / `sec-guardduty-findings` |
| 5 | WAF Web ACL(`ALB_ARN` 指定時のみ) | `alb-protection`(REGIONAL、AWSManagedRulesCommonRuleSet) |

## 実行手順

### 前提

- AWS CLI v2 がインストールされ、管理者権限の認証情報が設定済みであること
- `bash`、`sed`、`python3`(任意。JSON 確認用)が使えること

### 1. 構築する

```bash
cd projects/05-security-monitoring/handson
chmod +x build.sh cleanup.sh

# 必須: 通知先メールアドレス
export ALERT_EMAIL="you@example.com"
# 任意: リージョン(既定は ap-northeast-1)、名前のプレフィックス(既定は sec)
export REGION="ap-northeast-1"
# 任意: レベル3 の ALB ARN を渡すと WAF も構築します
export ALB_ARN="arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:loadbalancer/app/xxxxx/xxxxx"

./build.sh
```

### 2. 動作を確認する

1. `ALERT_EMAIL` に届く SNS の確認メール(Subscription Confirmation)のリンクをクリックし、購読を承認します。承認しないと通知は届きません。
2. 証跡がロギング中か確認します。

```bash
aws cloudtrail get-trail-status --name org-management-trail --query "IsLogging"
```

3. Config ルールの評価結果を確認します(初回評価には数分かかります)。

```bash
aws configservice describe-compliance-by-config-rule --config-rule-names restricted-ssh
```

4. GuardDuty の通知経路を試すには、サンプル検出結果を生成すると EventBridge 経由でメールが届きます。

```bash
source .handson-state.env
aws guardduty create-sample-findings --detector-id "${DETECTOR_ID}"
```

5. IAM グループにユーザーを追加する場合は、必ず先にそのユーザーの MFA デバイスを登録してください(`ForceMFA` の Deny により、MFA なしでは登録操作以外ができなくなります)。

### 3. 削除する

```bash
./cleanup.sh
```

グループにユーザーを追加していた場合は、先に `aws iam remove-user-from-group` で外してから実行してください。

## 💰 コストに関する注意

**GuardDuty・AWS Config・WAF は、有効化している間ずっと課金され続けます。** 無料利用枠の対象ではありません(GuardDuty のみ初回 30 日間トライアルあり)。

- 学習・検証が終わったら、必ず `./cleanup.sh` を実行して無効化・削除してください
- `cleanup.sh` 実行後も、コンソールで GuardDuty(ディテクター)・Config(レコーダー)・WAF(Web ACL)が残っていないか最終確認することをおすすめします
- 実際の本番運用では逆に「常時有効にしておくべきサービス」である点も合わせて理解しておきましょう

コスト管理の考え方は [コスト管理ガイド](../../../docs/03-cost-management.md) を参照してください。

## 関連ドキュメント

- [レベル5 課題ドキュメント](../README.md)
- [コスト管理ガイド](../../../docs/03-cost-management.md)
