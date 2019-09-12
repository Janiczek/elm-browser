const fs = require('async-file');
const readdir = require('recursive-readdir');
const path = require('path');
const os = require('os');

const shouldIgnore = (rootPath) => (file, stats) => {
  const filename = path.basename(file);
  const extension = path.extname(file);
  if (stats.isDirectory()) {
    return filename === 'node_modules';
  } else {
    return extension !== '.elm' && (filename !== 'elm.json' || !file.includes(`${rootPath}/elm.json`));
  }
};

const shouldIgnoreDeps = (elmJsonDeps) => (file, stats) => {
  const filename = path.basename(file);
  const extension = path.extname(file);
  if (stats.isDirectory()) {
    return filename === 'node_modules';
  } else {
    const dep = elmJsonDeps.find(dep => file.includes(dep));
    return dep == null || ((extension !== '.elm' || !file.includes('/src/')) && (filename !== 'elm.json' || !file.includes(`${dep}/elm.json`)));
  }
};

const readContent = async (path) => {
  const content = await fs.readTextFile(path);
  return [path, content];
};

const readContents = async (paths) => {
  return Promise.all(paths.map(readContent));
};

const listFilesForIndex = async (rootPath) => {
  const userPaths = await readdir(rootPath, [shouldIgnore(rootPath)]);

  const elmJsonString = await fs.readFile(`${rootPath}/elm.json`);
  const elmJson = JSON.parse(elmJsonString);
  const elmJsonDeps = [
    ...depPaths(elmJson['dependencies']['direct']),
    ...depPaths(elmJson['dependencies']['indirect']),
    ...depPaths(elmJson['test-dependencies']['direct']),
    ...depPaths(elmJson['test-dependencies']['indirect'])
  ];
  const depsPaths = await readdir(
    path.join(os.homedir(),'.elm',elmJson['elm-version'],'package'),
    [shouldIgnoreDeps(elmJsonDeps)]
  );

  const userFiles = await readContents(userPaths);
  const depsFiles = await readContents(depsPaths);

  return [...userFiles, ...depsFiles];
};

const depPaths = (deps) => {
  return Object.entries(deps)
    .map(([dep,version]) => `${dep}/${version}`);
};

module.exports = listFilesForIndex;
