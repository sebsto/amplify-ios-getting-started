REGION=us-east-2

# get the amplify app id with : amplify env list --details

# Initial run - use `create-secret`, afterwards use `update-secret` when updating the information.

# aws --region $REGION secretsmanager create-secret --name amplify-app-id --secret-string d3.......t9p
# aws --region $REGION secretsmanager create-secret --name amplify-project-name --secret-string iosgettingstarted
# aws --region $REGION secretsmanager create-secret --name amplify-environment --secret-string dev

#aws --region $REGION secretsmanager create-secret --name apple-signing-dev-certificate --secret-binary fileb://./secrets/sebsto-apple-dev.p12 
aws --region $REGION secretsmanager update-secret --secret-id apple-signing-dev-certificate --secret-binary fileb://./secrets/sebsto-apple-dev.p12

# aws --region $REGION secretsmanager create-secret --name apple-signing-dist-certificate --secret-binary fileb://./secrets/sebsto-apple-dist.p12 
aws --region $REGION secretsmanager update-secret --secret-id apple-signing-dist-certificate --secret-binary fileb://./secrets/sebsto-apple-dist.p12

# aws --region $REGION secretsmanager create-secret --name amplify-getting-started-dev-provisionning --secret-binary fileb://./secrets/amplifyiosgettingstarteddev.mobileprovision
aws --region $REGION secretsmanager update-secret --secret-id amplify-getting-started-dev-provisionning --secret-binary fileb://./secrets/amplifyiosgettingstarteddev.mobileprovision

# aws --region $REGION secretsmanager create-secret --name amplify-getting-started-dist-provisionning --secret-binary fileb://./secrets/amplifyiosgettingstarteddist.mobileprovision
aws --region $REGION secretsmanager update-secret --secret-id amplify-getting-started-dist-provisionning --secret-binary fileb://./secrets/amplifyiosgettingstarteddist.mobileprovision

# aws --region $REGION secretsmanager create-secret --name amplify-getting-started-test-provisionning --secret-binary fileb://./secrets/amplifyiosgettingstarteduitests.mobileprovision
aws --region $REGION secretsmanager update-secret --secret-id amplify-getting-started-test-provisionning --secret-binary fileb://./secrets/amplifyiosgettingstarteduitests.mobileprovision

# aws --region $REGION secretsmanager create-secret --name apple-id --secret-string myemail@me.com
# aws --region $REGION secretsmanager create-secret --name apple-secret --secret-string aaaa-aaaa-aaaa-aaaa 
