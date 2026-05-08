const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('hamsterCrmStorage', {
  load: () => ipcRenderer.invoke('hamster-crm:load'),
  save: (data) => ipcRenderer.invoke('hamster-crm:save', data),
  dataPath: () => ipcRenderer.invoke('hamster-crm:data-path'),
});
