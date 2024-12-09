let setup = {}

if (process.platform === 'darwin') {
  setup = require('bindings')('electron_mac_popover.node');
}

module.exports = setup;
