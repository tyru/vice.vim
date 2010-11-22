
# Features
## Inheritance

    " vice.vim needs to know defined SID.
    function! s:SID()
        return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endfunction
    " 'generate_stub' is defaultly 0 for some reasons.
    " you can omit the vice#class()'s 3rd argument
    " if you like default one.
    let s:VICE_OPTIONS = {'generate_stub': 1}


    " Trait
    "
    " TODO: currently no way to require methods to implement,
    " in this case, `self.message()`.

    let s:Printable = vice#class('Printable', s:SID(), s:VICE_OPTIONS)
    function! {s:Printable.method('print')}(self)
        echon a:self.message()
    endfunction
    function! {s:Printable.method('say')}(self)
        echo a:self.message()
    endfunction


    let s:Foo = vice#class('Foo', s:SID(), s:VICE_OPTIONS)
    call s:Foo.extends(s:Printable)
    function! {s:Foo.method('message')}(self)
        return 'foo'
    endfunction


    let s:Bar = vice#class('Bar', s:SID(), s:VICE_OPTIONS)
    call s:Bar.extends(s:Printable)
    function! {s:Bar.method('message')}(self)
        return 'bar'
    endfunction


    echon "--- Foo ---\n"

    let foo = s:Foo.new()
    " "foo"
    call foo.print()
    " "foo" with newline
    call foo.say()

    echon "\n"
    echon "--- Bar ---\n"

    let bar = s:Bar.new()
    " "bar"
    call bar.print()
    " "bar" with newline
    call bar.say()

# TODO
## Trait (Perl's role-like feature)
NOTE: The similar thing is possible with .extends(),
but traits can *require* some methods to implement

- Trait can force implementer's class to implement some methods.
- Trait can *require* some methods to implement

## Type constraints

    let s:class = vice#new('Klass')
    let meta = s:class._meta

    " Create Pair type (local to s:buffer_string object).
    function! meta.subtype('Pair', 'List').where(Value)
        return len(a:Value) == 2
    endfunction

    " Create Pair type (local to s:buffer_string object).
    function! meta.subtype('Pair', 'List').define()
        function self.where(Value)
            return len(a:Value) == 2
        endfunction
    endfunction

- .where()
- when it should be called?
    - How do other languages' system do that?
    * it should be called when assigning a value.

## etc.
- Moose(Perl)'s before(), after()
    - override (or more like Aspect-Oriented?)
