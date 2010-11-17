" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! vice#util_class#RichStr#new(...) "{{{
    let default_value = a:0 ? a:1 : ''
    return extend(
    \   s:RichStr.new(),
    \   {'_str': default_value},
    \   'force'
    \)
endfunction "}}}


let s:class = vice#class('RichStr', s:SID_PREFIX)

call s:class.property('_str', '')

function! s:class.get() "{{{
    return self._str.get()
endfunction "}}}

function! s:class.set(str) "{{{
    let self._str.set(a:Value)
endfunction "}}}

function! s:class.prepend(str) "{{{
    let self._str.set(a:Value . self._str.get())
endfunction "}}}

function! s:class.append(str) "{{{
    let self._str.set(self._str.get() . a:Value)
endfunction "}}}

function! s:class.start_with(str) "{{{
    call vice#validate_type(a:Value, type(""))
    return stridx(self._str.get(), a:Value) ==# 0
endfunction "}}}

let s:RichStr = s:class.new()
unlet s:class


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
