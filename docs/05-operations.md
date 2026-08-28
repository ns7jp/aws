# 運用手順書

## 1. 日次・週次・月次

| 頻度 | 作業 | 異常の目安 | 次の行動 |
|---|---|---|---|
| 日次 | Alarm と target health | ALARM、healthy < 2 | 障害対応へ |
| 日次 | AWS Health / 未対応通知 | サービスイベント | 影響範囲確認 |
| 週次 | nginx/OS error log | 急増・反復エラー | 時刻と request ID で調査 |
| 週次 | EC2/ALB 使用状況 | CPU、5xx の継続上昇 | 容量・アプリ原因を切り分け |
| 月次 | パッチ・AMI 更新計画 | 古い package/AMI | 検証後 instance refresh |
| 月次 | IAM・SG・料金の棚卸し | 不要権限、広い許可、予算超過 | 変更申請・削除 |

## 2. アラーム対応

### CPU 高騰

1. Alarm の開始時刻・対象 ASG を確認。
2. ALB request count、target response time、5xx と相関を見る。
3. SSM で `top`、`ps`、`journalctl` を確認。
4. アクセス増なら scaling、プロセス異常なら切離し・置換を判断。

### ALB 5xx

1. `HTTPCode_ELB_5XX_Count` か target 5xx かを区別。
2. target health、nginx error log、user data 完了を確認。
3. 直前変更があればロールバック判断。

### Healthy host 不足

1. target health reason code を確認。
2. Security Group、nginx、`/health`、ASG activity を順に確認。
3. healthy が0になる前に変更停止・エスカレーション。

## 3. 定型変更

1. 変更理由、影響、ロールバック、試験、担当者を記録。
2. feature branch で Terraform を修正。
3. `fmt`、`validate`、静的チェック、plan を実施。
4. plan を別の人がレビュー。
5. 承認時間帯に apply。
6. ST-01、ST-04、変更固有試験を実施。
7. 証跡と構成管理記録を更新。

コンソールでの直接変更は緊急時に限定し、事後に Terraform へ反映して drift を解消します。

## 4. パッチ手順

Launch Template の user data または AMI を更新し、新バージョンを作ります。ASG instance refresh を使い、healthy capacity を維持しながら段階的に入れ替えます。開始前後で target health、ALB 5xx、アプリ疎通を確認します。

## 5. バックアップ

このデモは状態を持たないため、EC2 自体のバックアップより「コードから再作成できること」を優先します。実案件でデータを保持する場合は、データ分類、RPO/RTO、AWS Backup、復元試験、保管・暗号化・別アカウント保護を追加します。バックアップ取得成功だけでは不十分で、復元試験が必要です。

## 6. 監視の注意

アラームを作っただけでは運用になりません。通知先、受付時間、一次対応者、応答期限、エスカレーション先を決め、通知テストを実施してください。このリポジトリでは SNS ARN 未指定時に通知を無効化するため、実通知は `NOT RUN` です。
