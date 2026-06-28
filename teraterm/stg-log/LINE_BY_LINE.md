# stg_log_auto.ttl Line-by-Line Guide

This guide explains what the macro is doing. Line numbers refer to `stg_log_auto.ttl`.

## Start Assumption

This macro starts **after** you manually log in to the bastion in Tera Term.

You do this manually:

1. Open Tera Term.
2. Use the host value already shown in the host field.
3. Type the LDAP password yourself.
4. Reach the bastion shell prompt.
5. Run this macro from `Control -> Macro`.

The macro does not create a file on the bastion or app host.

## Header

- Line 1: Names the macro.
- Lines 3-7: State the correct start point: manual Tera Term login first, macro second.
- Lines 9-10: State the important design rule: no server-side file placement.

## Local Settings

- Line 12: Starts the local setting section.
- Line 13: `APP_HOST` is the host reached by SSH from the bastion.
- Line 14: `RC_USER` is the OS user switched to after entering the app host.
- Lines 16-17: `FRONT_NAMESPACE` and `BACK_NAMESPACE` choose the Kubernetes namespace per target.
- Lines 19-20: Explain that the pod keyword only narrows candidates; the user still chooses.
- Lines 21-22: `FRONT_POD_PATTERN` and `BACK_POD_PATTERN` are pod-name keywords.
- Lines 24-25: `FRONT_LOG_DIR` and `BACK_LOG_DIR` are the log directories on the selected node.
- Lines 27-28: `FRONT_LOG_GLOB` and `BACK_LOG_GLOB` are filename patterns for log files.
- Line 30: `TAIL_LINES` controls how many lines are shown from the newest log.

## Runtime Prompts

- Line 32: Starts values that are entered each run.
- Line 33: Opens a password dialog for the LDAP password used later by SSH.
- Line 34: Stores the entered LDAP password in `LDAP_PASS`.
- Lines 35-38: Stop the macro if the LDAP password is empty.
- Line 40: Opens a password dialog for the `rcuser` password.
- Line 41: Stores the entered `rcuser` password in `RC_PASS`.
- Lines 42-45: Stop the macro if the `rcuser` password is empty.
- Line 47: Asks whether the target is `front` or `back`.
- Line 48: Stores the target in `TARGET`.
- Lines 49-51: Defaults to `front` when the input is empty.

## Sync With Existing Bastion Login

- Lines 53-55: Document that the user has already logged in to the bastion manually.
- Line 56: `sendln ''` sends an empty Enter key to refresh the shell prompt.
- Line 57: Waits until the macro sees a shell prompt.

## SSH To App Host

- Line 59: Starts the app-host SSH step.
- Line 60: Builds `ssh <H_A>` into variable `cmd`.
- Line 61: Sends that SSH command to the current terminal.
- Line 62: Handles SSH prompts such as password or first-connect confirmation.
- Line 63: Waits until the app-host shell prompt appears.

## Switch To rcuser

- Line 65: Starts the user-switch step.
- Line 66: Builds `su - rcuser`.
- Line 67: Sends the `su` command.
- Line 68: Waits for a password prompt.
- Line 69: Sends the `rcuser` password.
- Line 70: Waits until the `rcuser` shell prompt appears.

## Export Settings

- Lines 72-73: Explain that settings are exported as shell variables, not files.
- Line 74: Calls `export_runtime_values`.
- Line 75: Waits until all export commands have returned to the prompt.

## Show Pod Candidates

- Lines 77-78: Explain the first inline shell block. It is sent to `sh` through standard input.
- Line 79: Starts `sh <<'STG_LIST_EOF'`; the following lines are executed by `sh` without saving a file.
- Line 80: `set -eu` makes the inline shell stop on errors or missing variables.
- Lines 81-94: Choose namespace and pod keyword from `TARGET`.
- Lines 95-97: Print target, namespace, and heading text.
- Line 98: Runs `kubectl get pod -n "$NS" -o wide` to show the full pod list.
- Lines 99-101: Print a heading for the narrowed candidate list.
- Line 102: Runs `kubectl get pod`, keeps Running pods matching the keyword, and prints number, pod name, status, and node.
- Line 103: Ends the inline shell block.
- Line 104: Waits until the shell prompt returns.

