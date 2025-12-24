# AWS Multi-Account Platform with Terragrunt Stacks + FluxCD

Modern multi-account AWS platform using:
- **Terragrunt Stacks** for infrastructure orchestration
- **FluxCD** for GitOps application deployment
- **AWS Organizations** for account management
- **EKS** in each environment account

## Architecture

```
Root Account (Management)
├── AWS Organizations
├── Service Control Policies (SCPs)
├── Organization Units
└── Member Accounts
    ├── Dev Account (EKS + FluxCD)
    ├── Staging Account (EKS + FluxCD)
    └── Prod Account (EKS + FluxCD)
```

## Repository Structure

```
aws-fluxcd-terragrunt-stacks/
├── infrastructure-catalog/          # Reusable patterns
│   ├── modules/                    # Terraform modules
│   ├── units/                      # Terragrunt units
│   └── stacks/                     # Terragrunt stacks
├── infrastructure-live/            # Live environments
│   ├── management/                 # Root account
│   │   └── global/
│   │       └── organization/
│   ├── dev/
│   │   └── eu-central-1/
│   │       └── platform/
│   ├── staging/
│   │   └── eu-central-1/
│   │       └── platform/
│   └── prod/
│       └── eu-central-1/
│           └── platform/
└── flux-config/                    # FluxCD configurations
    ├── clusters/
    ├── apps/
    └── infrastructure/
```

## Getting Started

1. **Setup Organization** (Root Account)
2. **Deploy Platform Stacks** (Each Account)  
3. **Configure FluxCD** (GitOps)
4. **Deploy Applications**

## Key Features

- ✅ Modern Terragrunt Stacks
- ✅ Multi-account isolation
- ✅ GitOps with FluxCD
- ✅ EKS in each environment
- ✅ Proper SCPs and governance
- ✅ Cross-account OIDC
