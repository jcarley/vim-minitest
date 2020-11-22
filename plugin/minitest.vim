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
  let l:test = ""
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

    let l:last_spec_file = s:CurrentFilePath()
    let l:last_spec_file_with_line = l:last_spec_file . ":" . line(".")
    let l:test = l:last_spec_file_with_line

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

function! s:CurrentFilePath()
  return @%
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

function! MakeMinitestFileIfMissing()
ruby << EOF
  class MakeMinitestFileIfMissing
    def self.for(buffer)
      if test_file?(buffer) || already_exists?(test_for_buffer(buffer))
        puts "test already exists"
        return
      end

      # puts "going to make #{directory_for_test(buffer)}"
      # puts "going to make #{test_for_buffer(buffer)}"
      system 'mkdir', '-p', directory_for_test(buffer)
      File.open(test_for_buffer(buffer), File::WRONLY|File::CREAT|File::EXCL) do |file|
        file.write "require 'test_helper'"
      end
    end

    private
    def self.test_file?(file)
      file.match(/.*_test.rb$/)
    end

    def self.already_exists?(b)
      File.exists?(b)
    end

    def self.test_for_buffer(b)
      test_buffer = b.sub('/app/', '/test/')
      test_buffer.sub!('/lib/', '/test/lib/')
      test_buffer.sub!('.rb', '_test.rb')
      return test_buffer
    end

    def self.directory_for_test(b)
      File.dirname(self.test_for_buffer(b))
    end
  end
  buffer = VIM::Buffer.current.name
  MakeMinitestFileIfMissing.for(buffer)
EOF
endfunction
