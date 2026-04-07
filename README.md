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

### Default: Dalmatian (2024.2) and Later

By default, the script is configured for **Dalmatian (2024.2) and newer releases** using the modern secure RBAC model:

- `enforce_scope = true` - Enforces system vs project scope separation
- `enforce_new_defaults = true` - Uses improved default policies
- No custom policy files - Uses built-in scope-aware policies

**This configuration works out-of-the-box** for Dalmatian and later deployments with enhanced security.

### Using with Bobcat/Caracal (Pre-Dalmatian)

For **Bobcat and Caracal** releases, you need to enable legacy policy mode because these versions don't fully support the new RBAC model:

**Important**: Bobcat/Caracal don't support `enforce_scope=true`. Nova requires Placement to identify available resources, and mismatched RBAC settings will prevent instance scheduling.

1. **Edit the installation script** and uncomment the legacy policy sections:

   **For Placement** (in `placement_controller`, around lines 1023-1046):
   ```bash
   # Uncomment all lines in the "For Bobcat/Caracal" section:
   sed -i "s/enforce_scope = true/enforce_scope = false/" /etc/placement/placement.conf
   sed -i "s/enforce_new_defaults = true/enforce_new_defaults = false/" /etc/placement/placement.conf
   cat > /etc/placement/policy.yaml << 'PLACEMENTPOLICY'
   # ... (uncomment entire policy file block)
   ```

   **For Nova Controller** (in `nova_controller`, around lines 1114-1133):
   ```bash
   # Uncomment all lines in the "For Bobcat/Caracal" section
   sed -i "s/enforce_scope = true/enforce_scope = false/" /etc/nova/nova.conf
   sed -i "s/enforce_new_defaults = true/enforce_new_defaults = false/" /etc/nova/nova.conf
   cat > /etc/nova/policy.yaml << 'NOVAPOLICY'
   # ... (uncomment entire policy file block)
   ```

   **For Nova Compute** (in `nova_compute_node`, around lines 1196-1215):
   ```bash
   # Uncomment all lines in the "For Bobcat/Caracal" section
   # (same as Nova Controller)
   ```

2. **What changes**: 
   - Disables scope enforcement (compatible with Bobcat/Caracal)
   - Uses simple admin-based policy rules
   - Creates custom policy files with basic access control

3. **Why this matters**: Pre-Dalmatian releases don't enforce scope separation and use different policy evaluation logic. The legacy configuration ensures services work together properly.

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

