# Usage Guide

This guide provides detailed examples of using the action-deployment-queue GitHub Action to manage deployments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Actions](#actions)
  - [Create Deployment](#create-deployment)
  - [Update Deployment Status](#update-deployment-status)
  - [Rollback Deployment](#rollback-deployment)
- [Complete Workflows](#complete-workflows)
- [Troubleshooting](#troubleshooting)

## Prerequisites

The action uses sensible defaults from the GitHub Actions context, so minimal configuration is required:

1. **Authentication** (Optional)
   - The action defaults to using `${{ github.token }}` (built-in GITHUB_TOKEN)
   - If you need custom permissions, provide a GitHub Personal Access Token with:
     - `read:org` - Verify organisation membership
     - `read:user` - Get user information

2. **Deployment Queue API Access**
   - API URL defaults to the CLI's default endpoint
   - Override with `api_url` input if using a custom endpoint
   - Organisation membership configured in the API

3. **Repository Configuration** (Optional)
   - Override defaults by providing explicit values (see [Configuration](#configuration))

## Configuration

### Default Behaviour

The action automatically uses:
- **`github_token`**: `${{ github.token }}` (built-in GITHUB_TOKEN)
- **`organisation`**: `${{ github.repository_owner }}`
- **`api_url`**: CLI's default endpoint

### Custom Configuration (Optional)

Override defaults by providing explicit values:

#### Repository Variables

```
DEPLOYMENT_API_URL=https://deployments.example.com
DEPLOYMENT_ORG=my-custom-organisation
```

#### Repository Secrets

```
DEPLOYMENT_GITHUB_TOKEN=ghp_xxxxxxxxxxxx
```

To create a custom GitHub token:
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `read:org` and `read:user` scopes
3. Copy the token value
4. Add as repository secret named `DEPLOYMENT_GITHUB_TOKEN`

## Actions

### Create Deployment

Create a new deployment in the queue.

#### Basic Example

```yaml
- name: Create Kubernetes deployment
  id: create_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: my-service
    version: v1.2.3
    type: k8s
    provider: gcp
    account: my-project
    region: europe-west1
    # Optional: Override defaults if needed
    # api_url: ${{ vars.DEPLOYMENT_API_URL }}
    # github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    # organisation: ${{ vars.DEPLOYMENT_ORG }}

- name: Output deployment ID
  run: echo "Deployment ID ${{ steps.create_deployment.outputs.deployment_id }}"
```

#### Required Inputs

| Input | Description | Valid Values |
|-------|-------------|--------------|
| `name` | Component name | Any string |
| `version` | Version to deploy | Any string (e.g., v1.2.3, commit SHA) |
| `type` | Deployment type | `k8s`, `terraform`, `data_pipeline` |
| `provider` | Cloud provider | `gcp`, `aws`, `azure` |

#### Optional Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `account` | Cloud account ID | - |
| `region` | Cloud region | - |
| `tenant` | Tenant ID | - |
| `cell` | Cell ID | - |
| `auto` | Auto-deploy when ready | `true` |
| `commit` | Git commit SHA | `${{ github.sha }}` |
| `build_uri` | Build URI | GitHub Actions run URL |
| `description` | Deployment description | Commit message (first line) |
| `notes` | Deployment notes | - |
| `pipeline_params` | Pipeline params (JSON) | - |

#### With All Options

```yaml
- name: Create deployment with all options
  id: create_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: my-service
    version: ${{ github.sha }}
    type: k8s
    provider: aws
    account: production
    region: eu-west-1
    tenant: tenant-retail
    cell: cell-001
    commit: ${{ github.sha }}
    description: "Release ${{ github.ref_name }}"
    notes: "Deployed from GitHub Actions"
    build_uri: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
    pipeline_params: '{"replicas": 3, "memory": "2Gi"}'
    auto: true
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### With Dynamic Version from Git Tag

```yaml
- name: Extract version from tag
  id: version
  run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

- name: Create deployment
  id: create_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: my-service
    version: ${{ steps.version.outputs.VERSION }}
    type: k8s
    provider: gcp
    account: production
    region: europe-west1
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### Terraform Deployment

```yaml
- name: Create Terraform deployment
  id: create_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: infrastructure
    version: v2.0.0
    type: terraform
    provider: aws
    account: prod-account
    region: us-east-1
    pipeline_params: '{"workspace": "production"}'
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### Data Pipeline Deployment

```yaml
- name: Create data pipeline deployment
  id: create_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: etl-pipeline
    version: v1.5.0
    type: data_pipeline
    provider: gcp
    account: data-project
    region: europe-west1
    pipeline_params: '{"mode": "full", "partitions": "2024-01"}'
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### With Manual Approval Required

```yaml
- name: Create deployment requiring manual release
  id: create_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: user-service
    version: v2.0.0
    type: k8s
    provider: gcp
    account: production-project
    region: europe-west1
    auto: false  # Requires manual release via CLI or API
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

### Update Deployment Status

Update the status of an existing deployment.

#### Mark as Deployed

```yaml
- name: Mark deployment as deployed
  uses: martocorp/action-deployment-queue@v1
  with:
    action: update
    deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
    status: deployed
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### Mark as Failed

```yaml
- name: Mark deployment as failed
  if: failure()
  uses: martocorp/action-deployment-queue@v1
  with:
    action: update
    deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
    status: failed
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### Valid Status Values

| Status | Description |
|--------|-------------|
| `scheduled` | Waiting in queue |
| `in_progress` | Currently deploying |
| `deployed` | Successfully deployed |
| `failed` | Deployment failed |
| `skipped` | Deployment skipped |

#### Conditional Status Update

```yaml
- name: Deploy application
  id: deploy
  run: kubectl apply -f k8s/

- name: Update deployment status
  uses: martocorp/action-deployment-queue@v1
  with:
    action: update
    deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
    status: ${{ steps.deploy.outcome == 'success' && 'deployed' || 'failed' }}
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### Update with Environment Variables

```yaml
- name: Store deployment ID
  run: echo "DEPLOYMENT_ID=${{ steps.create_deployment.outputs.deployment_id }}" >> $GITHUB_ENV

- name: Update status using environment variable
  uses: martocorp/action-deployment-queue@v1
  with:
    action: update
    deployment_id: ${{ env.DEPLOYMENT_ID }}
    status: deployed
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

### Rollback Deployment

Create a rollback deployment from an existing deployment.

#### Rollback to Previous Version

```yaml
- name: Rollback to previous version
  id: rollback_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: rollback
    deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}

- name: Output rollback deployment ID
  run: echo "Rollback deployment ID ${{ steps.rollback_deployment.outputs.deployment_id }}"
```

#### Rollback to Specific Version

```yaml
- name: Rollback to v1.0.0
  id: rollback_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: rollback
    deployment_id: ${{ inputs.failed_deployment_id }}
    target_version: v1.0.0
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

#### Rollback on Failure

```yaml
- name: Deploy application
  id: deploy
  run: kubectl apply -f k8s/

- name: Rollback on failure
  if: failure()
  uses: martocorp/action-deployment-queue@v1
  with:
    action: rollback
    deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

## Complete Workflows

### Production Deployment Workflow

```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Extract version from tag
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

      - name: Create deployment
        id: create_deployment
        uses: martocorp/action-deployment-queue@v1
        with:
          action: create
          name: my-service
          version: ${{ steps.version.outputs.VERSION }}
          type: k8s
          provider: gcp
          account: production
          region: europe-west1
          commit: ${{ github.sha }}
          build_uri: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
          description: "Production release ${{ steps.version.outputs.VERSION }}"
          auto: true
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Configure kubectl
        uses: azure/setup-kubectl@v3

      - name: Authenticate with GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}

      - name: Get GKE credentials
        run: |
          gcloud container clusters get-credentials production-cluster \
            --region europe-west1 \
            --project production

      - name: Deploy to Kubernetes
        id: deploy
        run: |
          kubectl apply -f k8s/
          kubectl rollout status deployment/my-service -n production

      - name: Mark deployment as deployed
        if: success()
        uses: martocorp/action-deployment-queue@v1
        with:
          action: update
          deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
          status: deployed
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Mark deployment as failed
        if: failure()
        uses: martocorp/action-deployment-queue@v1
        with:
          action: update
          deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
          status: failed
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Rollback on failure
        if: failure()
        uses: martocorp/action-deployment-queue@v1
        with:
          action: rollback
          deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}
```

### Manual Rollback Workflow

```yaml
name: Rollback Production

on:
  workflow_dispatch:
    inputs:
      deployment_id:
        description: 'Deployment ID to rollback'
        required: true
        type: string
      target_version:
        description: 'Target version (leave empty for previous)'
        required: false
        type: string

jobs:
  rollback:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Create rollback deployment
        id: rollback_deployment
        uses: martocorp/action-deployment-queue@v1
        with:
          action: rollback
          deployment_id: ${{ inputs.deployment_id }}
          target_version: ${{ inputs.target_version }}
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Configure kubectl
        uses: azure/setup-kubectl@v3

      - name: Authenticate with GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}

      - name: Get GKE credentials
        run: |
          gcloud container clusters get-credentials production-cluster \
            --region europe-west1 \
            --project production

      - name: Perform rollback
        id: perform_rollback
        run: |
          kubectl rollout undo deployment/my-service -n production
          kubectl rollout status deployment/my-service -n production

      - name: Mark rollback as deployed
        if: success()
        uses: martocorp/action-deployment-queue@v1
        with:
          action: update
          deployment_id: ${{ steps.rollback_deployment.outputs.deployment_id }}
          status: deployed
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Mark rollback as failed
        if: failure()
        uses: martocorp/action-deployment-queue@v1
        with:
          action: update
          deployment_id: ${{ steps.rollback_deployment.outputs.deployment_id }}
          status: failed
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}
```

### Multi-Environment Deployment

```yaml
name: Deploy to Multiple Environments

on:
  push:
    branches:
      - main
      - develop

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment:
          - name: staging
            provider: gcp
            account: staging-project
            region: europe-west1
          - name: production
            provider: gcp
            account: prod-project
            region: europe-west1

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Create deployment
        id: create_deployment
        uses: martocorp/action-deployment-queue@v1
        with:
          action: create
          name: my-service
          version: ${{ github.sha }}
          type: k8s
          provider: ${{ matrix.environment.provider }}
          account: ${{ matrix.environment.account }}
          region: ${{ matrix.environment.region }}
          commit: ${{ github.sha }}
          description: "Deployment to ${{ matrix.environment.name }}"
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Deploy to ${{ matrix.environment.name }}
        run: |
          # Your environment-specific deployment logic
          echo "Deploying to ${{ matrix.environment.name }}"

      - name: Update status
        uses: martocorp/action-deployment-queue@v1
        with:
          action: update
          deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
          status: deployed
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}
```

### Terraform Deployment Workflow

```yaml
name: Deploy Infrastructure

on:
  push:
    paths:
      - 'terraform/**'
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Create Terraform deployment
        id: create_deployment
        uses: martocorp/action-deployment-queue@v1
        with:
          action: create
          name: infrastructure
          version: ${{ github.sha }}
          type: terraform
          provider: aws
          account: production
          region: us-east-1
          commit: ${{ github.sha }}
          pipeline_params: '{"workspace": "production"}'
          description: "Infrastructure update"
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Apply
        id: apply
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve

      - name: Mark as deployed
        if: success()
        uses: martocorp/action-deployment-queue@v1
        with:
          action: update
          deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
          status: deployed
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Mark as failed
        if: failure()
        uses: martocorp/action-deployment-queue@v1
        with:
          action: update
          deployment_id: ${{ steps.create_deployment.outputs.deployment_id }}
          status: failed
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}
```

## Troubleshooting

### Authentication Errors

**Error**: `Authentication failed: Invalid token`

**Solution**: Verify that:
1. The GitHub token has `read:org` and `read:user` scopes
2. The token is not expired
3. The secret name matches exactly: `DEPLOYMENT_GITHUB_TOKEN`

### Organisation Membership

**Error**: `User is not a member of organisation: my-org`

**Solution**: Ensure:
1. The user associated with the GitHub token is a member of the specified organisation
2. The organisation name is spelled correctly (case-sensitive)
3. Organisation membership is public or the token has sufficient permissions

### API Connection Issues

**Error**: `Failed to connect to API`

**Solution**: Check that:
1. The API URL is correct and accessible
2. The API is running and responsive
3. Network connectivity is not blocked by firewall rules

### Deployment ID Not Found

**Error**: `Deployment not found: <id>`

**Solution**: Verify:
1. The deployment ID is correct
2. The deployment exists in the specified organisation
3. You're using the correct API URL and organisation

### Container Image Not Found

**Error**: `Unable to pull image: martocorp/deployment-queue-cli:latest`

**Solution**: Ensure:
1. The container image exists and is published to Docker Hub
2. The image is publicly accessible
3. The image tag is correct (version tags do not include "v" prefix)

### Input Validation Errors

**Error**: `Error: 'name' is required for create action`

**Solution**: Ensure all required inputs are provided for the selected action:
- **create**: name, version, type, provider
- **update**: deployment_id, status
- **rollback**: deployment_id

**Error**: `Error: 'type' must be k8s, terraform, or data_pipeline`

**Solution**: Use only valid values for enum inputs:
- **type**: `k8s`, `terraform`, `data_pipeline`
- **provider**: `gcp`, `aws`, `azure`
- **status**: `scheduled`, `in_progress`, `deployed`, `failed`, `skipped`
- **auto**: `true`, `false`

## Advanced Usage

### Using Custom Container Image

```yaml
- name: Use specific CLI version
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: my-service
    version: v1.0.0
    type: k8s
    provider: gcp
    container_image: martocorp/deployment-queue-cli:1.0.0
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

**Note**: Version tags do not include the "v" prefix (e.g., `1.0.0` not `v1.0.0`)

### Environment-Specific Configuration

```yaml
- name: Deploy to environment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: my-service
    version: ${{ github.sha }}
    type: k8s
    provider: gcp
    api_url: ${{ vars[format('DEPLOYMENT_API_URL_{0}', github.event.inputs.environment)] }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars[format('DEPLOYMENT_ORG_{0}', github.event.inputs.environment)] }}
```

### Skipping Confirmation Prompts

By default, the action skips confirmation prompts (`yes: true`). To enable prompts:

```yaml
- name: Create deployment with confirmation
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: my-service
    version: v1.0.0
    type: k8s
    provider: gcp
    yes: false  # Enable confirmation prompts (not recommended for CI/CD)
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

**Note**: Confirmation prompts are not useful in CI/CD workflows and should typically remain disabled.

## Related Documentation

- [deployment-queue-cli Documentation](https://github.com/martocorp/deployment-queue-cli)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Conventional Commits](https://www.conventionalcommits.org/)
