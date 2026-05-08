const fs = require('fs');
const path = require('path');

const indexPath = path.join(__dirname, '..', 'build', 'web', 'index.html');
let html = fs.readFileSync(indexPath, 'utf8');
html = html.replace('<base href="/">', '<base href="./">');
fs.writeFileSync(indexPath, html, 'utf8');
