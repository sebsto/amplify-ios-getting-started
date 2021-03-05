REGION=us-east-2

# get the amplify app id with : amplify env list --details

aws --region $REGION secretsmanager create-secret --name amplify-app-id --secret-string d3.......t9p --query ARN 
aws --region $REGION secretsmanager create-secret --name amplify-project-name --secret-string iosgettingstarted
aws --region $REGION secretsmanager create-secret --name amplify-environment --secret-string dev
aws --region $REGION secretsmanager create-secret --name apple-dist-certificate --secret-binary fileb://./apple-dist.p12 
aws --region $REGION secretsmanager create-secret --name amplify-getting-started-provisionning --secret-binary fileb://./Amplify_Getting_Started.mobileprovision
aws --region $REGION secretsmanager create-secret --name apple-id --secret-string myemail@me.com
aws --region $REGION secretsmanager create-secret --name apple-secret --secret-string aaaa-aaaa-aaaa-aaaa 
