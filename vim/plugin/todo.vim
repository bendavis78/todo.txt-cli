command! -nargs=* Todo                call Todo(<q-args>)
command! -nargs=+ TodoAdd             call TodoAdd(<q-args>)
command! -nargs=* -complete=customlist,CompleteTodoList TodoList call TodoList(<q-args>)
command! -nargs=0 TodoListProjects call TodoListProj()
command! -nargs=0 TodoListContexts call TodoListCon()
nnoremap <Leader>tl :TodoList<ENTER>

function! TodoList(args)
	call Todo('list ' . a:args)
	nnoremap <buffer> q :q<ENTER>
	execute 'nnoremap <buffer> r :silent TodoList ' . a:args . '<ENTER>'
	execute 'nnoremap <buffer> d :silent call TodoDoneCurrent()<ENTER>:silent TodoList ' . a:args . '<ENTER>'
	execute 'nnoremap <buffer> p :call TodoPriorityCurrent()<ENTER>:silent TodoList ' . a:args . '<ENTER>'
	execute 'nnoremap <buffer> P :call TodoAppendProjectCurrent()<ENTER>:silent TodoList ' . a:args . '<ENTER>'
	execute 'nnoremap <buffer> C :call TodoAppendContextCurrent()<ENTER>:silent TodoList ' . a:args . '<ENTER>'
endfunction

function! TodoCurrentLineId()
	let row = split(getline('.'))
	return row[0]
endfunction

function! TodoDoneCurrent()
	let id = TodoCurrentLineId()
	call TodoAction('do ' . id)
endfunction

function! TodoPriorityCurrent()
	let id = TodoCurrentLineId()
	call inputsave()
	let priority = input("Priority?", "A")
	call inputrestore()
	call TodoAction('pri ' . id . ' ' . priority)
endfunction

function! TodoAppendContextCurrent()
	let id = TodoCurrentLineId()
	call inputsave()
	let context = input("Context: ", "@", "customlist,CompleteTodoProjects")
	call inputrestore()
	call TodoAction('append ' . id . ' ' . context)
endfunction

function! TodoAppendProjectCurrent()
	let id = TodoCurrentLineId()
	call inputsave()
	let project = input("Project: ", "+", "customlist,CompleteTodoProjects")
	call inputrestore()
	call TodoAction('append ' . id . ' ' . project)
endfunction

function! TodoListProj()
	call TodoAction('listproj')
endfunction

function! TodoListCon()
	call TodoAction('listcon')
endfunction

function! TodoAdd(args)
	call TodoAction('add "' . a:args . '"')
endfunction

function! CompleteTodo(type, arg_lead, cmd_line, cursor_pos)
	let opts = split(<SID>SystemTodo('list' . a:type))
	return filter(opts, 'match(v:val, ''\V'' . a:arg_lead) == 0')
endfunction

function! CompleteTodoContexts(arg_lead, cmd_line, cursor_pos)
	return CompleteTodo('con', a:arg_lead, a:cmd_line, a:cursor_pos)
endfunction

function! CompleteTodoProjects(arg_lead, cmd_line, cursor_pos)
	return CompleteTodo('proj', a:arg_lead, a:cmd_line, a:cursor_pos)
endfunction

function! CompleteTodoList(arg_lead, cmd_line, cursor_pos)
	let opts = [ ]
	if !strlen(a:arg_lead) || a:arg_lead =~ '^+'
		let opts += CompleteTodoProjects(a:arg_lead, a:cmd_line, a:cursor_pos)
	endif
	if !strlen(a:arg_lead) || a:arg_lead =~ '^@'
		let opts += CompleteTodoContexts(a:arg_lead, a:cmd_line, a:cursor_pos)
	endif
	return opts
endfunction

function! TodoAction(args)
	echo <SID>SystemTodo(a:args)
endfunction

function! Todo(args)
	let todo_output = <SID>SystemTodo(a:args)
	if !strlen(todo_output)
		echo "No output from todo command"
		return
	endif
	call <SID>OpenTodoBuffer(todo_output)
	setlocal filetype=todo-list
endfunction

function! s:SystemTodo(args)
	let default_args = <SID>DefaultTodoArgs()
	return system('todo.sh ' . default_args . ' ' . a:args . ' < /dev/null')
endfunction

function! s:DefaultTodoArgs()
	let args = ""
	if exists('g:todotxt_cfg_file') && strlen(g:todotxt_cfg_file)
		args += '-d ' . g:todotxt_cfg_file
	endif
	return args
endfunction

function! s:OpenTodoBuffer(content)
	if exists('b:is_todo_output_buffer') && b:is_todo_output_buffer
		enew!
	else
		new
	endif
    setlocal buftype=nofile readonly modifiable
    silent put=a:content
    keepjumps 0d
    setlocal nomodifiable
    let b:is_todo_output_buffer = 1
endfunction