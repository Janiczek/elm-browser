const {ncp} = require('ncp');

const ncpAsync = (src, dst, options) => {
  return new Promise((resolve, reject) => {
      ncp(src, dst, options, (err) => {
          if (err) {
            if (typeof err == "string") {
              err = new Error(err);
            }
            reject(err);
          }
          else {
            resolve();
          }
      })
  });
}

const copyFromTemplate = (appPath, path) => {
  return ncpAsync(`${appPath}/new-project-template`, path, {});
};

module.exports = copyFromTemplate;
