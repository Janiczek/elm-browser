const electron = require('electron');
const {remote, ipcRenderer} = electron;
const {requireTaskPool} = require('electron-remote');
const Elm = require('../../dist/js/elm.js');

const mainProcess = remote.require('./main.js');

// do CPU-intensive stuff in another process
const $replaceInFile = requireTaskPool(require.resolve('./replace-in-file.js'));
const $copyFromTemplate = requireTaskPool(require.resolve('./copy-from-template.js'));
const $listFilesForIndex = requireTaskPool(require.resolve('./list-files-for-index.js'));

const app = Elm.Main.fullscreen();

const sendToElm = (tag, data) => {
    app.ports.msgForElm.send({tag, data});
};

const askForNewProjectPath = () => {
    const path = chooseProjectPath();
    $copyFromTemplate(mainProcess.appPath, path);
    sendToElm('ProjectCreated', path);
};

const askForOpenProjectPath = () => {
    const path = chooseProjectPath();
    sendToElm('ProjectOpened', path);
};

const listFilesForIndex = async (path) => {
    const files = await $listFilesForIndex(path);
    sendToElm('FilesForIndex', files);
};

ipcRenderer.on('create-project', askForNewProjectPath);
ipcRenderer.on('open-project', askForOpenProjectPath);

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

    case 'AskForNewProjectPath':
        askForNewProjectPath();
        break;

    case 'AskForOpenProjectPath':
        askForOpenProjectPath();
        break;

    case 'ListFilesForIndex':
        listFilesForIndex();
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
