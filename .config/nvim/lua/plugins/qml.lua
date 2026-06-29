return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    servers = { "qml-language-server" },
    config = {
      ["qml-language-server"] = {
        cmd = { "qml-language-server" },
        filetypes = { "qml" },
        root_markers = { { "qmldir", "shell.qml" }, ".git" },
      },
    },
  },
}
