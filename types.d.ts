declare module 'electron-mac-popover' {
  export interface ShowOptions {
    rect: {
      x: number;
      y: number;
      width: number;
      height: number;
    };
    size: {
      width: number;
      height: number;
    };
    edge?: 'max-x-edge'
      | 'max-y-edge'
      | 'min-x-edge'
      | 'min-y-edge';
	behavior?: 'transient' | 'semi-transient' | 'application-defined';
    animate?: boolean;
    appearance?: 'aqua'
      | 'darkAqua'
      | 'vibrantLight'
      | 'accessibilityHighContrastAqua'
      | 'accessibilityHighContrastDarkAqua'
      | 'accessibilityHighContrastVibrantLight'
      | 'accessibilityHighContrastVibrantDark';
  }

  export class ElectronMacPopover {
    constructor(nativeWindowHandle: Buffer);
    show(nativeWindowHandle: Buffer, options: ShowOptions): void;
    close(): void;
    onClosed(callback: () => void): void;
  }
}
