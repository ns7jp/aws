# 試験計画・成績書

## 1. 試験原則

- 実行前に期待値を決める。
- コマンド、日時、実行者、終了コード、実測値を残す。
- 「画面が出た」ではなく、要件の合否を判定する。
- テンプレートのチェック欄は未実施なら空欄にし、`NOT RUN` と書く。

## 2. 試験ケース

| ID | 種別 | 操作 | 期待値 | 要件 | 状態 |
|---|---|---|---|---|---|
| ST-01 | 正常 | `GET /` と `GET /health` | HTTP 200 | FR-01 | NOT RUN |
| ST-02 | 可用性 | ASG instances の AZ を取得 | 2 AZ に1台以上 | NFR-01 | NOT RUN |
| ST-03 | Security | SG と ENI public IP を取得 | EC2 SSH inbound なし、public IP なし | NFR-02 | NOT RUN |
| ST-04 | Health | target health を取得 | healthy が2 | NFR-01/05 | NOT RUN |
| ST-05 | 管理 | Session Manager 接続 | 鍵・22番なしで接続成功 | FR-02 | NOT RUN |
| ST-06 | Logging | HTTPアクセス後 Logs を検索 | access log が到着 | FR-03 | NOT RUN |
| ST-07 | Monitoring | Alarm 一覧を取得 | 3種が存在、設定値が設計通り | NFR-03 | NOT RUN |
| ST-08 | 障害 | 1台で nginx を停止 | 切離し・置換、サービス継続 | NFR-05 | NOT RUN |
| ST-09 | IaC | 再度 `plan` | 意図しない差分なし | NFR-04 | NOT RUN |
| ST-10 | Cleanup | destroy 後に棚卸し | 管理対象リソース0 | NFR-06 | NOT RUN |

## 3. 詳細手順の例

### ST-03: セキュリティ

1. EC2 の instance ID、subnet、public IP を取得する。
2. EC2 Security Group の inbound を取得する。
3. `PublicIpAddress` が空であることを確認する。
4. TCP/22 の許可がないことを確認する。
5. TCP/80 の source が ALB Security Group ID だけであることを確認する。

不合格時: 公開を続けず、Security Group と Launch Template を修正し、instance refresh 後に再試験する。

### ST-08: EC2 障害訓練

> [!CAUTION]
> 学習用アカウント・承認済み時間帯だけで行います。正常な target が2台あることを事前確認します。

1. ブラウザーまたは `curl` で5秒ごとの疎通監視を開始する。
2. 片方の EC2 で `sudo systemctl stop nginx` を実行する。
3. target が unhealthy になる時刻を記録する。
4. ALB の応答が継続するか記録する。
5. ASG による置換と healthy=2 への復帰を確認する。
6. タイムライン、影響、改善点を障害記録へ転記する。

中止条件: 全 target unhealthy、想定外課金、別環境への操作、顧客影響の兆候。

## 4. 成績記録テンプレート

```text
試験ID:
実施日時(JST):
実施者:
対象account/region（マスク可）:
事前条件:
実行コマンド/操作:
期待値:
実測値:
終了コード:
証跡ファイル:
判定: PASS / FAIL / BLOCKED / NOT RUN
備考・課題ID:
```
