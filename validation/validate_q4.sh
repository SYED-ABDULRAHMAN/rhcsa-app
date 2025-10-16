#!/bin/bash
#
# Validation script for Question 4: Modify Existing User Properties
# Expected user: testuser with modified shell, home, comment, and group membership
#

# Function to escape JSON strings
escape_json() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    printf '%s' "$str"
}

# Initialize checks array
declare -A checks

# Check 1: Username exists
if id testuser &>/dev/null; then
    checks[username_passed]="true"
    checks[username_message]="✓ User testuser exists"
else
    checks[username_passed]="false"
    checks[username_message]="✗ User testuser does not exist"
fi

# Check 2: Shell is /bin/zsh
ACTUAL_SHELL=$(getent passwd testuser 2>/dev/null | cut -d: -f7 || echo "N/A")
if [ "$ACTUAL_SHELL" = "/bin/zsh" ]; then
    checks[shell_passed]="true"
    checks[shell_message]="✓ Shell is /bin/zsh"
else
    checks[shell_passed]="false"
    checks[shell_message]="✗ Shell is $ACTUAL_SHELL, expected /bin/zsh"
fi

# Check 3: Home directory is /opt/testuser
ACTUAL_HOME=$(getent passwd testuser 2>/dev/null | cut -d: -f6 || echo "N/A")
if [ "$ACTUAL_HOME" = "/opt/testuser" ]; then
    checks[home_dir_passed]="true"
    checks[home_dir_message]="✓ Home directory is /opt/testuser"
else
    checks[home_dir_passed]="false"
    checks[home_dir_message]="✗ Home is $ACTUAL_HOME, expected /opt/testuser"
fi

# Check 4: Comment field
ACTUAL_COMMENT=$(getent passwd testuser 2>/dev/null | cut -d: -f5 || echo "N/A")
ACTUAL_COMMENT_ESC=$(escape_json "$ACTUAL_COMMENT")
if [ "$ACTUAL_COMMENT" = "Modified Test User" ]; then
    checks[comment_passed]="true"
    checks[comment_message]="✓ Comment is 'Modified Test User'"
else
    checks[comment_passed]="false"
    checks[comment_message]="✗ Comment is '$ACTUAL_COMMENT_ESC', expected 'Modified Test User'"
fi

# Check 5: User is in testgroup
GROUPS_LIST=$(id -Gn testuser 2>/dev/null || echo "N/A")
if echo "$GROUPS_LIST" | grep -qw "testgroup"; then
    checks[in_testgroup_passed]="true"
    checks[in_testgroup_message]="✓ User is in testgroup"
else
    checks[in_testgroup_passed]="false"
    checks[in_testgroup_message]="✗ User is not in testgroup. Groups: $GROUPS_LIST"
fi

# Build JSON output
cat << EOF
{
  "checks": {
    "username": {
      "passed": ${checks[username_passed]},
      "message": "$(escape_json "${checks[username_message]}")"
    },
    "shell": {
      "passed": ${checks[shell_passed]},
      "message": "$(escape_json "${checks[shell_message]}")"
    },
    "home_dir": {
      "passed": ${checks[home_dir_passed]},
      "message": "$(escape_json "${checks[home_dir_message]}")"
    },
    "comment": {
      "passed": ${checks[comment_passed]},
      "message": "$(escape_json "${checks[comment_message]}")"
    },
    "in_testgroup": {
      "passed": ${checks[in_testgroup_passed]},
      "message": "$(escape_json "${checks[in_testgroup_message]}")"
    }
  }
}
EOF

exit 0
