" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! vice#util_class#RichStr#new(...) "{{{
    let default_value = a:0 ? a:1 : ''
    let obj = s:RichStr.new()
    call obj.set(default_value)
    return obj
endfunction "}}}


function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun


let s:RichStr = vice#class('RichStr', s:SID(), {'fn_property': 0})


call s:RichStr.property('_str', '')

function! {s:RichStr.method('get')}(this) "{{{
    return a:this._str.get()
endfunction "}}}

function! {s:RichStr.method('set')}(this, str) "{{{
    return a:this._str.set(a:str)
endfunction "}}}

function! {s:RichStr.method('prepend')}(this, str) "{{{
    return a:this._str.set(a:str . a:this._str.get())
endfunction "}}}

function! {s:RichStr.method('append')}(this, str) "{{{
    return a:this._str.set(a:this._str.get() . a:str)
endfunction "}}}

function! {s:RichStr.method('start_with')}(this, str) "{{{
    return stridx(a:this._str.get(), a:str) ==# 0
endfunction "}}}


if 0

" {'fn_property': 1}
let s:RichStr = vice#class('RichStr', s:SID(), {'fn_property': 1})


call s:RichStr.property('_str', '')

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

endif


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
