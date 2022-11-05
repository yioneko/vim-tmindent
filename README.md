# vim-tmindent

(**WIP**) [TextMate](https://macromates.com/manual/en/appendix) style indentation for (neo)vim. Also used by atom and vscode to implement auto indent.

See [available rules](./autoload/tmindent/rules.vim) for supported langauges.

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
    use_treesitter = function() return true end, -- used to differenct detect langauge region and comments
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
