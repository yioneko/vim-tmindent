let s:basic_rules_raw = {
      \   '&{}': #{
      \     increase: ['{[^}]*$'],
      \     decrease: ['^}'],
      \   },
      \   '&[]': #{
      \     increase: ['\[[^\]]*$'],
      \     decrease: ['^\]'],
      \   },
      \   '&()': #{
      \     increase: ['([^)]*$'],
      \     decrease: ['^)'],
      \   },
      \   '&<>': #{
      \     increase: ['<[^>]*$'],
      \     decrease: ['^>'],
      \   },
      \   '&tag': #{
      \     increase: [
      \       '\v\<(%(area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr))@!([\-_\.A-Za-z0-9]*)(\s|\>)@=[^\>]*\>(.*\<\/[^/>]*\>)@!$', 
      \       '\v^\>'
      \     ],
      \     decrease: [
      \       '\v^\<\/([\-_\.A-Za-z0-9]*)\s*\>',
      \       '\v^\/>'
      \     ],
      \   },
      \}

let s:default_rule_key = "&default"
let s:default_rule_raw = #{
      \     inherit: ['&{}', '&[]', '&()']
      \}

let s:rules_raw = {
      \   'c': #{
      \     comment: ['^//', '^*'],
      \     inherit: ['&{}', '&()', '&[]'],
      \     increase: ['\v<%(case|default)>.*\:\s*$'],
      \     decrease: ['\v<%(case|default)>.*\:\s*$'],
      \     indentnext: ['\v<%(if|while|for|switch)>((\;)@!.)*$'],
      \   },
      \   'cpp': #{
      \     inherit: ['c'],
      \   },
      \   'lua': #{
      \     comment: ['^--'],
      \     inherit: ['&{}', '&()'],
      \     increase: ['\v<%(if|else|while|for|function|then|do|repeat)>((<%(end|until)>)@!.)*$'],
      \     decrease: ['^\v<%(elseif|else|end|until)>']
      \   },
      \   'vim': #{
      \     comment: ['^"'],
      \     increase: ['\v<%(function|if|else|elseif|while|for|try|catch|finally|augroup)>((<%(endif|endfor|endfunction|endtry|END)>)@!.)*$'],
      \     decrease: ['\v^<%(endif|endfor|endfunction)>', '^augroup\s\+END'],
      \   },
      \   'python': #{
      \     comment: ['^#'],
      \     inherit: ['&{}', '&()', '&[]'],
      \     increase: ['\v<%(def|class|for|if|elif|else|while|try|with|finally|except|async)>.*\:\s*$'],
      \   },
      \   'html': #{
      \     comment: ['^<!--'],
      \     inherit: ['&tag'],
      \   },
      \   'vue': #{
      \     inherit: ['html'],
      \   },
      \   'json': #{
      \     comment: ['^//'],
      \     inherit: ['&{}','&[]'],
      \   },
      \   'css': #{
      \     comment: ['^*'],
      \     inherit: ['&{}'],
      \   },
      \   'less': #{
      \     inherit: ['css'],
      \   },
      \   'scss': #{
      \     inherit: ['css'],
      \   },
      \   'javascript': #{
      \     comment: ['^//', '^*'],
      \     increase: ['\v<%(case|default)>.*\:\s*$'],
      \     decrease: ['\v<%(case|default)>.*\:\s*$'],
      \     inherit: ['&{}', '&()', '&[]'],
      \   },
      \   'typescript': #{
      \     inherit: ['javascript', '&<>'],
      \   },
      \   'javascriptreact': #{
      \     inherit: ['javascript', '&tag'],
      \   },
      \   'typescriptreact': #{
      \     inherit: ['typescript', '&tag'],
      \   },
      \   'rust': #{
      \     comment: ['^//', '^*'],
      \     inherit: ['&{}', '&()', '&[]'],
      \   },
      \   'yaml': #{
      \     comment: ['^#'],
      \     inherit: ['&{}', '&()'],
      \     increase: ['\v(\:|\-)\s?(\&\w+)?$'],
      \   },
      \}

let s:cache_key = g:tmindent
let s:rule_cache = {}

function s:raw_get(lang, conf) abort
  let maybe_basic = get(s:basic_rules_raw, a:lang, v:null)
  if maybe_basic isnot v:null
    return maybe_basic
  endif

  let conf_rules = get(a:conf, "rules", {})
  let maybe_rule = get(conf_rules, a:lang, get(s:rules_raw, a:lang, v:null)) 
  if maybe_rule isnot v:null
    return maybe_rule
  endif

  let default_rule =  get(a:conf, "default_rule", s:default_rule_raw)
  return default_rule
endfunction

function s:get(key, or_build, conf) abort
  if !has_key(s:rule_cache, a:key)
    let rule = s:build(a:or_build, a:conf)
    let s:rule_cache[a:key] = rule
  endif
  return s:rule_cache[a:key]
endfunction

function s:build(raw_rule, conf) abort
  let res = #{
        \ comment: get(a:raw_rule, "comment", []),
        \ increase: get(a:raw_rule, "increase", []),
        \ decrease: get(a:raw_rule, "decrease", []),
        \ unindented: get(a:raw_rule, "unindented", []),
        \ indentnext:  get(a:raw_rule, "indentnext", [])
        \}

  let inherits = get(a:raw_rule, "inherit", [])
  for i in inherits
    let rhs = s:get(i, s:raw_get(i, a:conf), a:conf)

    for p in get(rhs, "comment", [])
      call add(res.comment, p)
    endfor
    for p in get(rhs, "increase", [])
      call add(res.increase, p)
    endfor
    for p in get(rhs, "decrease", [])
      call add(res.decrease, p)
    endfor
    for p in get(rhs, "unindented", [])
      call add(res.unindented, p)
    endfor
    for p in get(rhs, "indentnext", [])
      call add(res.indentnext, p)
    endfor
  endfor

  return res
endfunction

function tmindent#rules#get(lang) abort
  let user_conf = g:tmindent
  if user_conf isnot s:cache_key
    let s:cache_key = user_conf
    let s:rule_cache = {}
  endif

  return s:get(a:lang, s:raw_get(a:lang, user_conf), user_conf)
endfunction
