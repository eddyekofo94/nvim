return {
    "nvimdev/lspsaga.nvim",
    event = "BufWinEnter",
    keys = {
        {
            "K",
            "<cmd>Lspsaga hover_doc<CR>",
            desc = "Saga hover",
        },
        {
            "]d",
            "<cmd>Lspsaga diagnostic_jump_next<cr>",
            desc = "diagnostic jump next",
        },
        {
            "[d",
            "<cmd>Lspsaga diagnostic_jump_prev<cr>",
            desc = "diagnostic jump prev",
        },
    },
    config = function()
        require("lspsaga").setup({
            code_action = {
                enable = false
            },
            code_action_lightbulb = {
                enable = false,
            },
            ui = {
                kind = require("catppuccin.groups.integrations.lsp_saga").custom_kind(),
            },
        })
        local mapper = require("utils").keymap_set
        mapper("n", "dl", "<cmd>Lspsaga show_line_diagnostics<CR>", "Saga show line diagnostics")
        mapper("n", "K", "<cmd>Lspsaga hover_doc<CR>", "Saga hover")
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
