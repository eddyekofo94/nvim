-- Show project outline
return {
    'simrat39/symbols-outline.nvim', -- show symbols of the current buffer
    keys = {
        {
            "<leader>lO",
            "<cmd>SymbolsOutline<cr>",
            desc = "Symbols Outline",
        },
    },
    event = "VeryLazy",
    config = function()
        --- Return with with minimum threshold
        local width_with_min = function(ratio, min_width)
            local width = math.floor(vim.go.columns * ratio)
            width = math.max(width, min_width)
            return width
        end

        require('symbols-outline').setup({
            highlight_hovered_item = true,
            show_guides = true,
            auto_preview = true,
            position = 'left',
            relative_width = true,
            width = 30,
            auto_close = true,
            show_numbers = false,
            show_relative_numbers = false,
            show_symbol_details = true,
            preview_bg_highlight = 'Pmenu',
            autofold_depth = 0,
            auto_unfold_hover = true,
            fold_markers = { '', '' },
            wrap = false,
            keymaps = { -- These keymaps can be a string or a table for multiple keys
                close = { "<Esc>", "q" },
                goto_location ={  "<Cr>" , "l"},
                focus_location = "o",
                hover_symbol = "<C-space>",
                toggle_preview = "K",
                rename_symbol = "r",
                code_actions = "a",
                fold = "h",
                unfold = "p",
                fold_all = "W",
                unfold_all = "E",
                fold_reset = "R",
            },
            lsp_blacklist = {},
            symbol_blacklist = {},
            symbols = {
                File = { icon = "", hl = "@text.uri" },
                Module = { icon = "", hl = "@namespace" },
                Namespace = { icon = "", hl = "@namespace" },
                Package = { icon = "", hl = "@namespace" },
                Class = { icon = "𝓒", hl = "@type" },
                Method = { icon = "ƒ", hl = "@method" },
                Property = { icon = "", hl = "@method" },
                Field = { icon = "", hl = "@field" },
                Constructor = { icon = "", hl = "@constructor" },
                Enum = { icon = "ℰ", hl = "@type" },
                Interface = { icon = "ﰮ", hl = "@type" },
                Function = { icon = "", hl = "@function" },
                Variable = { icon = "", hl = "@constant" },
                Constant = { icon = "", hl = "@constant" },
                String = { icon = "𝓐", hl = "@string" },
                Number = { icon = "#", hl = "@number" },
                Boolean = { icon = "⊨", hl = "@boolean" },
                Array = { icon = "", hl = "@constant" },
                Object = { icon = "⦿", hl = "@type" },
                Key = { icon = "🔐", hl = "@type" },
                Null = { icon = "NULL", hl = "@type" },
                EnumMember = { icon = "", hl = "@field" },
                Struct = { icon = "𝓢", hl = "@type" },
                Event = { icon = "🗲", hl = "@type" },
                Operator = { icon = "+", hl = "@operator" },
                TypeParameter = { icon = "𝙏", hl = "@parameter" },
                Component = { icon = "", hl = "@function" },
                Fragment = { icon = "", hl = "@constant" },
            },
        })
    end,
}
