function! s:_vital_loaded(V) abort
  if get(g:, 'vital_vim_save_string_debug', 0)
  \ && a:V.exists('Vim.PowerAssert')
  \ && a:V.exists('Vim.DbC')
    execute a:V.import('Vim.PowerAssert').define('Assert')
    execute a:V.import('Vim.DbC').dbc()
  endif
endfunction

" s:string() convert {expr} to string with nested element support.
" @param {Any} expr
" @return {string}
function! s:string(expr) abort
  if type(a:expr) is# type([])
    return printf('[%s]', join(map(copy(a:expr), 's:string(v:val)'), ', '))
  elseif type(a:expr) is# type({})
    return s:_dict_to_string(a:expr)
  else
    return string(a:expr)
  endif
endfunction

function! s:__pre_string(in) abort
endfunction

function! s:__post_string(in, out) abort
  Assert type(a:out) is# type('')
  if type(a:in.expr) isnot# type([]) && type(a:in.expr) isnot# type({})
    Assert eval(a:out) is# a:in.expr, '{out} should be parsed back with eval()'
  endif
  if type(a:in.expr) isnot# type('') && type(a:in.expr) isnot# type(function('function'))
    Assert a:out is# s:_echo_capture(a:in.expr), '{out} should be same as `:echo`-ing {expr}'
  endif
endfunction

function! s:_dict_to_string(dict, ...) abort
  " `seen` cannot be dict because we cannot hash nested dict!
  let seen = get(a:, 1, [])
  let seen += [a:dict]
  let pairs = []
  for [k, l:V] in items(a:dict)
    if type(l:V) is# type({})
      if index(seen, l:V) !=# -1
        let v_str = '{...}'
      else
        let v_str = s:_dict_to_string(l:V, seen)
      endif
    else
      let v_str = s:string(l:V)
    endif
    let pairs += [printf('%s: %s', string(k), v_str)]
    unlet l:V
  endfor
  return printf('{%s}', join(pairs, ', '))
endfunction

function! s:__pre__dict_to_string(in) abort
  Assert type(a:in.dict) is# type({})
endfunction

function! s:__post__dict_to_string(in, out) abort
  Assert type(a:out) is# type('')
endfunction

function! s:_echo_capture(expr) abort
  let l:Expr = a:expr
  try
    let save_verbose = &verbose
    let &verbose = 0
    redir => out
    silent execute ':echo l:Expr'
  finally
    redir END
    let &verbose = save_verbose
  endtry
  return out[1:]
endfunction

" ---
" let d = {}
" let d.d = d
" let d.e = deepcopy(d.d)
" let b = {}
" let b.b = b
" let d.e.c = b
"
" echo s:string(d)
" echo s:string('hi')
" echo s:string('h"i')
" echo s:string('h''i')
" echo s:string(1)
" echo s:string(1.0)
" echo s:string({'hoge': 'foo'})
" echo s:string([1.0, 'hi', 1, 0, function('function'), {'dict': d}])
" echo s:string([1.0, 'hi'])