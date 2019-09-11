const {compileToString} = require('node-elm-compiler');

const compileElm = (path, userElmFiles) => {
  return compileToString(userElmFiles, {
      cwd: path,
  });
};

module.exports = compileElm;
