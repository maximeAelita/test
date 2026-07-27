// IRONVINE desktop shell. The game is a single self-contained HTML file, so the
// wrapper's only jobs are: give it a window, keep Electron's chrome out of the
// way, and make the OS-level fullscreen/quit behaviour match what a Steam player
// expects. The in-game F key and pause menu drive fullscreen themselves.
const { app, BrowserWindow, globalShortcut } = require('electron');

// Steam Deck and older integrated GPUs are happier without the compositor's
// occlusion heuristics kicking in on a fullscreen canvas app.
app.commandLine.appendSwitch('disable-backgrounding-occluded-windows');

let win = null;

function createWindow() {
  win = new BrowserWindow({
    width: 1280,
    height: 720,
    minWidth: 640,
    minHeight: 360,
    fullscreen: true,
    fullscreenable: true,
    autoHideMenuBar: true,
    backgroundColor: '#05060a',
    show: false,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      backgroundThrottling: false
    }
  });
  win.setMenuBarVisibility(false);
  win.removeMenu();
  win.once('ready-to-show', () => win.show());
  win.loadFile('game/index.html');
}

app.whenReady().then(() => {
  createWindow();
  // F11 is the desktop convention; the game's own F key still works inside the page.
  globalShortcut.register('F11', () => {
    if (win) win.setFullScreen(!win.isFullScreen());
  });
});

app.on('will-quit', () => globalShortcut.unregisterAll());
app.on('window-all-closed', () => app.quit());
