## 🎬 Quick Start

```bash
# Clone the repository
cd /opt

git clone https://github.com/SYED-ABDULRAHMAN/rhcsa-app.git
chmod +x /opt/rhcsa-app/validation/*.sh
cd rhcsa-app
# Install dependencies
apt install npm -y

npm install

# Start the server (requires sudo)
sudo node server.js

# Open browser
# Navigate to: http://localhost:3000
```
To run as a container
docker run -d --name rhcsa-lab -p 3000:3000 --privileged --security-opt seccomp=unconfined syedabdulrahman134/rhcsa-lab:latest

# 🎓 RHCSA Practice Lab

An interactive, web-based practice environment for Red Hat Certified System Administrator (RHCSA) exam preparation. Features a real Linux terminal, automated validation, and hands-on learning exercises.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/node-%3E%3D16.0.0-brightgreen)](https://nodejs.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

## 🌟 Features

- **📺 Real Terminal Access** - Full PTY-based terminal via WebSocket
- **✅ Automated Validation** - Instant feedback on your solutions
- **🔄 Hot Reload** - Update questions without restarting server
- **📊 Partial Credit** - Get credit for partially correct answers
- **📝 Dynamic Questions** - All questions loaded from JSON files
- **🎯 Progress Tracking** - Track completion and scores
- **🚀 No Database Required** - File-based, easy deployment
- **🐳 Container Ready** - Works in Docker/Kubernetes

---

## 📸 Screenshots

### Main Interface
```
┌─────────────────────────────────────────────────────────────┐
│ 🧪 RHEL User Lab - RHCSA Practice    Progress: 3/5  Score: 55│
│ [Q1✓] [Q2✓] [Q3✓] [Q4] [Q5]                                 │
├──────────────────────────┬──────────────────────────────────┤
│ Question Panel           │ Terminal                         │
│                          │ [student@rhel ~]$ _              │
│ Create Basic User        │                                  │
│ ⭐ User Management       │                                  │
│                          │                                  │
│ Requirements:            │                                  │
│ ✓ Username: john_dev     │                                  │
│ ✓ UID: 2500              │                                  │
│ ✗ Home: /home/john_dev   │                                  │
│                          │                                  │
│ [Check Answer] [Reset]   │                                  │
└──────────────────────────┴──────────────────────────────────┘
```

---

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Browser (Client)                      │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐         │
│  │ Question   │  │  Terminal   │  │   Progress   │         │
│  │  Display   │  │   (xterm)   │  │   Tracker    │         │
│  └─────┬──────┘  └──────┬──────┘  └──────┬───────┘         │
└────────┼─────────────────┼────────────────┼─────────────────┘
         │                 │                │
         │ HTTP/REST       │ WebSocket      │ LocalStorage
         │                 │                │
┌────────┼─────────────────┼────────────────┼─────────────────┐
│        ▼                 ▼                ▼                  │
│  ┌─────────────────────────────────────────────────┐        │
│  │           Express.js Server (Node.js)           │        │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │        │
│  │  │   API    │  │   PTY    │  │    File      │  │        │
│  │  │  Routes  │  │  Manager │  │   Watcher    │  │        │
│  │  └────┬─────┘  └────┬─────┘  └──────┬───────┘  │        │
│  └───────┼─────────────┼────────────────┼──────────┘        │
│          │             │                │                   │
│          ▼             ▼                ▼                   │
│  ┌──────────────┐  ┌──────────┐  ┌────────────┐           │
│  │  Question    │  │   Bash   │  │  Question  │           │
│  │  Loader      │  │  Shell   │  │   JSON     │           │
│  └──────┬───────┘  └──────────┘  └────────────┘           │
│         │                                                   │
│         ▼                                                   │
│  ┌──────────────┐                                          │
│  │  Validation  │                                          │
│  │   Runner     │                                          │
│  └──────┬───────┘                                          │
│         │                                                   │
│         ▼                                                   │
│  ┌──────────────┐                                          │
│  │ Bash Scripts │                                          │
│  │ (Validators) │                                          │
│  └──────────────┘                                          │
└───────────────────────────────────────────────────────────┘
```

### Data Flow

#### 1️⃣ **Question Loading Flow**
```
Startup
   ↓
Load module_index.json
   ↓
For each enabled module
   ↓
Load moduleX.json → Parse questions → Store in memory
   ↓
Start file watcher
   ↓
On file change → Reload affected module → Notify clients
```

#### 2️⃣ **Terminal Interaction Flow**
```
Browser (xterm.js)
   ↓
User types command
   ↓
WebSocket → Server
   ↓
node-pty → Bash shell
   ↓
Command execution
   ↓
Output → WebSocket → Browser
   ↓
Display in terminal
```

#### 3️⃣ **Validation Flow**
```
User clicks "Check Answer"
   ↓
Frontend → POST /api/validate/:questionId
   ↓
Server loads question from memory
   ↓
Execute validation script (bash)
   ↓
Script checks system state
   ↓
Script outputs JSON results
   ↓
Server parses JSON
   ↓
Calculate score & partial credit
   ↓
Return results to frontend
   ↓
Update UI with ✓/✗ per requirement
```

---


### Testing Installation

```bash
# Test validation scripts output valid JSON
bash test_validators.sh

# Test individual validator
bash validation/validate_q1.sh | jq .

# Expected output:
# {
#   "checks": {
#     "username": {"passed": false, "message": "✗ User john_dev does not exist"},
#     ...
#   }
# }
```

---

## 📂 Project Structure

```
rhcsa-lab/
├── server.js                    # Express server + WebSocket handler
├── package.json                 # Node.js dependencies
├── README.md                    # This file
├── test_validators.sh           # Test script for validators
│
├── public/
│   └── index.html              # Frontend (single-page app)
│
├── lib/
│   ├── questionLoader.js       # Loads & watches JSON files
│   └── validationRunner.js     # Executes bash validation scripts
│
├── questions/
│   ├── module_index.json       # Module registry & configuration
│   ├── module1_users.json      # User management questions
│   ├── module2_files.json      # File management (template)
│   └── ...
│
└── validation/
    ├── validate_q1.sh          # Q1 validator script
    ├── validate_q2.sh          # Q2 validator script
    └── ...
```

---

## 🔧 How It Works

### 1. Question Loading System

**File: `lib/questionLoader.js`**

```javascript
// On server startup
loadModuleIndex() 
  → Read module_index.json
  → Get list of enabled modules
  → For each module:
      → Load moduleX.json
      → Validate question structure
      → Store in memory (Map)

// File watching
fs.watch(questionsDir)
  → Detect file changes
  → Reload affected module
  → Update in-memory cache
  → No restart needed!
```

**Question JSON Structure:**
```json
{
  "question_id": "Q1",
  "title": "Create Basic User Account",
  "difficulty": "easy",
  "points": 15,
  "requirements": [
    {
      "id": "username",
      "text": "Username: john_dev",
      "check_key": "username"
    }
  ],
  "validation_script": "validate_q1.sh",
  "cleanup_script": "userdel -r john_dev"
}
```

### 2. Validation System

**File: `lib/validationRunner.js`**

```javascript
async function runValidation(scriptName, requirements) {
  // 1. Find script in /validation directory
  const scriptPath = `/validation/${scriptName}`;
  
  // 2. Execute bash script with 30s timeout
  const { stdout } = await exec(`bash ${scriptPath}`);
  
  // 3. Parse JSON output from script
  const result = JSON.parse(stdout);
  
  // 4. Match results with requirements
  requirements.forEach(req => {
    const check = result.checks[req.check_key];
    // Mark as passed/failed
  });
  
  // 5. Calculate partial credit
  const percentage = (passed / total) * 100;
  const score = (points * percentage) / 100;
  
  // 6. Return to frontend
  return { success, percentage, checks, score };
}
```

**Validation Script Template:**
```bash
#!/bin/bash

# Initialize checks object
declare -A checks

# Check 1: User exists
if id john_dev &>/dev/null; then
    checks[username_passed]="true"
    checks[username_message]="✓ User exists"
else
    checks[username_passed]="false"
    checks[username_message]="✗ User does not exist"
fi

# Output JSON
cat << EOF
{
  "checks": {
    "username": {
      "passed": ${checks[username_passed]},
      "message": "${checks[username_message]}"
    }
  }
}
EOF
```

### 3. Terminal System

**WebSocket Connection:**
```javascript
// Server-side (server.js)
wss.on('connection', (ws) => {
  // Spawn PTY (pseudo-terminal)
  const term = pty.spawn('/bin/bash', [], {
    cols: 80,
    rows: 24,
    env: process.env
  });
  
  // PTY output → WebSocket → Browser
  term.onData(data => {
    ws.send(JSON.stringify({ type: 'output', data }));
  });
  
  // Browser input → WebSocket → PTY
  ws.on('message', msg => {
    const { type, data } = JSON.parse(msg);
    if (type === 'input') {
      term.write(data);
    }
  });
});
```

**Frontend (xterm.js):**
```javascript
// Initialize terminal
const term = new Terminal();
term.open(document.getElementById('terminal'));

// Connect WebSocket
const socket = new WebSocket('ws://localhost:3000');

// Display server output
socket.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  if (msg.type === 'output') {
    term.write(msg.data);
  }
};

