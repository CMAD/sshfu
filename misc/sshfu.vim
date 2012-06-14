if version >= 600
  if exists("b:current_syntax")
    finish
  endif
else
  syntax clear
endif

syn case match

syn keyword sshfuKeyword host
syn keyword sshfuKeyword address
syn keyword sshfuKeyword gw
syn keyword sshfuKeyword user
syn keyword sshfuKeyword key

syn match sshfuComment "^#.*$" contains=sshfuTodo
syn keyword sshfuTodo TODO FIXME contained

hi def link sshfuKeyword Keyword
hi def link sshfuComment Comment
hi def link sshfuTodo Todo

let b:current_syntax = "sshfu"

