# CentOS OpenStack Node Setup

Automated installation scripts for deploying OpenStack on CentOS Stream 9.

## Overview

This script builds OpenStack nodes with support for:
- Controller nodes (Keystone, Glance, Nova, Cinder, Neutron, Swift, Placement, Horizon)
- Compute nodes (Nova, Neutron)
- Storage nodes (Cinder volume, Swift storage)
- Network nodes (Neutron L3/DHCP agents)

## Tested Versions

- **OS**: CentOS Stream 9
- **OpenStack**: Bobcat (2023.2) and later releases

## Prerequisites

- Clean CentOS Stream 9 installation
- Network connectivity between nodes
- Sufficient disk space for services and storage

## Password Management

When `openstack_passwords` exists, the script will rename the current file before creating a new one.

**IMPORTANT**: Passwords are generated using openssl to generate random passwords. **Backup the `openstack_passwords` file after generation!**

## Usage

```bash
# Run prerequisite checks
./cos-node-setup check_prerequisites

# Install controller services
./cos-node-setup keystone_controller
./cos-node-setup glance_controller
./cos-node-setup placement_controller
./cos-node-setup nova_controller
./cos-node-setup neutron_controller
./cos-node-setup cinder_controller
./cos-node-setup swift_controller

# Install compute node
./cos-node-setup nova_compute_node
./cos-node-setup neutron_compute_node

# Install storage nodes
./cos-node-setup cinder_volume_node
./cos-node-setup swift_node

# Cleanup functions
./cos-node-setup clean_<service>_<node_type>
```

## RBAC Policy Configuration

### OpenStack Dalmatian (2024.2) and Later

By default, the script is configured for **Dalmatian and newer releases**, which have built-in scope-aware RBAC policies. No additional policy files are needed.

### Pre-Dalmatian (Bobcat, Caracal)

For releases **before Dalmatian**, you need to enable custom policy files for Nova and Placement:

1. **Edit the installation script** and uncomment the following lines:

   **For Placement** (around line 1034-1035):
   ```bash
   cp /etc/placement/policy.json.example /etc/placement/policy.json
   sed -i "/^\[oslo_policy\]/a policy_file = /etc/placement/policy.json" /etc/placement/placement.conf
   ```

   **For Nova Controller** (around line 1127-1128):
   ```bash
   cp /etc/nova/policy.yaml.example /etc/nova/policy.yaml
   sed -i "/^\[oslo_policy\]/a policy_file = /etc/nova/policy.yaml" /etc/nova/nova.conf
   ```

   **For Nova Compute** (around line 1209-1210):
   ```bash
   cp /etc/nova/policy.yaml.example /etc/nova/policy.yaml
   sed -i "/^\[oslo_policy\]/a policy_file = /etc/nova/policy.yaml" /etc/nova/nova.conf
   ```

2. **Why this matters**: Pre-Dalmatian releases don't have complete scope-aware policy defaults. The custom policy files ensure proper RBAC enforcement with system-scoped credentials.

3. **Note**: Policy files are created as `.example` to prevent automatic loading on Dalmatian+ where they would override improved built-in defaults.

## Configuration Files

- `openstack_vars` - Node configuration (IPs, hostnames, settings)
- `openstack_passwords` - Generated service passwords (backup this file!)
- `resume_status` - Track installation progress
- `clean_functions` - Cleanup/rollback functions

## Utility Scripts

### flavors

Creates standard OpenStack compute flavors after deployment:

```bash
./flavors
```

This script creates five standard flavors:
- **m1.tiny** - 512 MB RAM, 1 vCPU, 5 GB disk
- **m1.small** - 2 GB RAM, 1 vCPU, 20 GB disk
- **m1.medium** - 4 GB RAM, 2 vCPUs, 40 GB disk
- **m1.large** - 8 GB RAM, 4 vCPUs, 80 GB disk
- **m1.xlarge** - 16 GB RAM, 8 vCPUs, 160 GB disk

Run this after completing the controller node installation to make instance flavors available to users.

### gp

Git push helper script for repository maintainers:

```bash
./gp
```

This script:
1. Verifies GitHub SSH authentication
2. Prompts for a commit message
3. Stages all changes (`git add .`)
4. Commits with your message
5. Pushes to `origin/main`

**Note**: This is a development convenience script for repository maintainers only. End users deploying OpenStack do not need to use this.

## Support

This script uses RBAC-compliant authentication with `enforce_scope=true` in Keystone. Make sure you understand system-scoped vs project-scoped credentials before deployment.

