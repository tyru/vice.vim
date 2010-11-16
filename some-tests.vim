
" It can
function! s:method()
    return 's:foo'
endfunction
function! {s:method()}()
    echo 'foo!'
endfunction
call s:foo()

" It can't
let s:o = {}
function! s:method()
    return 's:o.foo'
endfunction
function! {s:method()}()
    echo 'foo!'
endfunction
call s:o.foo()
