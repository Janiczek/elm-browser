const electron = require('electron');
const {remote, ipcRenderer} = electron;
const {Elm} = require('../dist/js/elm.js');

const mainProcess = remote.require('./main.js');

const replaceInFile = require('./js/bg/replace-in-file.js');
const copyFromTemplate = require('./js/bg/copy-from-template.js');
const listUserElmFiles = require('./js/bg/list-user-elm-files.js');
const listFilesForIndex = require('./js/bg/list-files-for-index.js');
const compileElm = require('./js/bg/compile-elm.js');

const app = Elm.Main.init();

const sendToElm = (tag, data) => {
    app.ports.msgForElm.send({tag, data});
};

const createProject = async () => {
    const path = await chooseProjectPath();
    await copyFromTemplate(mainProcess.appPath, path);
    const userElmFiles = await listUserElmFiles(path);
    await compileElm(path, userElmFiles);
    sendToElm('ProjectCreated', path);
};

const openProject = async () => {
    const path = await chooseProjectPath();
    const userElmFiles = await listUserElmFiles(path);
    await compileElm(path, userElmFiles);
    sendToElm('ProjectOpened', path);
};

const listFilesForIndex_ = async (path) => {
    const result = await listFilesForIndex(path);
    sendToElm('FilesForIndex', result);
};

ipcRenderer.on('create-project', createProject);
ipcRenderer.on('open-project', openProject);

ipcRenderer.on('close-project', (event, arg) => {
    sendToElm('ProjectClosed', null);
});

app.ports.msgForElectron.subscribe(async function(msgForElectron) {

    const {tag, data} = msgForElectron;

    switch (tag) {

    case 'ErrorLogRequested':
        errorLogRequested(data);
        break;

    case 'ChangeTitle':
        changeTitle(data);
        break;

    case 'ReplaceInFile':
        await replaceInFile(data.filepath, data.from, data.to, data.replacement);
        break;

    case 'CreateProject':
        await createProject();
        break;

    case 'OpenProject':
        await openProject();
        break;

    case 'ListFilesForIndex':
        await listFilesForIndex_(data.path);
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

const chooseProjectPath = async function() {
    const result = await mainProcess.selectDirectory();
    if (result.canceled) {
      return Promise.reject('User has cancelled the directory selection dialog');
    } else {
      return Promise.resolve(result.filePaths[0]);
    }
};
