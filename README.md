
# Inheritance

    " vice.vim needs to know defined SID.
    function s:SID()
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
    function {s:Printable.method('print'))}()
        echon self.message()
    endfunction
    function {s:Printable.method('say'))}()
        echo self.message()
    endfunction


    let s:Parent = vice#class('Parent', s:SID(), s:VICE_OPTIONS)
    function {s:Parent.method('message')}()
        return 'parent'
    endfunction


    let s:Child = vice#class('Child', s:SID(), s:VICE_OPTIONS)
    call s:Child.extends(s:Parent)
    function {s:Child.method('message')}()
        return 'child'
    endfunction


    parent = s:Parent.new()
    " "parent"
    echo parent.print()
    " "parent" with newline
    echo parent.say()

    child = s:Child.new()
    " "child"
    echo child.print()
    " "child" with newline
    echo child.say()

# TODO
# Trait (Perl's role-like feature)
NOTE: The similar thing is possible with .extends(),
but traits can *require* some methods to implement

- Trait can force implementer's class to implement some methods.
- Trait can *require* some methods to implement

## Type constraints
- .where()
- when it should be called?
    - How do other languages' system do that?
    * it should be called when assigning a value.

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

# etc.
- Moose(Perl)'s before(), after()
    - override (or more like Aspect-Oriented?)
