REGION=us-west-2

# Run these command from your laptop where the secrets are, not from the EC2 Mac instance
# do not change the name of the secrets. Builds scripts are using these names to retrieve the secrets.

# Create JSON structure with all files as base64
SECRET_JSON=$(cat << EOF
{
  "apple_dev_key_p12": "$(base64 -i secrets/apple_dev_key.p12)",
  "apple_dist_key_p12": "$(base64 -i secrets/apple_dist_key.p12)",
  "dev_mobileprovision": "$(base64 -i secrets/amplifyiosgettingstarteddev.mobileprovision)",
  "dist_mobileprovision": "$(base64 -i secrets/amplifyiosgettingstarteddist.mobileprovision)",
  "uitests_mobileprovision": "$(base64 -i secrets/amplifyiosgettingstarteduitests.mobileprovision)",
  "apple_api_key": "$(base64 -i secrets/AuthKey_66FM24QJK3.p8)",
  "apple_api_key_id": "66FM24QJK3",
  "apple_api_issuer_id": "69a6de7b-8428-47e3-e053-5b8c7c11a4d1",
  "apple_api_issuer_id": "69a6de7b-8428-47e3-e053-5b8c7c11a4d1"
}
EOF
)

# Create or update the secret
# aws secretsmanager create-secret \
#   --name "ios-build-secrets" \
#   --secret-string "$SECRET_JSON" \
#   --region $REGION

# To update existing secret:
aws secretsmanager update-secret \
  --secret-id "ios-build-secrets" \
  --secret-string "$SECRET_JSON" \
  --region $REGION