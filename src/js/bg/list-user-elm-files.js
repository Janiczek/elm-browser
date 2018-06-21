const readdir = require('recursive-readdir');
const path = require('path');

const shouldIgnore = (file, stats) => {
  const filename = path.basename(file);
  const extension = path.extname(file);
  if (stats.isDirectory()) {
    return filename === 'elm-stuff';
  } else {
    return extension !== '.elm';
  }
};

const listUserElmFiles = (path) => {
  return readdir(path, [shouldIgnore]);
};

module.exports = listUserElmFiles;
