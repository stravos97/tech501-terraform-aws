# Two-Tier Azure Infrastructure with Terraform

This project creates a secure two-tier application infrastructure in Azure using Terraform. It consists of a web application tier and a database tier, with appropriate networking and security configurations.

## Architecture Overview

```
                                     +----------------+
                                     |                |
                                     |  Azure Cloud   |
                                     |                |
                                     +----------------+
                                            |
                                     +----------------+
                                     |   Virtual      |
                                     |   Network      |
                                     +----------------+
                                    /                \
                              ____/                    \____
                             /                              \
              +----------------+                    +----------------+
              |  Public Subnet |                    | Private Subnet |
              +----------------+                    +----------------+
              |                |                    |                |
              |   App VM       |                    |    DB VM      |
              | (Public IP)    |                    | (Private IP)  |
              +----------------+                    +----------------+
```

## Prerequisites

1. Azure Account and Subscription
2. Azure CLI installed and configured
3. Terraform installed (v1.0.0 or newer)
4. SSH key pair for VM access

## Project Structure

```
create-azure-two-tier/
├── main.tf              # Main configuration file
├── variables.tf         # Variable definitions
├── outputs.tf          # Output definitions
└── modules/            # Modular components
    ├── vnet/          # Virtual Network configuration
    ├── network/       # Network interface and security
    └── compute/       # Virtual machine configurations
```

## Module Architecture

```
                                    main.tf
                                       |
                    +------------------+------------------+
                    |                  |                 |
                    v                  v                 v
              vnet module       network module     network module
            (Shared VNet)      (App Tier)         (DB Tier)
                    ^                  |                 |
                    |                  v                 v
                    |           compute module     compute module
                    |           (App VM)          (DB VM)
                    |                  |                 |
                    |                  |                 |
                    +------------------+-----------------+
                              Network Communication
                                 (VNet Peering)

Module Dependencies:
-------------------
1. vnet module:
   - Creates shared VNet
   - Manages address space
   - No dependencies

2. network module (App):
   - Depends on vnet module
   - Creates public subnet
   - Manages NSG rules
   - Allocates public IP

3. network module (DB):
   - Depends on vnet module
   - Creates private subnet
   - Manages NSG rules
   - No public IP

4. compute module (App):
   - Depends on network module (App)
   - Creates app VM
   - Configures custom data
   - References DB private IP

5. compute module (DB):
   - Depends on network module (DB)
   - Creates DB VM
   - Basic initialization

Data Flow:
----------
→ vnet module outputs VNet name to network modules
→ network modules output NIC IDs to compute modules
→ network module (DB) outputs private IP to compute module (App)
→ All modules output resource IDs and IPs to main.tf
```

## Configuration Breakdown

