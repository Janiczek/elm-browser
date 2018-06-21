const electron = require('electron');
const {remote, ipcRenderer} = electron;
const Elm = require('../../dist/js/elm.js');

const mainProcess = remote.require('./main.js');
const app = Elm.Main.fullscreen();

const sendToElm = (tag, data) => {
    app.ports.msgForElm.send({tag, data});
};

ipcRenderer.on('open-project', (event, arg) => {
    chooseProjectPath();
});

ipcRenderer.on('close-project', (event, arg) => {
    sendToElm('ProjectClosed', null);
});

app.ports.msgForElectron.subscribe(msgForElectron => {

    const {tag, data} = msgForElectron;

    switch (tag) {

    case 'ErrorLogRequested':
        errorLogRequested(data);
        break;

    case 'ChangeTitle':
        changeTitle(data);
        break;

    case 'ReplaceInFile':
        ipcRenderer.send('replace-in-file', data);
        break;

    default:
        console.error({error: 'Unexpected Msg for Electron', msg: msgForElectron});
        break;

    }

});

const errorLogRequested = error => {
    console.error(error);
};

const changeTitle = newTitle => {
    document.title = newTitle;
};
