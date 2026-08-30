gcloud run services delete bq-data-agent \
  --project "${GOOGLE_CLOUD_PROJECT}" \
  --region "${GOOGLE_CLOUD_REGION}" \
  --quiet

gcloud projects delete ${GOOGLE_CLOUD_PROJECT}