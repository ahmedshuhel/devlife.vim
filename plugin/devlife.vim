let s:project_root_dir = finddir('.git/..', expand('%:p:h').';')
let s:plugin_dir = expand('<sfile>:h:h')
let s:template_dir = s:plugin_dir . "/tmpls"


function! s:RelPath(path, current_path) abort

python3 << EOF
import vim
from os.path import relpath

def get_rel_path():
  return relpath(vim.eval('a:path'), vim.eval('a:current_path'))
EOF

return py3eval('get_rel_path()')
endfunction

function! s:Sanitize(fn)
  " Replace `(`, `)` `-` with empty string
  return join(split(substitute(a:fn, "-\\|(\\|)", "", "g"), "-\\|\\s\\|/\\|\\"), "-")
endfunction

function! s:CreateOneOffMeeting(fn)
    let l:fp = s:project_root_dir . "/meetings/" . strftime("%Y-%m-%d") . "-" . s:Sanitize(a:fn) . ".md"
    call s:InsterAtCursor(s:RelPath(l:fp, expand('%:p:h')))
    call s:NewFile(l:fp)

    let l:cmd = s:template_dir . "/dlom.sh"
    let l:result = system(cmd)
    call append(0, split(l:result, '\n'))
endfunction

function! s:CreateInterviewNotes(fn)
    let l:fp = s:project_root_dir . "/meetings/interview/" . strftime("%Y-%m-%d") . "-" . s:Sanitize(a:fn) . ".md"
    call s:InsterAtCursor(s:RelPath(l:fp, expand('%:p:h')))
    call s:NewFile(l:fp)

    let l:cmd = s:template_dir . "/dli.sh" . " '" . a:fn . "'"
    let l:result = system(cmd)
    call append(0, split(l:result, '\n'))
endfunction


function! s:InsterAtCursor(text)
    let l:line = getline('.')
    call setline('.', strpart(l:line, 0, col('.') - 1) . a:text . strpart(l:line, col('.') - 1))
endfunction

function! s:CreateMeeting(pn)
    let l:date = strftime("%Y-%m-%d")
    let l:folder_path = s:project_root_dir . "/meetings/recurring/" . a:pn . "/"
    let l:file_path = l:folder_path . l:date . ".md"
    let l:last_entry = s:FindLastEntry(localtime(), 'meetings/recurring/' . a:pn . '/', 240)

    " Insert link in the current buffer. e.g. daily note
    call s:InsterAtCursor(s:RelPath(l:file_path, expand('%:p:h')))

    execute "edit " . l:last_entry

    " Add next entry link. Note: `Previous` is at line 2 and we want to add
    " `Next` exactly after line #2
    call append(2, '- [Next](' . s:RelPath(l:file_path,  fnamemodify(l:last_entry, ":p:h")) . ')')

    " Copy from #Action/Decisions into register `*
    execute "normal /## Decision\/Actions\<CR>"
    execute "normal j"
    execute "normal yG"
    let l:backlog = getreg('*')
    " End copy

    call s:NewFile(l:file_path)

    let l:cmd = s:template_dir . "/dlm.sh " . s:RelPath(l:last_entry, l:folder_path)
    let l:result = system(cmd)
    call append(0, split(l:result, '\n'))

    execute "normal /## Agenda\<CR>"
    execute "normal j"
    execute "normal p"
    " call append(line("."), split(l:backlog, '\n'))
endfunction

function! s:FindLastEntry(today, base_path, max_retry)
    if (a:max_retry <= 0)
      return s:project_root_dir . "/"  . a:base_path . strftime('%Y-%m-%s', localtime()) . '.md'
    endif

    let l:yesterday = a:today - 24 * 3600
    let l:entry = findfile(strftime('%Y-%m-%d', l:yesterday) . '.md', a:base_path . '**')

    if !empty(l:entry)
      return s:project_root_dir . "/"  . l:entry
    else
      return s:FindLastEntry(l:yesterday, a:base_path, a:max_retry - 1)
    endif
endfunction

