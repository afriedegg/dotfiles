map <F6> : call CompileUndir()<CR>
func! CompileUndir()
	exec "!fdp -Tpng % -o %<.png && open -g %<.png"
endfunc
