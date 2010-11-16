
let s:class = vice#new('Klass')
let meta = s:class._meta

" Create Pair type (local to s:buffer_string object).
function! meta.subtype('Pair').where(Value)
    return type(a:Value) == type([])
    \   && len(a:Value) == 2
endfunction

" Create Pair type (local to s:buffer_string object).
function! meta.subtype('Pair').define()
    function self.where(Value)
        return type(a:Value) == type([])
        \   && len(a:Value) == 2
    endfunction
endfunction
