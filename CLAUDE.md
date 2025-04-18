# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands
- Infrastructure planning: `make plan`
- Apply infrastructure changes: `make apply`
- Destroy infrastructure: `make destroy-infra`
- Manage state: `make create-state-resources`, `make setup-backend`
- Clean: `make clean`, `make clean-state-local`
- Run Python scripts: `python3 core/python/create-proxmox-template.py [command] [options]`

## Code Style Guidelines
- Python: Follow PEP 8 conventions with 4-space indentation
- Error handling: Use try/except with descriptive error messages
- CLI applications: Use argparse for command-line interfaces
- Naming: snake_case for variables/functions, UPPER_CASE for constants
- Infrastructure: Use Terraform modules for reusable components
- Documentation: Add comments for complex operations
- Script headers: Document purpose, arguments, and sample usage