### Provider Configuration (main.tf)

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  resource_provider_registrations = var.resource_provider_registrations
}
```

This block configures the Azure provider:
- `features {}`: Required empty block for the Azure provider
- `subscription_id`: Your Azure subscription ID
- `resource_provider_registrations`: Controls how the provider handles Azure resource provider registration

### Virtual Network (modules/vnet)

The Virtual Network (VNet) module creates the network foundation:
- Creates a single VNet that both tiers will use
- Defines the overall network address space
- Enables communication between app and database tiers

### Application Tier

The application tier consists of:

1. Network Configuration (modules/network)
   - Public subnet for internet accessibility
   - Public IP address for external access
   - Network Security Group (NSG) rules:
     - Inbound port 22 (SSH) for administration
     - Inbound port 80 (HTTP) for web traffic
   - Network interface with public IP

2. Compute Configuration (modules/compute)
   - Linux VM with specified size
   - OS disk with configurable caching and storage type
   - Custom data script for application setup
   - SSH key authentication
   - Connection to MongoDB using private IP

### Database Tier

The database tier consists of:

1. Network Configuration (modules/network)
   - Private subnet (no internet access)
   - No public IP address
   - Network Security Group (NSG) rules:
     - Inbound port 27017 (MongoDB) from app subnet only
     - Inbound port 22 (SSH) from app subnet only
     - Inbound port 3000 from app subnet
   - Network interface with private IP only

2. Compute Configuration (modules/compute)
   - Linux VM with specified size
   - OS disk configuration
   - SSH key authentication
   - Basic initialization script

## Security Features

1. Network Isolation
   - DB tier in private subnet
   - No direct internet access to DB
   - App tier in public subnet with controlled access

2. Network Security Groups
   - App NSG: Allows only necessary inbound ports (22, 80)
   - DB NSG: Allows only app subnet traffic on specific ports (22, 27017, 3000)

3. Authentication
   - SSH key-based authentication
   - Password authentication disabled
   - No shared credentials between tiers

## Deployment Instructions

1. Initialize Terraform:
   ```bash
   terraform init
   ```
   This downloads required providers and modules.

2. Review the variables:
   - Copy variables.tf to terraform.tfvars
   - Fill in your specific values:
     - subscription_id
     - resource_group_name
     - SSH key path
     - VM sizes and names
     - Network address spaces

3. Plan the deployment:
   ```bash
   terraform plan
   ```
   Review the planned changes carefully.

4. Apply the configuration:
   ```bash
   terraform apply
   ```
   Type 'yes' when prompted.

5. Verify deployment:
   - Check Azure portal for resources
   - Try SSH into app VM
   - Verify app can connect to database

## Common Operations

### Connecting to VMs

1. App VM (direct SSH):
   ```bash
   ssh -i <path-to-private-key> adminuser@<app-vm-public-ip>
   ```

2. DB VM (through app VM):
   ```bash
   # First SSH to app VM, then to DB VM
   ssh -i <path-to-private-key> adminuser@<db-vm-private-ip>
   ```

### Checking Logs

1. Application logs:
   ```bash
   # On app VM
   pm2 logs
   ```

2. System logs:
   ```bash
   sudo journalctl -u mongodb    # DB VM
   sudo journalctl -u nginx      # App VM
   ```

### Destroying Infrastructure

To remove all created resources:
```bash
terraform destroy
```
Review carefully before confirming.

## Troubleshooting

1. Connection Issues:
   - Verify NSG rules
   - Check VM status
   - Confirm private IP addresses

2. Database Connection:
   - Verify MongoDB is running
   - Check connection string
   - Verify port 27017 is open

3. Application Issues:
   - Check pm2 status
   - Verify environment variables
   - Check application logs

## Variables Reference

### Required Variables:
- `subscription_id`: Azure subscription ID
- `resource_group_name`: Existing resource group name
- `admin_username`: VM administrator username
- `ssh_key_path`: Path to SSH public key

### Optional Variables (with defaults):
- `vm_size`: VM size (default: "Standard_DS1_v2")
- `location`: Azure region (default: resource group location)
- `vnet_address_space`: VNet address range
- `app_subnet_address_prefix`: App subnet range
- `db_subnet_address_prefix_db`: DB subnet range

## Outputs

- `app_public_ip`: Public IP of the application VM
- `app_private_ip`: Private IP of the application VM
- `db_private_ip`: Private IP of the database VM

## Step by Step Deployment Process

This section details exactly how the infrastructure was deployed, from start to finish:

1. Virtual Network Setup
   - First, we created a VNet module (`modules/vnet/`) to handle the base networking
   - This module creates a single VNet that both app and DB tiers share
   - The VNet is configured with a large enough address space to accommodate both subnets
   - Example: If VNet is 10.0.0.0/16, app subnet might be 10.0.1.0/24 and DB subnet 10.0.2.0/24

2. Network Module Creation (`modules/network/`)
   - Created a flexible network module that can create either public or private subnets
   - Implemented conditional public IP allocation based on subnet type
   - Set up NSG rules with dynamic blocks to handle different security rules for app and DB
   - Added outputs for IP addresses and network interface IDs

3. Compute Module Setup (`modules/compute/`)
   - Created a reusable compute module for both app and DB VMs
   - Implemented conditional custom data script based on VM role
   - Added SSH key authentication
   - Configured OS disk settings

4. Database Tier Implementation
   - Deployed the DB VM in a private subnet
   - Configured MongoDB port (27017) access from app subnet
   - Set up SSH access only from app subnet
   - Added port 3000 access from app subnet
   - No public IP assigned for security

5. Application Tier Implementation
   - Deployed the app VM in a public subnet
   - Configured public IP and NSG rules for web access
   - Set up environment variables to connect to DB using private IP
   - Enabled SSH access from internet for administration

6. Security Implementation
   - Created separate NSGs for app and DB tiers
   - Configured inbound/outbound rules for necessary ports only
   - Implemented network isolation for DB tier
   - Set up SSH key-based authentication

7. Module Integration
   - Connected all modules in main.tf
   - Set up proper dependencies between resources
   - Configured variable passing between modules
   - Added outputs for important information

8. Testing and Verification
   - Tested SSH access to app VM
   - Verified DB VM is only accessible through app VM
   - Confirmed MongoDB connectivity
   - Validated all security rules
   - Tested application functionality

Each step was implemented with security and maintainability in mind, using Terraform best practices such as:
- Modular design for reusability
- Clear variable definitions
- Proper resource naming
- Comprehensive tagging
- Careful security group configuration

## Best Practices

1. Network Security:
   - Keep DB in private subnet
   - Minimize open ports
   - Use specific source address prefixes

2. VM Management:
   - Use SSH keys instead of passwords
   - Regular updates and patches
   - Monitor logs and metrics

3. Infrastructure:
   - Use variables for customization
   - Tag resources appropriately
   - Regular terraform plan reviews
