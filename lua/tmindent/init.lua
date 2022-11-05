local ts_compat = require("tmindent.ts_compat")

local M = {}

local function get_buf_line(bufnr, lnum)
	return vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, true)[1] or ""
end

local function get_first_nonblank_col_at_line(bufnr, lnum)
	local line = get_buf_line(bufnr, lnum)
	local _, col = string.find(line or "", "^%s*")
	return col or 0
end

function M.get_lang_at_line(bufnr, lnum)
	local ok, parser = pcall(ts_compat.get_parser, bufnr)
	if not ok or not parser then
		return
	end
	local col = get_first_nonblank_col_at_line(bufnr, lnum)
	local lang_tree = parser:language_for_range({ lnum, col, lnum, col })
	if lang_tree then
		local ts_lang = ts_compat.get_ft_from_parser(lang_tree:lang())
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

function M.setup(conf)
	if conf.use_jsregex ~= nil then
		vim.g.tmindent.use_jsregex = conf.use_jsregex
	end
	if conf.enabled ~= nil then
		vim.g.tmindent.enabled = conf.enabeld
	end
end

return M
