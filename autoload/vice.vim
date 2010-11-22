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
    \       '_super': [],
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
    \       '_super': [],
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

let s:Builder = {
\   '_object': {},
\   'new': s:get_local_func('Builder_new'),
\   'build': s:get_local_func('Builder_build'),
\}
" }}}
" s:MethodMaker {{{
" Abstruct class.
" NOTE: s:MethodMaker needs:
" - ._class_name
" - ._builders

function! s:MethodMaker_method(method_name, ...) dict "{{{
    let options = a:0 ? a:1 : {}
    let class_name = self._class_name
    let real_name = class_name . '_' . a:method_name

    " The function `real_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'real_name': '<SNR>' . self._sid . '_' . real_name,
    \   'method_name': a:method_name,
    \   'options': options,
    \}
    function! builder.build(this)
        if has_key(a:this._object, self.method_name)
        \   && !get(self.options, 'override', 0)
            throw "vice: Class '" . a:this._class_name . "'"
            \       . ": method '" . self.method_name . "' is "
            \       . "already defined, please specify"
            \       . " to .method(" . string(self.method_name) . ", "
            \       . "`{'override': 1}`) to override."
        endif
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
    call add(self._builders, builder)

    return 's:' . real_name
endfunction "}}}

let s:MethodMaker = {
\   '_sid': -1,
\   '_opt_generate_stub': 0,
\   'method': s:get_local_func('MethodMaker_method'),
\}
" }}}
" s:Extendable {{{
" Abstruct class.
" NOTE: s:Extendable needs:
" - ._class_name
" - ._builders

function! s:Extendable_extends(parent_factory) dict "{{{
    " a:parent_factory requires s:Builder.
    let builder = {'parent': a:parent_factory}
    function builder.build(this)
        " Build all methods.
        call self.parent.build()
        " Merge missing methods from parent class.
        call extend(a:this._object, self.parent._object, 'keep')
        " Add it to the super classes.
        call add(a:this._super, self.parent._object)
    endfunction
    call add(self._builders, builder)
endfunction "}}}

function! s:Extendable_super(...) dict "{{{
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
    call add(self._builders, builder)
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
    function builder.build(this)
        let a:this._object[self.name] = self.value
    endfunction
    call add(self._builders, builder)
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
            call add(a:this._builders, self)
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
    call add(self._builders, builder)
endfunction "}}}

let s:Class = {
\   'property': s:get_local_func('Class_property'),
\   'accessor': s:get_local_func('Class_accessor'),
\   'attribute': s:get_local_func('Class_attribute'),
\   'can': s:get_local_func('Class_can'),
\}
call extend(s:Class, s:Builder, 'error')
call extend(s:Class, s:MethodMaker, 'error')
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
call extend(s:Trait, s:MethodMaker, 'error')
call extend(s:Trait, s:Extendable, 'error')
" Implement some properties to satisfy abstruct parents.
let s:Trait._builders = []
let s:Trait._class_name = ''
" }}}

" :unlet for memory.
" Those classes' methods/properties are copied already.
unlet s:Builder
unlet s:MethodMaker
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
