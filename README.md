# AWS 構築案件パック

<a id="aws構築案件パック---未経験からサーバー構築エンジニアを目指すポートフォリオ"></a>

AWS インフラの設計・構築・削除を学ぶ、6 段階の教材とコードです。静的サイト公開から EC2、可用性、監視、Terraform / CI/CD を扱います。

> **更新停止（参考資料）**：2026-10-18 から更新を停止しています。教材・実施状況は当時のものです。採用の判断には、主作品 [server](https://github.com/ns7jp/server) の本人操作の記録をご覧ください。

<a id="このリポジトリの位置づけ"></a>

## 現在確認できること

- 文書・コードの多くは **AI 支援で作成した学習用の副作品**です。[支援の内訳・他作品との関係](docs/repository-guide.md#このリポジトリの位置づけ)
- **実 AWS での構築・疎通・監視・削除は未実施（NOT RUN）**です。本人・AI 支援セッションとも実行記録がありません。[証跡の現在地](evidence/README.md)
- 静的検査と一部のモックテストを用意しています。実 AWS での動作や本人の独力再現・運用経験を示すものではなく、面接用の文例も想定回答です。[検証範囲](docs/repository-guide.md#ハンズオンキットを実行する前に)

## 案件一覧(スキルマップ)

<a id="ハンズオンキット手を動かして構築する"></a>

| Lv | 教材・設計 | 構築・削除キット |
| --- | --- | --- |
| 1 | [静的 Web サイト公開（S3 / CloudFront）](projects/01-static-website/README.md) | [AWS CLI](projects/01-static-website/handson/README.md) |
| 2 | [EC2 Web サーバー（VPC / EC2）](projects/02-ec2-web-server/README.md) | [AWS CLI](projects/02-ec2-web-server/handson/README.md) |
| 3 | [可用性を高めた3層構成（ALB / Auto Scaling / RDS）](projects/03-ha-three-tier/README.md) | [AWS CLI](projects/03-ha-three-tier/handson/README.md) |
| 4 | [本番運用を想定した WordPress 環境](projects/04-wordpress-production/README.md) | [AWS CLI](projects/04-wordpress-production/handson/README.md) |
| 5 | [セキュリティ監視・ガバナンス基盤](projects/05-security-monitoring/README.md) | [AWS CLI](projects/05-security-monitoring/handson/README.md) |
| 6 | [IaC と CI/CD（Terraform / CodePipeline）](projects/06-iac-cicd/README.md) | [Terraform](projects/06-iac-cicd/handson/README.md) |

コードを確認する場合は、[レベル2の設計](projects/02-ec2-web-server/README.md)と[キット](projects/02-ec2-web-server/handson/README.md)から読めます。実行前には、[キットの検証範囲](docs/repository-guide.md#ハンズオンキットを実行する前に)と[コスト・削除管理](docs/03-cost-management.md)を確認してください。

## 学習・検証の案内

| 知りたいこと | 開く文書 |
| --- | --- |
| 教材の進め方・設計方針 | [教材の読み方と詳細](docs/repository-guide.md) |
| 基礎知識・用語 | [AWS 基礎](docs/01-aws-basics-for-beginners.md)・[用語集](docs/02-glossary.md) |
| 実行結果の記録方法 | [証跡台帳](evidence/README.md)・[レベル2の記録計画](evidence/level02/README.md) |
| ローカル・CI の静的検査 | [検証スクリプト](scripts/validate.sh)・[GitHub Actions](.github/workflows/validate.yml) |

<details>
<summary>以前の README の節から探す</summary>

<a id="自己紹介"></a><a id="このポートフォリオの構成"></a><a id="読み方ガイド"></a><a id="設計方針"></a>

自己紹介・学習順・読み方・設計方針は[教材の読み方](docs/repository-guide.md)にまとめました。

<a id="構築証跡と自動検証"></a><a id="補足ドキュメント"></a><a id="関連ドキュメント"></a>

[検証方法](docs/repository-guide.md#構築証跡と自動検証)と[補足ドキュメント](docs/repository-guide.md#補足ドキュメント)も移動先から確認できます。

</details>

## ライセンス

[MIT License](LICENSE) ／ [作者のプロフィール](https://github.com/ns7jp)
