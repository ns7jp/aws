# AWS用語集 ⑩略語一覧と総まとめテスト

> 📖 [用語集トップ(索引)に戻る](../02-glossary.md) ｜ 前ページ: [⑨Linux・サーバー運用の基礎](09-linux-server-basics.md)

## このページの使い方

このページは、①〜⑨で1つずつ覚えてきた用語を「横断して引く」ためのまとめページです。用語の意味そのものは各章に書いてあるので、ここでは**アルファベット略語から意味と該当章にたどり着くこと**、**まぎらわしい2つを一言で区別すること**、**覚えた知識を問題形式で確認すること**の3つに絞っています。

使う場面は大きく3つあります。1つ目は、案件のREADMEや求人票で見慣れない略語に出会ったときに、下の早見表で正体を確認する使い方です。2つ目は、面接前日に「2. まぎらわしい用語の対比」と「4. 総まとめテスト」だけを通しで読む使い方です。3つ目は、学習の順番に迷ったときに「5. 学習の進め方(30日ロードマップ)」を開く使い方です。

最初から全部を暗記する必要はありません。**わからなかった行の「詳しい説明」リンクをたどり、該当章のエントリを読み直す**——この往復を繰り返すことが、この用語集のいちばん効率のよい使い方です。

## 1. アルファベット略語 早見表

AWSの現場で飛び交う略語を、AWS固有のものと一般IT用語をまとめてアルファベット順に並べました。「詳しい説明」列は、その用語をフルで解説している章へのリンクです。

