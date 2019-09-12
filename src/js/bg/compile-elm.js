const {compileToString} = require('node-elm-compiler');

const compileElm = async function(path, userElmFiles) {
  return compileToString(userElmFiles, {
      cwd: path,
  });
};

module.exports = compileElm;
