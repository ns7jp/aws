# 面接説明ガイド

## 1. 60秒説明

> 小規模 Web サイトを想定し、Terraform で AWS の構築案件パックを設計しました。入口は2 AZ の ALB、サーバーは public IP を持たない private subnet の EC2 Auto Scaling です。通信はインターネットから ALB の80番、ALB から EC2 の80番だけに絞り、管理には SSH ではなく Session Manager を使います。CloudWatch で CPU、ALB 5xx、正常台数を監視し、試験・障害対応・削除まで手順化しました。学習環境と本番想定の NAT 冗長性や HTTPS の差も明示しています。

実 AWS で未実施なら最後に必ず「実環境 apply と試験は NOT RUN」と加えます。

## 2. よく聞かれる質問

### なぜ EC2 を private subnet に置いたのですか

利用者が直接 EC2 へ到達する必要がないからです。公開入口を ALB に限定し、EC2 は ALB Security Group からの80番だけ受けます。管理も Session Manager を使うため、公開IPやSSH開放を避けられます。

### なぜ2 AZですか

単一 AZ の障害で全台を失うリスクを下げるためです。ただし `lab` の NAT は費用優先で1台なので、出口は完全冗長ではありません。このトレードオフを本番へ持ち込まないことも設計判断です。

### Security Group と Network ACL の違いは

Security Group はリソースに付く stateful な許可リスト、Network ACL は subnet 境界の stateless な許可・拒否リストです。本構成では SG を主制御とし、NACL は既定値です。多層防御や明示拒否の要件があれば NACL を追加設計します。

### 構築できたことをどう証明しますか

Terraform apply 成功だけでは不十分です。HTTP 200、2 AZ 配置、public IP/SSHなし、target health、SSM、ログ、Alarm、障害時置換、再 plan、destroy を期待値付きで試験します。

### 改善するなら何を追加しますか

ACM/HTTPS、Route 53、WAF、VPC Flow Logs、CloudTrail/Config/GuardDuty、S3 backend、AMI パイプライン、AWS Backup、通知訓練、負荷試験です。要件・脅威・RTO/RPOに基づき優先順位を付けます。

## 3. STAR で話すテンプレート

- Situation: どんな顧客・課題を想定したか
- Task: 自分が満たすべき要件は何か
- Action: 何を調べ、どう比較し、何を実装・試験したか
- Result: 数値・PASS/FAIL・改善点は何か

## 4. 自己レビュー

- サービス名を並べるだけでなく、採用理由を言えるか。
- 制約・料金・単一障害点を隠していないか。
- 自分が実行したことと、設計だけのことを区別しているか。
- エラーや FAIL から何を直したかを説明できるか。
