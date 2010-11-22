" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! vice#class(class_name, sid) "{{{
    let obj = deepcopy(s:SkeletonObject)
    return extend(
    \   deepcopy(s:ClassFactory),
    \   {
    \       '_class_name': a:class_name,
    \       '_sid': a:sid,
    \       '_object': obj,
    \       '_builders': [],
    \       '_super': [],
    \   },
    \   'force'
    \)
endfunction "}}}

" s:SkeletonObject {{{
let s:SkeletonObject = {}
function! s:SkeletonObject.new() "{{{
    return deepcopy(self)
endfunction "}}}
" }}}

" s:ClassFactory {{{
" See vice#class() for constructor.
let s:ClassFactory = {}

function! s:ClassFactory.new() "{{{
    if has_key(self, '_builders')
        for builder in self._builders
            call builder.build(self._object)
        endfor
        unlet self._builders
    endif
    return deepcopy(self._object)
endfunction "}}}

function! s:ClassFactory.method(method_name) "{{{
    let class_name = self._class_name
    let real_name = class_name . '_' . a:method_name

    " The function `real_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'real_name': '<SNR>' . self._sid . '_' . real_name,
    \   'method_name': a:method_name,
    \}
    function! builder.build(object)
        " Create a stub for `self.real_name`.
        " NOTE: Currently allows to override.
        execute join([
        \   'function! a:object[' . string(self.method_name) . '](...)',
        \       'call call(' . string(self.real_name) . ', [self] + a:000)',
        \   'endfunction',
        \], "\n")
    endfunction
    call add(self._builders, builder)

    return 's:' . real_name
endfunction "}}}

function! s:ClassFactory.extends(parent_factory) "{{{
    let builder = {'parent': a:parent_factory}
    function builder.build(object)
        " Current inheritance implementation is just doing extend().
        call extend(a:object, self.parent, 'keep')
        call add(a:object._super, self.parent)
    endfunction
    call add(self._builders, builder)

    return self
endfunction "}}}

function! s:ClassFactory.super(...) "{{{
    if len(self._super) == 1
        return self._super[0]
    endif
    if a:0 && type(a:1) == type("")
        " Look up the parent class by name.
        for super in self._super
            if super._class_name ==# a:1
                return super
            endif
        endfor
    endif
    return self._super
endfunction "}}}

function! s:ClassFactory.property(property_name, Value) "{{{
    let builder = {'name': a:property_name, 'value': a:Value}
    function builder.build(object)
        " Create a property.
        let a:object[self.name] = extend(
        \   deepcopy(s:SkeletonProperty),
        \   {'_value': self.value},
        \   'error'
        \)
    endfunction
    call add(self._builders, builder)
endfunction "}}}
" s:SkeletonProperty {{{

function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
let s:SID_PREFIX = s:SID()
delfunc s:SID

function! s:get_local_func(function_name) "{{{
    return function('<SNR>' . s:SID_PREFIX . '_' . a:function_name)
endfunction "}}}

function! s:PropertySkeleton_get() dict "{{{
    return self._value
endfunction "}}}

function! s:PropertySkeleton_set(Value) dict "{{{
    let self._value = a:Value
endfunction "}}}

let s:SkeletonProperty = {
\   'get': s:get_local_func('PropertySkeleton_get'),
\   'set': s:get_local_func('PropertySkeleton_set'),
\}
" }}}

" }}}


" TODO: Type constraints
let s:builtin_types = {}

function! s:initialize_builtin_types() "{{{
    let s:builtin_types['Dict[`a]'] = {}
    function s:builtin_types['Dict[`a]'].where(Value)
        return type(a:Value) == type({})
    endfunction

    let s:builtin_types['List[`a]'] = {}
    function s:builtin_types['List[`a]'].where(Value)
        return type(a:Value) == type([])
    endfunction

    let s:builtin_types['Num'] = {}
    function s:builtin_types['Num'].where(Value)
        return type(a:Value) == type(0)
        \   || type(a:Value) == type(0.0)
    endfunction

    let s:builtin_types['Int'] = {'parent': 'Num'}
    function s:builtin_types['Int'].where(Value)
        return type(a:Value) == type(0)
    endfunction

    let s:builtin_types['Float'] = {'parent': 'Num'}
    function s:builtin_types['Float'].where(Value)
        return type(a:Value) == type(0.0)
    endfunction

    let s:builtin_types['Str'] = {}
    function s:builtin_types['Str'].where(Value)
        return type(a:Value) == type("")
    endfunction

    let s:builtin_types['Fn'] = {}
    function s:builtin_types['Fn'].where(Value)
        return type(a:Value) == type(function('tr'))
    endfunction
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
