# EC2 1台：ログ採取つき実施手順

**実AWSでは NOT RUN**。本人が用意したAWS環境で、[既存キット](../../projects/02-ec2-web-server/handson/README.md)を1回実行するための手順です。この文書の更新時にはAWSへ接続していません。[記録テンプレート](../templates/ec2-one-host-record.md)に、実行していない結果を転記しないでください。

## 1. 実行前の条件

| 項目 | 実行前の確認 |
|---|---|
| 認証 | AWS CLI v2、本人が利用を決めた学習用プロファイル。SSO等の一時認証も使用可。ルート認証情報は使わない |
| アカウント | `EXPECTED_ACCOUNT_ID` は利用先として決めた12桁のID。現在の認証先から機械的に代入しない |
| リージョン・AZ | 既定は東京。利用可能なAZを下の読み取りコマンドで選び、`REGION` / `AZ` を明示 |
| 権限 | STS照会、EC2/VPC作成・参照・削除、公開SSMパラメータ読み取り。観測にCloudWatchメトリクスの閲覧権限、費用確認にBillingの閲覧権限も必要 |
| 接続元 | SSH/HTTPを実行する端末のグローバルIPv4。VPNやプロキシでHTTPとSSHの出口が異なる場合は先に確認。IP変更時は `/0` へ広げず許可元を見直す |
| 費用 | [料金確認](../../docs/03-cost-management.md)に沿って EC2、EBS、IPv4、転送を見積もる。無料を前提にせず、予算通知・削除予定時刻・後日確認日を決める |
| 作業環境 | Bash、curl、OpenSSH、Git。状態ファイル・秘密鍵を信頼できるローカル領域に保持できること |

以下はリポジトリのルートから開始し、値を自分の設定へ置き換えます。実IDを含むコマンドや端末全体のスクリーンショットは公開しません。

```bash
cd projects/02-ec2-web-server/handson
export AWS_PROFILE='自分の学習用プロファイル名'
export EXPECTED_ACCOUNT_ID='利用すると決めた12桁のID'
export REGION=ap-northeast-1
export AWS_PAGER=''
aws --version
aws sts get-caller-identity --region "$REGION" --query Account --output text
aws ec2 describe-availability-zones --region "$REGION" \
  --filters Name=state,Values=available --query 'AvailabilityZones[].ZoneName' --output text
export AZ='上の結果から選んだAZ'
export MY_IP='接続元のグローバルIPv4（/32なし）'
```

認証先が意図したアカウントでなければ、認証を直してから再確認します。`build.sh` も一致を検査し、不正なIPv4・既存状態ファイル・既存秘密鍵では作成前に停止します。

## 2. 未加工ログを非公開で残す

同じBashセッションで実行します。`.private-evidence/` はGit除外済みです。ログにはIP・リソースID・エラーの詳細が含まれるため、このディレクトリを丸ごと公開しません。`set -x` や `aws --debug` は使用しません。

```bash
umask 077
RUN_DIR="$PWD/.private-evidence/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$RUN_DIR"
git rev-parse HEAD > "$RUN_DIR/commit.txt"
# コマンド、UTCの開始/終了時刻、終了コード、標準出力/標準エラーを保存。
capture() {
  local label="$1" status
  shift
  if [[ -e "$RUN_DIR/$label.log" || -e "$RUN_DIR/$label.meta" ]]; then
    echo '同じラベルの記録が既にあります。再試行には別名を使ってください。' >&2
    return 1
  fi
  {
    date -u '+start=%Y-%m-%dT%H:%M:%SZ'
    printf 'command='; printf '%q ' "$@"; printf '\n'
  } > "$RUN_DIR/$label.meta"
  if "$@" > "$RUN_DIR/$label.log" 2>&1; then status=0; else status=$?; fi
  { date -u '+end=%Y-%m-%dT%H:%M:%SZ'; printf 'exit=%s\n' "$status"; } >> "$RUN_DIR/$label.meta"
  printf '%s: exit=%s（非公開ログ: %s）\n' "$label" "$status" "$RUN_DIR/$label.log"
  return "$status"
}
capture build bash ./build.sh
```

出力はログファイルへ保存されます。別端末の `tail -f` 等で進行を確認できます。`build` が非0なら成功とせず、失敗箇所を記録します。部分的に作られた資源は状態ファイルに残るので、再度 `build.sh` を走らせず、下の削除手順へ進みます。削除も失敗したら状態と鍵を保持し、原因を直して別のラベルで再試行します。

## 3. 疎通と観測

構築が成功した場合だけ実施します。読み込むのは**自分の `build.sh` が生成した状態ファイル**だけです。第三者のファイルは `source` しません。

```bash
source ./.handson-state.env
capture ec2-status aws ec2 describe-instance-status --region "$REGION" \
  --instance-ids "$INSTANCE_ID" --include-all-instances
capture http curl --silent --show-error --connect-timeout 5 --max-time 15 \
  --output /dev/null --write-out 'HTTP=%{http_code}\n' "http://$EIP/"
capture httpd-active ssh -o ConnectTimeout=10 -i "$PEM_FILE" "ec2-user@$EIP" \
  'systemctl is-active httpd'
capture httpd-enabled ssh -o ConnectTimeout=10 -i "$PEM_FILE" "ec2-user@$EIP" \
  'systemctl is-enabled httpd'
```

