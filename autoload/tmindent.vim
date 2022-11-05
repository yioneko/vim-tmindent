function s:get_shift(buf) abort
  let shiftwidth = getbufvar(a:buf, "&shiftwidth")
  if shiftwidth <= 0
    return getbufvar(a:buf, "&tabstop")
  endif
  return shiftwidth
endfunction

function s:get_buf_line_trimed(buf, lnum, lang) abort
  let line = trim(getbufline(a:buf, a:lnum)[0])
  let comment_start = len(line)
  for pat in get(tmindent#rules#get(a:lang), "comment", [])
    let matched_idx = match(line, pat)
    if matched_idx != -1 && matched_idx < comment_start
      let comment_start = matched_idx
    endif
  endfor
  return strpart(line, 0, comment_start)
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
  for pat in get(tmindent#rules#get(a:lang), "unindented", [])
    if a:text =~# pat
      return v:true
    endif
  endfor
  return v:false
endfunction

function s:should_increase(lang, text) abort
  for pat in get(tmindent#rules#get(a:lang), "increase", [])
    echo a:text =~# pat
    if a:text =~# pat
      return v:true
    endif
  endfor
  return v:false
endfunction

function s:should_indent_next(lang, text) abort
  for pat in get(tmindent#rules#get(a:lang), "indentnext", [])
    if a:text =~# pat
      return v:true
    endif
  endfor
  return v:false
endfunction

function s:should_decrease(lang, text) abort
  for pat in get(tmindent#rules#get(a:lang), "decrease", [])
    if a:text =~# pat
      return v:true
    endif
  endfor
  return v:false
endfunction

function s:get_prev_valid_line(buf, lnum) abort
  let cur_lang = s:get_lang_at_line(a:buf, a:lnum)

  if a:lnum > 1
    let result_lnum = 0
    for i in range(a:lnum - 1, 1, -1)
      let prev_lang = s:get_lang_at_line(a:buf, i)
      " TODO: ts comment lang
      if prev_lang != "comment" && prev_lang != cur_lang
        return result_lnum
      endif

      let line = s:get_buf_line_trimed(a:buf, i, cur_lang)
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
  let prev_line = s:get_buf_line_trimed(a:buf, prev_lnum, lang)
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
  " TODO: comment lang
  let lang = s:get_lang_at_line(a:buf, a:lnum)

  let indent = s:get_inherit_indent_for_line(buf, a:lnum)
  let line = s:get_buf_line_trimed(buf, a:lnum, lang)

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
