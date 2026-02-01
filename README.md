[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# action-deployment-queue

A GitHub Action to manage deployments using the deployment-queue-cli. Create, update status, and rollback deployments directly from your GitHub workflows.

## Features

- **Create Deployments**: Queue new deployments for Kubernetes, Terraform, or data pipeline types
- **Update Status**: Change deployment status (scheduled, in_progress, deployed, failed, skipped)
- **Rollback**: Create rollback deployments to previous versions
- **Input Validation**: Automatic validation of required parameters based on action type
- **Dual Authentication**: GitHub PAT with organisation verification
- **Container-Based**: Uses the official deployment-queue-cli container

## Usage

### Basic Example

```yaml
name: Deploy Application

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Create deployment
        uses: martocorp/action-deployment-queue@v1
        with:
          action: create
          name: my-service
          version: v1.2.3
          type: k8s
          provider: gcp
          account: my-project
          region: europe-west1
          api_url: https://deployments.example.com
          github_token: ${{ secrets.DEPLOYMENT_QUEUE_GITHUB_TOKEN }}
          organisation: my-org
```

### Create Deployment

Create a new deployment with required and optional parameters:

```yaml
- name: Create Kubernetes deployment
  id: create_deployment
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: my-service
    version: ${{ github.sha }}
    type: k8s
    provider: aws
    account: my-account
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

- name: Output deployment ID
  run: echo "Created deployment ID ${{ steps.create_deployment.outputs.deployment_id }}"
```

#### Create with Manual Approval

```yaml
- name: Create deployment requiring manual release
  uses: martocorp/action-deployment-queue@v1
  with:
    action: create
    name: user-service
    version: v2.0.0
    type: terraform
    provider: gcp
    account: production-project
    region: europe-west1
    auto: false  # Requires manual release
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

### Update Deployment Status

Update the status of an existing deployment:

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

### Rollback Deployment

Create a rollback deployment from an existing deployment:

```yaml
- name: Rollback to previous version
  uses: martocorp/action-deployment-queue@v1
  with:
    action: rollback
    deployment_id: ${{ inputs.failed_deployment_id }}
    target_version: v1.0.0  # Optional: specify target version
    yes: true
    api_url: ${{ vars.DEPLOYMENT_API_URL }}
    github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
    organisation: ${{ vars.DEPLOYMENT_ORG }}
```

## Inputs

### Common Inputs (Required for All Actions)

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `action` | Action to execute: `create`, `update`, or `rollback` | Yes | - |
| `api_url` | Deployment Queue API URL | Yes | - |
| `github_token` | GitHub token with `read:org` and `read:user` scopes | Yes | - |
| `organisation` | GitHub organisation name | Yes | - |

### Create Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Component name | Yes | - |
| `version` | Version to deploy | Yes | - |
| `type` | Deployment type: `k8s`, `terraform`, or `data_pipeline` | Yes | - |
| `provider` | Cloud provider: `gcp`, `aws`, or `azure` | Yes | - |
| `account` | Cloud account ID | No | - |
| `region` | Cloud region | No | - |
| `tenant` | Tenant ID | No | - |
| `cell` | Cell ID | No | - |
| `auto` | Auto-deploy when ready: `true` or `false` | No | `true` |
| `description` | Deployment description | No | - |
| `notes` | Deployment notes | No | - |
| `commit` | Git commit SHA | No | - |
| `build_uri` | Build URI | No | - |
| `pipeline_params` | Pipeline extra params as JSON string | No | - |

### Update Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `deployment_id` | Deployment ID | Yes | - |
| `status` | New status: `scheduled`, `in_progress`, `deployed`, `failed`, or `skipped` | Yes | - |

### Rollback Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `deployment_id` | Deployment ID to rollback | Yes | - |
| `target_version` | Target version for rollback | No | previous |

### Optional Inputs (All Actions)

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `yes` | Skip confirmation prompts: `true` or `false` | No | `true` |
| `container_image` | Container image to use | No | `martocorp/deployment-queue-cli:latest` |

## Outputs

| Output | Description |
|--------|-------------|
| `deployment_id` | Deployment ID (for create and rollback actions) |
| `result` | Command execution result |

## Authentication

The action requires a GitHub Personal Access Token (PAT) with the following scopes:
- `read:org` - Verify organisation membership
- `read:user` - Get user information

### Creating a GitHub Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `read:org` and `read:user` scopes
3. Add the token as a repository secret: `DEPLOYMENT_GITHUB_TOKEN`

### Recommended Setup

Store configuration as repository variables and secrets:

**Variables:**
```
DEPLOYMENT_API_URL=https://deployments.example.com
DEPLOYMENT_ORG=my-organisation
```

**Secrets:**
```
DEPLOYMENT_GITHUB_TOKEN=ghp_xxxxxxxxxxxx
```

## Environment Variables

The action sets the following environment variables for the CLI:
- `DEPLOYMENT_QUEUE_CLI_API_URL` - API endpoint
- `DEPLOYMENT_QUEUE_CLI_GITHUB_TOKEN` - GitHub authentication token
- `DEPLOYMENT_QUEUE_CLI_ORGANISATION` - Organisation context

## Complete Workflow Example

```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Extract version
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
          account: production-project
          region: europe-west1
          commit: ${{ github.sha }}
          build_uri: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
          description: "Production release ${{ steps.version.outputs.VERSION }}"
          auto: true
          api_url: ${{ vars.DEPLOYMENT_API_URL }}
          github_token: ${{ secrets.DEPLOYMENT_GITHUB_TOKEN }}
          organisation: ${{ vars.DEPLOYMENT_ORG }}

      - name: Deploy application
        run: |
          # Your deployment logic here
          kubectl apply -f k8s/

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

## Container Image

By default, the action uses `martocorp/deployment-queue-cli:latest` from Docker Hub. You can specify a different image or tag:

```yaml
- name: Create deployment with specific CLI version
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

## Documentation

- [Usage Guide](docs/USAGE.md) - Detailed usage examples and CLI reference
- [Code Style Guide](docs/CODESTYLE.md) - Development guidelines

## Related Projects

- [deployment-queue-cli](https://github.com/martocorp/deployment-queue-cli) - The underlying CLI tool and container

## Development

See [docs/CODESTYLE.md](docs/CODESTYLE.md) for development guidelines.

### Commands

- `make init` - Install development dependencies
- `make lint` - Run YAML linting
- `make validate` - Validate action configuration
- `make clean` - Clean temporary files

## Licence

MIT

