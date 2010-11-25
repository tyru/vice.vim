" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" vice.vim needs to know the SID of where the methods are defined.
function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction


" 'generate_stub' is defaultly 0 for some reasons.
" you can omit the vice#class()'s 3rd argument
" if you like default one.
let s:Foo = vice#class('Foo', s:SID(), {'generate_stub': 1})

function! {s:Foo.method('message')}(self)
    return 'foo'
endfunction


function! s:run()
    let foo = s:Foo.new()
    Is foo.message(), "foo", '`foo.message()` is "foo".'

    let props = filter(sort(keys(foo)), 'v:val[0] != "_"')
    IsDeeply props, ['message'], "`obj` has public methods `.message()`."
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
