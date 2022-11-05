# vim-tmindent

[TextMate](https://macromates.com/manual/en/appendix) style indentation for (neo)vim. Also used by atom and vscode to implement auto indent.

I developed this as a supplement to [nvim-yati](yioneko/nvim-yati) for saner fallback indent computation, and it could also be used as a standalone indentexpr.

See [available rules](./autoload/tmindent/rules.vim) for supported languages.

## Usage

For vim user:

```vim
let g:tmindent = {
    \   'enabled': { -> index(["lua", "yaml"], &filetype) >= 0 },
    \   'default_rule': {},
    \   'rules': {
    \       'json': #{ comment: ['^//'], inherit: ['&{}', '&[]'] }
    \   }
    \}
```

Or if you use neovim:

```lua
require('tmindent').setup({
    enabled = function() return vim.tbl_contains({ "lua" }, vim.bo.filetype) end,
    use_treesitter = function() return true end, -- used to detect different langauge region and comments
    default_rule = {},
    rules = {
        lua = {
            comment = {'^--'},
            -- inherit pair rules
            inherit = {'&{}', '&()'},
            -- these patterns are the same as TextMate's
            increase = {'\v<%(else|function|then|do|repeat)>((<%(end|until)>)@!.)*$'},
            decrease = {'^\v<%(elseif|else|end|until)>'},
            unindented = {},
            indentnext = {},
        }
    }
})
```

## Credits

- vscode
- [vim-gindent](https://github.com/hrsh7th/vim-gindent)
