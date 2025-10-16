#!/bin/bash
#
# Validation script for Question 2: Create User with Multiple Groups
# Expected user: admin_user with UID 3000, primary group sysadmin, secondary groups wheel,docker
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
if id admin_user &>/dev/null; then
    checks[username_passed]="true"
    checks[username_message]="✓ User admin_user exists"
else
    checks[username_passed]="false"
    checks[username_message]="✗ User admin_user does not exist"
fi

# Check 2: UID is 3000
ACTUAL_UID=$(id -u admin_user 2>/dev/null || echo "N/A")
if [ "$ACTUAL_UID" = "3000" ]; then
    checks[uid_passed]="true"
    checks[uid_message]="✓ UID is correct (3000)"
else
    checks[uid_passed]="false"
    checks[uid_message]="✗ UID is $ACTUAL_UID, expected 3000"
fi

# Check 3: Primary group is 'sysadmin' with GID 4000
ACTUAL_GROUP=$(id -gn admin_user 2>/dev/null || echo "N/A")
ACTUAL_GID=$(id -g admin_user 2>/dev/null || echo "N/A")
if [ "$ACTUAL_GROUP" = "sysadmin" ] && [ "$ACTUAL_GID" = "4000" ]; then
    checks[primary_group_passed]="true"
    checks[primary_group_message]="✓ Primary group is sysadmin (GID 4000)"
else
    checks[primary_group_passed]="false"
    checks[primary_group_message]="✗ Primary group is $ACTUAL_GROUP (GID $ACTUAL_GID), expected sysadmin (GID 4000)"
fi

# Check 4: Secondary groups include wheel and docker
GROUPS_LIST=$(id -Gn admin_user 2>/dev/null || echo "N/A")
HAS_WHEEL=false
HAS_DOCKER=false

if echo "$GROUPS_LIST" | grep -qw "wheel"; then
    HAS_WHEEL=true
fi

if echo "$GROUPS_LIST" | grep -qw "docker"; then
    HAS_DOCKER=true
fi

if [ "$HAS_WHEEL" = true ] && [ "$HAS_DOCKER" = true ]; then
    checks[secondary_groups_passed]="true"
    checks[secondary_groups_message]="✓ User is in wheel and docker groups"
elif [ "$HAS_WHEEL" = true ]; then
    checks[secondary_groups_passed]="false"
    checks[secondary_groups_message]="✗ User is in wheel but not docker"
elif [ "$HAS_DOCKER" = true ]; then
    checks[secondary_groups_passed]="false"
    checks[secondary_groups_message]="✗ User is in docker but not wheel"
else
    checks[secondary_groups_passed]="false"
    checks[secondary_groups_message]="✗ User is not in wheel or docker groups"
fi

# Check 5: Home directory
ACTUAL_HOME=$(getent passwd admin_user 2>/dev/null | cut -d: -f6 || echo "N/A")
if [ "$ACTUAL_HOME" = "/home/admin_user" ]; then
    checks[home_dir_passed]="true"
    checks[home_dir_message]="✓ Home directory is /home/admin_user"
else
    checks[home_dir_passed]="false"
    checks[home_dir_message]="✗ Home is $ACTUAL_HOME, expected /home/admin_user"
fi

# Check 6: Shell
ACTUAL_SHELL=$(getent passwd admin_user 2>/dev/null | cut -d: -f7 || echo "N/A")
if [ "$ACTUAL_SHELL" = "/bin/bash" ]; then
    checks[shell_passed]="true"
    checks[shell_message]="✓ Shell is /bin/bash"
else
    checks[shell_passed]="false"
    checks[shell_message]="✗ Shell is $ACTUAL_SHELL, expected /bin/bash"
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
    "primary_group": {
      "passed": ${checks[primary_group_passed]},
      "message": "$(escape_json "${checks[primary_group_message]}")"
    },
    "secondary_groups": {
      "passed": ${checks[secondary_groups_passed]},
      "message": "$(escape_json "${checks[secondary_groups_message]}")"
    },
    "home_dir": {
      "passed": ${checks[home_dir_passed]},
      "message": "$(escape_json "${checks[home_dir_message]}")"
    },
    "shell": {
      "passed": ${checks[shell_passed]},
      "message": "$(escape_json "${checks[shell_message]}")"
    }
  }
}
EOF

exit 0
