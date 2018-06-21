const {compileToString} = require('node-elm-compiler');

const compileElm = (path, userElmFiles) => {
  return compileToString(userElmFiles, {
      yes: true,
      cwd: path,
  });
};

module.exports = compileElm;
