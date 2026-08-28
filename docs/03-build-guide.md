# 構築手順書

## 0. 作業ゲート

次をすべて確認できない場合は `plan` / `apply` をしません。

- [ ] 作業対象の AWS account ID と Region を声出し確認した
- [ ] MFA と予算通知を設定した
- [ ] 使用ロールの権限・有効期限を確認した
- [ ] `terraform.tfvars` と state が Git 対象外である
- [ ] 終了予定時刻と `destroy` 担当を決めた
- [ ] 失敗時は新規変更を止め、plan を取り直すと合意した

```powershell
aws sts get-caller-identity
aws configure get region
```

期待値: 想定 account/role で、Region は `ap-northeast-1`。出力を公開するときは account ID をマスクします。`$LASTEXITCODE` が0であることを直後に確認します。

## 1. 事前検査

```powershell
Copy-Item terraform/terraform.tfvars.example terraform/terraform.tfvars
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
python tests/static_checks.py
```

失敗したら `apply` へ進まず、最初のエラーから直します。

## 2. Plan

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform plan -out=casepack.tfplan
terraform -chdir=terraform show -no-color casepack.tfplan
```

レビュー観点:

- provider の Region と AWS account が正しい
- `0.0.0.0/0` の inbound は ALB の80番だけ
- EC2 に public IP と SSH inbound がない
- `environment=lab` なら NAT 1台、`production` なら2台
- 意図しない destroy/replacement、秘密値、過大な台数がない

## 3. Apply

承認済み plan ファイルだけを適用します。

```powershell
terraform -chdir=terraform apply casepack.tfplan
terraform -chdir=terraform output
```

途中失敗時は同じコマンドを闇雲に繰り返しません。エラー時刻、リソース、API メッセージを記録し、`terraform plan` で実状態との差分を再確認します。

## 4. 初期確認

```powershell
$albUrl = terraform -chdir=terraform output -raw alb_url
Invoke-WebRequest "$albUrl/health" -UseBasicParsing
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names (terraform -chdir=terraform output -raw autoscaling_group_name)
aws elbv2 describe-target-health --target-group-arn (terraform -chdir=terraform output -raw target_group_arn)
```

期待値: HTTP 200、ASG の desired capacity は2、healthy target は2。

## 5. SSM 接続

```powershell
aws ec2 describe-instances --filters "Name=tag:Project,Values=aws-casepack" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output table
aws ssm start-session --target <INSTANCE_ID>
```

接続後の確認:

```bash
sudo systemctl status nginx --no-pager
curl -fsS http://localhost/health
sudo tail -n 20 /var/log/nginx/access.log
```

## 6. ロールバック

### 変更失敗

1. 追加変更を止める。
2. 直前の Git commit と plan を特定する。
3. 既知の正常コードへ戻す変更をレビューする。
4. 新たに plan を作り、破壊変更を確認してから apply する。
5. [試験計画](04-test-plan.md) の ST-01、ST-04、ST-06 を再実施する。

### 演習環境の削除

```powershell
terraform -chdir=terraform plan -destroy -out=destroy.tfplan
terraform -chdir=terraform show -no-color destroy.tfplan
terraform -chdir=terraform apply destroy.tfplan
```

削除後は EC2、ALB、NAT Gateway、Elastic IP、CloudWatch Logs の残存と Billing をコンソールでも確認します。state ファイルを先に消してはいけません。
