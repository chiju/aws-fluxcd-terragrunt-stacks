# 2. AWS Organizations Setup

## Overview
This document covers the setup of AWS Organizations with Terragrunt stacks for multi-account management.

## Prerequisites
- AWS CLI configured with appropriate permissions
- Terragrunt installed
- Access to management account

## Infrastructure Created

### Organization Structure
- AWS Organizations enabled with all features
- Service Control Policies enabled
- Root organizational unit configured

### Organizational Unit
- Platform OU created under root

### AWS Accounts Created
- **Dev Account**: fluxcd-stacks-dev
- **Staging Account**: fluxcd-stacks-staging  
- **Prod Account**: fluxcd-stacks-prod

## Commands Used

### Bootstrap and Initialize
```bash
export AWS_PROFILE=your-profile
cd infrastructure-live/management/global/organization

# Bootstrap: Initialize stack with backend creation
terragrunt stack run init --non-interactive --backend-bootstrap

# Validate configuration
terragrunt stack run validate --non-interactive

# Plan deployment
terragrunt stack run plan --non-interactive

# Apply changes
terragrunt stack run apply --non-interactive
```

### Check Status
```bash
terragrunt stack run plan --non-interactive
```

## Configuration Files
- **Stack Definition**: `terragrunt.stack.hcl`
- **Organization Module**: `infrastructure-catalog/modules/aws-organization`
- **Account Module**: `infrastructure-catalog/modules/aws-account`
- **OU Module**: `infrastructure-catalog/modules/aws-organizational-unit`

## Key Features
- All accounts configured with `close_on_deletion = true`
- Proper dependency management between organization, OU, and accounts
- Mock outputs for development workflow
- Service Control Policies enabled

## Status
✅ All infrastructure deployed successfully  
✅ No configuration drift detected  
✅ Ready for next phase