function! s:CreateDailyTask()
    let l:date = strftime("%Y-%m-%d")
    let l:month = strftime('%m.%B')
    let l:year = strftime('%Y')

    let l:fp = s:project_root_dir . "/tasks/" . l:year . "/" . l:month . "/" . l:date . ".md"

    if filereadable(l:fp)
      execute "e ". l:fp
      return 
    endif

    let l:last_entry = s:FindLastEntry(localtime(), 'tasks/', 60)

    let l:folder_path = s:project_root_dir . "/tasks/" . l:year . "/" . l:month . "/"
    let l:file_path = l:folder_path . l:date . ".md"

    execute "edit " . l:last_entry

    " Add next entry link. Note: `Previous` is at line 2 and we want to add
    " `Next` exactly after line #2
    call append(3, '- [Next](' . s:RelPath(l:file_path,  fnamemodify(l:last_entry, ":p:h")) . ')')


    " Copy from #Tasks into register `*
    execute "normal /Tasks\<CR>"
    execute "normal j"
    execute "normal yG"
    let l:backlog = getreg('*')
    " End copy

    call s:NewFile(l:file_path)

    let l:cmd = s:template_dir . "/dlt.sh " . s:RelPath(l:last_entry, l:folder_path)
    let l:result = system(cmd)
    call append(0, split(l:result, '\n'))
    execute "normal /Tasks\<CR>"
    execute "normal p"
endfunction

function! s:CreatePost(fn)
    let l:fp = s:project_root_dir . "/posts/" . strftime("%Y-%m-%d") . "-" . s:Sanitize(a:fn) . ".md"
    call s:InsterAtCursor(s:RelPath(l:fp, expand('%:p:h')))
    call s:NewFile(l:fp)

    let l:cmd = s:template_dir . "/dlp.sh " . " '". a:fn ."'"
    let l:result = system(l:cmd)
    call append(0, split(l:result, '\n'))
endfunction

function! s:CreateDailyNote()
    let l:date = strftime("%Y-%m-%d")
    let l:month = strftime('%m.%B')
    let l:year = strftime('%Y')
    let l:folder_path = s:project_root_dir . "/morning_tea/" . l:year . "/" . l:month 

    let l:file_path = l:folder_path . "/" . l:date . ".md"

    if filereadable(l:file_path)
      execute "e ". l:file_path
      return 
    endif

    call s:NewFile(l:file_path)

    let l:cmd = s:template_dir . "/dln.sh"
    let l:result = system(l:cmd)
    call append(0, split(l:result, '\n'))
endfunction

function! s:CreateTil(fn)
    let l:fp = s:project_root_dir . "/til/" . strftime("%Y-%m-%d") . "-" . join(split(a:fn), '-') . ".md"
    call s:NewFile(l:fp)

    let l:cmd = s:template_dir . "/dll.sh " . " '". a:fn ."'"
    let l:result = system(l:cmd)
    call append(0, split(l:result, '\n'))
endfunction

function! s:NewFile(fp)
    echom "Creating file '" . a:fp . "'"
    execute "e ". a:fp
    :w
endfunction

function! MarkdownGF()
    " Get the filename under the cursor
    let cfile=expand('<cfile>')
    " Separate the filename from the section
    let parts=split(cfile, '#')

    " No section marked
    if (len(parts) == 1)
        execute "normal! gf"
    " There is a subsection in the file name
    else
        " Build relative file path from current directory and edit
        execute "e " . expand('%:h') . "/" . parts[0]

        " Normalize: 'todo-list' => 'todo list'
        let l:raw_section = join(split(parts[1], '-'), ' ')

        " Capitalize: `todo list` => `Todo List`
        let l:section = substitute(l:raw_section, '\<.', '\u&', 'g')

        " Build the pattern
        let l:pattern = "^\\#\\+\\s" . l:section . "$"
        call search(l:pattern, 'w')
    endif
endfunction


" Create non-existent directory on buffer create
" https://stackoverflow.com/a/4294176/530767
function s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
        let dir=fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction

augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END

autocmd! Filetype markdown nnoremap <buffer> gf :call MarkdownGF()<CR>

command! DlCreateDailyTask call s:CreateDailyTask()
command! DlCreateDailyNote call s:CreateDailyNote()
command! -nargs=1 DlCreatePost call s:CreatePost(<q-args>)
command! -nargs=1 DlCreateTil call s:CreateTil(<q-args>)
command! -nargs=1 DlCreateMeeting call s:CreateMeeting(<q-args>)
command! -nargs=1 DlCreateOneOffMeeting call s:CreateOneOffMeeting(<q-args>)
command! -nargs=1 DlCreateInterviewNotes call s:CreateInterviewNotes(<q-args>)

"Mappings {{
nnoremap dlt :DlCreateDailyTask<CR>
nnoremap dln :DlCreateDailyNote<CR>
nnoremap dlp :DlCreatePost
nnoremap dll :DlCreateTil
nnoremap dlm :DlCreateMeeting
nnoremap dlom :DlCreateOneOffMeeting
nnoremap dli :DlCreateInterviewNotes
"}}
