-- test
return {
	-- Test
	base46 = {
		theme = "everforest_light",
		theme_toggle = { "catppuccin", "everforest_light" },
		hl_override = {
			Comment = { italic = true },      -- Comments in Clojure
			["@comment"] = { italic = true }, -- Comments in Lua
			["@symbol"] = { fg = "blue" },
			["@function"] = { fg = "yellow" },
			-- clojureCond = { fg = "blue" }
		},
		hl_add = {
			clojureKeyword = { fg = "blue" },  -- the ':' before the kw name
			["@lsp.type.keyword.clojure"] = { fg = "blue" },
			["@lsp.type.macro.clojure"] = { fg = "pink" },
			clojureMacro = { fg = "blue" },
		}
	},
	ui = {
		tabufline = {
			enabled = false
		},
		statusline = {
			theme = "default",
			order = { "mode", "file", "%=", "lsp_msg", "diagnostics", "cwd", "cursor" },
		}
	},
	colorify = {
		enabled = false
	}
}
