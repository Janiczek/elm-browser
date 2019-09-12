const readdir = require('recursive-readdir');
const path = require('path');
const fs = require('fs');

const shouldIgnore = (sourceDirs) => (file, stats) => {
  const filename = path.basename(file);
  const extension = path.extname(file);
  if (stats.isDirectory()) {
    return !sourceDirs.some(dir => dir.includes(filename)) 
      || filename === 'elm-stuff' 
      || filename === 'node_modules';
  } else {
    return extension !== '.elm';
  }
};

const listUserElmFiles = async function(path) {
  const elmJson = JSON.parse(fs.readFileSync(`${path}/elm.json`, 'utf-8'));
  const sourceDirs = elmJson['source-directories'];
  const files = await readdir(path, [shouldIgnore(sourceDirs)]);
  return files;
};

module.exports = listUserElmFiles;
