" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


" Interfaces {{{

function! vice#class(class_name, sid, ...) "{{{
    " FIXME: hmm, all members including parents' members
    " are initialized here.
    let options = a:0 ? a:1 : {}

    let obj = {}
    if get(options, 'auto_clone_method', 1)
        let obj.clone = s:SkeletonObject.clone
    endif
    if get(options, 'auto_new_method', 0)
        let obj.new = s:SkeletonObject.new
    endif

    return extend(
    \   deepcopy(s:Class),
    \   {
    \       '_class_name': a:class_name,
    \       '_sid': a:sid,
    \       '_object': obj,
    \       '_builders': [],
    \       '_super': -1,
    \       '_opt_generate_stub': get(options, 'generate_stub', 0),
    \   },
    \   'force'
    \)
endfunction "}}}

function! vice#trait(class_name, sid, ...) "{{{
    " FIXME: hmm, all members including parents' members
    " are initialized here.
    let options = a:0 ? a:1 : {}
    return extend(
    \   deepcopy(s:Trait),
    \   {
    \       '_class_name': a:class_name,
    \       '_sid': a:sid,
    \       '_object': (get(options, 'empty_object', 0) ?
    \                       {} : deepcopy(s:SkeletonObject)),
    \       '_builders': [],
    \       '_super': -1,
    \       '_opt_generate_stub': get(options, 'generate_stub', 0),
    \   },
    \   'force'
    \)
endfunction "}}}

" }}}

" Implementation {{{

function s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
let s:SID_PREFIX = s:SID()
delfunc s:SID

function! s:get_local_func(function_name) "{{{
    return function('<SNR>' . s:SID_PREFIX . '_' . a:function_name)
endfunction "}}}


