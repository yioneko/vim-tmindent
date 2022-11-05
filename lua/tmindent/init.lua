local ts_compat = require("tmindent.ts_compat")
local r = require("tmindent.rules")

local M = {}

function M.jsregex_available()
	return pcall(require, "jsregexp")
end

function M.test_rule(lang, pattern_key, line)
	local lang_rule = vim.g.tmindent["overrides_" .. lang]
	if not lang_rule then
		lang_rule = r.rules[lang] or r.default_rule
	end
	local compiled = lang_rule[pattern_key]
	if compiled then
		local matches = compiled(line)
		return not vim.tbl_isempty(matches)
	end

	return false
end

function M.get_lang_at_line(bufnr, lnum)
	local ts_lang = ts_compat.get_lang_at_line_ts(bufnr, lnum)
	if ts_lang then
		return ts_lang
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
	r.overrides(conf.overrides, conf.default_rule)
end

return M
