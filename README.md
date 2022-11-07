# vim-tmindent

[TextMate](https://macromates.com/manual/en/appendix) style indentation for (neo)vim. Also used by atom and vscode to implement auto indent.

I developed this as a supplement to [nvim-yati](https://github.com/yioneko/nvim-yati) for saner fallback indent computation, and it could also be used as a standalone indentexpr.

See [available rules](./autoload/tmindent/rules.vim) for supported languages.

## Usage

### Vim

```vim
let g:tmindent = {
  \   'enabled': { -> index(["lua", "yaml"], &filetype) >= 0 },
  \   'default_rule': {},
  \   'rules': {
  \       'json': #{ comment: ['//'], inherit: ['&{}', '&[]'] }
  \   }
  \ }
```

### Neovim (Lua)

```lua
require('tmindent').setup({
  enabled = function() return vim.tbl_contains({ "lua" }, vim.bo.filetype) end,
  use_treesitter = function() return true end, -- used to detect different langauge region and comments
  default_rule = {},
  rules = {
    lua = {
      comment = {'--'},
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

### Integration

#### Indent API

```vim
call tmindent#get_indent(lnum, bufnr) " lnum is 1-indexed
```

```lua
require('tmindent').get_indent(lnum, bufnr) -- NOTE: lnum is 0-indexed
```

#### [nvim-yati](https://github.com/yioneko/nvim-yati)

```lua
local tm_fts = { "lua", "javascript", "python" } -- or any other langs

require("nvim-treesitter.configs").setup {
  yati = {
    default_fallback = function(lnum, computed, bufnr)
      if vim.tbl_contains(tm_fts, vim.bo[bufnr].filetype) then
        return require('tmindent').get_indent(lnum, bufnr) + computed
      end
      -- or any other fallback methods
      return require('nvim-yati.fallback').vim_auto(lnum, computed, bufnr)
    end,
  }
}
```

## Rule

[Reference from vscode](https://code.visualstudio.com/api/language-extensions/language-configuration-guide#indentation-rules)

- `inherit`: list of other rules to extend
- `comment`: pattern to match comment, which will be trimmed before matching
- `string`: pattern to match string content, which will be replaced by whitespace before matching
- `increase`: `increaseIndentPattern` in TextMate
- `decrease`: `decreaseIndentPattern` in TextMate
- `unindented`: `unindentedLinePattern` in TextMate
- `indentnext`: `indentNextLinePattern` in TextMate

Basic rules include "&{}", "&[]", "&()", "&<>", "&tag".

## Credits

- vscode
- [vim-gindent](https://github.com/hrsh7th/vim-gindent)
