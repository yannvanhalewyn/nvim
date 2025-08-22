return {
	base46 = {
		-- onedark, catppuccin, tokyodark, everblush, jellybeans, rxyhn, yoru
		-- eveblush
		theme = "catppuccin",
		theme_toggle = { "catppuccin", "everforest_light" },
		hl_override = {
			-- ["@spell"] = { italic = true },
			["@comment"] = { italic = true },
			["@symbol"] = { fg = "blue" },
			["@function"] = { fg = "yellow" },
			-- Used heavily by vim diff
			DiffAdd = { fg = "NONE", bg = "#31352b" },
			DiffDelete = { fg = "NONE", bg = "#511c21" },
			Pmenu = { bg = "NONE" },
			-- Part of changed line that actually changed
			DiffText = { fg = "NONE", bg = "#373b43", bold = true },
		},

		hl_add = {
			["@function.call.clojure"] = { fg = "yellow" },
			["function.call"] = { fg = "yellow" },
			["function.call.lua"] = { fg = "yellow" },
			-- ["@function.call"] = { fg = "yellow" },
			["@string.special.symbol"] = { fg = "blue" },

			-- Deleted line in git status when not higlighted
			NeogitDiffDelete = { fg = "#e06c75" },
			-- Deleted line in git status when higlighted
			NeogitDiffDeleteHighlight = { link = "DiffDelete" },
			-- Shows 'midified' in yellow in git status
			NeogitChangeModified = { fg = "yellow" },
			-- Shows 'deleted' in red in git status
			NeogitChangeDeleted = { fg = "red" },
			--
			DiffviewDiffChange = { bg = "#2d3139" },
			DiffviewDiffAddAsDelete = { link = "DiffDelete" },
		},
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
