# Devenops Infra

This repository contains the deployment and operations code for the Devenops application platform.

It does not contain the application source code itself. Instead, it manages how the application is built, tagged, deployed, tested, promoted, and exposed in AWS. The application source is pulled separately during CI from the `devenvaruv/devenops` repository.

## What This Repo Manages

This repo manages:

- GitHub Actions workflows for CI/CD
- Docker image build and promotion flow through AWS ECR
- Kubernetes manifests for running services on AWS EKS
- Namespace-based environment promotion (`nightly`, `qa`, `uat`, `green`, `blue`)
- Route53 DNS updates for the green deployment
- Security scanning workflows
- Monitoring setup with Prometheus and Grafana

The Kubernetes layer currently deploys three services:

- `frontend`
- `auth`
- `games`

The `frontend` service is exposed publicly through a Kubernetes `LoadBalancer`. The `auth` and `games` services are internal cluster services.

## High-Level Flow

The deployment model is based on image promotion across environments.

1. Build changed services from the source repo and push images to ECR with a date-based tag such as `nightly-YYYYMMDD`.
2. Deploy those images into a temporary Kubernetes namespace such as `nightly`.
3. Smoke test the frontend service.
4. Retag the same images for the next environment, for example `qa-YYYYMMDD` and `uat-YYYYMMDD`.
5. After UAT passes, promote the image to a production version tag such as `v1`, `v2`, and so on.
6. Deploy production images into `blue` or `green` namespaces.
7. Optionally update Route53 so traffic can reach the green deployment.

## Repository Layout

```text
.github/workflows/   GitHub Actions pipelines
k8s/deployments/     Kubernetes Deployment manifests
k8s/services/        Kubernetes Service manifests
scripts/             Bash scripts used by the workflows
```

## Prerequisites

This repo assumes the following already exist:

- An AWS account with access to ECR, EKS, and Route53
- An EKS cluster named `EKS-Cluster` in `us-east-1`
- ECR repositories for `frontend`, `auth`, and `games` or permissions to create them
- A Route53 hosted zone if you want DNS automation for green deployments
- GitHub repository secrets configured for Actions
- The application source repo `devenvaruv/devenops`

### Required GitHub Secrets

Set these secrets in the infra repository:

- `AWS_ACCOUNT_ID`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `HOSTED_ZONE_ID`

If you want to point a custom domain to Route53, your domain nameservers must be delegated to the Route53 hosted zone values.

## How To Start

There are two supported ways to use this repo.

### Option 1: Start Through GitHub Actions

This is the primary way the repo is intended to run.

1. Open the repository in GitHub.
2. Go to the `Actions` tab.
3. Manually trigger `Nightly Build` to start the pipeline.

From there, the environment flow is:

- `Nightly Build`
- `QA Build`
- `UAT Build`
- `Deploy to Green`
- `Promote Green to Blue` when you are ready to switch over

You can also run `Build Prod` directly if you want to deploy the latest production-tagged images to the `blue` namespace.

### Option 2: Run the Scripts Manually

You can also run the scripts locally or from a runner, but your environment must already have:

- `bash`
- `docker`
- `aws`
- `kubectl`
- `jq`
- `envsubst`
- valid AWS credentials
- kubeconfig access to the EKS cluster

Typical manual flow:

```bash
bash scripts/create_namespace.sh nightly
bash scripts/deploy_services.sh nightly
bash scripts/test_deployment.sh nightly frontend-service
```

For production-style deployments that use the latest `vN` tags:

```bash
bash scripts/create_namespace.sh blue
bash scripts/deploy_services_prod.sh blue
bash scripts/test_deployment.sh blue frontend-service
```

For green deployment plus DNS update:

```bash
bash scripts/create_namespace.sh green
bash scripts/deploy_services_prod.sh green
bash scripts/test_deployment.sh green frontend-service
export HOSTED_ZONE_ID=<your-route53-zone-id>
bash scripts/update_dns.sh green.devenops.shop green frontend-service
```

## What Each Workflow Does

### Nightly Build

- Checks out this infra repo
- Checks out the application source repo
- Detects which services changed
- Builds and pushes changed images to ECR with a `nightly-YYYYMMDD` tag
- Deploys them into the `nightly` namespace
- Tests the frontend
- Promotes those images to `qa-YYYYMMDD`
- Deletes the temporary namespace

### QA Build

- Deploys the `qa-YYYYMMDD` images into the `qa` namespace
- Tests the frontend
- Promotes images to `uat-YYYYMMDD`
- Deletes the temporary namespace

### UAT Build

- Deploys the `uat-YYYYMMDD` images into the `uat` namespace
- Tests the frontend
- Promotes images to production version tags like `v1`, `v2`, and so on
- Deletes the temporary namespace

### Build Prod

- Deploys the latest production version tags into the `blue` namespace
- Tests the frontend

### Deploy to Green

- Deploys the latest production version tags into the `green` namespace
- Tests the frontend
- Updates Route53 to point `green.devenops.shop` to the green load balancer

### Promote Green to Blue

- Deploys the latest production version tags into the `blue` namespace
- Deletes the `green` namespace

### DevSecOps Security Scan

Runs:

- Trivy
- Checkov
- KubeLinter
- OWASP Dependency-Check

The reports are uploaded as GitHub Actions artifacts.

### Setup Monitoring on EKS

- Installs Helm
- Creates a `monitoring` namespace
- Installs `kube-prometheus-stack`
- Prints the Grafana admin password
- Prints the port-forward command for local access

## Kubernetes Deployment Model

The Kubernetes manifests use a `${TAG}` placeholder in the container image reference. The scripts inject the tag at deploy time using `envsubst`.

Examples:

- non-production namespaces use tags such as `nightly-YYYYMMDD`, `qa-YYYYMMDD`, and `uat-YYYYMMDD`
- production namespaces use version tags such as `v1`, `v2`, `v3`

## Notes

- This repo does not provision AWS infrastructure. It assumes the infrastructure already exists.
- The workflows are currently configured for `us-east-1`.
- The current production deployment pattern is namespace-based blue/green, not service-mesh-based traffic splitting.
- The smoke test validates the public frontend endpoint by resolving the service load balancer and curling the root URL.

## Quick Checks

To see which image is running in a pod:

```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath="{.spec.containers[*].image}"
```

Example:

```bash
kubectl get pod frontend-7f69dd57d4-67t8x -n blue -o jsonpath="{.spec.containers[*].image}"
```
