# Utility Scripts

Small personal utility scripts and Tera Term macros.

## Rules

- Do not commit passwords, tokens, internal host names, internal URLs, IP addresses, namespaces, log paths, or customer/business data.
- Keep work-specific values as short placeholders such as `<H_B>` and fill them only on the local machine where the script is run.
- Prefer readable scripts with comments over compact encoded blocks.

## Contents

- `teraterm/stg-log/` - interactive Tera Term macro template that starts after manual bastion login, selects a Kubernetes Pod, and tails the latest log on the corresponding Node.
