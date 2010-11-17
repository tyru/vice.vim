" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! vice#class(class_name, namespace, ...) "{{{
    " a:namespace is currently just a SID.
    let obj = deepcopy(s:object)
    if a:0 && has_key(a:1, 'parent')
        " Currently `derive` means just doing extend().
        call extend(obj, a:1.parent, 'keep')
    endif
    return extend(
    \   deepcopy(s:class_factory),
    \   {
    \       '_class_name': a:class_name,
    \       '_namespace' : a:namespace,
    \       '_object'    : obj,
    \       '_builders'  : [],
    \   },
    \   'force'
    \)
endfunction "}}}

function! vice#throw_exception(msg) "{{{
    throw 'vice: ' . a:msg
endfunction "}}}

function! vice#validate_type(Value, expected) "{{{
    let type_id = type(a:Value)
    if type_id !=# a:expected
        call vice#throw_exception(
        \   'type validation failed: '
        \   . 'expected (' . type_id . '), '
        \   . 'got (' . a:expected . ')'
        \)
    endif
endfunction "}}}


function! s:initialize_builtin_types() "{{{
    function vice#class('Dict', s:SID_PREFIX).where(Value)
        return type(a:Value) == type({})
    endfunction

    function vice#class('List', s:SID_PREFIX).where(Value)
        return type(a:Value) == type([])
    endfunction

    function vice#class('Num', s:SID_PREFIX).where(Value)
        return type(a:Value) == type(0)
        \   || type(a:Value) == type(0.0)
    endfunction

    function vice#class('Int', s:SID_PREFIX, {'parent': 'Num'}).where(Value)
        return type(a:Value) == type(0)
    endfunction

    function vice#class('Float', s:SID_PREFIX, {'parent': 'Num'}).where(Value)
        return type(a:Value) == type(0.0)
    endfunction

    function vice#class('Str', s:SID_PREFIX).where(Value)
        return type(a:Value) == type("")
    endfunction

    function vice#class('Fn', s:SID_PREFIX).where(Value)
        return type(a:Value) == type(function('tr'))
    endfunction
endfunction "}}}



let s:object = {}
function! s:object.new() "{{{
    return deepcopy(self)
endfunction "}}}



" See vice#class() for constructor.
let s:class_factory = {}

function! s:class_factory.new() "{{{
    for builder in self._builders
        call builder.build()
    endfor
    return deepcopy(self._object)
endfunction "}}}

function! s:class_factory.method(name) "{{{
    let real_name = self._class_name . '_' . a:name

    " The function `real_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'object': self._object,
    \   'real_name': '<SNR>' . self._namespace. '_' . real_name,
    \   'method_name': a:name,
    \}
    function! builder.build()
        " NOTE: Currently allows to override.
        let self.object[self.method_name] = function(self.real_name)
    endfunction
    call add(self._builders, builder)

    return 's:' . real_name
endfunction "}}}

function! s:class_factory.has(name, ...) "{{{
    let self._object[a:name] = {'_name': a:name}
    if has_key(self, 'where')
        let self._object[a:name].where = self.where
    endif

    function! self._object[a:name].get()
        return copy(self._value)
    endfunction

    function! self._object[a:name].set(Value)
        if has_key(self, 'where') && !self.where(a:Value)
            call vice#throw_exception(
            \   ':' . self._name . ' : received invalid type.')
        endif
        let self._value = a:Value
    endfunction
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
