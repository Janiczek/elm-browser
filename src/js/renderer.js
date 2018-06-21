const electron = require('electron');
const {remote, ipcRenderer} = electron;
const {requireTaskPool} = require('electron-remote');
const Elm = require('../../dist/js/elm.js');

const mainProcess = remote.require('./main.js');

// do CPU-intensive stuff in another process
const $replaceInFile = requireTaskPool(require.resolve('./bg/replace-in-file.js'));
const $copyFromTemplate = requireTaskPool(require.resolve('./bg/copy-from-template.js'));
const $listUserElmFiles = requireTaskPool(require.resolve('./bg/list-user-elm-files.js'));
const $listFilesForIndex = requireTaskPool(require.resolve('./bg/list-files-for-index.js'));
const $compileElm = requireTaskPool(require.resolve('./bg/compile-elm.js'));

const app = Elm.Main.fullscreen();

const sendToElm = (tag, data) => {
    app.ports.msgForElm.send({tag, data});
};

const createProject = async () => {
    const path = chooseProjectPath();
    $copyFromTemplate(mainProcess.appPath, path);
    const userElmFiles = await $listUserElmFiles(path);
    await $compileElm(path, userElmFiles);
    sendToElm('ProjectCreated', path);
};

const openProject = async () => {
    const path = chooseProjectPath();
    const userElmFiles = await $listUserElmFiles(path);
    await $compileElm(path, userElmFiles);
    sendToElm('ProjectOpened', path);
};

const listFilesForIndex = async (path) => {
    const result = await $listFilesForIndex(path);
    console.log({result});
    sendToElm('FilesForIndex', result);
};

ipcRenderer.on('create-project', createProject);
ipcRenderer.on('open-project', openProject);

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
        $replaceInFile(data.filepath, data.from, data.to, data.replacement);
        break;

    case 'CreateProject':
        createProject();
        break;

    case 'OpenProject':
        openProject();
        break;

    case 'ListFilesForIndex':
        listFilesForIndex(data.path);
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

const chooseProjectPath = () => {
    const paths = mainProcess.selectDirectory();
    if (paths !== undefined && paths.length > 0) {
      return paths[0];
    }
};
