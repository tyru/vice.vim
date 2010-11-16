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
    let obj._meta.class_name = a:class_name
    let obj._meta._parent_obj = obj    " FIXME: recursive reference.

    return obj
endfunction "}}}


let s:meta_object = {
\   'type': {},
\}

" Returns function method name.
function! s:meta_object.method(name) "{{{
endfunction "}}}

" Create property.
function! s:meta_object.property(name, ...) "{{{
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
