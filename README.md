vim-altcomplete
===============

This plugin provides alternative default completion of command arguments
implemented in Vim Script.

Vim provides some default completion of command argument.
For example ```-complete=augroup```, ```-complete=buffer```, and so on.
But we cannot combine default completion and user-defined completion.
This plugin enables to combine them.


## Examples

```vim
" Example 01
command! -nargs=1 -complete=customlist,altcomplete#var Example01  echo <args>

" Example 02
function! s:example02(ArgLead, CmdLine, CursorPos)
  return ['aaa', 'bbb', 'ccc'] + altcomplete#var(a:ArgLead, a:CmdLine, a:CursorPos)
endfunction
command! -nargs=* -complete=customlist,example02 Example02  echo <q-args>
```


## Progress

- [x] augroup
- [x] buffer
- [x] behave
- [x] color
- [x] command
- [x] compiler
- [x] cscope
- [x] dir
- [x] environment
- [x] event
- [x] expression
- [x] file
- [x] file_in_path
- [x] filetype
- [x] function
- [ ] help
- [x] highlight
- [x] history
- [x] locale
- [ ] mapping
- [ ] menu
- [ ] option
- [x] shellcmd
- [x] sign
- [x] syntax
- [x] syntime
- [x] tag
- [ ] tag_listfiles
- [x] user
- [x] var


## LICENSE

This software is released under the MIT License, see [LICENSE](LICENSE).
