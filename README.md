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

  ipcMain.on('open-popover', (e, rect, size, edge, behavior, animate, appearance) => {
    const options = { rect, size, edge, behavior, animate, appearance };

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
- `options`: (passed through to [NSPopover](https://developer.apple.com/documentation/appkit/nspopover))
  - `rect` { x: number, y: number, width: number, height: number }
  - `size` { width: number, height: number }
  - `edge` 'max-x-edge' | 'max-y-edge' | 'min-x-edge' | 'min-y-edge' (optional, default: 'max-x-edge')
  - `behavior` 'transient' | 'semi-transient' | 'application-defined' (optional, default: 'application-defined')
  - `animates` boolean (optional, default: false)
  - `appearance` 'aqua' | 'darkAqua' | 'vibrantLight' | 'accessibilityHighContrastAqua' | 'accessibilityHighContrastDarkAqua' | 'accessibilityHighContrastVibrantLight' | 'accessibilityHighContrastVibrantDark' (optional, default: 'aqua')

### popover.close()

Closes the NSPopover.

### popover.onClosed(callback)

Callback is called when the popover closes.

- `callback`: Function
