# FastAPI Azure Container Instance Deployment

A complete deployment solution for containerized applications on Azure Container Instances using Terraform and GitHub Actions with remote state management.

## Project Structure

```
├── app/                    # Application directory (customizable)
│   ├── main.py            # FastAPI app with uptime endpoint
│   ├── requirements.txt   # Python dependencies
│   └── Dockerfile         # Docker image configuration
├── infra/                 # Terraform infrastructure
│   ├── main.tf           # Main Terraform configuration
│   ├── backend.tf         # Remote state configuration
│   ├── variables.tf      # Variable definitions
│   └── outputs.tf        # Output definitions
├── .github/workflows/     # GitHub Actions pipelines
│   ├── build-and-push.yml # Docker build, push, and deployment
│   └── infrastructure.yml # Infrastructure management
└── setup-state-storage.sh # Script to create remote state storage
```

## API Endpoints

- `GET /` - Returns uptime information
- `GET /health` - Health check endpoint

> **Note**: The `app/` directory can contain any application with a Dockerfile. This example uses FastAPI, but you can replace it with any containerized application (Node.js, .NET, Python Flask, etc.).

## Complete Setup Guide

### Step 1: Prerequisites

1. **Azure subscription** with permissions to create resources
2. **GitHub repository** for your code
3. **Azure CLI** installed locally
4. **Terraform** installed locally (optional, for local testing)

### Step 2: Initial Azure Setup

#### 2.1 Create Service Principal

Create a service principal with required permissions:

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal with Contributor and User Access Administrator roles
az ad sp create-for-rbac \
  --name "sp-fastapi-aci-github" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth

# Grant User Access Administrator role (needed for managed identity role assignments)
SP_ID=$(az ad sp list --display-name "sp-fastapi-aci-github" --query "[0].id" -o tsv)
az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

Copy the entire JSON output - you'll need it for the `AZURE_CREDENTIALS` secret.

#### 2.2 Setup Remote State Storage

**IMPORTANT**: Run this script before any infrastructure deployment:

```bash
chmod +x setup-state-storage.sh
./setup-state-storage.sh
```

This creates:
- Resource group: `rg-terraform-state`
- Storage account: `sttfstatefastapi001`
- Blob container: `tfstate`

After running the script, get the storage account key:

```bash
az storage account keys list \
  --resource-group rg-terraform-state \
  --account-name sttfstatefastapi001 \
  --query '[0].value' -o tsv
```

### Step 3: Configure GitHub Secrets

Set up these secrets in your GitHub repository (**Settings** → **Secrets and variables** → **Actions** → **New repository secret**):

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AZURE_CREDENTIALS` | Service principal JSON | Copy from Step 2.1 output |
| `ARM_ACCESS_KEY` | Storage account key | Copy from Step 2.2 command |
| `ACR_LOGIN_SERVER` | ACR server URL | Get after first infra deployment |
| `ACR_USERNAME` | ACR username | Get after first infra deployment |
| `ACR_PASSWORD` | ACR password | Get after first infra deployment |

### Step 4: Deploy Infrastructure

> ⚠️ **IMPORTANT NOTE**: The infrastructure deployment will **FAIL** on the first run because the Docker image doesn't exist yet. This is expected behavior.

1. **First Deployment** (will fail):
   - Go to **Actions** → **Infrastructure Management**
   - Click **Run workflow**
   - Select **apply** and **dev** environment
   - Run the workflow (it will fail at container creation)

2. **Get ACR Credentials** (after partial deployment):
   ```bash
   cd infra
   
   # Get ACR details
   echo "ACR_LOGIN_SERVER: $(terraform output -raw acr_login_server)"
   echo "ACR_USERNAME: $(az acr credential show --name $(terraform output -raw acr_name) --query 'username' -o tsv)"
   echo "ACR_PASSWORD: $(az acr credential show --name $(terraform output -raw acr_name) --query 'passwords[0].value' -o tsv)"
   ```

3. **Set ACR Secrets**: Add the three ACR secrets to your GitHub repository

4. **Build and Push Image**:
   - Go to **Actions** → **Build and Push Docker Image**
   - Click **Run workflow** to build and push your application image

5. **Re-run Infrastructure Deployment**:
   - Go back to **Actions** → **Infrastructure Management**
   - Run workflow again with **apply** and **dev**
   - This time it should complete successfully

### Step 5: Verify Deployment

After successful deployment, your application will be accessible at:
- **URL**: `http://<container-fqdn>:8000/`
- **Health Check**: `http://<container-fqdn>:8000/health`

The URLs will be displayed in the GitHub Actions workflow summary.

## Usage

### Continuous Deployment

After initial setup, any push to the `main` branch will:
1. Build and push the Docker image to ACR
2. Update the container instance with the new image
3. Your application will be automatically deployed

### Infrastructure Management

Use the **Infrastructure Management** workflow to:
- **Plan**: Preview infrastructure changes
- **Apply**: Create/update infrastructure  
- **Destroy**: Remove all infrastructure

### Local Development

```bash
cd app
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Test locally: `curl http://localhost:8000/`

## Customization

### Custom Applications

Replace the contents of `app/` directory with your application:
- Any language/framework (Node.js, .NET, Python, Go, etc.)
- Must include a `Dockerfile`
- Dockerfile should expose the port your app runs on
- Update `infra/main.tf` if you need different port/resources

### Infrastructure Customization

Modify `infra/variables.tf`:
- `resource_group_name`: Change resource group name
- `location`: Change Azure region
- `prefix`: Change resource naming prefix
- `environment`: Add environment-specific configurations

### Environment Variables

Add environment variables in `infra/main.tf`:
```hcl
environment_variables = {
  "ENV" = var.environment
  "DATABASE_URL" = "your-database-url"
  "API_KEY" = "your-api-key"
}
```

## Troubleshooting

### Common Issues

1. **First Infrastructure Deployment Fails**: Expected! Follow Step 4 instructions.

2. **ACR Authentication Issues**: 
   - Verify ACR secrets are set correctly
   - Check if service principal has required permissions

3. **Container Won't Start**:
   - Check container logs in Azure Portal
   - Verify Dockerfile exposes correct port
   - Ensure application binds to `0.0.0.0`, not `localhost`

4. **State Lock Issues**:
   - If Terraform state is locked, go to Azure Portal
   - Navigate to storage account blob container
   - Delete the `.terraform.tfstate.lock` file

### Getting Help

- Check GitHub Actions logs for detailed error messages
- Use Azure Portal to inspect container instance logs
- Verify all secrets are set correctly in GitHub repository settings

## Security Notes

- Service principal follows principle of least privilege
- ACR admin credentials are used for simplicity (consider using managed identities for production)
- All secrets are stored securely in GitHub repository secrets
- Container instances use managed identity for ACR access