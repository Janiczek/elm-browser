const electron = require('electron');
const remote = electron.remote;
const Elm = require('../../dist/elm.js');

const mainProcess = remote.require('./main');
const app = Elm.Main.fullscreen();

const sendToElm = (tag, data) => {
  app.ports.msgForElm.send({tag, data});
}

app.ports.msgForElectron.subscribe(msgForElectron => {

    const {tag, data} = msgForElectron;

    switch (tag) {

      case 'ChooseProjectPath':
        chooseProjectPath();
        break;

      case 'ErrorLogRequested':
        errorLogRequested(data);
        break;

      default:
        console.error({error: 'Unexpected Msg for Electron', msg: msgForElectron});
        break;

    }

});

const chooseProjectPath = () => {
  const paths = mainProcess.selectDirectory();
  if (paths === undefined) {
    sendToElm('NoProjectPathChosen', null);
  } else {
    sendToElm('ProjectPathChosen', paths[0]);
  }
};

const errorLogRequested = error => {
  console.error(error);
};
