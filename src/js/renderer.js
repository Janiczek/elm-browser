const electron = require('electron');
const {remote, ipcRenderer} = electron;
const Elm = require('../../dist/js/elm.js');
const monacoLoader = require('monaco-loader');

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

    case 'ChooseProjectPath':
        chooseProjectPath();
        break;

    case 'ErrorLogRequested':
        errorLogRequested(data);
        break;

    case 'CreateIndex':
        createIndex();
        break;

    case 'ChangeTitle':
        changeTitle(data);
        break;

    case 'SetEditorModel':
        setEditorModel(data);
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

const createIndex = () => {
    // TODO in future do things in the main thread, not the renderer thread?
    const index = require('../project_index_dummy.json');
    //setTimeout(function(){
    //    sendToElm('IndexCreated', index);
    //}, 1000);
    sendToElm('IndexCreated', index);
};

const changeTitle = newTitle => {
    document.title = newTitle;
};

const setEditorModel = ({sourceCode, language}) => {
//    editor.setModel(monaco.editor.createModel(sourceCode, language));
};
