
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
