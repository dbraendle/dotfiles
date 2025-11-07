# SSH Module

Deploys SSH configuration template for later management by Homelab Ansible.

## Architecture

This module follows a **template-first** approach:

1. The module deploys a base SSH configuration template
2. Real server configurations are managed by Ansible (not stored in this repo)
3. The template includes sensible defaults and placeholders for Ansible

## Files

- `module.json` - Module metadata
- `install.sh` - Deploys SSH config template
- `update.sh` - Re-deploys template (overwrites existing)
- `uninstall.sh` - Removes SSH config (with backup)
- `services.example.json` - Example server data structure (for documentation)

## SSH Config Template

Location: `config/ssh/.ssh/config.template`

The template includes:

- **Default settings**: SSH multiplexing, security settings, compression
- **GitHub configuration**: Pre-configured for git operations
- **Ansible markers**: `ANSIBLE_MANAGED_HOSTS_START/END` section for server configs

## Installation

```bash
./modules/ssh/install.sh
```

This will:

1. Create `~/.ssh/` directory if it doesn't exist (chmod 700)
2. Create `~/.ssh/sockets/` for SSH multiplexing
3. Deploy template to `~/.ssh/config` (only if no config exists)
4. Set secure permissions (600) on config file

## Update

```bash
./modules/ssh/update.sh
```

Re-deploys the template. **Warning**: This overwrites your current config (backup created).

## Uninstall

```bash
./modules/ssh/uninstall.sh
```

Removes SSH config (backup created). SSH directory and keys are preserved.

## Ansible Integration

The real SSH configuration should be managed by your Homelab Ansible playbook:

1. Read server data from Ansible inventory (`inventory/hosts.yml`)
2. Use Ansible template module to generate SSH config
3. Replace content between `ANSIBLE_MANAGED_HOSTS_START/END` markers
4. Deploy to managed machines

### Example Ansible Task

```yaml
- name: Deploy SSH configuration
  template:
    src: templates/ssh_config.j2
    dest: ~/.ssh/config
    mode: '0600'
  vars:
    ssh_hosts: "{{ groups['all'] }}"
```

## Security Notes

- Never commit real server IPs or credentials to this repo
- Use `services.example.json` for documentation only
- Real data belongs in Ansible vault or inventory
- Always use ED25519 keys: `ssh-keygen -t ed25519`
- Be cautious with `ForwardAgent` (only on trusted hosts)

## Directory Structure

```
modules/ssh/
├── module.json          # Metadata
├── install.sh           # Installation script
├── update.sh            # Update script
├── uninstall.sh         # Uninstall script
├── README.md            # This file
└── services.example.json # Example server data

config/ssh/
└── .ssh/
    └── config.template  # SSH config template
```

## Dependencies

- OpenSSH (usually pre-installed)
- Standard Unix utilities (chmod, mkdir, cp)

## Features

- Secure default permissions (700 for directory, 600 for config)
- SSH multiplexing for better performance
- Control socket directory for connection reuse
- Template-based approach for Ansible integration
- Automatic backups before updates
- GitHub pre-configured for git operations
