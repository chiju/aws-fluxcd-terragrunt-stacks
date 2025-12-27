# GitHub App Setup for FluxCD

## Overview

Create a GitHub App to allow FluxCD to authenticate and access your repository securely.

## Prerequisites

- GitHub account with repository access
- GitHub CLI installed and authenticated
- Repository: `chiju/aws-fluxcd-terragrunt-stacks`

## Step 1: Create GitHub App

**Go to:** https://github.com/settings/apps/new

### Required Settings

**Basic Information:**
- **Name**: `FluxCD-Terragrunt-Stacks`
- **Homepage**: `https://github.com/chiju/aws-fluxcd-terragrunt-stacks`
- **Webhook**: ✅ **Uncheck "Active"** (we don't need webhooks)

**Repository Permissions:**
- **Contents**: `Read & Write` (FluxCD needs to write manifests during bootstrap)
- **Metadata**: `Read-only` (automatically required)

**Installation:**
- **Where can this app be installed**: `Only on this account`

Click **Create GitHub App**

## Step 2: Generate Private Key

1. After creation, scroll down to **Private keys** section
2. Click **Generate a private key**
3. A `.pem` file will be downloaded

## Step 3: Note App ID

On the app settings page, note the **App ID** near the top

## Step 4: Install App on Repository

1. Click **Install App** in the left sidebar
2. Click **Install** next to your account
3. Select **Only select repositories**
4. Choose `aws-fluxcd-terragrunt-stacks` repository
5. Click **Install**

## Step 5: Note Installation ID

After installation, you'll be redirected to a URL like:
```
https://github.com/settings/installations/XXXXXXXXX
```

The number at the end is your **Installation ID**

## Step 6: Store GitHub Secrets

```bash
# Navigate to Downloads folder (or wherever the .pem file was saved)
cd ~/Downloads

# Set private key (replace with your actual filename)
gh secret set FLUXCD_APP_PRIVATE_KEY < fluxcd-terragrunt-stacks.YYYY-MM-DD.private-key.pem --repo chiju/aws-fluxcd-terragrunt-stacks

# Set App ID (replace with your actual App ID)
gh secret set FLUXCD_APP_ID -b "YOUR_APP_ID" --repo chiju/aws-fluxcd-terragrunt-stacks

# Set Installation ID (replace with your actual Installation ID)
gh secret set FLUXCD_APP_INSTALLATION_ID -b "YOUR_INSTALLATION_ID" --repo chiju/aws-fluxcd-terragrunt-stacks
```

## Step 7: Verify Secrets

```bash
gh secret list --repo chiju/aws-fluxcd-terragrunt-stacks | grep FLUXCD
```

## Next Steps

After GitHub App setup:
1. Set the environment variables in your pipeline
2. Deploy the EKS + FluxCD stack
3. FluxCD will bootstrap itself and manage the `flux-config/` directory