// Send user input
term.onData(data => {
  socket.send(JSON.stringify({ type: 'input', data }));
});
```

### 4. Hot Reload Mechanism

```javascript
// lib/questionLoader.js
fs.watch('./questions', (eventType, filename) => {
  if (filename.endsWith('.json')) {
    console.log(`File changed: ${filename}`);
    
    // Debounce: wait 500ms after last change
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      reloadModule(filename);
      console.log('Module reloaded!');
    }, 500);
  }
});
```

**What happens:**
1. You edit `questions/module1_users.json`
2. File watcher detects change
3. Waits 500ms (debounce)
4. Reloads that module's questions
5. Updates in-memory cache
6. Frontend gets fresh data on next request
7. **No server restart needed!**

### 5. Partial Credit Calculation

```javascript
// Example: Question worth 20 points, 4/6 checks passed

const passed = 4;
const total = 6;
const maxPoints = 20;

// Calculate percentage
const percentage = (passed / total) * 100;  // 66.67%

// Calculate score
const score = (maxPoints * percentage) / 100;  // 13.33 points

// Frontend displays:
// "⚠️ Partially Correct: 4/6 requirements (67%)"
// "Score: 13 / 20 points"
```

---

## 🎯 API Endpoints

### GET `/api/modules`
Get all available modules

**Response:**
```json
{
  "success": true,
  "modules": [
    {
      "id": "module1",
      "name": "User Management",
      "description": "Creating and managing users and groups",
      "order": 1,
      "icon": "👥",
      "questionCount": 5
    }
  ]
}
```

### GET `/api/modules/:moduleId/questions`
Get questions for specific module

**Response:**
```json
{
  "success": true,
  "module": { "id": "module1", "name": "User Management" },
  "questions": [
    {
      "question_id": "Q1",
      "title": "Create Basic User Account",
      "difficulty": "easy",
      "points": 15,
      "requirements": [...]
    }
  ]
}
```

### POST `/api/validate/:questionId`
Validate student's answer

**Request:** No body required (checks system state)

**Response:**
```json
{
  "success": false,
  "percentage": 67,
  "passed": 4,
  "failed": 2,
  "total": 6,
  "score": 13.33,
  "maxScore": 20,
  "checks": {
    "username": {
      "passed": true,
      "message": "✓ User john_dev exists"
    },
    "uid": {
      "passed": false,
      "message": "✗ UID is 1001, expected 2500"
    }
  }
}
```

### POST `/api/reset/:questionId`
Clean up question resources

**Response:**
```json
{
  "success": true,
  "output": "User john_dev deleted\nGroup developers deleted",
  "questionId": "Q1"
}
```

---

## 📝 Adding New Questions

### Step 1: Define Question in JSON

Edit `questions/module1_users.json`:

```json
{
  "questions": [
    {
      "question_id": "Q6",
      "title": "Lock User Account",
      "difficulty": "easy",
      "points": 10,
      "description": "Lock the account of user 'tempuser' to prevent login.",
      "requirements": [
        {
          "id": "locked",
          "text": "Account is locked",
          "check_key": "account_locked"
        }
      ],
      "hints": [
        "Use 'usermod -L' to lock an account",
        "Check status with 'passwd -S username'"
      ],
      "solution_steps": [
        "sudo usermod -L tempuser",
        "sudo passwd -S tempuser"
      ],
      "validation_script": "validate_q6.sh",
      "cleanup_script": "usermod -U tempuser 2>/dev/null || true"
    }
  ]
}
```

### Step 2: Create Validation Script

Create `validation/validate_q6.sh`:

```bash
#!/bin/bash

