" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
let s:SID_PREFIX = s:SID()
delfunc s:SID

function! s:get_local_func(function_name) "{{{
    return function('<SNR>' . s:SID_PREFIX . '_' . a:function_name)
endfunction "}}}


function! vice#class(class_name, sid, ...) "{{{
    let options = a:0 ? a:1 : {}
    let obj = deepcopy(s:SkeletonObject)
    return extend(
    \   deepcopy(s:Class),
    \   {
    \       '_class_name': a:class_name,
    \       '_sid': a:sid,
    \       '_object': (get(options, 'empty_object', 0) ? {} : obj),
    \       '_builders': [],
    \       '_super': [],
    \       '_opt_generate_stub': get(options, 'generate_stub', 0),
    \       '_opt_fn_property': get(options, 'fn_property', 0),
    \   },
    \   'force'
    \)
endfunction "}}}

" s:SkeletonObject {{{
function! s:SkeletonObject_clone() dict "{{{
    return deepcopy(self)
endfunction "}}}

let s:SkeletonObject = {
\   'clone': s:get_local_func('SkeletonObject_clone'),
\}
" }}}

" s:Class {{{
" See vice#class() for constructor.

function! s:Class_new() dict "{{{
    call self.build()
    return deepcopy(self._object)
endfunction "}}}

function! s:Class_method(method_name) dict "{{{
    let class_name = self._class_name
    let real_name = class_name . '_' . a:method_name

    " The function `real_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'real_name': '<SNR>' . self._sid . '_' . real_name,
    \   'method_name': a:method_name,
    \   'do_generate_stub': self._opt_generate_stub,
    \}
    function! builder.build(object)
        " NOTE: Currently allows to override.
        if self.do_generate_stub
            " Create a stub for `self.real_name`.
            execute join([
            \   'function! a:object[' . string(self.method_name) . '](...)',
            \       'return call(' . string(self.real_name) . ', [self] + a:000)',
            \   'endfunction',
            \], "\n")
        else
            let a:object[self.method_name] = function(self.real_name)
        endif
    endfunction
    call add(self._builders, builder)

    return 's:' . real_name
endfunction "}}}

function! s:Class_extends(parent_factory) dict "{{{
    let builder = {'parent': a:parent_factory, 'super': self._super}
    function builder.build(object)
        call self.parent.build()    " Build all methods.
        call extend(a:object, self.parent._object, 'keep')
        call add(self.super, self.parent._object)
    endfunction
    call add(self._builders, builder)

    return self
endfunction "}}}

function! s:Class_super(...) dict "{{{
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

function! s:Class_property(property_name, Value) dict "{{{
    let builder = {
    \   'name': a:property_name,
    \   'value': a:Value,
    \   'fn_property': self._opt_fn_property,
    \}
    function builder.build(object)
        if self.fn_property
            let prop = '_property_' . self.name
            execute join([
            \   'function a:object[' . string(self.name) . '](...)',
            \       'if a:0',
            \           'let self[' . string(prop) . '] = a:1',
            \       'endif',
            \       'return self[' . string(prop) . ']',
            \   'endfunction',
            \], "\n")
            let a:object[prop] = self.value
        else
            let a:object[self.name] = extend(
            \   deepcopy(s:SkeletonProperty),
            \   {'_value': self.value},
            \   'error'
            \)
        endif
    endfunction
    call add(self._builders, builder)
endfunction "}}}
" s:SkeletonProperty {{{

function! s:SkeletonProperty_get() dict "{{{
    return self._value
endfunction "}}}

function! s:SkeletonProperty_set(Value) dict "{{{
    let self._value = a:Value
endfunction "}}}

let s:SkeletonProperty = {
\   'get': s:get_local_func('SkeletonProperty_get'),
\   'set': s:get_local_func('SkeletonProperty_set'),
\}
" }}}

function! s:Class_attribute(attribute_name, Value) dict "{{{
    let builder = {'name': a:attribute_name, 'value': a:Value}
    function builder.build(object)
        let a:object[self.name] = self.value
    endfunction
    call add(self._builders, builder)
endfunction "}}}

function! s:Class_build() dict "{{{
    if has_key(self, '_builders')
        for builder in self._builders
            call builder.build(self._object)
        endfor
        unlet self._builders
    endif
endfunction "}}}

let s:Class = {
\   'new': s:get_local_func('Class_new'),
\   'method': s:get_local_func('Class_method'),
\   'extends': s:get_local_func('Class_extends'),
\   'super': s:get_local_func('Class_super'),
\   'property': s:get_local_func('Class_property'),
\   'attribute': s:get_local_func('Class_attribute'),
\   'build': s:get_local_func('Class_build'),
\}
" }}}


function! vice#trait(...) "{{{
    let trait = call('vice#class', a:000)
    unlet trait.new    " Trait cannot be instantiated.
    return trait
endfunction "}}}


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
