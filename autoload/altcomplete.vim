" ============================================================================
" FILE: altcomplete.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" This plugin provides alternative default completion of command arguments
" implemented in Vim Script.
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


" vital import {{{
let s:V = vital#of('altcomplete')
let s:L = s:V.import('Data.List')
let s:P = s:V.import('Process')
" }}}


"variables {{{
let s:BEHAVE_LIST = ['mswin', 'xterm']
let s:PRE_COMMANDS = ['!', '#', '&', '*', '<', '=', '>', '@']
let s:CSCOPE_LIST = ['add', 'find', 'help', 'kill', 'reset', 'show']
let s:ENV_COMMAND = has('win32') ? 'set' : 'env'
let s:PATH_SEPARATOR = has('win32') ? ';' : ':'
let s:EMBEDDED_FUNCTIONS = filter(sort(readfile(expand('<sfile>:h') . '/listfile/function.txt')), 'exists("*" . v:val)')
let s:EVENT_LIST = filter(sort(readfile(expand('<sfile>:h') . '/listfile/event.txt')), 'exists("#" . v:val)')
let s:HISTORY_LIST = [
      \ '/', ':', '=', '>', '?', '@',
      \ 'all', 'cmd', 'debug', 'expr', 'input', 'search'
      \]
let s:SIGN_LIST = ['define', 'jump', 'list', 'place', 'undefine', 'unplace']
let s:SYNTIME_LIST = ['clear', 'off', 'on', 'report']
let s:VAR_DICT = {'b:' : b:, 'g:' : g:, 't:' : t:, 'v:' : v:, 'w:' : w:}
" }}}


function! altcomplete#augroup(arglead, cmdline, cursorpos) " {{{
  let augroups = split(s:redir('augroup')[1 :], '  ')
  return s:filter(augroups, a:arglead)
endfunction " }}}
function! altcomplete#behave(arglead, cmdline, cursorpos) " {{{
  return s:filter(copy(s:BEHAVE_LIST), a:arglead)
endfunction " }}}
function! altcomplete#buffer(arglead, cmdline, cursorpos) " {{{
  let buffers = map(split(s:redir('ls'), "\n"), 'substitute(v:val, "^.\\+\"\\(.\\+\\)\".\\+$", "\\1", "g")')
  return s:filter(buffers, a:arglead)
endfunction " }}}
function! altcomplete#color(arglead, cmdline, cursorpos) " {{{
  let colorlist = sort(map(split(globpath(&runtimepath,
        \ 'colors/*.vim'), "\n"), 'fnamemodify(v:val, ":t:r")'))
  return s:filter(colorlist, a:arglead)
endfunction " }}}
function! altcomplete#command(arglead, cmdline, cursorpos) " {{{
  let commands = s:PRE_COMMANDS + sort(map(split(s:redir('command'),"\n")[1 :],
        \ 'split(v:val[4 :], "\\s\\+")[0]'))
  return s:filter(commands, a:arglead)
endfunction " }}}
function! altcomplete#compiler(arglead, cmdline, cursorpos) " {{{
  let compilers = sort(map(split(s:redir('compiler'), "\n"), 'fnamemodify(v:val, ":t:r")'))
  return s:filter(compilers, a:arglead)
endfunction " }}}
function! altcomplete#cscope(arglead, cmdline, cursorpos) " {{{
  return s:filter(copy(s:CSCOPE_LIST), a:arglead)
endfunction " }}}
function! altcomplete#dir(arglead, cmdline, cursorpos) " {{{
  if a:arglead ==# '~'
    return [expand('~') . '/']
  elseif a:arglead ==# ''
    let dirs = map(filter(split(globpath('./', '*'), "\n"),
          \ 'isdirectory(v:val)'), 'fnameescape(v:val[2 :]) . "/"')
  else
    let dirs = map(filter(split(expand(a:arglead . '*'), "\n"),
          \ 'isdirectory(v:val)'), 'fnameescape(v:val) . "/"')
  endif
  if a:arglead[0] ==# '~'
    let dirs = map(dirs, 'substitute(v:val, "^" . expand("~"), "~", "")')
  endif
  return s:filter(dirs, a:arglead)
endfunction " }}}
function! altcomplete#environment(arglead, cmdline, cursorpos) " {{{
  let envs = map(split(s:P.system(s:ENV_COMMAND), "\n"), 'split(v:val, "=")[0]')
  return s:filter(envs, a:arglead)
endfunction " }}}
function! altcomplete#event(arglead, cmdline, cursorpos) " {{{
  return s:filter(copy(s:EVENT_LIST), a:arglead)
endfunction " }}}
function! altcomplete#expression(arglead, cmdline, cursorpos) " {{{
  let [global_funcs, local_funcs] = s:get_functions()
  let vars = altcomplete#var(a:arglead, a:cmdline, a:cursorpos)
  return s:filter(sort(global_funcs + vars) + local_funcs, a:arglead)
endfunction " }}}
function! altcomplete#file(arglead, cmdline, cursorpos) " {{{
  if a:arglead ==# '~'
    return [expand('~') . '/']
  elseif a:arglead ==# ''
    let files = map(split(globpath('./', '*'), "\n"),
          \ 'fnameescape(v:val[2 :]) . (isdirectory(v:val) ? "/" : "")')
  else
    let files = map(split(expand(a:arglead . '*'), "\n"),
          \ 'fnameescape(v:val) . (isdirectory(v:val) ? "/" : "")')
  endif
  if a:arglead[0] ==# '~'
    let files = map(files, 'substitute(v:val, "^" . expand("~"), "~", "")')
  endif
  return s:filter(files, a:arglead)
