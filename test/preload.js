const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('electronAPI', {
    openPopover: (rect, size, edge, behavior, animate, appearance) => {
        ipcRenderer.send('open-popover', rect, size, edge, behavior, animate, appearance);
    },
    closePopover: () => {
        ipcRenderer.send('close-popover');
    },
    sizePopover: (size, animate, duration) => ipcRenderer.send('size-popover', size, animate, duration)
})
