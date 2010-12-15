" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction



let g:Regexp = vice#class('Regexp', s:SID(), {'generate_stub': 1})

call g:Regexp.attribute('_pattern', '')
call g:Regexp.attribute('_matchlist', [])

function! {g:Regexp.constructor()}(this, pattern) "{{{
    let a:this._pattern = a:pattern
endfunction "}}}
function! {g:Regexp.method('match')}(this, str) "{{{
    let a:this._matchlist = matchlist(a:str, a:this._pattern)
    return !empty(a:this._matchlist)
endfunction "}}}
function! {g:Regexp.method('group')}(this, nr, ...) "{{{
    return get(a:this._matchlist, a:nr + 1, a:0 ? a:1 : 0)
endfunction "}}}
function! {g:Regexp.method('grouplist')}(this, ...) "{{{
    return a:this._matchlist[1 : a:0 ? a:1 : -1]
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
