import fs, { existsSync, mkdirSync, writeFileSync, readFileSync } from "fs";
import { resolve as resolvePath } from "path";

import { resolveModule as defaultResolve } from "luabundle/bundle/process.js";
import { defaultOptions } from "luabundle/bundle/options.js";
import { processModule } from "luabundle/bundle/process.js";

function mergeOptions(options) {
  return {
    ...defaultOptions,
    ...options,
    identifiers: {
      ...defaultOptions.identifiers,
      ...options.identifiers,
    },
  };
}

function bundleModule(module, options) {
  const postprocessedContent = options.postprocess
    ? options.postprocess(module, options)
    : module.content;
  const identifiers = options.identifiers;
  return `${identifiers.register}("${module.name}", function(require, _LOADED, ${identifiers.register}, ${identifiers.modules})\n${postprocessedContent}\nend)\n`;
}

export function bundleString(lua, options) {
  const realizedOptions = mergeOptions(options);
  const processedModules = {};

  processModule(
    {
      name: realizedOptions.rootModuleName,
      content: lua,
    },
    realizedOptions,
    processedModules
  );

  if (Object.keys(processedModules).length === 1 && !realizedOptions.force) {
    return lua;
  }

  const identifiers = realizedOptions.identifiers;
  const runtime = readFileSync(
    resolvePath("node_modules/luabundle/dist/bundle/runtime.lua"),
    "utf8"
  );

  let bundle = "";

  bundle += `${identifiers.require}, ${identifiers.loaded}, ${identifiers.register}, ${identifiers.modules} = ${runtime}`;
  bundle += realizedOptions.customRequireFn
    ? `(${realizedOptions.customRequireFn})\n`
    : "(require)\n";

  for (const [name, processedModule] of Object.entries(processedModules)) {
    bundle += bundleModule(
      {
        name,
        content: processedModule.content,
      },
      realizedOptions
    );
  }

  if (options.callRoot) {
    bundle += `${identifiers.require}('${realizedOptions.rootModuleName}')`;
  }

  return bundle;
}

export function bundle(inputFilePath, options = {}) {
  const realizedOptions = mergeOptions(options);
  const lua = readFileSync(inputFilePath, realizedOptions.sourceEncoding);
  return bundleString(lua, options);
}

const libsPaths = fs.readdirSync("./libs", { recursive: true }).map((p) => {
  p = "libs/" + p;
  if (p.includes(".lua")) {
    return p.slice(0, -4);
  } else {
    return p;
  }
});

const botCorePaths = fs
  .readdirSync("./bot_modules/core", { recursive: true })
  .map((p) => {
    p = "bot_modules/core/" + p;
    if (p.includes(".lua")) {
      return p.slice(0, -4);
    } else {
      return p;
    }
  });

const core = bundle("./scripts/core-requires.lua", {
  rootModuleName: "core",
  identifiers: { require: "__require_core" },
  ignoredModuleNames: [
    "cjson",
    "webview",
    "jls.lang.event",
    "jls.util.WebView",
    "jls.net.http.handler.FileHttpHandler",
  ],
});

const lib = bundle("./standard.lua", {
  rootModuleName: "standard",
  force: true,
  identifiers: { require: "__require_std" },
});

const customRequireLua = `function(path)
  if (path:find("^libs/") and path:find("^bot_modules/core")) then
    return __require_core(path)
  elseif (path:find("^standard")) then
    return __require_std(path)
  else
    return require(path)
  end
end`;

const bot = bundle("./index.lua", {
  callRoot: true,
  customRequireFn: customRequireLua,
  rootModuleName: "bot",
  identifiers: { require: "__require_bot" },
  resolveModule: (name, packagePaths) => {
    if (
      name.includes("libs/") ||
      name.includes("standard") ||
      name.includes("bot_modules/core") ||
      name.includes("webview-launcher")
    ) {
      return null;
    }

    return defaultResolve(name, packagePaths);
  },
  ignoredModuleNames: [
    ...libsPaths,
    ...botCorePaths,
    "webview-launcher",
    "standard",
    "cjson",
    "webview",
    "jls.lang.event",
    "jls.util.WebView",
    "jls.net.http.handler.FileHttpHandler",
  ],
});

if (!existsSync("./dist")) {
  mkdirSync("./dist", { recursive: true });
}

writeFileSync("./dist/core.lua", core);
writeFileSync("./dist/lib.lua", lib);
writeFileSync("./dist/bot.lua", bot);
