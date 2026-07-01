# stg_log_auto.ttl Line-by-Line Guide

This guide explains the simplified macro. Line numbers refer to `stg_log_auto.ttl`.

## Start Assumption

Run this macro only after manual bastion login:

1. Open Tera Term.
2. Use the host already shown in the host field.
3. Type the LDAP password yourself.
4. Reach the bastion shell prompt.
5. Run `Control -> Macro`.

The macro does not put any file on the bastion, app host, or node.

## Lines 1-10: Header

- Line 1: Names the macro.
- Lines 3-7: Document the manual Tera Term login start point.
- Lines 9-10: State that the macro sends commands only and does not place files on servers.

## Lines 12-25: Fixed Local Settings

- Line 12: Starts values that must be filled on the company PC.
- Line 13: `APP_HOST` is the host reached by SSH from the bastion.
- Line 14: `RC_USER` is the account used by `su -`.
- Lines 16-17: front/back Kubernetes namespaces.
- Lines 19-20: front/back fixed log directories.
- Lines 22-23: front/back log filename patterns.
- Line 25: Number of lines to show from the newest log.

## Lines 27-46: Runtime Inputs

- Line 28: Opens a password dialog for LDAP password used by later SSH commands.
- Line 29: Stores that value in `LDAP_PASS`.
- Lines 30-33: Stop if LDAP password is empty.
- Line 35: Opens a password dialog for the `rcuser` password.
- Line 36: Stores that value in `RC_PASS`.
- Lines 37-40: Stop if `rcuser` password is empty.
- Line 42: Asks whether target is `front` or `back`.
- Line 43: Stores the answer in `TARGET`.
- Lines 44-46: Default to `front` when empty.

## Lines 48-50: Sync With Bastion Prompt

- Line 48: Starts the sync step.
- Line 49: Sends an empty Enter key to refresh the prompt.
- Line 50: Waits until a shell prompt appears.

## Lines 52-56: SSH To App Host

- Line 52: Starts the app-host SSH step.
- Line 53: Builds `ssh <H_A>`.
- Line 54: Sends that command to Tera Term.
- Line 55: Handles LDAP password or first-connect prompts.
- Line 56: Waits for the app-host shell prompt.

## Lines 58-63: Switch To rcuser

- Line 58: Starts user switch.
- Line 59: Builds `su - rcuser`.
- Line 60: Sends that command.
- Line 61: Waits for a password prompt.
- Line 62: Sends the `rcuser` password.
- Line 63: Waits for the `rcuser` prompt.

## Lines 65-77: Choose Fixed front/back Values

- Line 65: Starts fixed value selection.
- Line 66: Checks whether target is `front`.
- Line 67: Uses front namespace.
- Line 68: Uses front log directory.
- Line 69: Uses front log file pattern.
- Line 70: Checks whether target is `back`.
- Line 71: Uses back namespace.
- Line 72: Uses back log directory.
- Line 73: Uses back log file pattern.
- Lines 74-76: Stop if target is neither `front` nor `back`.
- Line 77: Ends the condition.

## Lines 79-86: Show Pod List And Pick Node

- Line 79: Starts pod list display.
- Line 80: Builds `kubectl get pod -n "<namespace>" -o wide`.
- Line 81: Sends that command.
- Line 82: Waits for the prompt after the pod list is displayed.
- Line 84: Builds a command that extracts the first Running pod's NODE column into `NODE_NAME`.
- Line 85: Sends that command.
- Line 86: Waits for the prompt after `NODE_NAME` is printed.

The macro reuses the NODE value that appears in the `kubectl -o wide` output.

## Lines 88-104: SSH To Node And Tail Fixed Log

- Line 88: Starts node SSH and log display.
- Line 89: Sends `ssh $NODE_NAME`.
- Line 90: Handles LDAP password or first-connect prompts.
- Line 91: Waits for the node shell prompt.
- Line 93: Builds `cd "<fixed log directory>"`.
- Line 94: Sends the `cd` command.
- Line 95: Waits for the prompt.
- Line 97: Sends `pwd` so the current directory is visible.
- Line 98: Builds `ls -ltr <fixed log glob> | tail -20`.
- Line 99: Sends the `ls` command.
- Line 100: Waits for the prompt.
- Line 102: Builds a command that finds the newest matching log and tails it.
- Line 103: Sends the tail command.

## Lines 105-106: End

- Line 105: Comment that the terminal stays open.
- Line 106: Ends the macro.

## Lines 108-111: wait_shell_prompt

- Line 108: Starts helper section.
- Line 109: Defines `wait_shell_prompt`.
- Line 110: Waits for common shell prompts: `$`, `#`, or `>`.
- Line 111: Returns to caller.

## Lines 113-142: handle_ssh_login_with_ldap

- Line 113: Starts SSH prompt handler section.
- Line 114: Defines `handle_ssh_login_with_ldap`.
- Line 115: Starts loop.
- Line 116: Waits for first-connect confirmation, password prompts, shell prompts, or common SSH errors.
- Lines 117-118: If SSH asks to continue connecting, send `yes`.
- Lines 119-122: If SSH asks for password, send `LDAP_PASS`.
- Lines 123-128: If a shell prompt appears, return because SSH succeeded.
- Lines 129-131: Stop on permission failure.
- Lines 132-134: Stop on route failure.
- Lines 135-137: Stop on hostname resolution failure.
- Lines 138-140: Return for any other match.
- Line 141: End loop.
- Line 142: Return to caller.
