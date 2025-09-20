eksctl create iamidentitymapping \
--cluster project-bedrock \
--region us-east-1 \
--arn "arn:aws:iam::932263135322:user/developer-readonly" \
--username "developer-readonly" \
--group "read-only-group"
