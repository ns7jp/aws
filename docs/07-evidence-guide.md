# 証跡・成果物ガイド

## 1. 採用担当者に伝わる証跡

スクリーンショットの枚数より、次のつながりが重要です。

```text
要件 NFR-02
  → 設計: EC2 は private、SSH inbound なし
  → 実装: launch template / web security group
  → 試験 ST-03
  → 結果: public IP なし、TCP/22 なし（日時・コマンド付き）
```

## 2. 推奨ファイル構成

```text
evidence/runs/20260828-1400/
├─ 00-context.md
├─ 01-tool-versions.txt
├─ 02-plan-redacted.txt
├─ 03-outputs-redacted.json
├─ 04-target-health-redacted.json
├─ 05-security-groups-redacted.json
├─ 06-test-results.md
├─ 07-incident-drill.md
└─ 08-destroy-check.md
```

## 3. 証跡の必須情報

- 実施日時（JST/UTCを明記）
- 対象環境と Region（account ID はマスク）
- コマンドまたは操作
- 期待値と実測値
- 終了コード
- PASS/FAIL/BLOCKED/NOT RUN
- 問題があれば issue、修正 commit、再試験へのリンク

## 4. 公開前チェック

- [ ] AWS access key / secret / session token がない
- [ ] `.tfstate`、`.tfplan`、`.env`、秘密鍵がない
- [ ] account ID、ARN の account 部分をマスクした
- [ ] 個人情報、会社名、内部IP・内部URL、Cookie がない
- [ ] スクリーンショットの別タブ・通知・プロフィール画像も確認した
- [ ] 未実施項目を PASS と書いていない

## 5. README に書く実績文の型

実施後:

> Terraform で2 AZ の ALB + private EC2 Auto Scaling 環境を構築し、疎通、SG、SSM、ログ、片系障害を試験した。全10項目中9 PASS、通知試験1件は BLOCKED。証跡は日時・期待値・実測値付きで保存した。

未実施時:

> 設計、Terraform、試験・運用手順を作成し、静的検査を実施した。AWS apply と実環境試験は課金・認証を伴うため NOT RUN。

テンプレートやコード作成を、実環境で構築・運用した実績として表現しないことが信頼につながります。
