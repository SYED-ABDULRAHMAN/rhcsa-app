const { exec } = require('child_process');
const path = require('path');
const fs = require('fs').promises;

const VALIDATION_DIR = path.join(__dirname, '../validation');
const VALIDATION_TIMEOUT = 30000; // 30 seconds

/**
 * Run validation script and parse results
 */
async function runValidation(scriptName, requirements) {
    const scriptPath = path.join(VALIDATION_DIR, scriptName);
    
    // Check if script exists
    try {
        await fs.access(scriptPath);
    } catch (error) {
        throw new Error(`Validation script not found: ${scriptName}`);
    }
    
    // Make script executable
    try {
        await fs.chmod(scriptPath, 0o755);
    } catch (error) {
        console.warn('Warning: Could not set execute permission on script');
    }
    
    return new Promise((resolve, reject) => {
        const startTime = Date.now();
        
        exec(`bash ${scriptPath}`, {
            timeout: VALIDATION_TIMEOUT,
            shell: '/bin/bash',
            maxBuffer: 1024 * 1024 // 1MB
        }, (error, stdout, stderr) => {
            const executionTime = Date.now() - startTime;
            
            // Log execution details
            console.log(`📊 Validation: ${scriptName} (${executionTime}ms)`);
            
            if (stderr) {
                console.error('Validation stderr:', stderr);
            }
            
            // Parse JSON output
            try {
                const result = parseValidationOutput(stdout, requirements);
                result.executionTime = executionTime;
                resolve(result);
            } catch (parseError) {
                console.error('Parse error:', parseError);
                console.error('Script output:', stdout);
                
                // Return failure result if parsing fails
                resolve({
                    success: false,
                    percentage: 0,
                    passed: 0,
                    failed: requirements.length,
                    total: requirements.length,
                    checks: requirements.map(req => ({
                        id: req.id,
                        passed: false,
                        message: '✗ Unable to validate (script error)'
                    })),
                    message: 'Validation script error',
                    executionTime: executionTime
                });
            }
        });
    });
}

/**
 * Parse validation script JSON output
 */
function parseValidationOutput(stdout, requirements) {
    // Try to parse JSON from stdout
    let jsonData;
    
    try {
        // Find JSON in output (might have other text)
        const jsonMatch = stdout.match(/\{.*\}/s);
        if (!jsonMatch) {
            throw new Error('No JSON found in output');
        }
        
        jsonData = JSON.parse(jsonMatch[0]);
    } catch (error) {
        throw new Error(`Invalid JSON output: ${error.message}`);
    }
    
    // Extract check results
    const checks = [];
    let passed = 0;
    let failed = 0;
    
    requirements.forEach(req => {
        const checkKey = req.check_key || req.id;
        const checkResult = jsonData.checks?.[checkKey];
        
        if (checkResult && checkResult.passed) {
            checks.push({
                id: req.id,
                passed: true,
                message: checkResult.message || `✓ ${req.text}`
            });
            passed++;
        } else {
            checks.push({
                id: req.id,
                passed: false,
                message: checkResult?.message || `✗ ${req.text} - Not met`
            });
            failed++;
        }
    });
    
    const total = requirements.length;
    const percentage = Math.round((passed / total) * 100);
    const success = failed === 0;
    
    // Calculate score (proportional to percentage)
    const score = percentage;
    
    return {
        success,
        percentage,
        passed,
        failed,
        total,
        checks,
        score,
        message: success 
            ? '🎉 All requirements met!' 
            : `${passed}/${total} requirements met`
    };
}

/**
 * Validate script exists and is executable
 */
async function validateScript(scriptName) {
    const scriptPath = path.join(VALIDATION_DIR, scriptName);
    
    try {
        const stats = await fs.stat(scriptPath);
        
        if (!stats.isFile()) {
            return { valid: false, error: 'Not a file' };
        }
        
        // Check if executable
        try {
            await fs.access(scriptPath, fs.constants.X_OK);
            return { valid: true };
        } catch (error) {
            return { valid: false, error: 'Not executable' };
        }
        
    } catch (error) {
        return { valid: false, error: 'File not found' };
    }
}

/**
 * List all validation scripts
 */
async function listValidationScripts() {
    try {
        const files = await fs.readdir(VALIDATION_DIR);
        const scripts = files.filter(f => f.endsWith('.sh'));
        
        const scriptInfo = await Promise.all(
            scripts.map(async (script) => {
                const validation = await validateScript(script);
                return {
                    name: script,
                    valid: validation.valid,
                    error: validation.error
                };
            })
        );
        
        return scriptInfo;
    } catch (error) {
        console.error('Error listing validation scripts:', error);
        return [];
    }
}

module.exports = {
    runValidation,
    validateScript,
    listValidationScripts
};
