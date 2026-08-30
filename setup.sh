set -e 

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "[ERROR] Missing arguments!"
  echo "Usage: source ./setup.sh <PROJECT_ID> <REGION>"
  exit 1
fi

PROJECT_ID=$1
REGION=$2

# SETUP ACTIVE PROJECT
echo "[INFO] Setting active project..."
gcloud config set project "$PROJECT_ID"
echo "[INFO] Active project is set to: $PROJECT_ID"

# SETUP CLOUD-RUN-REGION
echo "[INFO] Setting cloud run region..."
gcloud config set run/region "$REGION"
echo "[INFO] Cloud run region is set to: $REGION"

# EXPORT ENV-VARS
echo "[INFO] Exporting environment variables..."
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project -q)}"
export GOOGLE_CLOUD_REGION="${GOOGLE_CLOUD_REGION:-$(CR_REGION=$(gcloud config get-value run/region -q 2> /dev/null); echo "${CR_REGION:-us-central1}")}"
export GOOGLE_GENAI_USE_ENTERPRISE="True"
export GOOGLE_CLOUD_LOCATION="global"

# VERIFY ENV-VARS
echo "=================================="
echo "Verifying environment variables..."
echo "GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"
echo "GOOGLE_CLOUD_REGION: $GOOGLE_CLOUD_REGION"
echo "GOOGLE_GENAI_USE_ENTERPRISE: $GOOGLE_GENAI_USE_ENTERPRISE"
echo "GOOGLE_CLOUD_LOCATION: $GOOGLE_CLOUD_LOCATION"
echo "=================================="

# ENABLE APIS
echo "[INFO] Enabling required services..."
gcloud services enable --project "${GOOGLE_CLOUD_PROJECT}" \
  run.googleapis.com \
  aiplatform.googleapis.com \
  artifactregistry.googleapis.com \
  bigquery.googleapis.com \
  cloudbuild.googleapis.com

# Deploy to cloud run
echo "[INFO] Deploying agent to Cloud Run..."
uv tool run --from google-adk==2.4.0 \
  adk deploy cloud_run \
      --with_ui \
      --project $GOOGLE_CLOUD_PROJECT \
      --region $GOOGLE_CLOUD_REGION \
      --service_name bq-data-agent \
      --app_name data_agent \
      src \
      -- \
      --allow-unauthenticated \
      --max-instances 1 \
      --labels dev-tutorial=codelab-cloud-run-adk-gemini-bq-mcp \
      --set-env-vars GOOGLE_GENAI_USE_ENTERPRISE=True,GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT},GOOGLE_CLOUD_LOCATION=${GOOGLE_CLOUD_LOCATION}

gcloud run services describe bq-data-agent \
  --project $GOOGLE_CLOUD_PROJECT \
  --region $GOOGLE_CLOUD_REGION \
  --format 'value(status.url)'