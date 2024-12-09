# electron-mac-popover

## Description

```js
$ npm i electron-mac-popover
```

This Native Node Module allows you to open an Electron WebContents in a macOS
native NSPopover, to allow for a more native feel for an Electron app. It
exposes the parameters that can be used to customize how an NSPopover behaves.

It is based on my earlier PR in the Electron repository (https://github.com/electron/electron/pull/37423), which which makes more sense to be handled in a separate Native Module hence
not introducing more patches into the codebase.

## Usage

``` typescript
const { app, ipcMain, BrowserWindow } = require('electron');
const { ElectronMacPopover } = require('electron-mac-popover');

app.on('ready', () => {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    frame: false,
  });

  win.loadFile('./index.html');

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

    nativePopover.show(win.getNativeWindowHandle(), options);
  });

  ipcMain.on('close-popover', (e) => {
    nativePopover.close();
  });
});
```

## Documentation

### popover = new ElectronMacPopover(popoverWindowHandle)

The constructor that returns a nativePopover instance.

- `popoverWindowHandle`: the native window handle of a BrowserWindow that will
  be inserted into the popover.

### popover.show(positioningWindowHandle, options)

Opens the NSPopover.

- `positioningWindowHandle`: the native window handle of a BrowserWindow that
  the popover will be positioned relative to.
- `options`: can be found in the [official docs](https://developer.apple.com/documentation/appkit/nspopover).

### popover.close()

Closes the NSPopover.
