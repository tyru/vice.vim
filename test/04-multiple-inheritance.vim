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


let s:ParentA = vice#class('ParentA', s:SID(), s:VICE_OPTIONS)
let s:ParentB = vice#class('ParentB', s:SID(), s:VICE_OPTIONS)
let s:Child = vice#class('Child', s:SID(), s:VICE_OPTIONS)

try
    call s:Child.extends(s:ParentA)
    Ok 1, ".extends() does not throw an exception"
catch /\<vice:/
    Ok 0, ".extends() does not throw an exception"
endtry

try
    call s:Child.extends(s:ParentB)
    Ok 0, ".extends() throws an exception: multiple inheritance"
catch /\<vice:/
    Ok 1, ".extends() throws an exception: multiple inheritance"
endtry


Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