# Function to escape JSON strings
escape_json() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    printf '%s' "$str"
}

declare -A checks

# Check if account is locked
STATUS=$(passwd -S tempuser 2>/dev/null | awk '{print $2}')
if [ "$STATUS" = "L" ] || [ "$STATUS" = "LK" ]; then
    checks[account_locked_passed]="true"
    checks[account_locked_message]="✓ Account is locked"
else
    checks[account_locked_passed]="false"
    checks[account_locked_message]="✗ Account is not locked (status: $STATUS)"
fi

# Output JSON
cat << EOF
{
  "checks": {
    "account_locked": {
      "passed": ${checks[account_locked_passed]},
      "message": "$(escape_json "${checks[account_locked_message]}")"
    }
  }
}
EOF

exit 0
```

### Step 3: Make Executable & Test

```bash
# Make executable
chmod +x validation/validate_q6.sh

# Test manually
bash validation/validate_q6.sh | jq .

# Test with actual user
sudo useradd tempuser
sudo usermod -L tempuser
bash validation/validate_q6.sh | jq .

# Should show: "passed": true

# Cleanup
sudo userdel tempuser
```

### Step 4: Refresh Browser

**That's it!** The file watcher detects the change and reloads the questions automatically. Just refresh your browser.

---

## 🎓 Student Workflow

```
1. Student opens browser
   ↓
