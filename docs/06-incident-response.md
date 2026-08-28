# 障害対応 Runbook

## 1. 初動の合言葉「止・見・守・直・残」

1. **止**: 変更作業を止める
2. **見**: 時刻、影響、アラーム、直前変更を見る
3. **守**: サービスと証跡を守る（ログを消さない）
4. **直**: 安全な回避・復旧を行う
5. **残**: タイムライン、原因、再発防止を残す

## 2. 重大度

| Severity | 例 | 初動目標（教材値） |
|---|---|---|
| SEV1 | 全利用者が閲覧不可、情報漏えい疑い | 即時エスカレーション |
| SEV2 | 片 AZ/一部機能異常、性能大幅劣化 | 15分以内に担当開始 |
| SEV3 | 冗長性低下、利用者影響なし | 営業時間内に対応計画 |

実案件では顧客の SLA と運用契約に合わせます。

## 3. 共通初動

```text
検知日時(JST):
検知元:
申告/Alarm内容:
利用者影響:
対象環境・Region:
直前変更:
指揮者/作業者/連絡担当:
次回更新時刻:
```

読み取り調査を優先し、再起動や削除は仮説と影響を記録してから行います。

## 4. サイトが開けない

切り分け順は **DNS → ALB → Target → OS → Application**。

1. ALB DNS が名前解決できるか。
2. ALB state と listener が正常か。
3. target health と reason code は何か。
4. Security Group の ALB→EC2:80 があるか。
5. SSM 接続できるか、nginx は active か。
6. `/health` は localhost で200か。
7. user data、nginx error log、ASG activity に異常がないか。

### 安全な回復候補

- 直前の誤設定を既知の正常な Terraform へ戻す。
- 1台だけ異常なら ASG に置換させる。
- AMI/user data の共通障害なら新規台数を増やす前に修正する。

## 5. SSM 接続できない

1. instance が running、SSM managed node が Online か。
2. instance profile と `AmazonSSMManagedInstanceCore` があるか。
3. private subnet から TCP/443 の出口があるか。
4. NAT の状態、経路、Network ACL、DNS を確認。
5. SSM Agent log と CloudWatch を確認。

SSH 22番を一時的に全世界へ開く対応は禁止です。

## 6. セキュリティ事故疑い

1. 認証情報を露出させず、検知情報と時刻を保存。
2. セキュリティ担当へ即時エスカレーション。
3. 侵害疑い instance を安易に terminate/reboot しない。
4. 証跡保全後、承認済み手順で通信隔離・資格情報無効化。
5. CloudTrail、VPC Flow Logs、ALB/OSログを関連付ける。

本教材はフォレンジック手順を実装していません。実案件では専用 Incident Response Plan を用意します。

## 7. 事後レビュー

- 何が起きたか（事実）
- 影響と時間
- 検知できた点 / できなかった点
- 根本原因と寄与要因
- 復旧を遅らせた点
- 再発防止（担当・期限・確認方法付き）

個人を責めず、仕組みを改善します。