" s:Builder "{{{
" Abstruct class.
" NOTE: s:Builder needs:
" - ._builders

function! s:Builder_new() dict "{{{
    call self.build()
    return deepcopy(self._object)
endfunction "}}}

function! s:Builder_build() dict "{{{
    while !empty(self._builders)
        let builder = remove(self._builders, 0)
        call builder.build(self)
    endwhile
endfunction "}}}

function! s:Builder__add_builder(builder) dict "{{{
    call add(self._builders, a:builder)
endfunction "}}}

let s:Builder = {
\   '_object': {},
\   'new': s:get_local_func('Builder_new'),
\   'build': s:get_local_func('Builder_build'),
\   '_add_builder': s:get_local_func('Builder__add_builder'),
\}
" }}}
" s:MethodManager {{{
" Abstruct class.
" NOTE: s:MethodManager needs:
" - ._class_name
" - ._builders

function! s:MethodManager_method(method_name, ...) dict "{{{
    let options = a:0 ? a:1 : {}
    let class_name = self._class_name
    let real_name = class_name . '_' . a:method_name

    " The function `real_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'real_name': '<SNR>' . self._sid . '_' . real_name,
    \   'method_name': a:method_name,
    \}
    function! builder.build(this)
        if a:this._opt_generate_stub
            " Create a stub for `self.real_name`.
            execute join([
            \   'function! a:this._object[' . string(self.method_name) . '](...)',
            \       'return call(' . string(self.real_name) . ', [self] + a:000)',
            \   'endfunction',
            \], "\n")
        else
            let a:this._object[self.method_name] = function(self.real_name)
        endif
    endfunction
    call self._add_builder(builder)

    " Check an rude override.
    if !get(options, 'override', 0)
    \   && (self._has_method(a:method_name)
    \       || self._parent_has_method(a:method_name))
        throw "vice: Class '" . self._class_name . "'"
        \       . ": method '" . a:method_name . "' is "
        \       . "already defined, please specify"
        \       . " to .method(" . string(a:method_name) . ", "
        \       . "`{'override': 1}`) to override."
    endif
    let self._methods[a:method_name] = builder.real_name

    return 's:' . real_name
endfunction "}}}

function! s:MethodManager__has_method(method_name) dict "{{{
    return has_key(self._methods, a:method_name)
endfunction "}}}

function! s:MethodManager__parent_has_method(method_name) dict "{{{
    if type(self._super) == type({})
        let super = self._super
        if super._has_method(a:method_name)
            return 1
        endif
        if super._parent_has_method(a:method_name)
            return 1
        endif
    endif
    return 0
endfunction "}}}

function! s:MethodManager__get_method(method_name, ...) dict "{{{
    return call('get', [self._methods, a:method_name] + (a:0 ? [a:1] : []))
endfunction "}}}

function! s:MethodManager__parent_get_method(method_name, ...) dict "{{{
    if type(self._super) == type({})
        let super = self._super
        if super._has_method(a:method_name)
            return super._get_method(a:method_name)
        endif
        let not_found = {}
        let Value = super._parent_get_method(a:method_name, not_found)
        if Value isnot not_found
            return Value
        endif
    endif
    return a:0 ? a:1 : 0
endfunction "}}}

function! s:MethodManager__call_parent_method(this, method_name, args) dict "{{{
    " NOTE: the 1st arg is a:this.
    let not_found = {}
    let method = self._parent_get_method(a:method_name, not_found)
    if method isnot not_found
        if self._opt_generate_stub
            return call(method, [a:this] + a:args)
        else
            return call(method, a:args, a:this)
        endif
    endif

    throw "vice: Class '" . self._class_name . "':"
    \       . " .super() could not find the parent"
    \       . " who has '" . a:method_name . "'."
endfunction "}}}

let s:MethodManager = {
\   '_sid': -1,
\   '_opt_generate_stub': 0,
\   '_methods': {},
\   'method': s:get_local_func('MethodManager_method'),
\   '_has_method': s:get_local_func('MethodManager__has_method'),
\   '_parent_has_method': s:get_local_func('MethodManager__parent_has_method'),
\   '_get_method': s:get_local_func('MethodManager__get_method'),
\   '_parent_get_method': s:get_local_func('MethodManager__parent_get_method'),
\   '_call_parent_method': s:get_local_func('MethodManager__call_parent_method'),
\}
" }}}
" s:Extendable {{{
" Abstruct class.
" NOTE: s:Extendable needs:
" - ._class_name
" - ._builders

function! s:Extendable_extends(parent_factory) dict "{{{
    if type(self._super) == type({})
        let quote = "'"
        throw "vice: Class '" . self._class_name . "':"
        \       . " multiple inheritance is prohibited:"
        \       . " from Class '" . a:parent_factory._class_name . "',"
        \       . " already inherited from Class '"
        \       . self._super._class_name . "'."
    endif
    let self._super = a:parent_factory

    " a:parent_factory requires s:Builder.
    let builder = {'parent': a:parent_factory}
    function builder.build(this)
        " Build all methods.
        call self.parent.build()
        " Merge missing methods from parent class.
        call extend(a:this._object, self.parent._object, 'keep')
    endfunction
    call self._add_builder(builder)
endfunction "}}}

function! s:Extendable_super(this, method_name, ...) dict "{{{
    " NOTE: This is called at runtime.
    " Not while building an object.

    " Look up the parent class's method.
    return self._call_parent_method(a:this, a:method_name, (a:0 ? a:1 : []))
endfunction "}}}

let s:Extendable = {
\   'extends': s:get_local_func('Extendable_extends'),
\   'super': s:get_local_func('Extendable_super'),
\   '_super': [],
\}
" }}}
" s:Class {{{
" See vice#class() for the constructor.

function! s:Class_accessor(accessor_name, Value) dict "{{{
    let builder = {
    \   'name': a:accessor_name,
    \   'value': a:Value,
    \}
    function builder.build(this)
        let acc = '_accessor_' . self.name
        execute join([
        \   'function a:this._object[' . string(self.name) . '](...)',
        \       'if a:0',
        \           'let self[' . string(acc) . '] = a:1',
        \       'endif',
        \       'return self[' . string(acc) . ']',
        \   'endfunction',
        \], "\n")
        let a:this._object[acc] = self.value
    endfunction
    call self._add_builder(builder)
endfunction "}}}

function! s:Class_property(property_name, Value) dict "{{{
    let builder = {
    \   'name': a:property_name,
    \   'value': a:Value,
    \}
    function builder.build(this)
        let a:this._object[self.name] = extend(
        \   deepcopy(s:SkeletonProperty),
        \   {'_value': self.value},
        \   'error'
        \)
    endfunction
    call self._add_builder(builder)
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
    function builder.build(this)
        let a:this._object[self.name] = self.value
    endfunction
    call self._add_builder(builder)
endfunction "}}}

function! s:Class_can(trait) dict "{{{
    " Extends all methods before using trait.
    call self.extends(a:trait)

    let builder = {'trait': a:trait, 'has_postponed_once': 0}
    function! builder.build(this)
        " The reason why only trait should postpone
        " its .build() process is that .method() can be
        " after the .can({trait}) .
        " So `self.trait.requires()` method(s)
        " may not exist at the first time.
        if !self.has_postponed_once
            call a:this._add_builder(self)
            let self.has_postponed_once = 1
            return
        endif
        if !has_key(self.trait, 'requires')
            return
        endif
        for prereq_method in self.trait.requires()
            if !has_key(a:this._object, prereq_method)
                throw "vice: required method '" . prereq_method . "'"
                \       . " is not found at the class "
                \       . "'" . a:this._class_name . "'."
            endif
        endfor
    endfunction
    call self._add_builder(builder)
endfunction "}}}

let s:Class = {
\   'property': s:get_local_func('Class_property'),
\   'accessor': s:get_local_func('Class_accessor'),
\   'attribute': s:get_local_func('Class_attribute'),
\   'can': s:get_local_func('Class_can'),
\}
call extend(s:Class, s:Builder, 'error')
call extend(s:Class, s:MethodManager, 'error')
call extend(s:Class, s:Extendable, 'error')
" Implement some properties to satisfy abstruct parents.
let s:Class._builders = []
let s:Class._class_name = ''
" }}}
" s:SkeletonObject {{{
function! s:SkeletonObject_clone() dict "{{{
    return deepcopy(self)
endfunction "}}}

let s:SkeletonObject = {
\   'clone': s:get_local_func('SkeletonObject_clone'),
\}
" }}}
" s:Trait {{{
" vice#trait() for the constructor.

let s:Trait = {}
call extend(s:Trait, s:Builder, 'error')
call extend(s:Trait, s:MethodManager, 'error')
call extend(s:Trait, s:Extendable, 'error')
" Implement some properties to satisfy abstruct parents.
let s:Trait._builders = []
let s:Trait._class_name = ''
" }}}

" :unlet for memory.
" Those classes' methods/properties are copied already.
unlet s:Builder
unlet s:MethodManager
unlet s:Extendable


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

" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
