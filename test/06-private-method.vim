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


" NOTE: use this test if someone wants to implement?
Skip 'this feature is not implemented currently.'
\       . 'and will be not.'


let s:Parent = vice#class('Parent', s:SID(), s:VICE_OPTIONS)

function! {s:Parent.method('foo')}(this)
    try
        Is a:this.do_foo(), 'do_foo', 'calling .do_foo()'
    catch
        Ok 0, 'calling .do_foo()'
    endtry
    return 'foo'
endfunction

function! {s:Parent.method('do_foo', {'private': 1})}(this)
    return 'do_foo'
endfunction



let s:Child = vice#class('Child', s:SID(), s:VICE_OPTIONS)
call s:Child.extends(s:Parent)

function! {s:Child.method('do_foo')}(this)
    return 'child'
endfunction



function! s:do_method_name_hiding_test(class_factory)
    try
        let parent = a:class_factory.new()
        Ok 1, "can call public method .foo()"
    catch /\<vice:/
        Ok 0, "can call public method .foo()"
        return
    endtry

    try
        Is parent.foo(), 'foo', 'calling .foo()'
        Ok 1, "can call public method .foo()"
    catch /\<vice:/
        Ok 0, "can call public method .foo()"
    endtry

    try
        Is parent.do_foo(), 'do_foo', 'calling .do_foo()'
        Ok 1, "cannot call private method .do_foo()"
    catch /\<vice:/
        Ok 0, "cannot call private method .do_foo()"
    endtry
endfunction

function! s:run()
    call s:do_method_name_hiding_test(s:Parent)
    call s:do_method_name_hiding_test(s:Child)
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
