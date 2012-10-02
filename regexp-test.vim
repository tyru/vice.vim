

source Regexp.vim


let r = g:Regexp.new('^\s*hello\s*,\=\s*\(.\+\)'.'\c')
if r.match('hello world')
    " => "world"
    echo r.group(0)
endif
if r.match('Hello, vim')
    " => "vim"
    echo r.group(0)
endif
if r.match('Hello vimmers')
    " => "vimmers"
    echo r.group(0)
endif

let r = g:Regexp.new('^\(\%(foo\)\=\)\(\%(bar\)\=\)\(\%(baz\)\)$')
if r.match('foobarbaz')
    " => ['foo', 'bar', 'baz']
    echo r.grouplist(3)
endif
if r.match('foobaz')
    " => ['foo', '', 'baz']
    echo r.grouplist(3)
endif
if r.match('barbaz')
    " => ['', 'bar', 'baz']
    echo r.grouplist(3)
endif
