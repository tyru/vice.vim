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
    for builder in self._builders
        call builder.build(self._object)
    endfor
    return deepcopy(self._object)
endfunction "}}}

function! s:ClassFactory.method(name) "{{{
    let class_name = self._class_name
    let real_name = class_name . '_' . a:name

    " The function `real_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'real_name': '<SNR>' . self._sid . '_' . real_name,
    \   'method_name': a:name,
    \}
    function! builder.build(object)
        " NOTE: Currently allows to override.
        let a:object[self.method_name] = function(self.real_name)
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
