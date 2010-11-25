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


let s:Foo = vice#class('Foo', s:SID(), {'generate_stub': 1})

function! {s:Foo.constructor()}(this)
    Diag "Foo's constructor"
    let a:this.foo = 1
endfunction

let s:Bar = vice#class('Bar', s:SID(), {'generate_stub': 1})

function! {s:Bar.constructor()}(this, arg)
    Diag "Bar's constructor"
    Is a:arg, 'bar', "s:Bar's constructor: the 1st arg is 'bar'."
    let a:this.bar = 1
endfunction


function! s:run()
    let foo = s:Foo.new()
    let has_key = has_key(foo, 'foo')
    Ok has_key, 'foo has .foo'
    if has_key
        Is foo.foo, 1, 'foo.foo is 1'
    endif
    IsDeeply foo, {'foo': 1}, "foo is {'foo': 1}"


    let bar = s:Bar.new('bar')
    let has_key = has_key(bar, 'bar')
    Ok has_key, 'bar has .bar'
    if has_key
        Is bar.bar, 1, 'bar.bar is 1'
    endif
    IsDeeply bar, {'bar': 1}, "bar is {'bar': 1}"
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

