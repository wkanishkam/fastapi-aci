# FastAPI Azure Container Instance Deployment

A simple FastAPI application that returns uptime information, deployed to Azure Container Instances using Terraform and GitHub Actions.

## Project Structure

```
├── app/                    # FastAPI application
│   ├── main.py            # FastAPI app with uptime endpoint
│   ├── requirements.txt   # Python dependencies
│   └── Dockerfile         # Docker image configuration
├── infra/                 # Terraform infrastructure
│   ├── main.tf           # Main Terraform configuration
│   ├── variables.tf      # Variable definitions
│   └── outputs.tf        # Output definitions
└── .github/workflows/     # GitHub Actions
    ├── build-and-push.yml # Docker build and push workflow
    └── infrastructure.yml # Infrastructure management workflow
```

## API Endpoints

- `GET /` - Returns uptime information
- `GET /health` - Health check endpoint

## Setup Instructions

### Prerequisites

1. Azure subscription
2. GitHub repository
3. Azure CLI installed locally (for initial setup)

### GitHub Secrets Required

Set up the following secrets in your GitHub repository:

```bash
# For ACR authentication
ACR_LOGIN_SERVER=<your-acr-login-server>  # e.g., fastapicrxxxx.azurecr.io
ACR_USERNAME=<your-acr-username>
ACR_PASSWORD=<your-acr-password>

# For Azure authentication
AZURE_CREDENTIALS=<service-principal-json>
```

### Azure Service Principal Setup

Create a service principal with appropriate permissions:

```bash
# Create service principal
az ad sp create-for-rbac --name "fastapi-aci-sp" --role contributor --scopes /subscriptions/<subscription-id> --sdk-auth

# The output JSON should be stored in AZURE_CREDENTIALS secret
```

### Local Development

1. Install dependencies:
```bash
cd app
pip install -r requirements.txt
```

2. Run the application:
```bash
uvicorn main:app --reload
```

3. Test the API:
```bash
curl http://localhost:8000/
```

### Deployment

1. **Deploy Infrastructure**: Go to Actions → Infrastructure Management → Run workflow → Select "apply"

2. **Get ACR Details**: After infrastructure deployment, get the ACR login server and credentials:
   ```bash
   # Get outputs from Terraform
   cd infra
   terraform output acr_login_server
   terraform output acr_name
   
   # Get ACR credentials
   az acr credential show --name $(terraform output -raw acr_name)
   ```

3. **Set GitHub Secrets**: Add `ACR_LOGIN_SERVER`, `ACR_USERNAME`, and `ACR_PASSWORD` to your repository secrets

4. **Build and Deploy Application**: Push changes to main branch or manually trigger the build workflow

### Infrastructure Management

Use the Infrastructure Management workflow to:
- **Plan**: Preview infrastructure changes
- **Apply**: Create/update infrastructure
- **Destroy**: Remove all infrastructure

### Accessing the Application

After deployment, the application will be available at:
- `http://<container-group-fqdn>:8000/`
- The FQDN will be displayed in the GitHub Actions workflow summary

## Customization

### Environment Variables

Modify `infra/variables.tf` to customize:
- Resource group name
- Azure region
- ACR name
- Environment tags

### Application Configuration

Update `app/main.py` to add more endpoints or modify the uptime calculation logic.

## Troubleshooting

1. **ACR Pull Issues**: Ensure the user-assigned identity has AcrPull permissions
2. **Container Start Issues**: Check container logs in Azure Portal
3. **GitHub Actions Failures**: Verify all required secrets are set correctly