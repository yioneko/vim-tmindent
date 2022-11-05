-- TODO: Remove this once nvim-treesitter is completely upstreamed to core
local M = {}

function M.get_parser(bufnr, lang)
	local ok, ts_parser = pcall(require, "nvim-treesitter.parsers")
	if ok then
		return ts_parser.get_parser(bufnr, lang)
	end
	return vim.treesitter.get_parser(bufnr, lang)
end

-- These langs are not reliable, faillback to vim filetype
local ambiguous_parser_langs = {
	"javascript",
}

local parser_lang_ft_map = {
	tsx = "typescriptreact",
}

function M.get_ft_from_parser(parser_lang)
	if vim.tbl_contains(ambiguous_parser_langs, parser_lang) then
		return
	end
	return parser_lang_ft_map[parser_lang] or parser_lang
end

return M
