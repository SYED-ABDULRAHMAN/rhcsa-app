#!/bin/bash
#
# Validation script for Question 3: Create System Service Account
# Expected user: webapp with UID < 1000, home /var/www/webapp, shell /sbin/nologin
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
if id webapp &>/dev/null; then
    checks[username_passed]="true"
    checks[username_message]="✓ User webapp exists"
else
    checks[username_passed]="false"
    checks[username_message]="✗ User webapp does not exist"
fi

# Check 2: UID is below 1000 (system account)
ACTUAL_UID=$(id -u webapp 2>/dev/null || echo "N/A")
if [ "$ACTUAL_UID" != "N/A" ] && [ "$ACTUAL_UID" -lt 1000 ] 2>/dev/null; then
    checks[uid_range_passed]="true"
    checks[uid_range_message]="✓ UID is $ACTUAL_UID (system account range)"
else
    checks[uid_range_passed]="false"
    checks[uid_range_message]="✗ UID is $ACTUAL_UID, expected < 1000"
fi

# Check 3: Home directory
ACTUAL_HOME=$(getent passwd webapp 2>/dev/null | cut -d: -f6 || echo "N/A")
if [ "$ACTUAL_HOME" = "/var/www/webapp" ]; then
    checks[home_dir_passed]="true"
    checks[home_dir_message]="✓ Home directory is /var/www/webapp"
else
    checks[home_dir_passed]="false"
    checks[home_dir_message]="✗ Home is $ACTUAL_HOME, expected /var/www/webapp"
fi

# Check 4: Shell is /sbin/nologin or /usr/sbin/nologin
ACTUAL_SHELL=$(getent passwd webapp 2>/dev/null | cut -d: -f7 || echo "N/A")
if [ "$ACTUAL_SHELL" = "/sbin/nologin" ] || [ "$ACTUAL_SHELL" = "/usr/sbin/nologin" ]; then
    checks[shell_passed]="true"
    checks[shell_message]="✓ Shell is $ACTUAL_SHELL (no login)"
else
    checks[shell_passed]="false"
    checks[shell_message]="✗ Shell is $ACTUAL_SHELL, expected /sbin/nologin"
fi

# Check 5: Verify it's a system account (indirect check via UID range)
if [ "$ACTUAL_UID" != "N/A" ] && [ "$ACTUAL_UID" -lt 1000 ] 2>/dev/null; then
    checks[is_system_passed]="true"
    checks[is_system_message]="✓ Created as system account"
else
    checks[is_system_passed]="false"
    checks[is_system_message]="✗ Not created as system account"
fi

# Build JSON output
cat << EOF
{
  "checks": {
    "username": {
      "passed": ${checks[username_passed]},
      "message": "$(escape_json "${checks[username_message]}")"
    },
    "uid_range": {
      "passed": ${checks[uid_range_passed]},
      "message": "$(escape_json "${checks[uid_range_message]}")"
    },
    "home_dir": {
      "passed": ${checks[home_dir_passed]},
      "message": "$(escape_json "${checks[home_dir_message]}")"
    },
    "shell": {
      "passed": ${checks[shell_passed]},
      "message": "$(escape_json "${checks[shell_message]}")"
    },
    "is_system": {
      "passed": ${checks[is_system_passed]},
      "message": "$(escape_json "${checks[is_system_message]}")"
    }
  }
}
EOF

exit 0
