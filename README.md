# Utility Scripts

Small personal utility scripts and Tera Term macros.

## Rules

- Do not commit passwords, tokens, internal host names, internal URLs, IP addresses, namespaces, log paths, or customer/business data.
- Keep work-specific values as placeholders such as `<BASTION_HOST>` and fill them only on the local machine where the script is run.
- Prefer readable scripts with comments over compact encoded blocks.

## Contents

- `teraterm/stg-log/` - interactive Tera Term macro template for selecting a Kubernetes Pod and tailing the latest log on the corresponding Node.