| 略語 | 読み方 | 正式名称 | 日本語での意味 | 詳しい説明 |
|---|---|---|---|---|
| ACM | エーシーエム | AWS Certificate Manager | HTTPS用のSSL/TLS証明書を無料で発行し、自動更新してくれるサービス | [⑥セキュリティ](06-security-identity.md#acm) |
| ALB | エーエルビー | Application Load Balancer | HTTP/HTTPSの中身を見て振り分けるロードバランサー | [②ネットワーク](02-network.md#alb) |
| AMI | エーエムアイ | Amazon Machine Image | EC2を起動するためのOS入りひな形イメージ | [③コンピューティング](03-compute.md#ami) |
| API | エーピーアイ | Application Programming Interface | ソフトウェア同士がやり取りするための決められた窓口 | [①クラウド基礎](01-cloud-basics.md#api) |
| ARN | アーン/エーアールエヌ | Amazon Resource Name | AWS上のすべてのリソースを一意に指し示す識別子 | [①クラウド基礎](01-cloud-basics.md#arn) |
| ASG | エーエスジー | Auto Scaling Group | EC2の台数を自動で増減・復旧させる管理単位 | [③コンピューティング](03-compute.md#auto-scaling-group) |
| AZ | エーゼット | Availability Zone | リージョン内にある、電源も回線も独立した拠点のまとまり | [①クラウド基礎](01-cloud-basics.md#アベイラビリティゾーン) |
| CD | シーディー | Continuous Delivery / Continuous Deployment | 継続的デリバリー/デプロイ。自動で配布・反映できる状態にする習慣 | [⑧IaCとCI/CD](08-iac-cicd.md#cd) |
| CDK | シーディーケー | AWS Cloud Development Kit | 普通のプログラミング言語でCloudFormationを生成する仕組み | [⑧IaCとCI/CD](08-iac-cicd.md#aws-cdk) |
| CDN | シーディーエヌ | Content Delivery Network | 利用者に近い拠点からコンテンツを配る配信網 | [②ネットワーク](02-network.md#cdn) |
| CI | シーアイ | Continuous Integration | 継続的インテグレーション。変更のたびに自動でビルド・テストする習慣 | [⑧IaCとCI/CD](08-iac-cicd.md#ci) |
| CI/CD | シーアイシーディー | Continuous Integration / Continuous Delivery | 自動テストから自動反映までを一続きにした開発運用の総称 | [⑧IaCとCI/CD](08-iac-cicd.md#ci) |
| CIDR | サイダー | Classless Inter-Domain Routing | IPアドレスの範囲を `10.0.0.0/16` のようにまとめて書く表記 | [②ネットワーク](02-network.md#cidr) |
| CLI | シーエルアイ | Command Line Interface | 文字のコマンドで操作する方式。AWS CLIはその実装 | [①クラウド基礎](01-cloud-basics.md#aws-cli) |
| CMS | シーエムエス | Content Management System | 記事や画像をブラウザから更新できるコンテンツ管理システム | [⑨Linux](09-linux-server-basics.md#cms) |
| CNAME | シーネーム | Canonical Name Record | ドメイン名を別のドメイン名に転送する別名レコード | [②ネットワーク](02-network.md#cnameレコード) |
| CPU | シーピーユー | Central Processing Unit | 計算処理を担う中央演算装置。AWSでは仮想化された単位をvCPUと呼ぶ | [③コンピューティング](03-compute.md#vcpu) |
| CRR | シーアールアール | Cross-Region Replication | S3バケットを別リージョンへ自動複製する機能 | [④ストレージ](04-storage.md#クロスリージョンレプリケーション) |
| DB | ディービー | Database | データベース。データを整理して保存し、取り出す仕組み | [⑤データベース](05-database.md#dbインスタンス) |
| DDoS | ディードス | Distributed Denial of Service | 多数の端末から一斉に負荷をかけてサービスを止める攻撃 | [⑥セキュリティ](06-security-identity.md#aws-shield) |
| DHCP | ディーエイチシーピー | Dynamic Host Configuration Protocol | 接続した機器へIPアドレスなどを自動で配る仕組み。VPCでは自動的に働く | [②ネットワーク](02-network.md) |
| DNS | ディーエヌエス | Domain Name System | ドメイン名をIPアドレスに変換するインターネットの電話帳 | [②ネットワーク](02-network.md#dns) |
| DR | ディーアール | Disaster Recovery | 大規模災害・広域障害からの復旧計画とその構成 | [①クラウド基礎](01-cloud-basics.md#ディザスタリカバリ) |
| EBS | イービーエス | Amazon Elastic Block Store | EC2に取り付けるネットワーク接続型の仮想ディスク | [④ストレージ](04-storage.md#ebs) |
| EC2 | イーシーツー | Amazon Elastic Compute Cloud | 必要なときだけ借りられるAWSの仮想サーバー | [③コンピューティング](03-compute.md#ec2) |
| ECR | イーシーアール | Amazon Elastic Container Registry | AWS上のプライベートなコンテナイメージ置き場 | [③コンピューティング](03-compute.md#ecr) |
| ECS | イーシーエス | Amazon Elastic Container Service | AWS独自のコンテナ管理(オーケストレーション)サービス | [③コンピューティング](03-compute.md#ecs) |
| EFS | イーエフエス | Amazon Elastic File System | 複数のEC2から同時にマウントできる共有ファイルストレージ | [④ストレージ](04-storage.md#efs) |
| EIP | イーアイピー | Elastic IP Address | 付け替えできる固定のパブリックIPアドレス | [②ネットワーク](02-network.md#elastic-ip) |
| EKS | イーケーエス | Amazon Elastic Kubernetes Service | AWSがマネージドで提供するKubernetes | [③コンピューティング](03-compute.md#eks) |
| ELB | イーエルビー | Elastic Load Balancing | AWSのマネージド型ロードバランサーの総称 | [②ネットワーク](02-network.md#elb) |
| ENI | イーエヌアイ | Elastic Network Interface | EC2などに取り付ける仮想的なLANポート | [②ネットワーク](02-network.md#eni) |
| FQDN | エフキューディーエヌ | Fully Qualified Domain Name | `www.example.com.` のように末尾まで省略しない完全な名前 | [②ネットワーク](02-network.md#dns) |
| GSI | ジーエスアイ | Global Secondary Index | DynamoDBで主キー以外の項目でも検索できるようにする索引 | [⑤データベース](05-database.md#グローバルセカンダリインデックス) |
| GUI | ジーユーアイ | Graphical User Interface | 画面上のボタンやメニューを見ながら操作する方式 | [①クラウド基礎](01-cloud-basics.md#gui) |
| HCL | エイチシーエル | HashiCorp Configuration Language | Terraformの設定を書くための専用記法 | [⑧IaCとCI/CD](08-iac-cicd.md#hcl) |
| HTTP | エイチティーティーピー | Hypertext Transfer Protocol | Webページをやり取りする通信の約束事(80番) | [②ネットワーク](02-network.md#http) |
| HTTPS | エイチティーティーピーエス | Hypertext Transfer Protocol Secure | HTTPをTLSで暗号化した通信(443番) | [②ネットワーク](02-network.md#https) |
| IaaS | イアース/アイアース | Infrastructure as a Service | サーバーやネットワークという「素材」だけを借りる形態 | [①クラウド基礎](01-cloud-basics.md#iaas) |
| IaC | アイエーシー | Infrastructure as Code | インフラの構成をコードとして書き、実行して再現する考え方 | [⑧IaCとCI/CD](08-iac-cicd.md#iac) |
| IAM | アイアム | AWS Identity and Access Management | 「誰が・何に・何をできるか」を管理する認証認可の仕組み | [⑥セキュリティ](06-security-identity.md#iam) |
| IGW | アイジーダブリュー | Internet Gateway | VPCとインターネットをつなぐ正面玄関 | [②ネットワーク](02-network.md#インターネットゲートウェイ) |
| IMDS | アイエムディーエス | Instance Metadata Service | インスタンス自身の情報を内部から取得できる仕組み | [③コンピューティング](03-compute.md#インスタンスメタデータ) |
| IMDSv2 | アイエムディーエスブイツー | Instance Metadata Service Version 2 | トークンを必須にした、安全なメタデータ取得方式 | [③コンピューティング](03-compute.md#imdsv2) |
| IOPS | アイオップス | Input/Output Operations Per Second | 1秒あたりに処理できる読み書きの回数 | [④ストレージ](04-storage.md#iops) |
| IP | アイピー | Internet Protocol | ネットワーク上の機器に住所を割り当てて届ける約束事 | [②ネットワーク](02-network.md#ipアドレス) |
| JSON | ジェイソン | JavaScript Object Notation | 波かっこと角かっこでデータ構造を表すテキスト形式 | [⑧IaCとCI/CD](08-iac-cicd.md#json) |
| KMS | ケーエムエス | AWS Key Management Service | 暗号化に使う鍵を作成・保管・利用制御する鍵管理サービス | [⑥セキュリティ](06-security-identity.md#kms) |
| LCU | エルシーユー | Load Balancer Capacity Unit | ALBの従量課金を測る単位 | [②ネットワーク](02-network.md#lcu) |
| MFA | エムエフエー | Multi-Factor Authentication | パスワードに加えてもう1段階本人確認する多要素認証 | [⑥セキュリティ](06-security-identity.md#mfa) |
| MTTR | エムティーティーアール | Mean Time To Repair / Mean Time To Recovery | 障害発生から復旧までにかかった時間の平均(平均復旧時間) | [⑦監視・運用](07-monitoring-operations.md#mttr) |
| NACL | ナックル/エヌエーシーエル | Network Access Control List | サブネット単位で通信を許可・拒否するルール | [②ネットワーク](02-network.md#ネットワークacl) |
| NAT | ナット | Network Address Translation | プライベートIPをパブリックIPに変換して外と通信させる仕組み | [②ネットワーク](02-network.md#nat) |
| NFS | エヌエフエス | Network File System | ネットワーク越しにディレクトリを共有する代表的な方式。EFSが採用 | [④ストレージ](04-storage.md#ファイルストレージ) |
| NLB | エヌエルビー | Network Load Balancer | TCP/UDPを高速にさばくロードバランサー | [②ネットワーク](02-network.md#nlb) |
| NoSQL | ノーエスキューエル | Not only SQL | 表形式にこだわらず、拡張性や速度を優先したデータベースの総称 | [⑤データベース](05-database.md#nosql) |
| NTP | エヌティーピー | Network Time Protocol | ネットワーク越しにサーバーの時計を正確に合わせる仕組み | [⑨Linux](09-linux-server-basics.md#ntp) |
| OAC | オーエーシー | Origin Access Control | CloudFrontだけがS3を読めるようにする現行の仕組み | [②ネットワーク](02-network.md#oac) |
| OAI | オーエーアイ | Origin Access Identity | OACの前身にあたる旧方式 | [②ネットワーク](02-network.md#oai) |
| OIDC | オーアイディーシー | OpenID Connect | 長期のアクセスキーを置かずに一時認証情報を得る連携方式 | [⑧IaCとCI/CD](08-iac-cicd.md#oidc) |
| OS | オーエス | Operating System | ハードウェアとアプリの橋渡しをする基本ソフト。サーバーではLinuxが主流 | [⑨Linux](09-linux-server-basics.md#linux) |
| PaaS | パース | Platform as a Service | OSやミドルウェアまで用意された「土台」を借りる形態 | [①クラウド基礎](01-cloud-basics.md#paas) |
| PHP | ピーエイチピー | PHP: Hypertext Preprocessor | WordPressなどWebアプリで広く使われるプログラミング言語 | [⑨Linux](09-linux-server-basics.md#php) |
| PITR | ピーアイティーアール | Point-in-Time Recovery | 保持期間内の任意の時刻の状態へデータベースを復元する機能 | [⑤データベース](05-database.md#ポイントインタイムリカバリ) |
| RDB | アールディービー | Relational Database | データを表形式で持ち、表同士を関連付けて扱うデータベース | [⑤データベース](05-database.md#リレーショナルデータベース) |
| RDS | アールディーエス | Amazon Relational Database Service | AWSが運用を代行してくれるマネージドなリレーショナルデータベース | [⑤データベース](05-database.md#rds) |
| REST | レスト | Representational State Transfer | HTTPの作法に沿ってリソースを操作するAPIの設計スタイル | [④ストレージ](04-storage.md#rest-apiエンドポイント) |
| RI | アールアイ | Reserved Instances | 1年・3年の利用を予約して割引を受ける購入方式 | [①クラウド基礎](01-cloud-basics.md#リザーブドインスタンス) |
| RPO | アールピーオー | Recovery Point Objective | 障害時に失っても許容できるデータ量(時間)の目標。目標復旧時点 | [①クラウド基礎](01-cloud-basics.md#rpo) |
| RTO | アールティーオー | Recovery Time Objective | 障害発生から復旧までに許容できる時間の目標。目標復旧時間 | [①クラウド基礎](01-cloud-basics.md#rto) |
| S3 | エススリー | Amazon Simple Storage Service | AWSの代表的なオブジェクトストレージ。容量ほぼ無制限の貸倉庫 | [④ストレージ](04-storage.md#s3) |
| SaaS | サース | Software as a Service | 完成したソフトウェアをサービスとして使う形態 | [①クラウド基礎](01-cloud-basics.md#saas) |
| SCP | エスシーピー | Service Control Policy | 組織全体でアカウントの権限の上限を決めるOrganizationsの仕組み | [⑥セキュリティ](06-security-identity.md#サービスコントロールポリシー) |
| SDK | エスディーケー | Software Development Kit | プログラムからAWSを操作するための言語別ライブラリ | [①クラウド基礎](01-cloud-basics.md#aws-sdk) |
| SG | エスジー | Security Group | リソース単位で通信を許可する仮想ファイアウォール | [②ネットワーク](02-network.md#セキュリティグループ) |
| SLA | エスエルエー | Service Level Agreement | サービスの稼働率について提供側が公開している約束(契約) | [①クラウド基礎](01-cloud-basics.md#sla) |
| SLI | エスエルアイ | Service Level Indicator | サービスの品質を測るために選んだ、具体的な指標 | [⑦監視・運用](07-monitoring-operations.md#sli) |
| SLO | エスエルオー | Service Level Objective | そのSLIをどの水準まで満たすかという、自分たちで決める目標値 | [⑦監視・運用](07-monitoring-operations.md#slo) |
| SMB | エスエムビー | Server Message Block | Windowsで一般的なファイル共有の方式。FSxが対応 | [④ストレージ](04-storage.md#fsx) |
| SNS | エスエヌエス | Amazon Simple Notification Service | 1回の投げ込みを複数の宛先へ同時に配る通知サービス | [⑦監視・運用](07-monitoring-operations.md#sns) |
| SPOF | スポフ | Single Point of Failure | そこが壊れると全体が止まってしまう箇所。単一障害点 | [①クラウド基礎](01-cloud-basics.md#単一障害点) |
| SQL | エスキューエル/シークェル | Structured Query Language | リレーショナルデータベースを操作するための問い合わせ言語 | [⑤データベース](05-database.md#sql) |
| SQS | エスキューエス | Amazon Simple Queue Service | 処理待ちのメッセージを順番に貯めておくマネージドな行列 | [⑦監視・運用](07-monitoring-operations.md#sqs) |
| SSD | エスエスディー | Solid State Drive | 半導体を使った高速なディスク。EBSのgp3などが該当 | [④ストレージ](04-storage.md#gp3) |
| SSE | エスエスイー | Server-Side Encryption | 受け取った側(サーバー側)で自動的に暗号化して保存する方式 | [④ストレージ](04-storage.md#sse-s3) |
| SSE-KMS | エスエスイーケーエムエス | Server-Side Encryption with AWS KMS keys | KMSの鍵を使って暗号化し、鍵の利用履歴も残す方式 | [④ストレージ](04-storage.md#sse-kms) |
| SSE-S3 | エスエスイーエススリー | Server-Side Encryption with Amazon S3 managed keys | S3が管理する鍵で自動的に暗号化する保管時の暗号化 | [④ストレージ](04-storage.md#sse-s3) |
| SSH | エスエスエイチ | Secure Shell | サーバーへ暗号化された経路で遠隔ログインする方式(22番) | [②ネットワーク](02-network.md#sshプロトコル) |
| SSL | エスエスエル | Secure Sockets Layer | 通信を暗号化する旧世代の規格。現在の実体はTLSだが呼び名として残る | [②ネットワーク](02-network.md#tls) |
| SSM | エスエスエム | AWS Systems Manager | サーバーの運用作業をまとめて行うAWSの運用管理ツール群 | [⑦監視・運用](07-monitoring-operations.md#systems-manager) |
| STS | エスティーエス | AWS Security Token Service | 一時的な認証情報を発行するAWSのトークン発行所 | [⑥セキュリティ](06-security-identity.md#aws-sts) |
| TCP | ティーシーピー | Transmission Control Protocol | 確実に届けることを重視した通信の約束事 | [②ネットワーク](02-network.md#tcp) |
| TGW | ティージーダブリュー | Transit Gateway | 多数のVPCや拠点を束ねる中継ハブ | [②ネットワーク](02-network.md#transit-gateway) |
| TLS | ティーエルエス | Transport Layer Security | 通信を暗号化し、相手が本物かを証明する仕組み | [②ネットワーク](02-network.md#tls) |
| TTL | ティーティーエル | Time To Live | DNSの答えを何秒間キャッシュしてよいかの有効期限 | [②ネットワーク](02-network.md#ttl) |
| UDP | ユーディーピー | User Datagram Protocol | 速さを重視し、到達確認を省いた通信の約束事 | [②ネットワーク](02-network.md#udp) |
| URL | ユーアールエル | Uniform Resource Locator | Web上の資源の場所を表す文字列。署名付きURLで期限も付けられる | [②ネットワーク](02-network.md#署名付きurl) |
| UTC | ユーティーシー | Coordinated Universal Time | 世界共通の基準時刻(協定世界時)。AWSの既定はこちら | [⑨Linux](09-linux-server-basics.md#utc) |
| vCPU | ブイシーピーユー | virtual CPU | インスタンスに割り当てられる仮想的なCPUの数 | [③コンピューティング](03-compute.md#vcpu) |
| VPC | ブイピーシー | Virtual Private Cloud | AWS上に自分専用に区切って作る仮想ネットワーク | [②ネットワーク](02-network.md#vpc) |
| VPN | ブイピーエヌ | Virtual Private Network | 公衆回線の上に暗号化した専用線のような経路を作る技術 | [②ネットワーク](02-network.md) |
| WAF | ワフ | Web Application Firewall | Webアプリへの攻撃をリクエスト単位で検知・遮断する仕組み | [⑥セキュリティ](06-security-identity.md#aws-waf) |
| XSS | エックスエスエス | Cross-Site Scripting | Webページに悪意あるスクリプトを埋め込み、閲覧者の画面で実行させる攻撃 | [⑥セキュリティ](06-security-identity.md#xss) |
| YAML | ヤムル | YAML Ain't Markup Language | インデント(字下げ)で構造を表す、人が読みやすいテキスト形式 | [⑧IaCとCI/CD](08-iac-cicd.md#yaml) |

> 🧠 **覚え方のコツ**: 略語は「頭文字を思い出す」より「**どの階層の話か**」で引くほうが速く身につきます。`VPC / SG / NACL / IGW / NAT / ALB / NLB` はネットワーク階層、`EC2 / AMI / ASG / ECS / EKS` は計算階層、`S3 / EBS / EFS` は保存階層、`IAM / KMS / ACM / WAF / SCP` は防御階層、`CloudWatch / SNS / SSM / SLI / SLO / MTTR` は運用階層、`IaC / HCL / CI/CD / OIDC` は自動化階層です。**6つの階層の引き出し**を作って、そこに略語を放り込んでいってください。

## 2. まぎらわしい用語の対比(早見表)

面接で差がつくのは「知っているか」ではなく「**似た2つを一言で区別できるか**」です。ここは声に出して言えるようになるまで繰り返してください。

| 用語A | 用語B | 一番の違い | 覚え方 |
|---|---|---|---|
| [セキュリティグループ](02-network.md#セキュリティグループ) | [ネットワークACL](02-network.md#ネットワークacl) | SGはリソース単位でステートフル(戻りは自動許可)、NACLはサブネット単位でステートレス(戻りも明示的に許可が必要)。SGは許可のみ、NACLは拒否も書ける | SGは「個人のIDカード」、NACLは「フロア入口の警備員」 |
| [Multi-AZ](05-database.md#multi-az) | [リードレプリカ](05-database.md#リードレプリカ) | Multi-AZは可用性のための待機系(同期・アクセス不可)、リードレプリカは性能のための読み取り用複製(非同期・アクセス可) | 「控えの金庫室」と「閲覧用の写し」 |
| [IAMユーザー](06-security-identity.md#iamユーザー) | [IAMロール](06-security-identity.md#iamロール) | ユーザーは人に紐づく恒久的な身分証、ロールは誰でも一時的に借りられる期限付きの身分証 | 「社員証」と「来客用の一時入館証」 |
| [スケールアップ](01-cloud-basics.md#スケールアップ) | [スケールアウト](01-cloud-basics.md#スケールアウト) | アップは1台の性能を大きくする(垂直)、アウトは台数を増やす(水平) | 「部屋を広くする」と「部屋を増やす」 |
| [ALB](02-network.md#alb) | [NLB](02-network.md#nlb) | ALBはHTTP/HTTPSの中身(パス・ホスト名)を見て振り分ける、NLBはTCP/UDPをそのまま超高速でさばく | 「中身を読む受付」と「そのまま通す交通整理」 |
| [EBS](04-storage.md#ebs) | [S3](04-storage.md#s3) | EBSはEC2に取り付けて「ドライブ」として見えるブロックストレージ、S3はHTTP経由で預けるオブジェクトストレージ | 「部屋の作り付け収納」と「外にある貸倉庫」 |
| [EBS](04-storage.md#ebs) | [インスタンスストア](03-compute.md#インスタンスストア) | EBSはネットワーク接続型で停止しても残る、インスタンスストアは物理ホスト直結で終了・停止すると消える | 「持ち出せる収納」と「部屋を出たら捨てられる備品」 |
| [同期レプリケーション](05-database.md#同期レプリケーション) | [非同期レプリケーション](05-database.md#非同期レプリケーション) | 同期は複製先の書き込み完了を待つ(遅れゼロだが遅い)、非同期は待たない(速いが遅れが出る) | 「相手の受領印を待つ」と「投函したら次の仕事へ」 |
| [RTO](01-cloud-basics.md#rto) | [RPO](01-cloud-basics.md#rpo) | RTOは「復旧までの時間」の目標、RPOは「失ってよいデータの時間幅」の目標 | RTOのTはTime(時間)、RPOのPはPoint(どの時点まで戻せるか) |
| [CloudTrail](06-security-identity.md#cloudtrail) | [CloudWatch Logs](07-monitoring-operations.md#cloudwatch-logs) | CloudTrailは「誰がAWSを操作したか」の証跡、CloudWatch Logsはサーバーやアプリが出したログの置き場 | 「防犯カメラの録画」と「各部屋の業務日誌」 |
| [CloudWatch](07-monitoring-operations.md#cloudwatch) | [AWS Config](06-security-identity.md#aws-config) | CloudWatchは動作状況(数値・ログ)を監視、Configはリソースの設定内容が正しいかを評価・記録 | 「体温計」と「持ち物検査の点検簿」 |
| [インバウンド](02-network.md#インバウンド) | [アウトバウンド](02-network.md#アウトバウンド) | インバウンドは外から中へ入る通信、アウトバウンドは中から外へ出る通信 | 「来客」と「外出」。SGの既定はインバウンド全拒否・アウトバウンド全許可 |
| [パブリックサブネット](02-network.md#パブリックサブネット) | [プライベートサブネット](02-network.md#プライベートサブネット) | 違いはサブネット自体の種類ではなく、[ルートテーブル](02-network.md#ルートテーブル)に `0.0.0.0/0` → IGWの経路があるかどうか | 「道路に面した棟」と「奥の事務所棟」。玄関につながる廊下があるかで決まる |
| [インターネットゲートウェイ](02-network.md#インターネットゲートウェイ) | [NATゲートウェイ](02-network.md#natゲートウェイ) | IGWは双方向の出入口(VPCに1つ)、NATゲートウェイは中から外への片道専用(サブネットに配置し課金される) | 「正面玄関」と「外向き専用の通用口」 |
| 認証 | 認可 | 認証は「あなたが誰か」を確かめること、認可は「その人に何を許すか」を決めること | 認証は[MFA](06-security-identity.md#mfa)、認可は[IAMポリシー](06-security-identity.md#iamポリシー)。IDカードを見せるのが認証、開く扉が決まるのが認可 |
| [ステートフル](02-network.md#ステートフル) | [ステートレス](02-network.md#ステートレス) | ステートフルは状態を覚えている、ステートレスは1回ごとに独立している | SGはステートフル、NACLはステートレス。サーバー設計では[ステートレス](03-compute.md#ステートレス)が正義 |
| [オンデマンド](01-cloud-basics.md#オンデマンド) | [リザーブドインスタンス](01-cloud-basics.md#リザーブドインスタンス) | オンデマンドは契約なしの定価、RIは1年・3年の利用を約束して割引を受ける | 「都度払い」と「年間パスポート」。学習中は必ずオンデマンド |
| [可用性](01-cloud-basics.md#可用性) | [耐久性](04-storage.md#耐久性) | 可用性は「使えている割合」、耐久性は「データを失わない度合い」 | 「店が開いているか」と「預けた荷物が無事か」 |
| [Redis](05-database.md#redis) | [Memcached](05-database.md#memcached) | Redisは多機能でレプリケーションや永続化に対応、Memcachedは単純なキーと値に特化した軽量型 | 「多機能な冷蔵庫」と「保冷ボックス」。セッションストアならRedis |
| [CloudFormation](08-iac-cicd.md#cloudformation) | [Terraform](08-iac-cicd.md#terraform) | CloudFormationはAWS純正でYAML/JSON、TerraformはHashiCorp製でHCL。Terraformは複数クラウドを同じ書き方で扱える | 「純正部品」と「社外品の万能工具」 |
| [terraform plan](08-iac-cicd.md#terraform-plan) | [terraform apply](08-iac-cicd.md#terraform-apply) | planは差分を見るだけ(何も変えない)、applyは実際にAWSへ反映する | 「見積書」と「着工」。planを読まないapplyは事故のもと |
| [ブルーグリーンデプロイ](08-iac-cicd.md#ブルーグリーンデプロイ) | [カナリアリリース](08-iac-cicd.md#カナリアリリース) | ブルーグリーンは新旧2環境を用意して一気に切り替える、カナリアは一部の利用者にだけ先に出して様子を見る | 「引っ越し」と「試食販売」 |
| [ローリングアップデート](08-iac-cicd.md#ローリングアップデート) | [ブルーグリーンデプロイ](08-iac-cicd.md#ブルーグリーンデプロイ) | ローリングは同じ環境の中で少しずつ入れ替える、ブルーグリーンは環境ごと用意して切り替える | 「1部屋ずつ改装」と「隣に新築して引っ越す」 |
| [自動バックアップ](05-database.md#自動バックアップ) | [DBスナップショット](05-database.md#dbスナップショット) | 自動バックアップは保持期間が過ぎると消え、DBインスタンス削除で失われる。手動スナップショットは明示的に消すまで残る | 「自動で撮って自動で捨てる写真」と「アルバムに貼った写真」 |
| [SNS](07-monitoring-operations.md#sns) | [SQS](07-monitoring-operations.md#sqs) | SNSは1件を複数の宛先へ同時に配る同報(プッシュ型)、SQSは貯めておいて受け手が取りに来る(プル型) | 「館内一斉放送」と「順番待ちの行列」 |
| [宣言型](08-iac-cicd.md#宣言型) | 手続き型 | 宣言型は「あるべき最終形」を書く、手続き型は「手順」を書く | 「完成図を渡す」と「作り方を1手順ずつ指示する」。IaCは宣言型 |
| [Fargate](03-compute.md#fargate) | [EC2](03-compute.md#ec2) | Fargateはコンテナだけ動かせばよくホストの管理が不要、EC2はOSから自分で面倒を見る | 「調理器具ごと借りる」と「厨房を借りて自分で揃える」 |
| [エイリアスレコード](02-network.md#エイリアスレコード) | [CNAMEレコード](02-network.md#cnameレコード) | エイリアスはRoute 53独自でZone Apex(`example.com` 自体)にも使え追加課金がない、CNAMEはZone Apexに使えない | 「AWS専用の直通番号」と「一般的な転送設定」 |

## 3. 用語をつなげて覚えるストーリー

用語を1つずつ覚えるより、「1台のWebサーバーが利用者に届くまで」を1本の物語として通しで思い出すほうが、実務でも面接でも役に立ちます。以下を頭の中で映像として再生できるようになれば、①〜⑨の主要用語はつながって出てきます。

1. まず私たちは**[AWSアカウント](01-cloud-basics.md#awsアカウント)**という契約を結び、最強権限の**[ルートユーザー](01-cloud-basics.md#ルートユーザー)**には**[MFA](06-security-identity.md#mfa)**をかけて金庫にしまい、普段使いの**[IAMユーザー](06-security-identity.md#iamユーザー)**を作ります。
2. 東京という**[リージョン](01-cloud-basics.md#リージョン)**を選び、その中の2つの**[アベイラビリティゾーン](01-cloud-basics.md#アベイラビリティゾーン)**を使うと決めます。1つのAZに寄せると、そこが**[単一障害点](01-cloud-basics.md#単一障害点)**になるからです。
3. 自分専用の敷地として**[VPC](02-network.md#vpc)** `10.0.0.0/16` を切り、**[CIDR](02-network.md#cidr)**で区切った**[サブネット](02-network.md#サブネット)**を、AZごとに**[パブリックサブネット](02-network.md#パブリックサブネット)**と**[プライベートサブネット](02-network.md#プライベートサブネット)**の2種類ずつ用意します。
4. 敷地に**[インターネットゲートウェイ](02-network.md#インターネットゲートウェイ)**という正面玄関を付け、**[ルートテーブル](02-network.md#ルートテーブル)**に `0.0.0.0/0` → IGWと書いた瞬間、そのサブネットは「パブリック」になります。奥の棟からOS更新だけしたいので、外向き片道の**[NATゲートウェイ](02-network.md#natゲートウェイ)**も置きます。
5. 部屋を建てます。**[AMI](03-compute.md#ami)**というひな形と**[インスタンスタイプ](03-compute.md#インスタンスタイプ)**を選び、**[ユーザーデータ](03-compute.md#ユーザーデータ)**に初期設定を書いて**[EC2](03-compute.md#ec2)**を起動。ディスクは**[EBS](04-storage.md#ebs)**の**[gp3](04-storage.md#gp3)**です。
6. 部屋の中では**[Linux](09-linux-server-basics.md#linux)**が動いています。**[dnf](09-linux-server-basics.md#dnf)**で**[Apache](09-linux-server-basics.md#apache)**を入れ、**[systemctl](09-linux-server-basics.md#systemctl)**で常駐させ、**[ドキュメントルート](09-linux-server-basics.md#ドキュメントルート)**にHTMLを置くと、ようやく1ページが表示されます。
7. その部屋の扉に貼る許可リストが**[セキュリティグループ](02-network.md#セキュリティグループ)**です。80番と443番だけを開け、22番は開けません。代わりに**[Session Manager](07-monitoring-operations.md#session-manager)**で中に入ります。
8. 1台では止まるので、**[起動テンプレート](03-compute.md#起動テンプレート)**を作り、**[Auto Scaling Group](03-compute.md#auto-scaling-group)**に「最小2・最大4」を渡します。壊れた部屋は捨てて作り直す、これが**[オートヒーリング](03-compute.md#オートヒーリング)**です。
9. 2台に振り分ける受付が**[ALB](02-network.md#alb)**。振り分け先の名簿が**[ターゲットグループ](02-network.md#ターゲットグループ)**で、**[ヘルスチェック](02-network.md#ヘルスチェック)**に落ちた部屋には案内しません。
10. データは奥の金庫室**[RDS](05-database.md#rds)**へ。**[プライベートサブネット](02-network.md#プライベートサブネット)**に置き、**[Multi-AZ](05-database.md#multi-az)**で控えを持ち、アプリは**[DBエンドポイント](05-database.md#dbエンドポイント)**という代表電話にだけかけます。よく読む値は**[ElastiCache](05-database.md#elasticache)**の早見表に載せます。
11. 画像は部屋に置かず、外の貸倉庫**[S3](04-storage.md#s3)**に**[オフロード](04-storage.md#オフロード)**します。こうしてサーバーが状態を持たない**[ステートレス](03-compute.md#ステートレス)**な形になり、何台に増やしても同じ結果を返せます。
12. 世界中から速く見せるため、前段に**[CloudFront](02-network.md#cloudfront)**を置き、**[OAC](02-network.md#oac)**でS3を非公開のまま読ませます。名前は**[Route 53](02-network.md#route-53)**の**[エイリアスレコード](02-network.md#エイリアスレコード)**で結び、**[ACM](06-security-identity.md#acm)**の証明書で**[HTTPS](02-network.md#https)**にします。
13. 動き出したら見張ります。**[CloudWatch](07-monitoring-operations.md#cloudwatch)**の**[メトリクス](07-monitoring-operations.md#メトリクス)**に**[しきい値](07-monitoring-operations.md#しきい値)**を決めて**[CloudWatchアラーム](07-monitoring-operations.md#cloudwatchアラーム)**を作り、鳴ったら**[SNS](07-monitoring-operations.md#sns)**がメールで人を呼びます。
14. 守りも重ねます。入口に**[AWS WAF](06-security-identity.md#aws-waf)**、操作の記録に**[CloudTrail](06-security-identity.md#cloudtrail)**、設定の点検に**[AWS Config](06-security-identity.md#aws-config)**、脅威検知に**[GuardDuty](06-security-identity.md#guardduty)**。パスワードは**[Secrets Manager](06-security-identity.md#secrets-manager)**に預け、EC2には**[IAMロール](06-security-identity.md#iamロール)**を渡してアクセスキーは置きません。これが**[多層防御](06-security-identity.md#多層防御)**です。
15. 消えたら困るものは**[AWS Backup](04-storage.md#aws-backup)**で毎日取り、**[保持期間](04-storage.md#保持期間)**を決めます。ここで決めた間隔が、そのまま**[RPO](01-cloud-basics.md#rpo)**になります。
16. 最後に、ここまでの全部を**[Terraform](08-iac-cicd.md#terraform)**の**[HCL](08-iac-cicd.md#hcl)**で書き直し、**[tfstate](08-iac-cicd.md#tfstate)**をS3に置き、**[プルリクエスト](08-iac-cicd.md#プルリクエスト)**でレビューし、**[terraform plan](08-iac-cicd.md#terraform-plan)**の結果に**[手動承認](08-iac-cicd.md#手動承認)**のハンコを押してから**[terraform apply](08-iac-cicd.md#terraform-apply)**する。ここまで来て、ようやく「**[IaC](08-iac-cicd.md#iac)**で運用している」と言えます。

> 🧠 **覚え方のコツ**: この物語は「**契約 → 敷地 → 部屋 → 扉 → 台数 → 受付 → 金庫 → 倉庫 → 出張所 → 見張り → 守り → 控え → 設計図**」の13段です。面接で構成を説明するときも、この順番でしゃべれば話が飛びません。

## 4. 総まとめテスト(全50問)

紙に答えを書いてから照合すると定着します。答えを見て「知っている」と思っても、**声に出して1〜2文で言えるか**を必ず確かめてください。

### 4-1. 初級(20問)

| # | 問題 | 答え |
|---|---|---|
| 1 | リージョンとアベイラビリティゾーンの関係を説明してください | [リージョン](01-cloud-basics.md#リージョン)は世界各地にある地理的な単位で、その中に電源も回線も独立した複数の[アベイラビリティゾーン](01-cloud-basics.md#アベイラビリティゾーン)があります |
| 2 | VPCとサブネットの関係は何ですか | [VPC](02-network.md#vpc)が自分専用の「敷地」で、[サブネット](02-network.md#サブネット)はそれをAZ単位でさらに区切った「棟」です |
| 3 | あるサブネットが「パブリック」と言えるのはどんなときですか | [ルートテーブル](02-network.md#ルートテーブル)に `0.0.0.0/0` → [インターネットゲートウェイ](02-network.md#インターネットゲートウェイ)の経路があるときです |
| 4 | セキュリティグループはステートフルとステートレスのどちらですか | ステートフルです。行きの通信を許可すれば、戻りの通信は自動的に許可されます |
| 5 | SSH・HTTP・HTTPSの標準ポート番号はそれぞれ何番ですか | SSHが22番、HTTPが80番、HTTPSが443番です |
| 6 | S3でデータを入れる「入れ物」を何と呼びますか | [バケット](04-storage.md#バケット)です。名前は全世界で一意である必要があります |
| 7 | EC2のディスクにあたるサービスは何ですか | [EBS](04-storage.md#ebs)です。EC2に取り付けて使うブロックストレージです |
| 8 | AMIとは何ですか | [AMI](03-compute.md#ami)は、OSやソフトを設定済みの状態で保存した、EC2起動用のひな形イメージです |
| 9 | Elastic IPは何のために使いますか | 停止・起動してもパブリックIPが変わらないようにするためです。[Elastic IP](02-network.md#elastic-ip)は付け替えできる固定のパブリックIPです |
| 10 | IAMユーザーとIAMロールの違いを一言で | [IAMユーザー](06-security-identity.md#iamユーザー)は人に紐づく恒久的な身分証、[IAMロール](06-security-identity.md#iamロール)は一時的に借りる期限付きの身分証です |
| 11 | ルートユーザーはどう扱うべきですか | [MFA](06-security-identity.md#mfa)を必ず設定し、日常操作には使わずIAMユーザーを使います。請求設定など一部の操作でだけ使います |
| 12 | MFAとは何ですか | パスワードに加えて、スマートフォンのワンタイムコードなど別の要素でも本人確認する[多要素認証](06-security-identity.md#mfa)です |
| 13 | CloudWatchが扱う「数値」と「文字」はそれぞれ何と呼ばれますか | 数値が[メトリクス](07-monitoring-operations.md#メトリクス)、文字が[CloudWatch Logs](07-monitoring-operations.md#cloudwatch-logs)です |
| 14 | アラームをメールで受け取るために使うサービスは何ですか | [SNS](07-monitoring-operations.md#sns)です。トピックを作り、メールアドレスをサブスクリプションとして登録します |
| 15 | RDSのMulti-AZは何のための仕組みですか | 可用性のためです。別AZの[スタンバイ](05-database.md#スタンバイ)へ自動で[フェイルオーバー](01-cloud-basics.md#フェイルオーバー)します。性能向上のためではありません |
| 16 | リードレプリカは何のための仕組みですか | 読み取り性能の向上(参照処理の分散)のためです。[リードレプリカ](05-database.md#リードレプリカ)は非同期で複製されます |
| 17 | ロードバランサーのヘルスチェックは何をしていますか | 振り分け先が正常に応答するかを定期的に確認し、異常なターゲットには通信を流さないようにしています |
| 18 | Route 53はどんなサービスですか | AWSの[DNS](02-network.md#dns)およびドメイン登録サービスです。名前からIPアドレスを引けるようにします |
| 19 | CloudFrontはどんなサービスですか | AWSの[CDN](02-network.md#cdn)です。世界中のエッジ拠点にキャッシュを置き、利用者に近い場所から配信します |
| 20 | 使い終わった検証環境で、真っ先に確認すべきことは何ですか | 消し忘れによる課金です。特に[NATゲートウェイ](02-network.md#natゲートウェイ)・[Elastic IP](02-network.md#elastic-ip)・[EBS](04-storage.md#ebs)・RDSは起動していなくても課金される場合があります |

### 4-2. 中級(20問)

| # | 問題 | 答え |
|---|---|---|
| 21 | セキュリティグループとネットワークACLはどう使い分けますか | 通常の許可設定は[セキュリティグループ](02-network.md#セキュリティグループ)で行い、[ネットワークACL](02-network.md#ネットワークacl)は「特定IPをサブネット全体で拒否したい」など、拒否が必要な場面の補助として使います |
| 22 | プライベートサブネットのEC2がOS更新をするには何が必要ですか | [NATゲートウェイ](02-network.md#natゲートウェイ)経由の外向き経路、または必要なサービスへの[VPCエンドポイント](02-network.md#vpcエンドポイント)です |
| 23 | Session ManagerでEC2に接続できる条件を3つ挙げてください | SSM Agentが動作していること、[AmazonSSMManagedInstanceCore](07-monitoring-operations.md#amazonssmmanagedinstancecore)を含むIAMロールが付いていること、SSMエンドポイントへの通信経路があることです |
| 24 | ALBとNLBはどう選び分けますか | HTTP/HTTPSでパスやホスト名による振り分けが必要なら[ALB](02-network.md#alb)、TCP/UDPをそのまま極めて低いレイテンシでさばきたい、固定IPが欲しいなら[NLB](02-network.md#nlb)です |
| 25 | S3を公開せずCloudFrontから配信するにはどうしますか | [OAC](02-network.md#oac)を設定し、[バケットポリシー](04-storage.md#バケットポリシー)でそのディストリビューションからのアクセスだけを許可します。[ブロックパブリックアクセス](04-storage.md#ブロックパブリックアクセス)は有効のままにします |
| 26 | CloudFrontで使うACM証明書のリージョン制約は何ですか | バージニア北部(`us-east-1`)で発行した[ACM](06-security-identity.md#acm)証明書である必要があります。ALB用は同一リージョンで発行します |
| 27 | 請求額のアラームを作るとき注意すべきリージョンはどこですか | バージニア北部(`us-east-1`)です。[EstimatedCharges](07-monitoring-operations.md#estimatedcharges)はそこにしか存在しません |
| 28 | Auto Scaling Groupのヘルスチェックタイプを `ELB` にする理由は何ですか | EC2チェックだけではOSが生きていれば「正常」と判定され、Webサーバーが停止していても入れ替わらないためです。[ヘルスチェックタイプ](03-compute.md#ヘルスチェックタイプ)をELBにすると応答内容で判定できます |
| 29 | EBSとインスタンスストアの決定的な違いは何ですか | [EBS](04-storage.md#ebs)は停止しても内容が残るネットワーク接続型、[インスタンスストア](03-compute.md#インスタンスストア)は物理ホスト直結で停止・終了すると消えます |
| 30 | EBSスナップショットは毎回フルバックアップですか | いいえ。2回目以降は変更分だけを保存する[増分バックアップ](04-storage.md#増分バックアップ)です。ただし復元は常にその時点の完全な状態に戻せます |
| 31 | S3のバージョニングを有効にすると何が変わりますか | 上書き・削除しても旧世代が残ります([バージョニング](04-storage.md#バージョニング))。誤削除に強くなる一方、旧世代も課金対象になるため[ライフサイクルルール](04-storage.md#ライフサイクルルール)での整理が要ります |
| 32 | RDSの自動バックアップとDBスナップショットの違いは何ですか | [自動バックアップ](05-database.md#自動バックアップ)は保持期間が過ぎると消え、DBインスタンス削除時に原則失われます。手動の[DBスナップショット](05-database.md#dbスナップショット)は明示的に削除するまで残ります |
| 33 | ポイントインタイムリカバリでは何ができますか | 保持期間内の任意の時刻の状態へ復元できます([ポイントインタイムリカバリ](05-database.md#ポイントインタイムリカバリ))。復元先は既存インスタンスへの上書きではなく新しいDBインスタンスです |
| 34 | ElastiCacheのRedisとMemcachedはどう選びますか | セッション保持やレプリケーション・永続化が必要なら[Redis](05-database.md#redis)、単純なキーと値の高速キャッシュだけなら[Memcached](05-database.md#memcached)です |
| 35 | Webサーバーをステートレスにするには何を外に出しますか | セッション情報を[セッションストア](05-database.md#セッションストア)(ElastiCacheなど)へ、アップロードファイルを[S3](04-storage.md#s3)へ出します |
| 36 | IAMポリシーの評価で最も優先されるのは何ですか | [明示的な拒否](06-security-identity.md#明示的な拒否)です。どのAllowよりも優先され、Denyが1つでもあれば許可されません |
| 37 | EC2にIAMロールを取り付ける「受け皿」を何と呼びますか | [インスタンスプロファイル](06-security-identity.md#インスタンスプロファイル)です。マネジメントコンソールからの操作では自動で作られます |
| 38 | tfstateをS3に置き、ロックを併用する理由は何ですか | 複数人・複数実行で[tfstate](08-iac-cicd.md#tfstate)が壊れるのを防ぐためです。[バックエンド](08-iac-cicd.md#バックエンド)で共有し、[ステートロック](08-iac-cicd.md#ステートロック)で同時実行を排他制御します |
| 39 | `terraform plan` と `terraform apply` の違いは何ですか | [terraform plan](08-iac-cicd.md#terraform-plan)は差分を表示するだけで環境を変更せず、[terraform apply](08-iac-cicd.md#terraform-apply)が実際に反映します |
| 40 | ドリフトとは何で、どうやって気づきますか | コードの定義と実環境のズレのことです([ドリフト](08-iac-cicd.md#ドリフト))。次回の `terraform plan` に意図しない差分として現れるので、定期的にplanを回して検知します |

### 4-3. 上級・面接想定(10問)

「何を作ったか」ではなく「**なぜその構成にしたか**」を問う設問です。答えは暗記ではなく、自分の言葉で言い換えられる状態を目指してください。

| # | 問題 | 答え |
|---|---|---|
| 41 | なぜデータベースをプライベートサブネットに置いたのですか | インターネットから直接到達できる経路をなくし、[攻撃対象領域](06-security-identity.md#攻撃対象領域)を減らすためです。DBはアプリ層からしかアクセスされないので公開する必要がなく、[セキュリティグループ](02-network.md#セキュリティグループ)もWeb層のSGからの3306番のみに絞れます |
| 42 | なぜEC2にアクセスキーを置かず、IAMロールを使ったのですか | [アクセスキー](06-security-identity.md#アクセスキー)は長期の認証情報で、サーバー内に置くと漏えい時の被害が大きく、ローテーションも人手になるためです。[IAMロール](06-security-identity.md#iamロール)なら[AWS STS](06-security-identity.md#aws-sts)が短期の認証情報を自動更新してくれます |
| 43 | Multi-AZを組んでいるのに、なぜバックアップも必要なのですか | [Multi-AZ](05-database.md#multi-az)は同期複製なので、誤って削除したデータも即座に複製先へ反映されます。守れるのはAZ障害であって、人的ミスや論理破壊ではありません。そこは[自動バックアップ](05-database.md#自動バックアップ)と[ポイントインタイムリカバリ](05-database.md#ポイントインタイムリカバリ)の役割です |
| 44 | なぜ2つ以上のAZに分散させたのですか。コストとのトレードオフはどう考えましたか | 1AZ構成はその[アベイラビリティゾーン](01-cloud-basics.md#アベイラビリティゾーン)が[単一障害点](01-cloud-basics.md#単一障害点)になるためです。トレードオフとして、EC2の台数増とAZごとの[NATゲートウェイ](02-network.md#natゲートウェイ)がコスト要因になります。学習環境ではNATを1つに集約し、本番想定ではAZごとに配置するという判断の分け方を説明できるようにしています |
| 45 | なぜ22番ポートを開けず、Session Managerを採用したのですか | 22番のインバウンドを一切開けずに済み、秘密鍵の配布・保管も不要になるからです。加えて、誰が接続したかがIAMプリンシパル単位で[CloudTrail](06-security-identity.md#cloudtrail)に記録され、監査に耐えます([Session Manager](07-monitoring-operations.md#session-manager)) |
| 46 | なぜS3を公開せず、CloudFront+OACという構成にしたのですか | バケットを公開すると、URLを知る全員がオリジンへ直接到達でき、[AWS WAF](06-security-identity.md#aws-waf)や[署名付きURL](02-network.md#署名付きurl)といった前段の制御をすべて迂回されるためです。[OAC](02-network.md#oac)なら[ブロックパブリックアクセス](04-storage.md#ブロックパブリックアクセス)を有効のまま、CloudFrontだけに読ませられます |
| 47 | 手作業で作れるのに、なぜIaC化したのですか | 再現性・レビュー可能性・変更履歴の3つを得るためです([IaC](08-iac-cicd.md#iac))。特に「なぜこの設定にしたか」が[コミット](08-iac-cicd.md#コミット)と[プルリクエスト](08-iac-cicd.md#プルリクエスト)に残ることが、障害調査と引き継ぎで効きます。一方で設計の仕事自体は減らない、という点も併せて説明します |
| 48 | CI/CDを組んだのに、なぜ手動承認ステージを残したのですか | インフラの変更は取り返しがつかない操作(DBの再作成やリソース削除)を含みうるためです。[terraform plan](08-iac-cicd.md#terraform-plan)の結果を人が読み、[手動承認](08-iac-cicd.md#手動承認)を経てから[terraform apply](08-iac-cicd.md#terraform-apply)する形にして、自動化の速さと安全性の折り合いを付けています |
| 49 | なぜ設計の最初にRTOとRPOを決めるのですか | [RTO](01-cloud-basics.md#rto)と[RPO](01-cloud-basics.md#rpo)が決まらないと、Multi-AZが要るのか、バックアップは日次でよいのか、[ディザスタリカバリ](01-cloud-basics.md#ディザスタリカバリ)まで必要なのかが決められないからです。可用性の水準は技術ではなく業務要件から決まる、という順番を守るためです |
| 50 | この構成のまま本番運用に入ると、足りないものは何だと思いますか | 代表的には、(1)アプリ層のログ集約と[オブザーバビリティ](07-monitoring-operations.md#オブザーバビリティ)の不足、(2)障害時の[ランブック](07-monitoring-operations.md#ランブック)と[オンコール](07-monitoring-operations.md#オンコール)体制の未整備、(3)復旧手順を実際に試すリストア訓練の未実施、(4)アカウント分離([環境分離](08-iac-cicd.md#環境分離))と[サービスコントロールポリシー](06-security-identity.md#サービスコントロールポリシー)によるガードレールの不足です。「作れる」と「運用し続けられる」は別だと理解している、と示せる回答にします |

## 5. 学習の進め方(30日ロードマップ)

用語集を読むだけでは身につきません。**読む → 作る → 消す**を1セットにして進めてください。以下は、平日1〜2時間・休日3時間程度を想定した30日の目安です。

| 日程 | 読む章 | 手を動かすこと | 到達目標 |
|---|---|---|---|
| 1〜2日目 | [①クラウドとAWSアカウントの基礎](01-cloud-basics.md) | AWSアカウントを作成し、ルートユーザーにMFAを設定。IAMユーザーを作り、請求アラートと[AWS Budgets](01-cloud-basics.md#aws-budgets)を設定する | クラウドとオンプレミスの違い、リージョンとAZの違いを説明できる。課金を見張る仕組みが動いている |
| 3〜5日目 | [②ネットワーク 2-1〜2-2](02-network.md) | 手元のPCで `dig` と `curl` を試す。[AWS基礎知識(超入門)](../01-aws-basics-for-beginners.md)を通読する | IPアドレス・ポート番号・DNS・HTTPSの関係を図にして説明できる |
| 6〜9日目 | [②ネットワーク 2-3〜2-5](02-network.md) | [レベル1: 静的Webサイト公開](../../projects/01-static-website/README.md)に着手。S3 + CloudFront + Route 53 + ACMで自分のサイトを公開する | 独自ドメインでHTTPS配信ができ、OACでバケットを非公開に保てる |
| 10〜13日目 | [③コンピューティング 3-1〜3-2](03-compute.md) + [⑨Linux 9-1〜9-4](09-linux-server-basics.md) | [レベル2: EC2 Webサーバー構築](../../projects/02-ec2-web-server/README.md)。VPCを自作し、EC2にApacheを入れて公開する | VPC・サブネット・IGW・SGを自分で組め、`systemctl` でサービスを起動・自動起動設定できる |
| 14〜16日目 | [⑨Linux 9-5〜9-8](09-linux-server-basics.md) | 同じEC2で `top` `df` `ss` `journalctl` を使い、わざとApacheを止めて復旧させる | 「サイトが見えない」を、サーバー内部かネットワークかに切り分けられる |
| 17〜19日目 | [②ネットワーク 2-6](02-network.md) + [③コンピューティング 3-3](03-compute.md) | [レベル3: 高可用性3層構成](../../projects/03-ha-three-tier/README.md)の前半。ALBとAuto Scaling Groupを組み、1台落としても表示が続くことを確認する | ALB・ターゲットグループ・ヘルスチェック・ASGの役割を説明できる |
| 20〜22日目 | [⑤データベース](05-database.md) | レベル3の後半。RDSをMulti-AZで作り、プライベートサブネットに配置してEC2から接続する | Multi-AZとリードレプリカの違い、DBを非公開に置く理由を説明できる |
| 23〜24日目 | [④ストレージ](04-storage.md) | [レベル4: WordPress本番構成](../../projects/04-wordpress-production/README.md)の前半。画像をS3へオフロードし、AWS Backupで日次バックアップを設定する | EBS・S3・EFSの使い分けと、バックアップの保持期間設計を説明できる |
| 25〜26日目 | [⑦監視・運用](07-monitoring-operations.md) | レベル4の後半。CloudWatchアラーム3点(EC2のCPU・RDSの空き容量・ALBの5xx)を作り、SNSでメール通知が届くまで確認する | アラームの5項目(名前空間・ディメンション・統計・期間・評価期間)を自分で埋められる |
| 27〜28日目 | [⑥セキュリティ・ID管理](06-security-identity.md) | [レベル5: セキュリティ・監視基盤](../../projects/05-security-monitoring/README.md)。IAMグループ設計、CloudTrail・Config・GuardDuty・WAFを有効化する | 最小権限の原則と多層防御を、自分の構成に即して説明できる |
| 29〜30日目 | [⑧IaCとCI/CD](08-iac-cicd.md) | [レベル6: IaCとCI/CD](../../projects/06-iac-cicd/README.md)。Terraformでレベル2相当の構成をコード化し、`plan` → 承認 → `apply` を通す | ClickOpsとIaCの違い、tfstateとステートロックの必要性を説明できる |
| 仕上げ | このページ(⑩) | 「2. まぎらわしい用語の対比」を声に出して読み、「4. 総まとめテスト」50問を通しで解く。[面接での伝え方](../04-interview-prep.md)と[コスト管理と無料利用枠ガイド](../03-cost-management.md)を読む | 構成図を見ながら15分間、用語を正しく使って自分の構成を説明できる |

> ⚠️ **必ず守ってほしいこと**: 各レベルを終えたら、**その日のうちに使わないリソースを削除**してください。特にNATゲートウェイ・Elastic IP・RDS・ALBは、アクセスがなくても時間課金が続きます。削除手順は各案件のREADME末尾と[コスト管理と無料利用枠ガイド](../03-cost-management.md)にまとめてあります。

> ✅ **30日で終わらなくても問題ありません**。大事なのは日数ではなく「読んだ用語を、その週のうちに手で触ったか」です。触った用語は忘れませんが、読んだだけの用語は3日で消えます。

## 関連ドキュメント

- [用語集トップ(索引)](../02-glossary.md)
- [AWS基礎知識(超入門)](../01-aws-basics-for-beginners.md)
- [コスト管理と無料利用枠ガイド](../03-cost-management.md)
- [面接での伝え方](../04-interview-prep.md)
- [ポートフォリオ全体トップ](../../README.md)
- [前の章: ⑨Linux・サーバー運用の基礎](09-linux-server-basics.md)
- [①クラウドとAWSアカウントの基礎](01-cloud-basics.md)
- [②ネットワーク](02-network.md)
- [③コンピューティング](03-compute.md)
- [④ストレージ](04-storage.md)
- [⑤データベース](05-database.md)
- [⑥セキュリティ・ID管理](06-security-identity.md)
- [⑦監視・運用](07-monitoring-operations.md)
- [⑧IaCとCI/CD](08-iac-cicd.md)
- [レベル1: 静的Webサイト公開環境の構築](../../projects/01-static-website/README.md)
- [レベル2: EC2で自分のWebサーバーを構築する](../../projects/02-ec2-web-server/README.md)
- [レベル3: 可用性を高めた3層Webシステム構築](../../projects/03-ha-three-tier/README.md)
- [レベル4: 本番運用を想定したWordPress環境構築](../../projects/04-wordpress-production/README.md)
- [レベル5: セキュアな監視・ガバナンス基盤の構築](../../projects/05-security-monitoring/README.md)
- [レベル6: Infrastructure as CodeとCI/CDによる自動構築](../../projects/06-iac-cicd/README.md)
