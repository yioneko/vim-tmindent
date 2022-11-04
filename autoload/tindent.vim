let s:rule_setup = v:false

function s:jsregex_available() abort
  return luaeval("require('tindent').jsregex_available()")
endfunction

function s:setup_rules() abort
  if s:rule_setup
    return
  endif
  let s:rule_setup = v:true

  if !has_key(g:tindent, "rules")
    " TODO: how to translate js regex to vim ? (max 10 capture group limit)
    let g:tindent.rules = #{
      \ lua: #{ increase_pattern: '^\(\(\%(--\)\@!\).\)*\(\(\<\%(else\|function\|then\|do\|repeat\)\>\(\(\<\%(end\|until\)\>\)\@!.\)*\)\|\({\s*\)\)$', decrease_pattern: '^\s*\(\(\<\%(elseif\|else\|end\|until\)\>\)\|}\)' },
      \ }
  endif

  if !has_key(g:tindent, "default_rule")
    " TODO
    let g:tindent.default_rule = #{ increase_pattern: "", decrease_pattern: "" }
  endif
endfunction

function s:test_rule(lang, pattern_key, line) abort
  call s:setup_rules()

  if g:tindent.use_jsregex()
    return luaeval("require('tindent').test_rule(_A[1], _A[2], _A[3])", [a:lang, a:pattern_key, a:line])
  else
    let rule = get(g:tindent, "overrides_".a:lang, get(g:tindent.rules, a:lang, g:tindent.default_rule))
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
    return luaeval("require('tindent').get_buf_indent(_A[1], _A[2])", [a:buf, a:lnum - 1])
  endif

  if bufnr() != buf
    echo "[tindent]: Warning! The indent calculation might be wrong as the bufnr doesn't match with the current buffer." 
  endif
  return indent(lnum)
endfunction

function s:get_lang_at_line(buf, lnum) abort
  let lang = getbufvar(a:buf, "&filetype")
  if has('nvim')
    let lang = luaeval("require('tindent').get_lang_at_line(_A[1], _A[2])", [a:buf, a:lnum - 1])
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

  if s:should_increase(lang, prev_line) || s:should_indent_next(lang, prev_line)
    return prev_indent + s:get_shift(a:buf)
  elseif s:should_decrease(lang, prev_line)
    return prev_indent + s:get_buf_indent(a:buf, prev_lnum)
  else
    if prev_lnum == 1
      return prev_indent
    endif

    for i in range(prev_lnum - 1, 1, -1)
      let base = s:get_buf_indent(a:buf, i)
      let line = s:get_buf_line(a:buf, i)
      if s:should_increase(lang, line)
        return base + s:get_shift(a:buf)
      elseif s:should_decrease(lang, line)
        return base
      elseif s:should_indent_next(lang, line)
        let stopline = 0
        for j in range(i - 1, 1, -1)
          if s:should_indent_next(lang, s:get_buf_line(a:buf, j))
            continue
          endif
          let stopline = j
        endfor
        return s:get_buf_indent(a:buf, j + 1)
      endif
    endfor

    return s:get_buf_indent(a:buf, 1)
  endif
endfunction

function tindent#get_indent(lnum, buf) abort
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

function tindent#indentexpr() abort
  return tindent#get_indent(v:lnum, bufnr())
endfunction

function tindent#attach() abort
  if g:tindent.enabled()
    setlocal indentexpr=tindent#indentexpr()
  endif
endfunction