初回SSHではホスト鍵を確認してから接続します。接続できない場合は `StrictHostKeyChecking=no` で回避せず、EC2のコンソール等で鍵・接続先を照合します。セットアップ中なら、時刻と結果を残して `http-retry1` など別名で再確認します。

| 確認 | 合格の条件 | 記録するもの |
|---|---|---|
| EC2 | Instance/System Status がともに `ok` | 対象の対応関係、観測時刻、取得結果 |
| HTTP | **HTTP 200かつcurl終了コード0** | `.log` と `.meta`。curlはHTTPエラーでも0になり得るので両方確認 |
| Apache | `is-active` が `active`、`is-enabled` が `enabled` | 各終了コードと出力。自動起動設定と実際の再起動試験は区別 |
| CloudWatch | `CPUUtilization` と `StatusCheckFailed` を読める | EC2画面のMonitoringで観測開始/終了・期間・値を記録。欠測は `UNKNOWN`。CPUの低さを可用性の証明にしない |

この観測だけで24時間運用・アラーム通知・バックアップ復元を実施済みとはしません。失敗があれば、症状→仮説→確認→対処→再試験の順に、実際に行ったことだけを残します。

## 4. 削除前の台帳を保存してから削除する

成功時の `cleanup.sh` は鍵と状態ファイルを削除するため、**IDの照合用台帳を非公開で退避**します。秘密鍵のコピーは不要です。

```bash
if cp .handson-state.env "$RUN_DIR/resource-state.env" \
  && [[ -r "$RUN_DIR/resource-state.env" ]] \
  && cmp -s .handson-state.env "$RUN_DIR/resource-state.env"; then
  # 部分構築時に、以前のセッションのIDを照会に使わない。
  unset INSTANCE_ID
  if source ./.handson-state.env; then
    # EC2まで作成できた場合だけ、EBSのIDとDeleteOnTerminationも保存する。
    if [[ -n "${INSTANCE_ID:-}" ]]; then
      capture instance-before-cleanup aws ec2 describe-instances --region "$REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name,Volumes:BlockDeviceMappings}'
    fi
    capture cleanup bash ./cleanup.sh
  else
    echo '状態ファイルを読めません。元の台帳を保持し、削除は実行していません。' >&2
  fi
else
  echo '台帳の退避・照合に失敗しました。元の台帳を保持し、削除は実行していません。' >&2
fi
```

台帳のコピー・可読性・内容一致を確認できた場合だけ削除へ進みます。退避に失敗したら保存先を直してこのブロックをやり直します。部分構築で `INSTANCE_ID` が未記録ならEC2照会は自動で省略します。状態ファイルもない場合は作成前の停止かをログで確認します。`cleanup` の終了コードが非0の場合は、退避台帳を保持したまま失敗項目を解消し、`capture cleanup-retry1 bash ./cleanup.sh` と再試行します。削除済みと未確認を混同しません。

削除APIの終了後も、同じアカウント・リージョンのEC2/VPC画面で台帳の**個々のID**を照合します。空の一覧でもフィルターやリージョンが違えば証拠になりません。別用途のリソースは削除対象に含めません。

| 対象 | 確認結果として残す内容 |
|---|---|
| EC2 | 台帳のIDが `terminated`、または対象IDの参照結果に存在しない |
| EBS | `instance-before-cleanup.log` の各ボリュームIDが存在しない。残っていれば課金対象として追跡する |
| Elastic IP | 台帳のAllocation IDが存在しない。関連付け解除だけでは完了にしない |
| SG・サブネット・ルートテーブル・IGW・VPC | 台帳の各IDが存在しない |
| キーペア | 今回作成成功として記録された名前が存在しない。同名の既存キーは対象外 |

各行に確認時刻・画面または読み取りAPIの結果を残します。手動削除が必要になったら、対象IDを確認し、操作と再照合の結果を記録します。

## 5. 費用と公開用記録

翌日以降、Billing / Cost Managementで実施期間・リージョン・サービスを絞り、EC2・EBS・IPv4・転送の費用を確認します。請求データが未反映なら `UNKNOWN` とし、再確認日を決めます。クレジット適用前後と他の利用を分け、特定できない額をこの実験の実費と断定しません。予算通知は支出を強制停止しません。

原本から公開用の抜粋を作り、[記録テンプレート](../templates/ec2-one-host-record.md)とともに `evidence/level02/YYYY-MM-DD.md` からリンクします。置換は `i-実ID → <EC2-1>`、`vpc-実ID → <VPC-1>` など一貫した別名にし、日時・終了コード・HTTPコード・エラー名・判断に必要な結果は保持します。

- アカウントID、ARN、IP、DNS、ユーザー名・ローカルパス、請求の個人情報を伏せます。秘密鍵・認証トークン・状態ファイルは公開しません。
- スクリーンショットはアカウントメニュー、URL欄、通知先も確認します。画像を直した後に再度目視します。
- 公開前に `git diff --cached` と添付画像を確認します。Git除外は機密値を自動で伏せる機能ではありません。
- 最後に本人の言葉で「なぜ接続元を `/32` にしたか」「HTTP 200だけでは何が分からないか」「削除成功と請求確認を分ける理由」を書きます。説明できない点は未習得として残します。
