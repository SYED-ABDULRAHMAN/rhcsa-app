#!/bin/bash
#
# Validation script for Question 5: Create User with Password Expiration
# Expected user: contractor with UID 5000, account expiry, password aging
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
if id contractor &>/dev/null; then
    checks[username_passed]="true"
    checks[username_message]="✓ User contractor exists"
else
    checks[username_passed]="false"
    checks[username_message]="✗ User contractor does not exist"
fi

# Check 2: UID is 5000
ACTUAL_UID=$(id -u contractor 2>/dev/null || echo "N/A")
if [ "$ACTUAL_UID" = "5000" ]; then
    checks[uid_passed]="true"
    checks[uid_message]="✓ UID is correct (5000)"
else
    checks[uid_passed]="false"
    checks[uid_message]="✗ UID is $ACTUAL_UID, expected 5000"
fi

# Check 3: Account expiry date (2025-12-31)
CHAGE_OUTPUT=$(chage -l contractor 2>/dev/null || echo "N/A")
EXPIRY_DATE=$(echo "$CHAGE_OUTPUT" | grep "Account expires" | awk -F': ' '{print $2}' | xargs)

# Convert expected date to epoch seconds for comparison
EXPECTED_EPOCH=$(date -d "2025-12-31" +%s 2>/dev/null || echo "0")
ACTUAL_EPOCH=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || echo "0")

# Allow one day tolerance (86400 seconds)
if [ "$ACTUAL_EPOCH" -gt 0 ] && [ "$ACTUAL_EPOCH" -ge "$EXPECTED_EPOCH" ] && [ "$ACTUAL_EPOCH" -le $((EXPECTED_EPOCH + 86400)) ]; then
    checks[account_expiry_passed]="true"
    checks[account_expiry_message]="✓ Account expires on 2025-12-31"
else
    EXPIRY_DATE_ESC=$(escape_json "$EXPIRY_DATE")
    checks[account_expiry_passed]="false"
    checks[account_expiry_message]="✗ Account expiry is '$EXPIRY_DATE_ESC', expected 2025-12-31"
fi

# Check 4: Password max age (30 days)
MAX_DAYS=$(echo "$CHAGE_OUTPUT" | grep "Maximum number of days" | awk '{print $NF}' || echo "N/A")
if [ "$MAX_DAYS" = "30" ]; then
    checks[max_days_passed]="true"
    checks[max_days_message]="✓ Password max age is 30 days"
else
    checks[max_days_passed]="false"
    checks[max_days_message]="✗ Password max age is $MAX_DAYS, expected 30"
fi

# Check 5: Warning days (7 days)
WARN_DAYS=$(echo "$CHAGE_OUTPUT" | grep "Number of days of warning" | awk '{print $NF}' || echo "N/A")
if [ "$WARN_DAYS" = "7" ]; then
    checks[warn_days_passed]="true"
    checks[warn_days_message]="✓ Password warning is 7 days"
else
    checks[warn_days_passed]="false"
    checks[warn_days_message]="✗ Password warning is $WARN_DAYS, expected 7"
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
    "account_expiry": {
      "passed": ${checks[account_expiry_passed]},
      "message": "$(escape_json "${checks[account_expiry_message]}")"
    },
    "max_days": {
      "passed": ${checks[max_days_passed]},
      "message": "$(escape_json "${checks[max_days_message]}")"
    },
    "warn_days": {
      "passed": ${checks[warn_days_passed]},
      "message": "$(escape_json "${checks[warn_days_message]}")"
    }
  }
}
EOF

exit 0
