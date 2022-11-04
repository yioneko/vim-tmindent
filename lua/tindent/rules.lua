local M = {
	rules = {},
	default_rule = {},
}

local jsregexp = require("jsregexp")

function M.overrides(conf, default)
	for lang, patterns in pairs(conf or {}) do
		M.rules[lang] = {}
		for k, pattern in pairs(patterns) do
			local ok, compiled = pcall(jsregexp.compile, pattern, "g")
			if not ok then
				vim.schedule(function()
					vim.notify_once(string.format("[vim-tindent]: Compile regex for %s failed. %s", lang, compiled))
				end)
			else
				M.rules[lang][k] = compiled
			end
		end
	end

	for k, pattern in pairs(default or {}) do
		local ok, compiled = pcall(jsregexp.compile, pattern, "g")
		if not ok then
			vim.schedule(function()
				vim.notify_once(string.format("[vim-tindent]: Compile defauult regex s failed. %s", compiled))
			end)
		else
			M.default_rule[k] = compiled
		end
	end
end

M.overrides({
	lua = {
		increase_pattern = "^((?!(\\-\\-)).)*((\\b(else|function|then|do|repeat)\\b((?!\\b(end|until)\\b).)*)|(\\{\\s*))$",
		decrease_pattern = "^\\s*((\\b(elseif|else|end|until)\\b)|(\\})|(\\)))",
	},
	json = {
		increase_pattern = '({+(?=((\\\\.|[^"\\\\])*"(\\\\.|[^"\\\\])*")*[^"}]*)$)|(\\[+(?=((\\\\.|[^"\\\\])*"(\\\\.|[^"\\\\])*")*[^"\\]]*)$)',
		decrease_pattern = "^\\s*[}\\]],?\\s*$",
	},
	go = {
		increase_pattern = "^.*(\\bcase\\b.*:|\\bdefault\\b:|(\\b(func|if|else|switch|select|for|struct)\\b.*)?{[^}\"'`]*|\\([^)\"'`]*)$",
		decrease_pattern = "^\\s*(\\bcase\\b.*=|\\bdefault\\b:|}[)}]*[),]?|\\)[,]?)$",
	},
	html = {
		increase_pattern = "<(?!\\?|(?:area|base|br|col|frame|hr|html|img|input|keygen|link|menuitem|meta|param|source|track|wbr)\\b|[^>]*\\/>)([-_\\.A-Za-z0-9]+)(?=\\s|>)\\b[^>]*>(?!.*<\\/\\1>)|<!--(?!.*-->)|\\{[^}\"']*$",
		decrease_pattern = "^\\s*(<\\/(?!html)[-_\\.A-Za-z0-9]+\\b[^>]*>|-->|\\})",
	},
	julia = {
		increase_pattern = "^(\\s*|.*=\\s*|.*@\\w*\\s*)[\\w\\s]*(?:[\"'`][^\"'`]*[\"'`])*[\\w\\s]*\\b(if|while|for|function|macro|(mutable\\s+)?struct|abstract\\s+type|primitive\\s+type|let|quote|try|begin|.*\\)\\s*do|else|elseif|catch|finally)\\b(?!(?:.*\\bend\\b[^\\]]*)|(?:[^\\[]*\\].*)$).*$",
		decrease_pattern = "^\\s*(end|else|elseif|catch|finally)\\b.*$",
	},
	ruby = {
		increase_pattern = "^\\s*((begin|class|(private|protected)\\s+def|def|else|elsif|ensure|for|if|module|rescue|unless|until|when|in|while|case)|([^#]*\\sdo\\b)|([^#]*=\\s*(case|if|unless)))\\b([^#\\{;]|(\"|'|/).*\\4)*(#.*)?$",
		decrease_pattern = "^\\s*([}\\]]([,)]?\\s*(#|$)|\\.[a-zA-Z_]\\w*\\b)|(end|rescue|ensure|else|elsif|when|in)\\b)",
	},
	php = {
		increase_pattern = "({(?!.*}).*|\\(|\\[|((else(\\s)?)?if|else|for(each)?|while|switch|case).*:)\\s*((/[/*].*|)?$|\\?>)",
		decrease_pattern = "^(.*\\*\\/)?\\s*((\\})(\\)+[;,])|(\\]\\)*[;,])|\\b(else:)|\\b((end(if|for(each)?|while|switch));))",
	},
	javascript = {
		decrease_pattern = "^((?!.*?/\\*).*\\*/)?\\s*[\\}\\]].*$",
		increase_pattern = "^((?!//).)*(\\{([^}\"'`/]*|(\\t|[ ])*//.*)|\\([^)\"'`/]*|\\[[^\\]\"'`/]*)$",
		unindented_pattern = "^(\\t|[ ])*[ ]\\*[^/]*\\*/\\s*$|^(\\t|[ ])*[ ]\\*/\\s*$|^(\\t|[ ])*[ ]\\*([ ]([^\\*]|\\*(?!/))*)?$",
	},
	typescript = {
		decrease_pattern = "^((?!.*?/\\*).*\\*/)?\\s*[\\}\\]].*$",
		increase_pattern = "^((?!//).)*(\\{([^}\"'`/]*|(\\t|[ ])*//.*)|\\([^)\"'`/]*|\\[[^\\]\"'`/]*)$",
		unindented_pattern = "^(\\t|[ ])*[ ]\\*[^/]*\\*/\\s*$|^(\\t|[ ])*[ ]\\*/\\s*$|^(\\t|[ ])*[ ]\\*([ ]([^\\*]|\\*(?!/))*)?$",
	},
	yaml = {
		increase_pattern = "^\\s*.*(:|-) ?(&amp;\\w+)?(\\{[^}\"']*|\\([^)\"']*)?$",
		decrease_pattern = "^\\s+\\}$",
	},
	latex = {
		increase_pattern = "<(?!\\?|(?:area|base|br|col|frame|hr|html|img|input|keygen|link|menuitem|meta|param|source|track|wbr)\\b|[^>]*\\/>)([-_\\.A-Za-z0-9]+)(?=\\s|>)\\b[^>]*>(?!.*<\\/\\1>)|<!--(?!.*-->)|\\{[^}\"']*$",
		decrease_pattern = "^\\s*(<\\/(?!html)[-_\\.A-Za-z0-9]+\\b[^>]*>|-->|\\})",
	},
	-- from https://github.com/johnsoncodehk/volar/blob/76abcdd5d9457893f50122410a58b2c3145c7dea/extensions/vscode-vue-language-features/languages/vue-language-configuration.json
	vue = {
		increase_pattern = "<(?!\\?|(?:area|base|br|col|frame|hr|html|img|input|keygen|link|menuitem|meta|param|source|track|wbr|script|style)\\b|[^>]*\\/>)([-_\\.A-Za-z0-9]+)(?=\\s|>)\\b[^>]*>(?!\\s*\\()(?!.*<\\/\\1>)|<!--(?!.*-->)|\\{[^}\"']*$",
		decrease_pattern = "^\\s*(<\\/(?!html)[-_\\.A-Za-z0-9]+\\b[^>]*>|-->|\\})",
	},
}, {
	increase_pattern = "^.*\\{[^}\"']*$|^.*\\([^\\)\"']*$",
	decrease_pattern = "^\\s*(\\s*\\/[*].*[*]\\/\\s*)*[})]",
})

M.rules.javascriptreact = M.rules.javascript
M.rules.typescriptreact = M.rules.typescript

return M
