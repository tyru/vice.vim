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
let s:VICE_OPTIONS = {'generate_stub': 1}


let s:IDecorate = vice#trait('IDecorate', s:SID(), s:VICE_OPTIONS)

function! {s:IDecorate.method('emphasize')}(self)
    return '*' . a:self.message() . '*'
endfunction

function! {s:IDecorate.method('quote')}(self)
    return '> ' . a:self.message()
endfunction

function! s:IDecorate.requires()
    return ['message']
endfunction


let s:Foo = vice#class('Foo', s:SID(), s:VICE_OPTIONS)
call s:Foo.with(s:IDecorate)

function! {s:Foo.method('message')}(self)
    return 'foo'
endfunction


let s:Bar = vice#class('Bar', s:SID(), s:VICE_OPTIONS)
call s:Bar.with(s:IDecorate)

function! {s:Bar.method('message')}(self)
    return 'bar'
endfunction



function! s:run()
    let foo = s:Foo.new()
    Is foo.emphasize(), '*foo*', '*foo*'
    Is foo.quote(), '> foo', '> foo'
    Is foo.message(), 'foo', '> foo'

    let bar = s:Bar.new()
    Is bar.emphasize(), '*bar*', '*bar*'
    Is bar.quote(), '> bar', '> bar'
    Is bar.message(), 'bar', '> bar'

    for obj in [foo, bar]
        let props = filter(sort(keys(obj)), 'v:val[0] != "_"')
        IsDeeply props, ['clone', 'emphasize', 'message', 'quote'], "`obj` has public methods `.clone()`, `.emphasize()`, `.message()`, `.quote()`."
    endfor
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
