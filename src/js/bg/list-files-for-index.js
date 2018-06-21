const readdir = require('recursive-readdir');
const path = require('path');

const shouldIgnore = (file, stats) => {
  const filename = path.basename(file);
  const extension = path.extname(file);
  if (stats.isDirectory()) {
    return false;
  } else {
    return extension !== '.elm' && filename !== 'elm-package.json';
  }
};

const listFilesForIndex = (path) => {
  // TODO read the files in addition to the paths
  return readdir(path, [shouldIgnore]);
};

module.exports = listFilesForIndex;
