nnoremap <Plug>vim-minitest#RunCurrentTestFile :call <SID>RunCurrentTestFile()<CR>
nnoremap <Plug>vim-minitest#RunNearestTest :call <SID>RunNearestTest()<CR>
nnoremap <Plug>vim-minitest#RunLastTest :call <SID>RunLastTest()<CR>
nnoremap <Plug>vim-minitest#RunAllTests :call <SID>RunAllTests()<CR>

let s:plugin_path = expand("<sfile>:p:h:h")

if !exists("g:minitest_command")
  let s:cmd = "ruby -Itest {test}"

  if has("gui_running") && has("gui_macvim")
    let g:minitest_command = "silent !" . s:plugin_path . "/bin/run_in_os_x_terminal '" . s:cmd . "'"
  else
    let g:minitest_command = "!echo " . s:cmd . " && " . s:cmd
  endif
endif

function! s:RunAllTests()
  let l:test = "test/test_helper.rb"
  call s:SetLastTestCommand(l:test)
  call s:RunTests(l:test)
endfunction

function! s:RunCurrentTestFile()
  if s:InTestFile()
    let l:test = @%
    call s:SetLastTestCommand(l:test)
    call s:RunTests(l:test)
  else
    call s:RunLastTest()
  endif
endfunction

function! s:RunNearestTest()
  if s:InTestFile()
    let l:test = s:AppendTestFunctionNameToTestFilePath(s:NearestFunctionName())
    call s:SetLastTestCommand(l:test)
    call s:RunTests(l:test)
  else
    call s:RunLastTest()
  endif
endfunction

function! s:RunLastTest()
  if exists("s:last_test_command")
    call s:RunTests(s:last_test_command)
  endif
endfunction

function! s:InTestFile()
  " File path contains a segment test_<words, underscores>.rb
  return match(expand("%"), '_test.rb$') != -1
endfunction

function! s:SetLastTestCommand(test)
  let s:last_test_command = a:test
endfunction

function! s:RunTests(test)
  execute substitute(g:minitest_command, "{test}", a:test, "g")
endfunction

function! s:NearestFunctionName()
  if s:IsTestFunctionDefLine(".")
    return s:GetTestFunctionNameFromLine(".")
  elseif s:IsTestFunctionDefLine(s:PreviousFunctionDefLine())
    return s:GetTestFunctionNameFromLine(s:PreviousFunctionDefLine())
  elseif s:IsTestFunctionDefLine(s:NextFunctionDefLine())
    return s:GetTestFunctionNameFromLine(s:NextFunctionDefLine())
  endif
endfunction

function! s:IsTestFunctionDefLine(lineNumber)
  return s:IsNonEmptyLine(a:lineNumber) &&
        \ s:FirstWordOfLine(a:lineNumber) ==# "def" &&
        \ match(s:SecondWordOfLine(a:lineNumber), 'test_\w*') ==# 0
endfunction

function! s:GetTestFunctionNameFromLine(lineNumber)
  return s:SecondWordOfLine(a:lineNumber)
endfunction

function! s:AppendTestFunctionNameToTestFilePath(functionName)
  return @% . " -n " . a:functionName
endfunction

function! s:IsNonEmptyLine(lineNumber)
  return !empty(getline(a:lineNumber))
endfunction

function! s:PreviousFunctionDefLine()
  return search("def ", "nbceW")
endfunction

function! s:NextFunctionDefLine()
  return search("def ", "nceW")
endfunction

function! s:FirstWordOfLine(lineNumber)
  return s:NthWordOfLine(0, a:lineNumber)
endfunction

function! s:SecondWordOfLine(lineNumber)
  return s:NthWordOfLine(1, a:lineNumber)
endfunction

function! s:NthWordOfLine(n, lineNumber)
  return split(getline(a:lineNumber))[a:n]
endfunction
