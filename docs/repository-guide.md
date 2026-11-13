# AWS 教材の読み方・検証範囲

[教材一覧と概要](../README.md)に戻る。ここでは、教材の詳細、AI 支援の内訳、実行前の確認をまとめています。

教材・実施状況は更新停止時点（2026-10-18）のものです。今回の整理で AWS の実行実績は追加していません。

## このリポジトリの位置づけ

- **学習用の副作品です。** 主作品は [ns7jp/server](https://github.com/ns7jp/server) で、本人が手元のVMで操作した記録はそちらにまとめています。
- **AI支援で作成した部分が大きいです。** 文書・スクリプトの多くは、AIツール（Claude Code・OpenAI Codex）の支援で作成しました。2026-09-28 時点で確認できる範囲では、main へのプルリクエストのマージのうち16件は `claude/…`、3件は `codex`・`codex/…` のブランチからのもので、マージを除くコミット30件のうち24件は作者が `Claude`、1件は `Codex` です。作者が島田則幸のコミットが本人の手作業か AI ツールの出力かは、履歴からは区別できません。
- **本人による実行記録:** なし。実AWSでの構築・削除は、本人・AI支援セッションとも実行した記録がありません（下の表のとおり `NOT RUN`）。
- **主作品・他の副作品との関係:** 未実行のAWS構築コードは、このリポジトリのほかに主作品の [`terraform/`](https://github.com/ns7jp/server/blob/main/terraform/README.md)（AWSへ一度も apply していないと明記）と、[learning の AWS 演習キット](https://github.com/ns7jp/learning/blob/main/docs/learning-plan/aws-exercise-kit/README.md)（未使用の雛形）にもあり、内容が一部重なります。最初の実測は、このリポジトリの[レベル2の1台構成](../evidence/level02/README.md)を予定しています。

## 現在確認できること

| 区分 | 状態と確認先 |
| --- | --- |
| 文書・コード | 6案件の設計・手順、AWS CLI／Terraformのキットを作成済み |
| 静的検証 | [検証スクリプト](../scripts/validate.sh)と[CI](../.github/workflows/validate.yml)を用意。構文・リンク等の検査であり、AWSでの動作証明ではありません |
| 実AWSでの構築・疎通・監視・削除 | **未実施（NOT RUN）**。[実行証跡](../evidence/README.md)には、2026-09-17時点で本人の実測記録がありません |
| 独力再現・運用経験 | このリポジトリだけでは未確認。手順や想定問答を本人の実績として扱いません |

採用担当者の方は、[レベル2の構成図・設計](../projects/02-ec2-web-server/README.md) → [構築・削除コード](../projects/02-ec2-web-server/handson/README.md) → [証跡の現在地](../evidence/README.md)の順でご覧ください。次の実習は、既存のEC2キット1件で[構築から削除確認まで](../evidence/level02/README.md)を記録する形に絞っています。

## 自己紹介

島田則幸です。サーバー構築・運用を行うインフラエンジニアを目指しています。このリポジトリでは、セキュリティ・コスト・可用性を踏まえて設計を説明し、実行結果を別途記録できる形を重視しています。学習期間や資格など、このリポジトリ内で裏付けを確認できない項目は掲載していません。全体の取り組みは[プロフィール](https://github.com/ns7jp)をご覧ください。

## このポートフォリオの構成

```mermaid
flowchart LR
    L1["レベル1<br/>静的サイト公開"] --> L2["レベル2<br/>EC2 Webサーバー"]
    L2 --> L3["レベル3<br/>3層 高可用性構成"]
    L3 --> L4["レベル4<br/>WordPress本番運用"]
    L4 --> L5["レベル5<br/>セキュリティ監視基盤"]
    L5 --> L6["レベル6<br/>IaC + CI/CD"]

    Docs["補足ドキュメント<br/>基礎知識/用語集/コスト/面接対策"] -.->|前提知識として参照| L1
```

> 🧠 **覚え方のコツ**: 6つの案件は「①公開する→②自分でサーバーを建てる→③壊れなくする→④実運用に耐える→⑤守り続ける→⑥自動化する」という順で、この教材内の学習段階を並べています。レベル番号は教材の進め方の目安です。

## 教材とキットの詳細

| Lv | 教材 | 主な AWS サービス | 学習目標 | キットの方式・内容 |
| --- | --- | --- | --- | --- |
| 1 | [静的Webサイト公開環境の構築](../projects/01-static-website/README.md) | S3, CloudFront, Route 53, ACM | AWS基本操作、CDN配信の仕組み、独自ドメイン+HTTPS化 | AWS CLI：S3 + CloudFront(OAC)構築、HTMLサンプル、削除スクリプト。[構築・削除手順](../projects/01-static-website/handson/README.md) |
| 2 | [EC2で自分のWebサーバーを構築する](../projects/02-ec2-web-server/README.md) | VPC, EC2, セキュリティグループ, Elastic IP | VPC・サブネット設計、SSH接続、Webサーバー構築の基礎 | AWS CLI：VPC〜EC2〜Elastic IP を一括構築、user-data で Apache 自動導入。[構築・削除手順](../projects/02-ec2-web-server/handson/README.md) |
| 3 | [可用性を高めた3層Webシステム構築](../projects/03-ha-three-tier/README.md) | ALB, Auto Scaling, Multi-AZ RDS, NATゲートウェイ | 冗長化設計、負荷分散、多層防御のSG設計 | AWS CLI：6サブネット、NAT、3層SG、ALB、Auto Scaling、RDS Multi-AZ。[構築・削除手順](../projects/03-ha-three-tier/handson/README.md) |
| 4 | [本番運用を想定したWordPress環境構築](../projects/04-wordpress-production/README.md) | ElastiCache, S3, CloudFront, AWS Backup, CloudWatch | パフォーマンス設計、バックアップ運用、監視アラート設計 | AWS CLI(レベル3の差分)：Secrets Manager、ElastiCache、S3メディア、AWS Backup、CloudWatchアラーム。[構築・削除手順](../projects/04-wordpress-production/handson/README.md) |
| 5 | [セキュアな監視・ガバナンス基盤の構築](../projects/05-security-monitoring/README.md) | IAM, CloudTrail, AWS Config, GuardDuty, WAF | 最小権限設計、証跡管理、脅威検知、Webアプリ防御 | AWS CLI：IAMグループ+MFA強制、CloudTrail、Config、GuardDuty、WAF。[構築・削除手順](../projects/05-security-monitoring/handson/README.md) |
| 6 | [IaCとCI/CDによる自動構築](../projects/06-iac-cicd/README.md) | Terraform, S3, DynamoDB, CodePipeline, CodeBuild | Infrastructure as Code、state管理、CI/CDパイプライン設計 | Terraform：state用S3/DynamoDB、VPC/SG/EC2モジュール、CodeBuild buildspec。[構築・削除手順](../projects/06-iac-cicd/handson/README.md) |

## ハンズオンキットを実行する前に

各案件の `handson/` ディレクトリに、本編の構成を **AWS CLI スクリプト(レベル1〜5)/ Terraform(レベル6)で構築・削除するためのキット**を用意しています。実AWSでの成功は未確認です。まず対象1件のコードと手順を読み、実行条件を確認してください。

> ⚠️ **必ず読んでください**: キットは実AWS環境での動作検証を行っていません。検証の範囲は、全キットの静的検査（`bash -n`・shellcheck・JSON/YAML・Markdownリンク・`terraform fmt`、CIではレベル6の `terraform validate` と tfsec（警告のみ）も実行）と、**レベル2だけ**にある削除・所有確認のモックテスト（AWS CLIを模した回帰テスト `scripts/test_ec2_cleanup.py`・`scripts/test_ec2_build_ownership.py`）です。レベル1・3・4・5の `build.sh` / `cleanup.sh` には、アカウント照合や部分失敗時の状態保持を確かめるテストはありません。実行前に各 `handson/README.md` と [コスト管理ガイド](03-cost-management.md) を読み、予算アラートを設定し、検証後は `cleanup.sh` / `terraform destroy` で必ず削除してください。

## 構築証跡と自動検証

- **[evidence/](../evidence/README.md)**: キットを実際のAWSアカウントで実行した記録(所要時間・費用・スクリーンショット・つまずきと解決)を残す場所です。テンプレート [evidence/templates/handson-record.md](../evidence/templates/handson-record.md) をコピーして使います。本人が実施した範囲を示すには、実行後に記録を追加する必要があります。
- **[scripts/validate.sh](../scripts/validate.sh)**: シェル構文・shellcheck・JSON/YAML・Markdownリンク・Terraform fmt をまとめて検証します。GitHub Actions([.github/workflows/validate.yml](../.github/workflows/validate.yml))で push のたびに自動実行され、実AWS環境には接続しません。

```bash
./scripts/validate.sh   # リポジトリのルートで実行します
```

## 読み方ガイド

1. **AWSにまだ慣れていない方は** まず [docs/01-aws-basics-for-beginners.md](01-aws-basics-for-beginners.md) で全体像をつかんでから、レベル1から順番に読み進めてください。
2. **各案件の中で知らない用語が出てきたら** [docs/02-glossary.md](02-glossary.md) を辞書として参照してください。すべての案件からリンクしています。索引から、1用語ごとに「なぜ必要か・どこでハマるか」まで掘り下げた[詳細用語集(全10章・478項目)](glossary/01-cloud-basics.md)へ飛べます。
3. **手を動かして検証する場合は** 必ず [docs/03-cost-management.md](03-cost-management.md) の無料利用枠・削除チェックリストを先に確認してから進めてください(課金事故防止)。
4. **採用担当者・面接官の方へ**: 本人の実行結果は[証跡](../evidence/README.md)で確認できます（2026-09-17時点で未登録）。各案件のREADMEには構成図・構築手順に加えて「セキュリティのポイント」「コスト概算」「面接でのアピールポイント」まで記載していますが、面接でのアピールポイントは実施前に用意した想定回答（設計意図の説明例）で、本人の実績ではありません。

## 補足ドキュメント

| ドキュメント | 内容 |
| --- | --- |
| [AWS基礎知識(超入門)](01-aws-basics-for-beginners.md) | クラウドとは何か、リージョン/AZ、サービスカテゴリの全体像 |
| [AWS用語集(覚え方付き)](02-glossary.md) | **用語集のトップ(索引)**。全478項目のアイウエオ順索引、カテゴリ別ひとこと早見表、混同しやすい用語の比較表、ミニハンズオン |
| [詳細用語集 全10章](glossary/01-cloud-basics.md) | 1用語ごとに「正式名称/読み方/重要度/たとえるなら/もう少し詳しく/サーバー構築での勘所/よくあるつまずき/コスト/関連用語」まで解説。Linux・サーバー運用の基礎と全50問の総まとめテストも収録 |
| [コスト管理と無料利用枠ガイド](03-cost-management.md) | 無料プランの確認、削除チェックリスト、各案件の見積もり項目 |
| [このポートフォリオの面接での伝え方](04-interview-prep.md) | 自己紹介テンプレート、案件ごとのエレベーターピッチ、想定質問と回答の型 |

## 設計方針

このポートフォリオは、単に「動くものを作る」だけでなく、以下を意識して設計しています。

- **段階的な難易度設計**: レベル1〜6で、コンソール操作の基礎からセキュリティ運用・IaC化まで、実務で求められるステップを段階的に踏めるようにしています。
- **初心者が理解・記憶できる説明**: 専門用語は初出時に必ず言い換えを添え、各所に「🧠 覚え方のコツ」としてたとえ話・語呂合わせを入れています。
- **手を動かせる具体性**: 構築手順はCIDR・ポート番号・設定画面の項目名まで具体的に記載し、実際にAWSマネジメントコンソールで再現できるレベルまで書いています。
- **セキュリティ・コストを最初から意識する**: 各案件に「セキュリティのポイント」「コスト概算」を必ず設け、「作って終わり」にしない視点を組み込んでいます。
- **面接で語れる形にする**: 各案件に想定Q&Aを用意し、構成の「なぜ」を自分の言葉で説明できることを重視しています。

## 関連ドキュメント

- [AWS基礎知識(超入門)](01-aws-basics-for-beginners.md)
- [AWS用語集(覚え方付き・索引)](02-glossary.md)
- [詳細用語集 ②ネットワーク編(最重要)](glossary/02-network.md)
- [詳細用語集 ⑨Linux・サーバー運用の基礎](glossary/09-linux-server-basics.md)
- [詳細用語集 ⑩略語一覧と総まとめテスト(全50問)](glossary/10-abbreviations-and-quiz.md)
- [最初の案件(レベル1: 静的Webサイト公開)](../projects/01-static-website/README.md)
