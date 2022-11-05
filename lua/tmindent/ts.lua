local M = {}

-- These langs are not reliable, faillback to vim filetype
local ambiguous_parser_langs = {
	"javascript",
}

local parser_lang_ft_map = {
	tsx = "typescriptreact",
}

function M.get_parser(bufnr, lang)
	local ok, ts_parser = pcall(require, "nvim-treesitter.parsers")
	if ok then
		return ts_parser.get_parser(bufnr, lang)
	end
	return vim.treesitter.get_parser(bufnr, lang)
end

function M.get_ft_from_parser(parser_lang)
	if vim.tbl_contains(ambiguous_parser_langs, parser_lang) then
		return
	end
	return parser_lang_ft_map[parser_lang] or parser_lang
end

local function pos_cmp(pos1, pos2)
	if pos1[1] == pos2[1] then
		return pos1[2] - pos2[2]
	else
		return pos1[1] - pos2[1]
	end
end

local function range_contains(range1, range2)
	return pos_cmp(range1[1], range2[1]) <= 0 and pos_cmp(range1[2], range2[2]) >= 0
end

function M.get_node_for_range(range, bufnr, named, filter)
	local parser = M.get_parser(bufnr)
	local res

	parser:for_each_tree(function(tstree, lang_tree)
		if res then
			return
		end

		local root = tstree:root()
		local node
		if named then
			node = root:named_descendant_for_range(range[1][1], range[1][2], range[2][1], range[2][2])
		else
			node = root:descendant_for_range(range[1][1], range[1][2], range[2][1], range[2][2])
		end
		local srow, scol = node:start()
		local erow, ecol = node:end_()

		if range_contains({ { srow, scol }, { erow, ecol } }, range) and filter(lang_tree:lang(), node) then
			res = node
		end
	end)

	return res
end

return M
