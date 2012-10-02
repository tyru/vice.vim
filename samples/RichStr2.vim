" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! RichStrNew(...) "{{{
    let default_value = a:0 ? a:1 : ''
    let obj = s:RichStr.new()
    call obj.set(default_value)
    return obj
endfunction "}}}


function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun


let s:RichStr = vice#class('RichStr', s:SID(), {'generate_stub': 1})

" Or Perl's Class::Accessor like accessor.
call s:RichStr.accessor('_str', '')

function! {s:RichStr.method('get')}(this) "{{{
    return a:this._str()
endfunction "}}}

function! {s:RichStr.method('set')}(this, str) "{{{
    return a:this._str(a:str)
endfunction "}}}

function! {s:RichStr.method('prepend')}(this, str) "{{{
    return a:this._str(a:str . a:this._str())
endfunction "}}}

function! {s:RichStr.method('append')}(this, str) "{{{
    return a:this._str(a:this._str() . a:str)
endfunction "}}}

function! {s:RichStr.method('start_with')}(this, str) "{{{
    return stridx(a:this._str(), a:str) ==# 0
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
