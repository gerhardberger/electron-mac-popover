const { app, BrowserWindow, ipcMain } = require('electron');
const { ElectronMacPopover } = require('../')

app.on('ready', () => {
  const win = new BrowserWindow({
    width: 400,
    height: 600,
    webPreferences: {
      preload: `${__dirname}/preload.js`,
    }
  });

  win.loadFile('index.html');

  const popoverWindow = new BrowserWindow({
    width: 250,
    height: 250,
    show: false,
    transparent: true,
  });

  popoverWindow.loadFile('popover.html');

  const nativePopover = new ElectronMacPopover(popoverWindow.getNativeWindowHandle());

  ipcMain.on('open-popover', (e, rect, size, edge, behavior, animate) => {
    const options = { rect, size, edge, behavior, animate };

    console.log('event: open-popover', options);

    nativePopover.show(win.getNativeWindowHandle(), options);
  });

  ipcMain.on('close-popover', (e) => {
    console.log('event: close-popover');

    nativePopover.close();
  });
});
