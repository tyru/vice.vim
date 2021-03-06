" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


for file in ['RichStr.vim', 'RichStr2.vim']
    echo '---' file '---'
    source `=file`

    let rich_str = RichStrNew()
    " ""
    echo string(rich_str.get())

    call rich_str.set('hoge-')
    " "hoge-"
    echo string(rich_str.get())

    call rich_str.append('fuga-')
    " "hoge-fuga-"
    echo string(rich_str.get())

    " 1
    echo string(rich_str.start_with('hoge'))
endfor


 " Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}} 
