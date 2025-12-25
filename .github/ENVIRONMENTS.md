# GitHub Environments Configuration
# 
# This file documents the required GitHub environments for the pipeline.
# Create these environments in your GitHub repository settings.

## Required Environments:

### 1. dev
- **Protection Rules**: None (auto-deploy)
- **Required Reviewers**: None
- **Deployment Branches**: Any branch

### 2. staging  
- **Protection Rules**: Required reviewers (1)
- **Required Reviewers**: DevOps team members
- **Deployment Branches**: main branch only

### 3. production
- **Protection Rules**: Required reviewers (2)
- **Required Reviewers**: DevOps team leads + Security team
- **Deployment Branches**: main branch only
- **Wait Timer**: 5 minutes

### 4. dev-destroy
- **Protection Rules**: Required reviewers (1)
- **Required Reviewers**: DevOps team members
- **Deployment Branches**: main branch only

### 5. staging-destroy
- **Protection Rules**: Required reviewers (2)
- **Required Reviewers**: DevOps team leads
- **Deployment Branches**: main branch only

### 6. production-destroy
- **Protection Rules**: Required reviewers (3)
- **Required Reviewers**: DevOps team leads + Security team + Management
- **Deployment Branches**: main branch only
- **Wait Timer**: 30 minutes

## Required Secrets:

### Repository Secrets:
- `AWS_ACCOUNT_ID_DEV`: Dev account ID
- `AWS_ACCOUNT_ID_STAGING`: Staging account ID  
- `AWS_ACCOUNT_ID_PRODUCTION`: Production account ID
- `AWS_GITHUB_ROLE_ARN_DEV`: GitHub Actions role ARN for dev
- `AWS_GITHUB_ROLE_ARN_STAGING`: GitHub Actions role ARN for staging
- `AWS_GITHUB_ROLE_ARN_PROD`: GitHub Actions role ARN for production

## Setup Instructions:

1. Go to your repository Settings → Environments
2. Create each environment listed above
3. Configure protection rules as specified
4. Add required reviewers from your team
5. Set deployment branch restrictions
6. Configure wait timers for production environments
