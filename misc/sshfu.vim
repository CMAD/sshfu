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
syn keyword sshfuKeyword port
syn keyword sshfuKeyword key
syn keyword sshfuKeyword keepalive
syn keyword sshfuKeyword i
syn keyword sshfuKeyword comp
syn keyword sshfuKeyword level
syn keyword sshfuKeyword agent
syn keyword sshfuKeyword proxy

syn match sshfuComment "^#.*$" contains=sshfuTodo
syn keyword sshfuTodo TODO FIXME contained

hi def link sshfuKeyword Keyword
hi def link sshfuComment Comment
hi def link sshfuTodo Todo

let b:current_syntax = "sshfu"

