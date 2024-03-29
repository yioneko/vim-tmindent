" Currently we cannot assign lua function to vim global varaibles,
" and we have to separate config for vim and nvim here...
function s:should_use_treesitter() abort
  if has("nvim")
    return luaeval("require('tmindent').should_use_treesitter()")
  endif
  return g:tmindent.use_treesitter()
endfunction

function s:is_comment_lang(lang) abort
  return s:should_use_treesitter() && luaeval("require('tmindent').is_comment_lang(_A[1])", [a:lang])
endfunction

function s:get_shift(buf) abort
  let shiftwidth = getbufvar(a:buf, "&shiftwidth")
  if shiftwidth <= 0
    return getbufvar(a:buf, "&tabstop")
  endif
  return shiftwidth
endfunction

function s:get_buf_line_processed(buf, lnum, lang) abort
  let line = trim(getbufline(a:buf, a:lnum)[0])
  if s:should_use_treesitter()
    " trim comment by treesitter if possible
    let line = trim(luaeval("require('tmindent').get_buf_line_comment_trimed(_A[1], _A[2])", [a:buf, a:lnum - 1]))
  endif

  let comment_start = len(line)
  for pat in get(tmindent#rules#get(a:lang), "comment", [])
    let matched_idx = match(line, pat)
    if matched_idx != -1 && matched_idx < comment_start
      let comment_start = matched_idx
    endif
  endfor
  let processed = strpart(line, 0, comment_start)

  for pat in get(tmindent#rules#get(a:lang), "string", [])
    " replace string content with space
    let processed = substitute(processed, pat, { m -> repeat(" ", len(m[0])) }, 'g')
  endfor

  return processed
endfunction

function s:get_buf_indent(buf, lnum) abort
  if has('nvim')
    return luaeval("require('tmindent').get_buf_indent(_A[1], _A[2])", [a:buf, a:lnum - 1])
  elseif bufnr() != a:buf
    echo "[tmindent]: Warning! The indent calculation might be wrong as the bufnr doesn't match with the current buffer." 
  endif

  return indent(a:lnum)
endfunction

function s:get_lang_at_line(buf, lnum) abort
  let lang = getbufvar(a:buf, "&filetype")
  if s:should_use_treesitter()
    let lang = luaeval("require('tmindent').get_lang_at_line(_A[1], _A[2])", [a:buf, a:lnum - 1])
  endif
  return lang
endfunction

function s:get_lang_at_line_exclude_comment(buf, lnum) abort
  let lang = s:get_lang_at_line(a:buf, a:lnum)
  if s:is_comment_lang(lang)
    let lang = getbufvar(a:buf, "&filetype")
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

function s:should_indent_one(lang, text) abort
  for pat in get(tmindent#rules#get(a:lang), "indentone", [])
    if a:text =~# pat
      return v:true
    endif
  endfor
  return v:false
endfunction

function s:get_prev_valid_line(buf, lnum) abort
  let cur_lang = s:get_lang_at_line_exclude_comment(a:buf, a:lnum)

  if a:lnum > 1
    let result_lnum = 0
    for i in range(a:lnum - 1, 1, -1)
      let prev_lang = s:get_lang_at_line(a:buf, i)
      if !s:is_comment_lang(prev_lang) && prev_lang != cur_lang
        return result_lnum
      endif

      let line = s:get_buf_line_processed(a:buf, i, cur_lang)
      " Special case: c multiline indent start
      if s:is_comment_lang(prev_lang) && s:should_indent_one(cur_lang, line)
        return i
      endif

      if !s:should_ignore(cur_lang, line) && line !~# '^\s*$'
        return i
      endif

      let result_lnum = i
    endfor

    return result_lnum
  endif
endfunction

function s:get_inherit_indent_for_line(buf, lnum) abort
  let lang = s:get_lang_at_line_exclude_comment(a:buf, a:lnum)

  let prev_lnum = s:get_prev_valid_line(a:buf, a:lnum)
  if prev_lnum < 1
    return 0
  endif
  let prev_line = s:get_buf_line_processed(a:buf, prev_lnum, lang)
  let prev_indent = s:get_buf_indent(a:buf, prev_lnum)

  if s:should_indent_one(lang, prev_line)
    return prev_indent + 1
  elseif s:should_increase(lang, prev_line) || s:should_indent_next(lang, prev_line)
    return prev_indent + s:get_shift(a:buf)
  elseif s:should_decrease(lang, prev_line)
    return prev_indent
  else
    if prev_lnum == 1
      return prev_indent
    endif

    for i in range(prev_lnum - 1, 1, -1)
      let prev_lang = s:get_lang_at_line(a:buf, i)
      if s:is_comment_lang(prev_lang)
        continue
        " TODO: indentkeys elseif
      elseif prev_lang != lang
        return s:get_buf_indent(a:buf, i)
      elseif !s:should_indent_next(lang, s:get_buf_line_processed(a:buf, i, prev_lang))
        return s:get_buf_indent(a:buf, i + 1)
      endif
    endfor

    return s:get_buf_indent(a:buf, 1)
  endif
endfunction

function tmindent#get_indent(lnum, buf) abort
  let buf = a:buf == v:null ? bufnr() : a:buf

  let lang = s:get_lang_at_line_exclude_comment(a:buf, a:lnum)
  let line = s:get_buf_line_processed(buf, a:lnum, lang)

  if s:should_ignore(lang, line)
    return 0
  else
    let indent = s:get_inherit_indent_for_line(buf, a:lnum)

    if s:should_decrease(lang, line)
      let indent = indent - s:get_shift(buf)
    endif

    " deal with python indent, the calculated indent result should be viewed as the
    " maximum indent, respect the current indent of nonblank line if possible
    if get(tmindent#rules#get(lang), "indentasmax", v:false) && line !~# '^\s*$'
      let cur_indent = s:get_buf_indent(buf, a:lnum)
      return min([indent, cur_indent])
    else
      return indent
    endif
  endif
endfunction

function tmindent#indentexpr() abort
  return tmindent#get_indent(v:lnum, bufnr())
endfunction
