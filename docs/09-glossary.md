# 用語集

| 用語 | 説明 |
|---|---|
| CIDR | IPアドレス範囲の表記。`10.20.0.0/16` は VPC の範囲 |
| Internet Gateway | VPC とインターネットを接続する VPC コンポーネント |
| NAT Gateway | private 側から開始する外向き通信を中継するマネージドサービス |
| Stateful | 応答通信を自動的に許可する性質。Security Group が該当 |
| Stateless | 往路・復路を別々に規則化する性質。Network ACL が該当 |
| Health check | ALB が target の正常性を定期確認する仕組み |
| Desired capacity | ASG が維持しようとするインスタンス数 |
| IAM role | AWS サービスや利用者が一時的な権限を得る仕組み |
| IMDSv2 | EC2 内から metadata を取得する際のセッション指向方式 |
| IaC | インフラ設定をコードで宣言・再現・レビューする考え方 |
| Drift | コードと実環境の構成差分 |
| RTO | 障害後、復旧までに許容される時間 |
| RPO | 障害時に許容されるデータ損失時点 |