endfunction " }}}
function! altcomplete#file_in_path(arglead, cmdline, cursorpos) " {{{
  let files = sort(map(s:L.flatten(map(map(split(&path, ','),
        \ 'v:val[0] ==# "." ? expand("%:p:h") . "/" . v:val : v:val'),
        \ 'split(globpath(v:val, "*"), "\n")'), 1),
        \ 'fnameescape(fnamemodify(v:val, ":t"))'))
  return s:filter(files, a:arglead)
endfunction " }}}
function! altcomplete#filetype(arglead, cmdline, cursorpos) " {{{
  let colorlist = sort(map(split(globpath(&runtimepath, 'ftplugin/*.vim'), "\n"),
        \ 'fnamemodify(v:val, ":t:r")'))
  return s:filter(colorlist, a:arglead)
endfunction " }}}
function! altcomplete#function(arglead, cmdline, cursorpos) " {{{
  let [global_funcs, local_funcs] = s:get_functions()
  return s:filter(global_funcs + local_funcs, a:arglead)
endfunction " }}}
function! altcomplete#highlight(arglead, cmdline, cursorpos) " {{{
  let highlights = sort(map(split(s:redir('highlight'), "\n"), 'split(v:val, "\\s\\+")[0]'))
  return s:filter(highlights, a:arglead)
endfunction " }}}
function! altcomplete#history(arglead, cmdline, cursorpos) " {{{
  return s:filter(copy(s:HISTORY_LIST), a:arglead)
endfunction " }}}
function! altcomplete#locale(arglead, cmdline, cursorpos) " {{{
  if executable('locale')
    let locales = split(s:P.system('locale -a'), "\n")
    return s:filter(locales, a:arglead)
  else
    return []
  endif
endfunction " }}}
function! altcomplete#option(arglead, cmdline, cursorpos) " {{{
  let options = insert(sort(map(filter(split(s:redir('set all'), ' \{3,}\|\n')[3 :],
        \ 'stridx(v:val, "no") != 0'),
        \ 'substitute(stridx(v:val, "=") == -1 ? v:val : matchstr(v:val, "^.\\{-}\\ze="), "^  ", "", "")')), 'all')
  return options
endfunction " }}}
function! altcomplete#shellcmd(arglead, cmdline, cursorpos) " {{{
  let cmds = map(filter(s:L.flatten(map(split($PATH, s:PATH_SEPARATOR),
        \ 'split(globpath(v:val, "*"), "\n")'), 1),
        \ 'executable(v:val) || isdirectory(v:val)'),
        \ 'fnamemodify(v:val, ":t") . (isdirectory(v:val) ? "/" : "")')
  return s:filter(cmds, a:arglead)
endfunction " }}}
function! altcomplete#sign(arglead, cmdline, cursorpos) " {{{
  return s:filter(copy(s:SIGN_LIST), a:arglead)
endfunction " }}}
function! altcomplete#syntime(arglead, cmdline, cursorpos) " {{{
  return s:filter(copy(s:SYNTIME_LIST), a:arglead)
endfunction " }}}
function! altcomplete#syntax(arglead, cmdline, cursorpos) " {{{
  let colorlist = sort(map(split(globpath(&runtimepath, 'syntax/*.vim'), "\n"),
        \ 'fnamemodify(v:val, ":t:r")'))
  return s:filter(colorlist, a:arglead)
endfunction " }}}
function! altcomplete#tag(arglead, cmdline, cursorpos) " {{{
  let tags = map(filter(s:L.flatten(map(tagfiles(), 'readfile(v:val)'), 1),
        \ 'v:val !~# "^!"'), 'substitute(v:val, "\t.*$", "", "")')
  return s:filter(tags, a:arglead)
endfunction " }}}
function! altcomplete#user(arglead, cmdline, cursorpos) " {{{
  if filereadable('/etc/passwd')
    let users = sort(map(split(s:P.system('cat /etc/passwd'), "\n"), 'split(v:val, ":")[0]'))
    return s:filter(users, a:arglead)
  else
    return []
  endif
endfunction " }}}
function! altcomplete#var(arglead, cmdline, cursorpos) " {{{
  if a:arglead =~# '^g:'
    let vars = map(sort(keys(g:)), '"g:" . v:val')
  else
    let vars = sort(s:L.flatten(map(keys(s:VAR_DICT),
          \ 'v:val ==# "g:" ? keys(s:VAR_DICT[v:val]) : map(keys(s:VAR_DICT[v:val]), string(v:val) . " . v:val")'
          \ ), 1))
  endif
  return s:filter(vars, a:arglead)
endfunction " }}}

function! s:filter(candidates, arglead) " {{{
  return filter(a:candidates, 'stridx(tolower(v:val), tolower(a:arglead)) == 0')
endfunction " }}}
function! s:redir(cmd) " {{{
  let str = ''
  redir => str
  execute 'silent!' a:cmd
  redir END
  return str
endfunction " }}}
function! s:get_functions() " {{{
  let functions = sort(map(split(s:redir('function'), "\n"),
        \ 'substitute(v:val[9 :], "(\\@<=.\\+)$", "", "")'))
  let pos = match(functions, '^\a')
  if pos == -1
    return [s:EMBEDDED_FUNCTIONS, functions]
  elseif pos == 0
    return [functions + s:EMBEDDED_FUNCTIONS, []]
  else
    return [sort(functions[pos :] + s:EMBEDDED_FUNCTIONS), functions[: pos - 1]]
  endif
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
