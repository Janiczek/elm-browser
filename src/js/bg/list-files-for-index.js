const fs = require('async-file');
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

const readContent = async (path) => {
  const content = await fs.readTextFile(path);
  return [path, content];
};

const readContents = async (paths) => {
  return Promise.all(paths.map(readContent));
};

const listFilesForIndex = async (path) => {
  const paths = await readdir(path, [shouldIgnore]);
  return readContents(paths);
};

module.exports = listFilesForIndex;
