## インフラ構成図

<img src="https://github.com/user-attachments/assets/e0697660-a9ae-4db1-bc52-69dbf84826d1">

## モジュール一覧

- ssm（Systems Manager パラメーター作成）
- network（VPC やサブネットなどの構築）
- security（セキュリティグループの作成）
- vpce（VPC Endpoint の作成）
- alb（ALB の作成）
- cloudfront（CloudFront の設定）
- route53（Route53 のレコードの作成）
- password_ssm（データベースパスワードを作成し Systems Manager パラメーターに設定）
- rds（PostgreSQL データベースインスタンスの作成）
- app_s3（アプリケーション用バケットの作成）
- env_s3（環境変数ファイル用バケットの作成）
- app_s3_policy（アプリケーション用バケットのポリシーの作成）
- ecr（ECR リポジトリの作成）
- cluster（クラスターの作成）
- secrets（Secrets Manager でのシークレットの作成）
- task_iam（タスク実行エージェント、タスク内プロセス用 IAM の作成）
- env_s3_policy（環境変数ファイル用バケットのポリシーの作成）
- cloudwatch（CloudWatch ロググループの作成）
- task（タスクの作成）
- rails_task（Rails タスクの作成）
- private_dns（プライベートホストゾーンの作成）
- service（サービスの作成）
