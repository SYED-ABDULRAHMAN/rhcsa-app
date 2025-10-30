#!/bin/bash
#
# Validation script for Q1: Create User haris with UID 1050 and shell /bin/sh
#

escape_json() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    printf '%s' "$str"
}

declare -A checks

# Check 1: Username exists
if id haris &>/dev/null; then
    checks[username_passed]="true"
    checks[username_message]="✓ User haris exists"
else
    checks[username_passed]="false"
    checks[username_message]="✗ User haris does not exist"
fi

# Check 2: UID is 1050
ACTUAL_UID=$(id -u haris 2>/dev/null || echo "N/A")
if [ "$ACTUAL_UID" = "1050" ]; then
    checks[uid_passed]="true"
    checks[uid_message]="✓ UID is 1050"
else
    checks[uid_passed]="false"
    checks[uid_message]="✗ UID is $ACTUAL_UID, expected 1050"
fi

# Check 3: Shell is /bin/sh
ACTUAL_SHELL=$(getent passwd haris 2>/dev/null | cut -d: -f7 || echo "N/A")
if [ "$ACTUAL_SHELL" = "/bin/sh" ]; then
    checks[shell_passed]="true"
    checks[shell_message]="✓ Shell is /bin/sh"
else
    checks[shell_passed]="false"
    checks[shell_message]="✗ Shell is $ACTUAL_SHELL, expected /bin/sh"
fi

# Check 4: Home directory exists
ACTUAL_HOME=$(getent passwd haris 2>/dev/null | cut -d: -f6 || echo "N/A")
if [ -d "$ACTUAL_HOME" ]; then
    checks[home_exists_passed]="true"
    checks[home_exists_message]="✓ Home directory exists at $ACTUAL_HOME"
else
    checks[home_exists_passed]="false"
    checks[home_exists_message]="✗ Home directory does not exist"
fi

# Build JSON output
cat << EOF
{
  "checks": {
    "username": {
      "passed": ${checks[username_passed]},
      "message": "$(escape_json "${checks[username_message]}")"
    },
    "uid": {
      "passed": ${checks[uid_passed]},
      "message": "$(escape_json "${checks[uid_message]}")"
    },
    "shell": {
      "passed": ${checks[shell_passed]},
      "message": "$(escape_json "${checks[shell_message]}")"
    },
    "home_exists": {
      "passed": ${checks[home_exists_passed]},
      "message": "$(escape_json "${checks[home_exists_message]}")"
    }
  }
}
EOF

exit 0
