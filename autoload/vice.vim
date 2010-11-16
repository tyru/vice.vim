" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! vice#new(class_name) "{{{
    let obj = {}

    function obj.new()
        return deepcopy(self)
    endfunction

    let obj._meta = deepcopy(s:meta_object)
    let obj._meta._class_name = a:class_name
    let obj._meta._parent_obj = obj    " FIXME: recursive reference.

    return obj
endfunction "}}}


function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
let s:SID_PREFIX = s:SID()
delfunc s:SID

function! s:local_func(name) "{{{
    return '<SNR>' . s:SID_PREFIX . '_' . a:name
endfunction "}}}


let s:meta_object = {
\   'type': {},
\}

" Returns function method name.
function! s:meta_object.method(name) "{{{
    " TODO: Create method onto caller script scope.
    return s:local_func(self._class_name . '_method_' . a:name)
endfunction "}}}

" Create member (more primitive than property).
function! s:meta_object.member(name, Default) "{{{
    let parent = self._parent_obj
    let parent[a:name] = a:Default
endfunction "}}}

" Create property.
function! s:meta_object.property(name, ...) "{{{
    " TODO
endfunction "}}}

" Create subtype local to vice#new() object.
" a:1 is base type (if derived).
function! s:meta_object.subtype(name, ...) "{{{
    if !has_key(self.type, a:name)
        let self.type[a:name] = {}
    endif
    return self.type[a:name]
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
