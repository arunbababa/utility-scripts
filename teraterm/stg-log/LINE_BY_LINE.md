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

## Lines 79-82: Show Pod List

- Line 79: Starts pod list display.
- Line 80: Builds `kubectl get pod -n "<namespace>" -o wide`.
- Line 81: Sends that command.
- Line 82: Waits for the prompt after the pod list is displayed.

The user reads the `NODE` column manually from this output.

## Lines 84-90: Input Node Name

- Line 84: Starts node input step.
- Line 85: Opens an input dialog for the node name.
- Line 86: Stores the input in `NODE_NAME`.
- Lines 87-90: Stop if node name is empty.

## Lines 92-108: SSH To Node And Tail Fixed Log

- Line 92: Starts node SSH and log display.
- Line 93: Builds `ssh <NODE_NAME>`.
- Line 94: Sends the node SSH command.
- Line 95: Handles LDAP password or first-connect prompts.
- Line 96: Waits for the node shell prompt.
- Line 98: Builds `cd "<fixed log directory>"`.
- Line 99: Sends the `cd` command.
- Line 100: Waits for the prompt.
- Line 102: Sends `pwd` so the current directory is visible.
- Line 103: Builds `ls -ltr <fixed log glob> | tail -20`.
- Line 104: Sends the `ls` command.
- Line 105: Waits for the prompt.
- Line 107: Builds a command that finds the newest matching log and tails it.
- Line 108: Sends the tail command.

## Lines 110-111: End

- Line 110: Comment that the terminal stays open.
- Line 111: Ends the macro.

## Lines 113-116: wait_shell_prompt

- Line 113: Starts helper section.
- Line 114: Defines `wait_shell_prompt`.
- Line 115: Waits for common shell prompts: `$`, `#`, or `>`.
- Line 116: Returns to caller.

## Lines 118-147: handle_ssh_login_with_ldap

- Line 118: Starts SSH prompt handler section.
- Line 119: Defines `handle_ssh_login_with_ldap`.
- Line 120: Starts loop.
- Line 121: Waits for first-connect confirmation, password prompts, shell prompts, or common SSH errors.
- Lines 122-123: If SSH asks to continue connecting, send `yes`.
- Lines 124-127: If SSH asks for password, send `LDAP_PASS`.
- Lines 128-133: If a shell prompt appears, return because SSH succeeded.
- Lines 134-136: Stop on permission failure.
- Lines 137-139: Stop on route failure.
- Lines 140-142: Stop on hostname resolution failure.
- Lines 143-145: Return for any other match.
- Line 146: End loop.
- Line 147: Return to caller.
