const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const pty = require('node-pty');
const cors = require('cors');
const path = require('path');
const { loadModules, watchQuestions } = require('./lib/questionLoader');
const { runValidation } = require('./lib/validationRunner');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Store PTY sessions per WebSocket
const terminals = new Map();

// Load questions on startup
let modules = [];
let questionsMap = new Map();

async function initializeQuestions() {
    try {
        const data = await loadModules();
        modules = data.modules;
        questionsMap = data.questionsMap;
        console.log('✅ Loaded modules:', modules.map(m => m.name).join(', '));
        console.log(`✅ Total questions: ${questionsMap.size}`);
    } catch (error) {
        console.error('❌ Error loading questions:', error);
        process.exit(1);
    }
}

// Watch for question file changes
watchQuestions(async () => {
    console.log('🔄 Questions changed, reloading...');
    const data = await loadModules();
    modules = data.modules;
    questionsMap = data.questionsMap;
    console.log('✅ Questions reloaded successfully');
});

// API Routes

// Get all modules
app.get('/api/modules', (req, res) => {
    res.json({
        success: true,
        modules: modules.map(m => ({
            id: m.id,
            name: m.name,
            description: m.description,
            order: m.order,
            icon: m.icon,
            questionCount: m.questionCount
        }))
    });
});

// Get questions for a specific module
app.get('/api/modules/:moduleId/questions', (req, res) => {
    const moduleId = req.params.moduleId;
    const module = modules.find(m => m.id === moduleId);
    
    if (!module) {
        return res.status(404).json({
            success: false,
            error: 'Module not found'
        });
    }
    
    res.json({
        success: true,
        module: {
            id: module.id,
            name: module.name,
            description: module.description
        },
        questions: module.questions
    });
});

// Get all questions (for backward compatibility)
app.get('/api/questions', (req, res) => {
    const allQuestions = [];
    modules.forEach(module => {
        module.questions.forEach(q => {
            allQuestions.push({
                ...q,
                moduleName: module.name,
                moduleId: module.id
            });
        });
    });
    
    res.json({
        success: true,
        questions: allQuestions
    });
});

// Validate answer for a question
app.post('/api/validate/:questionId', async (req, res) => {
    const questionId = req.params.questionId;
    const question = questionsMap.get(questionId);
    
    if (!question) {
        return res.status(404).json({
            success: false,
            error: 'Question not found'
        });
    }
    
    try {
        const result = await runValidation(question.validation_script, question.requirements);
        
        res.json({
            success: result.success,
            percentage: result.percentage,
            passed: result.passed,
            failed: result.failed,
            total: result.total,
            checks: result.checks,
            score: result.score,
            maxScore: question.points,
            message: result.message
        });
    } catch (error) {
        console.error('Validation error:', error);
        res.status(500).json({
            success: false,
            error: 'Validation failed: ' + error.message,
            checks: question.requirements.map(req => ({
                id: req.id,
                passed: false,
                message: '✗ Validation script error'
            }))
        });
    }
});

// Reset question (run cleanup)
app.post('/api/reset/:questionId', async (req, res) => {
    const questionId = req.params.questionId;
    const question = questionsMap.get(questionId);
    
    if (!question) {
        return res.status(404).json({
            success: false,
            error: 'Question not found'
        });
    }
    
    try {
        const { exec } = require('child_process');
        const util = require('util');
        const execPromise = util.promisify(exec);
        
        if (question.cleanup_script) {
            const { stdout, stderr } = await execPromise(question.cleanup_script, {
                shell: '/bin/bash',
                timeout: 30000
            });
            
            res.json({
                success: true,
                output: stdout || 'Cleanup completed',
                questionId: questionId
            });
        } else {
            res.json({
                success: true,
                output: 'No cleanup script defined',
                questionId: questionId
            });
        }
    } catch (error) {
        console.error('Cleanup error:', error);
        res.json({
            success: true,
            output: 'Cleanup attempted (some commands may have failed)',
            error: error.message
        });
    }
});

// WebSocket Terminal Handler
wss.on('connection', (ws) => {
    console.log('🔌 New WebSocket connection');
    
    // Create PTY process
    const shell = process.env.SHELL || '/bin/bash';
    const term = pty.spawn(shell, [], {
        name: 'xterm-color',
        cols: 80,
        rows: 24,
        cwd: process.env.HOME,
        env: process.env
    });
    
    terminals.set(ws, term);
    
    // Send data from PTY to WebSocket
    term.onData((data) => {
        try {
            ws.send(JSON.stringify({
                type: 'output',
                data: data
            }));
        } catch (error) {
            console.error('Error sending to WebSocket:', error);
        }
    });
    
    // Handle PTY exit
    term.onExit(({ exitCode, signal }) => {
        console.log(`Terminal exited: code ${exitCode}, signal ${signal}`);
        try {
            ws.send(JSON.stringify({
                type: 'exit',
                exitCode: exitCode
            }));
            ws.close();
        } catch (error) {
            console.error('Error on terminal exit:', error);
        }
        terminals.delete(ws);
    });
    
    // Handle WebSocket messages
    ws.on('message', (message) => {
        try {
            const msg = JSON.parse(message);
            
            if (msg.type === 'input' && msg.data) {
                term.write(msg.data);
            } else if (msg.type === 'resize' && msg.cols && msg.rows) {
                term.resize(msg.cols, msg.rows);
            }
        } catch (error) {
            console.error('Error handling WebSocket message:', error);
        }
    });
    
    // Handle WebSocket close
    ws.on('close', () => {
        console.log('🔌 WebSocket disconnected');
        if (terminals.has(ws)) {
            terminals.get(ws).kill();
            terminals.delete(ws);
        }
    });
    
    // Handle WebSocket errors
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
        if (terminals.has(ws)) {
            terminals.get(ws).kill();
            terminals.delete(ws);
        }
    });
});

// Start server
async function startServer() {
    await initializeQuestions();
    
    server.listen(PORT, '0.0.0.0', () => {
        console.log('╔════════════════════════════════════════╗');
        console.log('║   🎓 RHCSA Practice Lab Server        ║');
        console.log('╚════════════════════════════════════════╝');
        console.log(`🌐 Server running at: http://localhost:${PORT}`);
        console.log(`📦 Modules loaded: ${modules.length}`);
        console.log(`📝 Questions loaded: ${questionsMap.size}`);
        console.log(`🔄 Hot-reload: ENABLED`);
        console.log('═══════════════════════════════════════════');
    });
}

startServer().catch(error => {
    console.error('Failed to start server:', error);
    process.exit(1);
});
