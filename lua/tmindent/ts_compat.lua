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

function M.get_buf_line(bufnr, lnum)
	return vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, true)[1] or ""
end

function M.get_first_nonblank_col_at_line(bufnr, lnum)
	local line = M.get_buf_line(bufnr, lnum)
	local _, col = string.find(line or "", "^%s*")
	return col or 0
end

function M.get_lang_at_line_ts(bufnr, lnum)
	local ok, parser = pcall(M.get_parser, bufnr)
	if not ok or not parser then
		return
	end
	local col = M.get_first_nonblank_col_at_line(bufnr, lnum)
	local lang_tree = parser:language_for_range({ lnum, col, lnum, col })
	if lang_tree then
		return M.get_ft_from_parser(lang_tree:lang())
	end
end

return M
