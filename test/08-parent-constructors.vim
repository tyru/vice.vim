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


let s:GrandParent = vice#class('GrandParent', s:SID(), {'generate_stub': 1})

function! {s:GrandParent.constructor()}(this)
    Diag "GrandParent's constructor"
    let a:this.grandparent = 1
endfunction


let s:Parent = vice#class('Parent', s:SID(), {'generate_stub': 1})
call s:Parent.extends(s:GrandParent)

function! {s:Parent.constructor()}(this)
    Diag "Parent's constructor"
    let a:this.parent = 1
endfunction


let s:Child = vice#class('Child', s:SID(), {'generate_stub': 1})
call s:Child.extends(s:Parent)

function! {s:Child.constructor()}(this)
    Diag "Child's constructor"
    let a:this.child = 1
endfunction


function! s:run()
    let parent = s:Parent.new()
    Ok has_key(parent, 'parent'), 'parent has .parent'
    Ok has_key(parent, 'grandparent'), 'parent has .grandparent'

    let child = s:Child.new()
    Ok has_key(child, 'child'), 'child has .child'
    Ok has_key(child, 'parent'), 'child has .parent'
    Ok has_key(child, 'grandparent'), 'child has .grandparent'
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

