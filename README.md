# Trait (Perl's role-like feature)
- Trait can force implementer's class to implement some methods.
- Trait can *require* some methods which
  must be implemented by implementer's class.

# Type constraints
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

# Inheritance

    let s:class = vice#class(
        'Klass',
        s:SID_PREFIX,
        {'parent': vice#class('Parent', s:SID_PREFIX)}
    )

# etc.
- Property is subroutine in Moose. vice should follow that.
    - Because it's more scalable.
    - ...but it can't in Vim script!
    - because function is not first class object.
- Moose's before(), after()
    - override (or more like Aspect-Oriented?)
- Separate `s:class_factory` to factory class (creating instance)
  and builder class (building class design).
