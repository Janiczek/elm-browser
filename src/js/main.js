const electron = require('electron');
const {app, dialog, Menu, ipcMain} = electron;
const BrowserWindow = electron.BrowserWindow;

const path = require('path');
const url = require('url');

let mainWindow;

const createWindow = () => {
    mainWindow = new BrowserWindow({
        width: 800,
        height: 600
    });

    mainWindow.loadURL(url.format({
        pathname: path.join(__dirname, '../index.html'),
        protocol: 'file:',
        slashes: true
    }));

    mainWindow.webContents.openDevTools();

    mainWindow.on('closed', () => {
        mainWindow = null;
    });

    const menuTemplate = [
        {
            label: 'File',
            submenu: [
                {
                    label: 'Create Project',
                    click: (menuItem, browserWindow, event) => {
                        mainWindow.webContents.send('create-project');
                    }
                },
                {
                    label: 'Open Project',
                    click: (menuItem, browserWindow, event) => {
                        mainWindow.webContents.send('open-project');
                    }
                },
                {
                    label: 'Close Project',
                    click: (menuItem, browserWindow, event) => {
                        mainWindow.webContents.send('close-project');
                    }
                },
            ]
        }
    ];

    const menu = Menu.buildFromTemplate(menuTemplate);
    Menu.setApplicationMenu(menu);
};

const selectDirectory = () => {
    return dialog.showOpenDialog(mainWindow, {
        properties: ['openDirectory']
    });
};

app.on('ready', createWindow);

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (mainWindow === null) {
        createWindow();
    }
});

const appPath = app.getAppPath();

module.exports = {
  selectDirectory,
  appPath,
};
