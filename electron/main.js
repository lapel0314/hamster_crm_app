const { app, BrowserWindow, ipcMain } = require('electron');
const fs = require('fs');
const path = require('path');

const isDev = !app.isPackaged;

function dataFilePath() {
  return path.join(app.getPath('documents'), 'GoldenHamsterCRM', 'hamster_crm_data.json');
}

async function ensureDataDir() {
  await fs.promises.mkdir(path.dirname(dataFilePath()), { recursive: true });
}

function webIndexPath() {
  return path.join(__dirname, '..', 'build', 'web', 'index.html');
}

async function createWindow() {
  const window = new BrowserWindow({
    width: 1440,
    height: 960,
    minWidth: 1180,
    minHeight: 760,
    title: '뵤펫 CRM',
    backgroundColor: '#fff7e8',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  await window.loadFile(webIndexPath());
  if (isDev && process.env.HAMSTER_CRM_DEVTOOLS === '1') {
    window.webContents.openDevTools({ mode: 'detach' });
  }
}

ipcMain.handle('hamster-crm:data-path', () => dataFilePath());

ipcMain.handle('hamster-crm:load', async () => {
  try {
    return await fs.promises.readFile(dataFilePath(), 'utf8');
  } catch (error) {
    if (error && error.code === 'ENOENT') return null;
    throw error;
  }
});

ipcMain.handle('hamster-crm:save', async (_event, data) => {
  await ensureDataDir();
  const target = dataFilePath();
  const tmp = `${target}.tmp`;
  await fs.promises.writeFile(tmp, data, 'utf8');
  await fs.promises.rename(tmp, target);
  return target;
});

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