## User Pod Selection

- Line 106: Starts the local pod-selection step.
- Line 107: Opens a local input dialog.
- Line 108: Stores the value in `POD_SELECT`.
- Lines 109-111: Defaults to `1` when the input is empty.
- Line 113: Builds `export POD_SELECT="<input>"`.
- Line 114: Sends that export command to the app-host shell.
- Line 115: Waits for the prompt.

## Resolve Pod, SSH Node, Tail Log

- Lines 117-118: Explain the second inline shell block.
- Line 119: Starts another `sh <<'STG_RUN_EOF'` block; again, no file is saved.
- Line 120: Uses strict shell behavior.
- Lines 121-138: Choose namespace, pod keyword, log directory, and log file pattern from `TARGET`.
- Line 139: Builds a Running pod list matching the chosen keyword.
- Lines 140-144: If the keyword matched nothing, fallback to all Running pods in the namespace.
- Lines 145-148: Stop if there are no Running pods.
- Line 149: Reads `POD_SELECT`; default is `1`.
- Lines 150-174: Resolve the user's selection into an exact pod name.
- Lines 151-166: Text input path: exact pod name first, then partial pod-name match.
- Lines 167-173: Numeric input path: pick the displayed candidate number.
- Line 175: Uses `kubectl ... -o jsonpath='{.spec.nodeName}'` to get the node name for the selected pod.
- Lines 176-179: Stop if no node was found.
- Lines 180-182: Print the selected pod, selected node, and next action.
- Lines 183-196: SSH to the node, change to the log directory, list recent matching logs, choose the newest one, and tail it.
- Line 197: Ends the inline shell block.
- Line 198: Handles the node SSH password prompt and waits for the shell prompt.
- Lines 200-201: Leave the Tera Term window open after log output is shown.

## wait_shell_prompt

- Line 203: Starts the helper section.
- Line 204: Defines the label `wait_shell_prompt`.
- Line 205: Waits for common shell prompt endings: `$`, `#`, or `>`.
- Line 206: Returns to the caller.

## export_runtime_values

- Line 208: Starts the export helper.
- Line 209: Defines the label `export_runtime_values`.
- Lines 210-211: Export `TARGET`.
- Lines 212-213: Export `FRONT_NAMESPACE`.
- Lines 214-215: Export `BACK_NAMESPACE`.
- Lines 216-217: Export `FRONT_POD_PATTERN`.
- Lines 218-219: Export `BACK_POD_PATTERN`.
- Lines 220-221: Export `FRONT_LOG_DIR`.
- Lines 222-223: Export `BACK_LOG_DIR`.
- Lines 224-225: Export `FRONT_LOG_GLOB`.
- Lines 226-227: Export `BACK_LOG_GLOB`.
- Lines 228-229: Export `TAIL_LINES`.
- Line 230: Returns to the caller.

## handle_ssh_login_with_ldap

- Line 232: Starts the SSH prompt handler.
- Line 233: Defines the label `handle_ssh_login_with_ldap`.
- Line 234: Starts a loop so multiple prompts can be handled.
- Line 235: Waits for first-connect confirmation, password prompts, shell prompts, or common SSH failures.
- Lines 236-237: If SSH asks to continue connecting, send `yes`.
- Lines 238-241: If SSH asks for a password, send `LDAP_PASS`.
- Lines 242-247: If a shell prompt appears, return because login is done.
- Lines 248-250: Stop with a message on permission failure.
- Lines 251-253: Stop with a message when the route is unavailable.
- Lines 254-256: Stop with a message when the host cannot be resolved.
- Lines 257-259: Return on any unexpected non-error match.
- Line 260: End the loop.
- Line 261: Return to the caller.