2. Selects a question (e.g., "Create Basic User")
   ↓
3. Reads requirements and hints
   ↓
4. Works in terminal:
   $ sudo groupadd -g 3000 developers
   $ sudo useradd -u 2500 -g developers john_dev
   ↓
5. Clicks "Check Answer"
   ↓
6. Sees results:
   ✓ Username: john_dev
   ✓ UID: 2500
   ✗ Home: /home/john (expected /home/john_dev)
   ↓
7. Fixes the issue:
   $ sudo usermod -d /home/john_dev john_dev
   ↓
8. Rechecks → All green ✓
   ↓
9. Gets full points (15/15)
   ↓
10. Moves to next question
```

---

## 🐳 Docker Deployment

```dockerfile
FROM rockylinux:9

WORKDIR /opt/rhcsa-app

# Install Node.js
RUN dnf install -y nodejs npm && dnf clean all

# Copy application
COPY package*.json ./
RUN npm install --production

COPY . .

# Make scripts executable
RUN chmod +x validation/*.sh

EXPOSE 3000

CMD ["node", "server.js"]
```

```bash
# Build image
docker build -t rhcsa-lab .

# Run container
docker run -d \
  --name rhcsa-lab \
  -p 3000:3000 \
  -v $(pwd)/questions:/opt/rhcsa-app/questions:ro \
  -v $(pwd)/validation:/opt/rhcsa-app/validation:ro \
  rhcsa-lab

# Update questions without rebuilding
vim questions/module1_users.json
# Hot reload picks up changes automatically!
```

---

## 🔒 Security Considerations

⚠️ **This application requires elevated privileges to manage users/groups.**

- Server must run with `sudo`
- Validation scripts execute with full privileges
- **Not suitable for untrusted multi-user environments**
- **Recommended for:**
  - Personal practice labs
  - Classroom environments
  - Isolated VMs/containers
  - Killerkoda scenarios

**Production Considerations:**
- Use separate container per student
- Implement resource limits
- Add authentication
- Use AppArmor/SELinux policies

---

## 🤝 Contributing

Contributions welcome! Here's how:

### Adding Questions
1. Fork the repo
2. Create question JSON in appropriate module
3. Write validation script (output JSON)
4. Test with `test_validators.sh`
5. Submit PR

### Reporting Issues
- Use GitHub Issues
- Include server logs
- Provide validation script output
- Mention OS/Node.js version

---

## 📜 License

MIT License - See [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

- [xterm.js](https://xtermjs.org/) - Terminal emulator
- [node-pty](https://github.com/microsoft/node-pty) - PTY bindings
- [Express.js](https://expressjs.com/) - Web framework
- Red Hat for RHCSA certification program

---

## 📞 Support

- **Documentation**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Issues**: [GitHub Issues](https://github.com/yourusername/rhcsa-lab/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/rhcsa-lab/discussions)

---

## 🎯 Roadmap

- [ ] Add more modules (filesystems, networking, etc.)
- [ ] Implement user authentication
- [ ] Add difficulty progression
- [ ] Create instructor dashboard
- [ ] Support for practice exams
- [ ] Multi-language support
- [ ] Integration with LMS systems

---

**Ready to master RHCSA? Clone and start practicing! 🚀**

```bash
git clone https://github.com/yourusername/rhcsa-lab.git
cd rhcsa-lab
npm install
sudo node server.js
# Open http://localhost:3000
```
