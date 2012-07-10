" All system-wide defaults are set in $VIMRUNTIME/debian.vim (usually just
" /usr/share/vim/vimcurrent/debian.vim) and sourced by the call to :runtime
" you can find below.  If you wish to change any of those settings, you should
" do it in this file (/etc/vim/vimrc), since debian.vim will be overwritten
" everytime an upgrade of the vim packages is performed.  It is recommended to
" make changes after sourcing debian.vim since it alters the value of the
" 'compatible' option.

" This line should not be removed as it ensures that various options are
" properly set to work with the Vim-related packages available in Debian.
runtime! debian.vim

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
    source /etc/vim/vimrc.local
endif

call pathogen#infect()

" Uncomment the next line to make Vim more Vi-compatible
" NOTE: debian.vim sets 'nocompatible'.  Setting 'compatible' changes numerous
" options, so any other options should be set AFTER setting 'compatible'.
"set compatible
set nocompatible	" Use Vim defaults (much better!)

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
"set showcmd        " Show (partial) command in status line.
"set showmatch      " Show matching brackets.
"set ignorecase     " Do case insensitive matching
"set smartcase      " Do smart case matching
"set incsearch      " Incremental search
"set gdefault   " apply sibstitutions to all lines by default
"set autowrite      " Automatically save before commands like :next and :make
"set hidden             " Hide buffers when they are abandoned
set mouse=a        " Enable mouse usage (all modes)
set encoding=utf-8
set autoindent			" always set autoindenting on
set expandtab
set tabstop=4
set softtabstop=4
set smarttab
set shiftwidth=4
set bs=2		" allow backspacing over everything in insert mode
set foldmethod=syntax	" fold by syntax
set foldlevel=999	" open all folds
"set backup		" keep a backup file
set viminfo='20,\"50	" read/write a .viminfo file, don't store more 
                        " than 50 lines of registers
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
"set number
set relativenumber
set undofile
set esckeys

" Don't use Ex mode, use Q for formatting
map Q gq

"set visualbell
set colorcolumn=80
highlight ColorColumn guibg=#cccccc ctermbg=darkgray
highlight Folded ctermfg=6 ctermbg=0

"nnoremap / /\v " use python/perl style regex
"vnoremap / /\v
nnoremap <leader><space> :noh<cr>
nnoremap <tab> %
vnoremap <tab> %
map <Esc>[H  <Home>
map <Esc>[F  <End>
map <F4> <Esc>:%s/\s\+$//g<CR>
map! <F2> <ESC>:set paste<CR>a
map! <F3> <ESC>:set nopaste<CR>a
map <F2> <Esc>:set paste<CR>i
map <F3> <Esc>:set nopaste<CR>i

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
    syntax enable
    set hlsearch
    " If using a dark background within the editing area and syntax highlighting
    " turn on this option as well
    set background=dark
    "set term=xterm
    let g:solarized_termcolors=16
    let g:solarized_contrast="high"
    let g:solarized_visibility="high"
    let g:solarized_termtrans=1
    colorscheme solarized
endif

" gnome-terminal doesn't properly report it's color capabilities
if $COLORTERM == 'gnome-terminal'
  set t_Co=256
endif


if has("autocmd")
    " Uncomment the following to have Vim jump to the last position when
    " reopening a file
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

    " Uncomment the following to have Vim load indentation rules and plugins
    " according to the detected filetype.
    filetype plugin indent on
endif

if !exists("autocommands_loaded")
    let autocommands_loaded = 1
    autocmd BufRead,BufNewFile,FileReadPost *.py source ~/.vim/python
endif

" a better htmldjango detection
augroup filetypedetect
" removes current htmldjango detection located at $VIMRUNTIME/filetype.vim
  au! BufNewFile,BufRead *.html
  au BufNewFile,BufRead *.html call FThtml()

  func! FThtml()
    let n = 1
    while n < 10 && n < line("$")
      if getline(n) =~ '\<DTD\s\+XHTML\s'
        setf xhtml
        return
      endif
      if getline(n) =~ '{%\|{{\|{#'
        setf htmldjango
        return
      endif
      let n = n + 1
    endwhile
    setf html
  endfunc
augroup END
