local ts = require("tmindent.ts")

local M = {}

local vim_incompt_options = {}

local function get_buf_line(bufnr, lnum)
	return vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, true)[1] or ""
end

local function get_first_nonblank_col_at_line(bufnr, lnum)
	local line = get_buf_line(bufnr, lnum)
	local _, col = string.find(line or "", "^%s*")
	return col or 0
end

function M.get_lang_at_line(bufnr, lnum)
	local ok, parser = pcall(ts.get_parser, bufnr)
	if not ok or not parser then
		return
	end
	local col = get_first_nonblank_col_at_line(bufnr, lnum)
	local lang_tree = parser:language_for_range({ lnum, col, lnum, col })
	if lang_tree then
		local ts_lang = ts.get_ft_from_parser(lang_tree:lang())
		if ts_lang then
			return ts_lang
		end
	end

	return vim.bo[bufnr].filetype
end

function M.get_buf_indent(bufnr, lnum)
	return vim.api.nvim_buf_call(bufnr, function()
		return vim.fn.indent(lnum + 1)
	end)
end

local comment_langs = {
	"comment",
	"jsdoc",
}

local comment_nodes = {
	"comment",
	"description",
	"block_comment",
}

function M.is_comment_lang(lang)
	return vim.tbl_contains(comment_langs, lang)
end

function M.get_buf_line_comment_trimed(bufnr, lnum)
	local line = get_buf_line(bufnr, lnum)
	local comment_filter = function(lang, node)
		return vim.tbl_contains(comment_nodes, node:type())
	end
	local rcol = #line
	local node = ts.get_node_for_range({ { lnum, rcol - 1 }, { lnum, rcol } }, bufnr, true, comment_filter)
	if node then
		if node:start() == lnum then
			local _, lcol = node:start()
			return line:sub(1, lcol)
		else
			return ""
		end
	end
	return line
end

function M.should_use_treesitter()
	if vim_incompt_options.use_treesitter then
		return vim_incompt_options.use_treesitter()
	end
	return vim.api.nvim_eval("g:tmindent.use_treesitter()")
end

function M.is_enabled()
	if vim_incompt_options.enabled then
		return vim_incompt_options.enabled()
	end
	return vim.api.nvim_eval("g:tmindent.enabled()")
end

function M.get_indent(lnum, bufnr)
	return vim.fn["tmindent#get_indent"](lnum + 1, bufnr)
end

function M.setup(conf)
	if not vim.g.tmindent then
		vim.g.tmindent = vim.empty_dict()
	end

	if conf.default_rule then
		vim.g.tmindent.default_rule = conf.default_rule
	end
	if conf.rules then
		vim.g.tmindent.rules = conf.rules
	end

	vim_incompt_options.enabled = conf.enabled
	vim_incompt_options.use_treesitter = conf.use_treesitter
end

return M
