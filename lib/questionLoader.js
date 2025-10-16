const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');

const QUESTIONS_DIR = path.join(__dirname, '../questions');
const MODULE_INDEX = 'module_index.json';

/**
 * Load module index file
 */
async function loadModuleIndex() {
    try {
        const indexPath = path.join(QUESTIONS_DIR, MODULE_INDEX);
        const content = await fs.readFile(indexPath, 'utf-8');
        return JSON.parse(content);
    } catch (error) {
        console.error('Error loading module index:', error);
        throw new Error('Failed to load module_index.json');
    }
}

/**
 * Load a specific module file
 */
async function loadModuleFile(filename) {
    try {
        const filePath = path.join(QUESTIONS_DIR, filename);
        const content = await fs.readFile(filePath, 'utf-8');
        return JSON.parse(content);
    } catch (error) {
        console.error(`Error loading ${filename}:`, error);
        throw new Error(`Failed to load ${filename}`);
    }
}

/**
 * Validate question structure
 */
function validateQuestion(question, moduleId) {
    const required = ['question_id', 'title', 'description', 'requirements', 'validation_script'];
    const missing = required.filter(field => !question[field]);
    
    if (missing.length > 0) {
        throw new Error(`Question ${question.question_id || 'unknown'} in ${moduleId} missing fields: ${missing.join(', ')}`);
    }
    
    if (!Array.isArray(question.requirements) || question.requirements.length === 0) {
        throw new Error(`Question ${question.question_id} has no requirements`);
    }
    
    return true;
}

/**
 * Load all modules and questions
 */
async function loadModules() {
    try {
        // Load module index
        const index = await loadModuleIndex();
        
        if (!index.modules || !Array.isArray(index.modules)) {
            throw new Error('Invalid module_index.json structure');
        }
        
        const modules = [];
        const questionsMap = new Map();
        
        // Load each enabled module
        for (const moduleDef of index.modules) {
            if (!moduleDef.enabled) {
                console.log(`⏭️  Skipping disabled module: ${moduleDef.name}`);
                continue;
            }
            
            try {
                const moduleData = await loadModuleFile(moduleDef.file);
                
                // Validate and process questions
                const questions = [];
                for (const question of moduleData.questions || []) {
                    try {
                        validateQuestion(question, moduleDef.id);
                        
                        // Add default values if missing
                        const processedQuestion = {
                            ...question,
                            difficulty_stars: question.difficulty_stars || getDifficultyStars(question.difficulty),
                            points: question.points || 10,
                            time_limit: question.time_limit || 600,
                            hints: question.hints || [],
                            solution_steps: question.solution_steps || [],
                            cleanup_script: question.cleanup_script || '',
                            order: question.order || 999
                        };
                        
                        questions.push(processedQuestion);
                        questionsMap.set(question.question_id, processedQuestion);
                        
                    } catch (error) {
                        console.error(`⚠️  Invalid question in ${moduleDef.id}:`, error.message);
                    }
                }
                
                // Sort questions by order
                questions.sort((a, b) => a.order - b.order);
                
                modules.push({
                    id: moduleDef.id,
                    name: moduleDef.name,
                    description: moduleDef.description,
                    order: moduleDef.order,
                    icon: moduleDef.icon || '📚',
                    file: moduleDef.file,
                    questionCount: questions.length,
                    questions: questions
                });
                
                console.log(`✅ Loaded module: ${moduleDef.name} (${questions.length} questions)`);
                
            } catch (error) {
                console.error(`❌ Failed to load module ${moduleDef.name}:`, error.message);
            }
        }
        
        // Sort modules by order
        modules.sort((a, b) => a.order - b.order);
        
        return {
            modules,
            questionsMap,
            version: index.version,
            lastUpdated: index.last_updated
        };
        
    } catch (error) {
        console.error('Fatal error loading modules:', error);
        throw error;
    }
}

/**
 * Get difficulty stars based on difficulty level
 */
function getDifficultyStars(difficulty) {
    const stars = {
        'easy': '⭐',
        'medium': '⭐⭐',
        'hard': '⭐⭐⭐',
        'expert': '⭐⭐⭐⭐'
    };
    return stars[difficulty?.toLowerCase()] || '⭐';
}

/**
 * Watch for changes in questions directory
 */
function watchQuestions(callback) {
    try {
        let timeout;
        
        fsSync.watch(QUESTIONS_DIR, { recursive: false }, (eventType, filename) => {
            if (!filename || !filename.endsWith('.json')) {
                return;
            }
            
            // Debounce: wait 500ms after last change
            clearTimeout(timeout);
            timeout = setTimeout(() => {
                console.log(`📝 File changed: ${filename}`);
                callback();
            }, 500);
        });
        
        console.log('👀 Watching questions directory for changes...');
        
    } catch (error) {
        console.error('Warning: Could not set up file watcher:', error.message);
    }
}

/**
 * Get question by ID
 */
async function getQuestionById(questionId) {
    const data = await loadModules();
    return data.questionsMap.get(questionId);
}

module.exports = {
    loadModules,
    watchQuestions,
    getQuestionById
};
