REGION=us-east-2

# get the amplify app id with : amplify env list --details

aws --region $REGION secretsmanager create-secret --name amplify-app-id --secret-string d3.......t9p --query ARN 
aws --region $REGION secretsmanager create-secret --name amplify-project-name --secret-string iosgettingstarted
aws --region $REGION secretsmanager create-secret --name amplify-environment --secret-string dev

aws --region $REGION secretsmanager create-secret --name apple-signing-dev-certificate --secret-binary fileb://./apple_dev_seb.p12 
aws --region $REGION secretsmanager create-secret --name apple-signing-dist-certificate --secret-binary fileb://./apple_dist_seb.p12 
aws --region $REGION secretsmanager create-secret --name amplify-getting-started-dist-provisionning --secret-binary fileb://./match_AppStore_comamazonawsamplifymobilegettingstarted.mobileprovision
aws --region $REGION secretsmanager create-secret --name amplify-getting-started-dev-provisionning --secret-binary fileb://./match_Development_comamazonawsamplifymobilegettingstarted.mobileprovision

aws --region $REGION secretsmanager create-secret --name apple-id --secret-string myemail@me.com
aws --region $REGION secretsmanager create-secret --name apple-secret --secret-string aaaa-aaaa-aaaa-aaaa 
