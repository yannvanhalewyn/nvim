local M = {}

local snippets = {
  global = {
    shebang = '#!/usr/bin/env bash',
  },
  lua = {
    fun = [[function ${1:name}(${2:args})
	$0
end]]
  },
  clojure = {
    sys = "integrant.repl.state/system",
    rf = "(clojure.tools.namespace.repl/refresh)",
    ra = "(clojure.tools.namespace.repl/refresh-all)",
    argl = "{:arglists '([${1:arglist}])}",
    rs = "(require 'sc.api)",
    spy = "(sc.api/spy $1)",
    ds = "(sc.api/defsc $1)",
    ls = "(sc.api/letsc $1)",
    log = "(clojure.tools.logging/debug $1)",
    diff = "(clojure.data/diff $1)",
    pnm = "(set! *print-namespace-maps* false)",
    hpp = "(require 'hashp.preload)",
    pp = "(clojure.pprint/pprint $1)",
    unalias = "(ns-unalias *ns* '$1)",
    unmap = "(ns-unmap *ns* '$1)",
    ["write-edn"] = [[(binding [*print-namespace-maps* false]
  (clojure.pprint/pprint ${1:data} (clojure.java.io/writer "${2:filename}")))]],
    ["read-csv"] = [=[(with-open [rdr (io/reader (io/file ${1:filename}))]
  (into [] (csv/read-csv rdr :separator \\${2:,})))]=],
    ["write-csv"] = [[(with-open [writer (io/writer (io/file ${1:file}))]
  (csv/write-csv writer ${2:csv-rows})),
  ]],
    xtq = [=[(db/q (user/$1-db)
  '{:find (pull ?e [*])
    :where [[?e ${2:query}]]})]=],
  }
};

M.expand_snippet = function()
  local line = vim.api.nvim_get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  local word_start = col
  while word_start > 0 and line:sub(word_start, word_start):match('[%w_-]') do
    word_start = word_start - 1
  end
  word_start = word_start + 1

  local trigger = line:sub(word_start, col)
  local filetype = vim.bo.filetype
  local snippet = (
    (snippets[filetype] and snippets[filetype][trigger])
    or snippets["global"][trigger]
  )

  if snippet then
    vim.api.nvim_buf_set_text(0, row - 1, word_start - 1, row - 1, col, { "" })
    vim.snippet.expand(snippet)
  else
    if vim.snippet.active() then
      vim.snippet.jump(1)
    end
  end

  return word_start
end

return M
