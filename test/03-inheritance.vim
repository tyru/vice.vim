" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

let s:VICE_OPTIONS = {'generate_stub': 1}


let s:Parent = vice#class('Parent', s:SID(), s:VICE_OPTIONS)

function! {s:Parent.method('foo')}(self)
    return 'foo'
endfunction

function! {s:Parent.method('bar')}(self)
    try
        call s:Parent.super(a:self, 'bar')
        Ok 0, "`s:Parent.super('bar')` throws an exception"
    catch /\<vice:/
        Ok 1, "`s:Parent.super('bar')` throws an exception"
    endtry
    return 'bar'
endfunction


let s:Child = vice#class('Child', s:SID(), s:VICE_OPTIONS)
call s:Child.extends(s:Parent)

function! {s:Child.method('foo', {'override': 1})}(self)
    try
        let r = s:Child.super(a:self, 'foo')
        Is r, 'foo', '.super() returns "foo".'
        Ok 1, "`s:Child.super('foo')` does not throw an exception"
        return r . 'l'
    catch /\<vice:/
        Ok 0, "`s:Child.super('foo')` does not throw an exception"
        Diag '[' . v:exception . ']::[' . v:throwpoint . ']'
        return 'must not reach here'
    endtry
endfunction

function! {s:Child.method('baz')}(self)
    try
        call s:Child.super(a:self, 'baz')
        Ok 0, "`s:Child.super('baz')` throws an exception"
    catch /\<vice:/
        Ok 1, "`s:Child.super('baz')` throws an exception"
    endtry
    return 'baz'
endfunction


let s:NaughtyChild = vice#class('NaughtyChild', s:SID(), s:VICE_OPTIONS)
call s:NaughtyChild.extends(s:Parent)

try
    " Naughty child, please specify {'override': 1} !
    function! {s:NaughtyChild.method('foo')}(self)
        echoerr "I'm a naughty child."
    endfunction
    Ok 0, "`{'override': 1}` is missing. must throw an exception."
catch /\<vice:/
    Ok 1, "`{'override': 1}` is missing. must throw an exception."
endtry


function! s:run()
    try
        let child = s:Child.new()
        Ok 1, "s:Child.new()"

        " Do tests.
        Is child.foo(), 'fool', 'child.foo() is "fool"'
        Is child.bar(), 'bar', 'child.bar() is "bar"'
        Is child.baz(), 'baz', 'child.bar() is "baz"'
    catch /\<vice:/
        Ok 0, "s:Child.new()"
        Diag '[' . v:exception . ']::[' . v:throwpoint . ']'
    endtry
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
