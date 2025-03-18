const fs = require('fs');
const path = require('path');
const util = require("node:util");
const express = require('express');
const astPath = path.join(__dirname, 'ast.json');
const projectName = 'ALCL' || process.env.PROJECT_NAME;
const port = 3000 || process.env.PORT;

if (!fs.existsSync(astPath)) {
    console.error('AST file not found');
    process.exit(1);
}

class DocParameter {
    constructor(name, type, description) {
        this.name = name;
        this.type = type;
        this.description = description;
    }

    toString() {
        return `${this.name}: ${this.type}`;
    }
}

class Docfunction {
    constructor(name, description) {
        this.name = name;
        this.description = description;
        this.parameters = [];
        this.isNative = false;
        this.returns = null;
    }

    addParameter(parameter) {
        this.parameters.push(parameter);
    }

    setReturns(returns) {
        this.returns = returns;
    }

    toString() {
        return `${this.name}(${this.parameters.map(p => p.toString()).join(', ')})` + (this.returns ? `: ${this.returns}` : '');
    }
}

class DocModule {
    constructor(name, description) {
        this.name = name;
        this.description = description;
        this.functions = [];
    }

    addFunction(func) {
        this.functions.push(func);
    }

    getFunction(name) {
        return this.functions.find(m => m.name === name);
    }

    getFunctionIndex(name) {
        return this.functions.findIndex(m => m.name === name);
    }
}

function parseAst(ast) {
    const modules = [];

    for (const moduleName of Object.keys(ast)) {
        const module = new DocModule(moduleName, "");
        const moduleAst = ast[moduleName];

        for (const moduleRootChild of moduleAst.children) {
            if (moduleRootChild.type == 4) { // FUNCTION
                const func = new Docfunction(moduleRootChild.value, "");

                for (const functionChild of moduleRootChild.children) {
                    if (functionChild.type == 5) { // PARAMETER
                        const parameter = new DocParameter(functionChild.value, functionChild.analysisType._type, "");
                        func.addParameter(parameter);
                    }

                    if (functionChild.type == 9) { // NATIVE FUNCTION
                        func.isNative = true;
                    }

                    if (functionChild.type == 10) { // EXTERN FUNCTION
                        func.isNative = true;
                    }
                }

                func.setReturns(moduleRootChild.analysisType._type);
                module.addFunction(func);
            }
        }

        modules.push(module);
    }

    return modules;
}

function printDoc(modules) {
    for (const module of modules) {
        console.log(`Module: ${module.name}`);
        console.log(`Description: ${module.description}`);

        for (const func of module.functions) {
            console.log(`   Method: ${func.toString()} `);
        }

        console.log();
    }
}

const astStartTime = Date.now();
const astContent = fs.readFileSync(astPath, 'utf8');
const astJson = JSON.parse(astContent);
const ast = parseAst(astJson);
const astEndTime = Date.now();
console.log(`AST loaded in ${astEndTime - astStartTime}ms`);

const app = express();

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
    res.render('index', { modules: ast, name: projectName, query: req.query });
});

app.listen(port, () => {
    console.log(`Server listening at http://localhost:${port}`);
});
