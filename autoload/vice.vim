" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! vice#new(class_name, caller_sid) "{{{
    let obj = {}

    function obj.new()
        return deepcopy(self)
    endfunction

    let obj._meta = deepcopy(s:meta_object)
    let obj._meta._class_name = a:class_name
    let obj._meta._parent_obj = obj    " FIXME: recursive reference.
    let obj._meta._caller_sid = a:caller_sid

    return obj
endfunction "}}}


function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
let s:SID_PREFIX = s:SID()
delfunc s:SID


let s:meta_object = {
\   '_type': {},
\   '_builders': [],
\}

" Returns function method name.
function! s:meta_object.method(name) "{{{
    let real_name = self._class_name . '_method_' . a:name
    let builder = {
    \   'method_name': a:name,
    \   'parent': self._parent_obj,
    \   'real_name': '<SNR>' . self._caller_sid . '_' . real_name,
    \}
    function builder.build()
        let self.parent[self.method_name] = function(self.real_name)
    endfunction
    call add(self._builders, builder)

    return 's:' . real_name
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
    if !has_key(self._type, a:name)
        let self._type[a:name] = {}
    endif
    return self._type[a:name]
endfunction "}}}

" Build vice#new() object.
function! s:meta_object.build() "{{{
    for builder in self._builders
        call builder.build()
    endfor
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
