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
let s:VICE_OPTIONS = {'generate_stub': 1}



let s:TFoo = vice#trait('TFoo', s:SID(), s:VICE_OPTIONS)
try
    call s:TFoo.new()
    Ok 0, "trait can't be instantiated"
catch /\<vice:/
    Ok 1, "trait can't be instantiated"
endtry


let s:TFooNonEmpty = vice#trait('TFooNonEmpty', s:SID(), s:VICE_OPTIONS)

function! {s:TFooNonEmpty.method('foo')}(this)
    Doing something foolish
endfunction

try
    call s:TFooNonEmpty.new()
    Ok 0, "also non-empty trait can't be instantiated"
catch /\<vice:/
    Ok 1, "also non-empty trait can't be instantiated"
endtry


let s:Klass = vice#class('Klass', s:SID(), s:VICE_OPTIONS)
call s:Klass.with(s:TFoo)

function! {s:Klass.method('foo')}(this)
    return 'foo'
endfunction

try
    let klass = s:Klass.new()
    Is klass.foo(), 'foo', 'calling klass.foo()'
    Ok 1, "class which inherits from trait can be instantiated"
catch /\<vice:/
    Ok 0, "class which inherits from trait can be instantiated"
endtry


Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
