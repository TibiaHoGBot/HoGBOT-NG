local home = os.getenv("HOME")

if home then
  package.cpath = package.cpath .. ";" .. home .. "/.luarocks/lib/lua/5.3/?.so"
end

local webviewLib = require('webview')
local dialog = require("nvdialog")
local jsonLib = require("cjson")
local utils = require("webview-launcher")

local api = require("bot_modules/api")
local createBhTree = require("behaviourtree/init")

-- require("lldebugger").start()

dialog.init()

local state = {
  healer = {
    enabled = true,
    rules = {
    }
  },
  persistences = {
    enabled = false,
    rules = {}
  },
  cavebot = {
    enabled = false,
    waypoints = {

    }
  },
  targeting = {
    enabled = false,
    rules = {}
  },
  hp = -1,
  mp = -1,
}

local bhtree = createBhTree(state, true)

if not bhtree then
  os.exit(0)
end

-- local url = 'http://localhost:5173/'
local url = 'https://hogbot-ng-app.pages.dev/'

local webview = webviewLib.new(url, 'HoGBOT-NG', 800, 600, true, true)

local options = {
  expose = {
    saveFile = api.saveFile,
    loadFile = api.loadFile,
    updateState = api.updateState
  },
  context = {
    dialog = dialog,
    jsonLib = jsonLib,
    state = state
  },
  initialize = true,
}

local callback = utils.createContext(webview, options)

webviewLib.callback(webview, callback)

function process_ui()
  webviewLib.loop(webview, "once")
end

-- webviewLib.loop(webview)
