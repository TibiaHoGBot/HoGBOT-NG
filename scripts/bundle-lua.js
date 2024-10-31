import {
  bundle,
} from 'luabundle';

import fs, {
  existsSync,
  mkdirSync,
  writeFileSync,
  lstatSync,
} from "fs";
import { sep as pathSeparator } from 'path'

function defaultResolve(name, packagePaths) {
  const platformName = name.replace(/\./g, pathSeparator)

  for (const pattern of packagePaths) {
    const path = pattern.replace(/\?/g, platformName)

    if (existsSync(path) && lstatSync(path).isFile()) {
      return path
    }
  }
  return null
}

const libs = fs.readdirSync('./libs', { recursive: true }).map(p => {
  p = "libs/" + p
  if (p.includes(".lua")) {
    return p.slice(0, -4)
  } else {
    return p
  }
});

const bot_modules = fs.readdirSync('./bot_modules', { recursive: true }).map(p => {
  p = "bot_modules/" + p
  if (p.includes(".lua")) {
    return p.slice(0, -4)
  } else {
    return p
  }
});

console.log(bot_modules)

const core = bundle("./scripts/merger.lua", {
  callRoot: false,
  ignoredModuleNames: ["cjson", "webview", "jls.lang.event", "jls.util.WebView", "jls.net.http.handler.FileHttpHandler"]
});
const lib = bundle("./library/lib.lua", { callRoot: false, force: true })

const customRequire = fs.readFileSync("./scripts/customRequire.lua").toString()

const bot = bundle("./index.lua", {
  customRequire: customRequire,
  callRoot: true,
  resolveModule: (name, packagePaths) => {
    console.log("name: ", name)
    console.warn("paths: ", packagePaths)

    if (name.includes("libs/") || name.includes("library/") || name.includes("bot_modules/") || name.includes("webview-launcher")) {
      return null
    }

    return defaultResolve(name, packagePaths)
  },
  ignoredModuleNames:
    [...libs, ...bot_modules, "webview-launcher", "library/lib", "cjson", "webview", "jls.lang.event", "jls.util.WebView", "jls.net.http.handler.FileHttpHandler"],

})

if (!existsSync("./dist")) {
  mkdirSync("./dist", { recursive: true })
}

writeFileSync("./dist/core.lua", core)
writeFileSync("./dist/lib.lua", lib)
writeFileSync("./dist/bot.lua", bot)