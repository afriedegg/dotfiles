" Vim syntax file
" Language:	Flat Plan
" Maintainer:	Hayden Stainsby <hds@caffeineconcepts.com>
" Last Change:	Wed, 10 Oct 2007
" Filenames:	*.keylayout

" REFERENCES:
"   [1] ...
"

" Quit when a syntax file was already loaded
if exists("b:current_syntax")
	finish
endif

runtime syntax/xml.vim

syn cluster xmlTagHook add=fpElement
syn case match

"syn match fpElement '\%(flatplan:\)\@<=document'
"syn match fpElement '\%(flatplan:\)\@<=title'
"syn match fpElement '\%(flatplan:\)\@<=subtitle'
"syn match fpElement '\%(flatplan:\)\@<=date'
"syn match fpElement '\%(flatplan:\)\@<=events'
"syn match fpElement '\%(flatplan:\)\@<=event'
"syn match fpElement '\%(flatplan:\)\@<=event-name'
"syn match fpElement '\%(flatplan:\)\@<=event-date'
"syn match fpElement '\%(flatplan:\)\@<=pages'
"syn match fpElement '\%(flatplan:\)\@<=page'
"syn match fpElement '\%(flatplan:\)\@<=page-number'
"syn match fpElement '\%(flatplan:\)\@<=content'
"syn match fpElement '\%(flatplan:\)\@<=content-type'
"syn match fpElement '\%(flatplan:\)\@<=content-name'
"syn match fpElement '\%(flatplan:\)\@<=content-length'

hi def link fpElement Statement

" vim: ts=8
