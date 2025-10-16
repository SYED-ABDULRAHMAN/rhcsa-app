#!/bin/bash
#
# Validation script for Question 1: Create Basic User Account
# Expected user: john_dev with specific UID, GID, home, shell, and comment
#

# Function to escape JSON strings
escape_json() {
    local str="$1"
    # Replace backslash, double quote, and control characters
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    printf '%s' "$str"
}

# Initialize checks array
declare -A checks

# Check 1: Username exists
if id john_dev &>/dev/null; then
    checks[username_passed]="true"
    checks[username_message]="✓ User john_dev exists"
else
    checks[username_passed]="false"
    checks[username_message]="✗ User john_dev does not exist"
fi

# Check 2: UID is 2500
ACTUAL_UID=$(id -u john_dev 2>/dev/null || echo "N/A")
if [ "$ACTUAL_UID" = "2500" ]; then
    checks[uid_passed]="true"
    checks[uid_message]="✓ UID is correct (2500)"
else
    checks[uid_passed]="false"
    checks[uid_message]="✗ UID is $ACTUAL_UID, expected 2500"
fi

# Check 3: Home directory
ACTUAL_HOME=$(getent passwd john_dev 2>/dev/null | cut -d: -f6 || echo "N/A")
if [ "$ACTUAL_HOME" = "/home/john_dev" ]; then
    checks[home_dir_passed]="true"
    checks[home_dir_message]="✓ Home directory is /home/john_dev"
else
    checks[home_dir_passed]="false"
    checks[home_dir_message]="✗ Home is $ACTUAL_HOME, expected /home/john_dev"
fi

# Check 4: Shell
ACTUAL_SHELL=$(getent passwd john_dev 2>/dev/null | cut -d: -f7 || echo "N/A")
if [ "$ACTUAL_SHELL" = "/bin/bash" ]; then
    checks[shell_passed]="true"
    checks[shell_message]="✓ Shell is /bin/bash"
else
    checks[shell_passed]="false"
    checks[shell_message]="✗ Shell is $ACTUAL_SHELL, expected /bin/bash"
fi

# Check 5: Comment field
ACTUAL_COMMENT=$(getent passwd john_dev 2>/dev/null | cut -d: -f5 || echo "N/A")
ACTUAL_COMMENT_ESC=$(escape_json "$ACTUAL_COMMENT")
if [ "$ACTUAL_COMMENT" = "Developer Account" ]; then
    checks[comment_passed]="true"
    checks[comment_message]="✓ Comment is 'Developer Account'"
else
    checks[comment_passed]="false"
    checks[comment_message]="✗ Comment is '$ACTUAL_COMMENT_ESC', expected 'Developer Account'"
fi

# Check 6: Primary group is 'developers' with GID 3000
ACTUAL_GROUP=$(id -gn john_dev 2>/dev/null || echo "N/A")
ACTUAL_GID=$(id -g john_dev 2>/dev/null || echo "N/A")
if [ "$ACTUAL_GROUP" = "developers" ] && [ "$ACTUAL_GID" = "3000" ]; then
    checks[primary_group_passed]="true"
    checks[primary_group_message]="✓ Primary group is developers (GID 3000)"
else
    checks[primary_group_passed]="false"
    checks[primary_group_message]="✗ Primary group is $ACTUAL_GROUP (GID $ACTUAL_GID), expected developers (GID 3000)"
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
    "home_dir": {
      "passed": ${checks[home_dir_passed]},
      "message": "$(escape_json "${checks[home_dir_message]}")"
    },
    "shell": {
      "passed": ${checks[shell_passed]},
      "message": "$(escape_json "${checks[shell_message]}")"
    },
    "comment": {
      "passed": ${checks[comment_passed]},
      "message": "$(escape_json "${checks[comment_message]}")"
    },
    "primary_group": {
      "passed": ${checks[primary_group_passed]},
      "message": "$(escape_json "${checks[primary_group_message]}")"
    }
  }
}
EOF

exit 0
