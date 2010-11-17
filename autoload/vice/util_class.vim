" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! vice#util_class#new(type, ...) "{{{
    let path = 'autoload/vice/util_class/' . a:type . '.vim'
    if globpath(&rtp, path) == ''
        call vice#throw_exception("'" . a:type . "' is not known type.")
    endif
    return call('vice#util_class#' . a:type . '#new', a:000)
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
