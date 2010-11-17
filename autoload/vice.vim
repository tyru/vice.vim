" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:global_traits = {}


function! vice#package(pkg, sid) "{{{
    return extend(
    \   deepcopy(s:package),
    \   {'_pkg': a:pkg, '_sid': a:sid},
    \   'force'
    \)
endfunction "}}}

let s:package = {}
function! s:package.class(name) "{{{
    return vice#class(self._pkg . '.' . a:name, self._sid)
endfunction "}}}


function! vice#class(class_name, sid, ...) "{{{
    " a:namespace is currently just a SID.
    let obj = deepcopy(s:object)
    return extend(
    \   deepcopy(s:class_factory),
    \   {
    \       '_class_name': a:class_name,
    \       '_sid' : a:_sid,
    \       '_object'    : obj,
    \       '_builders'  : [],
    \   },
    \   'force'
    \)
endfunction "}}}

function! vice#throw_exception(msg) "{{{
    throw 'vice: ' . a:msg
endfunction "}}}


function! s:initialize_builtin_classes() "{{{
    let pkg = vice#package('vice.builtins', s:SID_PREFIX)

    function pkg.class('Dict').where(Value)
        return type(a:Value) == type({})
    endfunction

    function pkg.class('List').where(Value)
        return type(a:Value) == type([])
    endfunction

    function pkg.class('Num').where(Value)
        return type(a:Value) == type(0)
        \   || type(a:Value) == type(0.0)
    endfunction

    function pkg.class('Int').extends('Num').where(Value)
        return type(a:Value) == type(0)
    endfunction

    function pkg.class('Float').extends('Num').where(Value)
        return type(a:Value) == type(0.0)
    endfunction

    function pkg.class('Str').where(Value)
        return type(a:Value) == type("")
    endfunction

    function pkg.class('Fn').where(Value)
        return type(a:Value) == type(function('tr'))
    endfunction
endfunction "}}}

function! s:parse_class_name(class_name) "{{{
    let _ = split(a:class_name, '\.')
    return [_[:-2], _[-1]]
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
    " NOTE: I don't use package name currently.
    let [__unused__, class_name] = s:parse_class_name(self._class_name)
    let real_name = class_name . '_' . a:name

    " The function `real_name` doesn't exist
    " when .method() is called.
    " So I need to build self._object at .new()
    let builder = {
    \   'object': self._object,
    \   'real_name': '<SNR>' . self._sid . '_' . real_name,
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
    let opt = a:0 ? a:1 : {}

    let self._object[a:name] = {'_name': a:name}
    let obj = self._object[a:name]

    if has_key(self, 'where')
        let obj.where = self.where
    endif
    if has_key(opt, 'default')
    \   && (has_key(self, 'where')
    \       && self.where(opt.default))
    \   || !has_key(self, 'where')
        let obj._value = opt.default
    endif

    function! obj.get()
        return copy(self._value)
    endfunction

    function! obj.set(Value)
        if has_key(self, 'where') && !self.where(a:Value)
            call vice#throw_exception(
            \   ':' . self._name . ' : received invalid type.')
        endif
        let self._value = a:Value
    endfunction
endfunction "}}}

function! s:class_factory.extends(parent) "{{{
    let builder = {'parent': a:parent, 'object': self._object}
    function builder.build()
        " Current inheritance implementation is just doing extend().
        call extend(self.object, self.parent, 'keep')
    endfunction
    call add(self._builders, builder)

    return self
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
