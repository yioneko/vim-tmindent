let s:rule_setup = v:false

function s:jsregex_available() abort
  return luaeval("require('tmindent').jsregex_available()")
endfunction

function s:setup_rules() abort
  if s:rule_setup
    return
  endif
  let s:rule_setup = v:true

  if !has_key(g:tmindent, "rules")
    " TODO: how to translate js regex to vim ? (max 10 capture group limit)
    let g:tmindent.rules = #{
      \ lua: #{ increase_pattern: '^\(\(\%(--\)\@!\).\)*\(\(\<\%(else\|function\|then\|do\|repeat\)\>\(\(\<\%(end\|until\)\>\)\@!.\)*\)\|\({\s*\)\)$', decrease_pattern: '^\s*\(\(\<\%(elseif\|else\|end\|until\)\>\)\|}\)' },
      \ }
  endif

  if !has_key(g:tmindent, "default_rule")
    " TODO
    let g:tmindent.default_rule = #{ increase_pattern: "", decrease_pattern: "" }
  endif
endfunction

function s:test_rule(lang, pattern_key, line) abort
  call s:setup_rules()

  if g:tmindent.use_jsregex()
    return luaeval("require('tmindent').test_rule(_A[1], _A[2], _A[3])", [a:lang, a:pattern_key, a:line])
  else
    let rule = get(g:tmindent, "overrides_".a:lang, get(g:tmindent.rules, a:lang, g:tmindent.default_rule))
    return has_key(rule, key) && a:line =~# rule[key]
  endif
endfunction

function s:get_shift(buf) abort
  let shiftwidth = getbufvar(a:buf, "&shiftwidth")
  if shiftwidth <= 0
    return getbufvar(a:buf, "&tabstop")
  endif
  return shiftwidth
endfunction

function s:get_buf_line(buf, lnum) abort
  return getbufline(a:buf, a:lnum)[0]
endfunction

function s:get_buf_indent(buf, lnum) abort
  if has('nvim')
    return luaeval("require('tmindent').get_buf_indent(_A[1], _A[2])", [a:buf, a:lnum - 1])
  endif

  if bufnr() != buf
    echo "[tmindent]: Warning! The indent calculation might be wrong as the bufnr doesn't match with the current buffer." 
  endif
  return indent(lnum)
endfunction

function s:get_lang_at_line(buf, lnum) abort
  let lang = getbufvar(a:buf, "&filetype")
  if has('nvim')
    let lang = luaeval("require('tmindent').get_lang_at_line(_A[1], _A[2])", [a:buf, a:lnum - 1])
  endif
  return lang
endfunction

function s:should_ignore(lang, text) abort
  return s:test_rule(a:lang, "unindented_pattern", a:text)
endfunction

function s:should_increase(lang, text) abort
  return s:test_rule(a:lang, "increase_pattern", a:text)
endfunction

function s:should_indent_next(lang, text) abort
  return s:test_rule(a:lang, "indent_next_pattern", a:text)
endfunction

function s:should_decrease(lang, text) abort
  return s:test_rule(a:lang, "decrease_pattern", a:text)
endfunction

function s:get_prev_valid_line(buf, lnum) abort
  let cur_lang = s:get_lang_at_line(a:buf, a:lnum)

  if a:lnum > 1
    let result_lnum = 0
    for i in range(a:lnum - 1, 1, -1)
      if s:get_lang_at_line(a:buf, i) != cur_lang
        return result_lnum
      endif

      let line = s:get_buf_line(a:buf, i)
      if !s:should_ignore(cur_lang, line) && line !~# '^\s*$'
        return i
      endif

      let result_lnum = i
    endfor

    return result_lnum
  endif
endfunction

function s:get_inherit_indent_for_line(buf, lnum) abort
  let lang = s:get_lang_at_line(a:buf, a:lnum)

  let prev_lnum = s:get_prev_valid_line(a:buf, a:lnum)
  if prev_lnum < 1
    return 0
  endif
  let prev_line = s:get_buf_line(a:buf, prev_lnum)
  let prev_indent = s:get_buf_indent(a:buf, prev_lnum)

  echo prev_line prev_indent
  if s:should_increase(lang, prev_line) || s:should_indent_next(lang, prev_line)
    echo "!"
    return prev_indent + s:get_shift(a:buf)
  elseif s:should_decrease(lang, prev_line)
    echo "?"
    return prev_indent
  else
    if prev_lnum == 1
      return prev_indent
    endif

    for i in range(prev_lnum - 1, 1, -1)
      if !s:should_indent_next(lang, i)
        echo i
        return s:get_buf_indent(a:buf, i + 1)
      endif
    endfor

    return s:get_buf_indent(a:buf, 1)
  endif
endfunction

function tmindent#get_indent(lnum, buf) abort
  let buf = a:buf == v:null ? bufnr() : a:buf
  let lang = s:get_lang_at_line(a:buf, a:lnum)

  let indent = s:get_inherit_indent_for_line(buf, a:lnum)
  let line = s:get_buf_line(buf, a:lnum)

  if s:should_decrease(lang, line)
    return indent - s:get_shift(buf)
  else
    return indent
  endif
endfunction

function tmindent#indentexpr() abort
  return tmindent#get_indent(v:lnum, bufnr())
endfunction

function tmindent#attach() abort
  if g:tmindent.enabled()
    setlocal indentexpr=tmindent#indentexpr()
  endif
endfunction
