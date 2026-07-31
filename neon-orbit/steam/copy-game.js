// Pulls the single-file game into the Electron package. The repo root stays
// the source of truth; steam/game/ is a build product and is gitignored.
const fs = require('fs');
const path = require('path');
fs.mkdirSync(path.join(__dirname, 'game'), { recursive: true });
fs.copyFileSync(path.join(__dirname, '..', 'index.html'),
                path.join(__dirname, 'game', 'index.html'));
console.log('copied index.html -> steam/game/index.html');
