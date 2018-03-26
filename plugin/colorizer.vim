" ============================================================================
" File:        colorizer.vim
" Author:      Christian Persson <c0r73x@gmail.com>
" Repository:  https://github.com/c0r73x/colorizer
"              Released under the MIT license
" ============================================================================

if !exists('g:colorizer_colors')
    let g:colorizer_colors = [
                \   'basic',
                \   'extra',
                \   'material',
                \ ]
endif

if !exists('g:colorizer_functions')
    let g:colorizer_functions = [
                \   'rgba\?',
                \   'hsla\?',
                \ ]
endif

if !exists('g:colorizer_hexval')
    let g:colorizer_hexval = [
                \   '#',
                \   '0x',
                \ ]
endif

if !exists('g:colorizer_events')
    let g:colorizer_events = [
                \   'CursorMoved',
                \   'CursorMovedI',
                \   'WinEnter',
                \ ]
endif

if !exists('g:colorizer_enabled')
    let g:colorizer_enabled = 0
endif

function! s:detect2hex(r, g, b)
    let l:r = a:r
    let l:g = a:g
    let l:b = a:b

    if l:r =~# '\d*\.[0-9f]\+' ||
                \ l:g =~# '\d*\.[0-9f]\+' ||
                \ l:b =~# '\d*\.[0-9f]\+'

        let l:r = substitute(substitute(l:r, '[.f]\+$', '', ''), '^\.', '0.', '')
        let l:g = substitute(substitute(l:g, '[.f]\+$', '', ''), '^\.', '0.', '')
        let l:b = substitute(substitute(l:b, '[.f]\+$', '', ''), '^\.', '0.', '')

        let l:r = (strlen(l:r) > 0) ? float2nr(eval(l:r . '* 255')) : 0
        let l:g = (strlen(l:g) > 0) ? float2nr(eval(l:g . '* 255')) : 0
        let l:b = (strlen(l:b) > 0) ? float2nr(eval(l:b . '* 255')) : 0
    endif

    return printf(
                \   '%02x%02x%02x',
                \   min([l:r, 255]),
                \   min([l:g, 255]),
                \   min([l:b, 255]),
                \ )
endfunction

function! s:rgb2hex(r,g,b)
    let l:rgb = map(
                \   [a:r, a:g, a:b],
                \   'v:val =~# ''%$'' ? (255 * v:val) / 100 : v:val'
                \ )

    return printf(
                \   '%02x%02x%02x',
                \   min([l:rgb[0], 255]),
                \   min([l:rgb[1], 255]),
                \   min([l:rgb[2], 255]),
                \ )
endfunction

function! s:hsl2hex(h,s,l)
    let [l:s,l:l] = map(
                \   [a:s, a:l],
                \   'v:val =~# ''%$'' ? v:val / 100.0 : v:val + 0.0',
                \ )

    let l:hh = (a:h % 360) / 360.0
    let l:m2 = l:l <= 0.5 ? l:l * (l:s + 1) : l:l + l:s - l:l * l:s
    let l:m1 = l:l * 2 - l:m2
    let l:rgb = []

    for l:h in [l:hh + (1 / 3.0), l:hh, l:hh - (1 / 3.0)]
        let l:h = l:h < 0 ? l:h + 1 : l:h > 1 ? l:h - 1 : l:h
        let l:v = l:h * 6 < 1 ? l:m1 + (l:m2 - l:m1) * l:h * 6 :
                    \ l:h * 2 < 1 ? l:m2 :
                    \ l:h * 3 < 2 ? l:m1 + (l:m2 - l:m1) * (2 / 3.0 - l:h) * 6 :
                    \ l:m1

        if l:v > 1.0 | let l:v = 1.0 | endif
        let l:rgb += [float2nr(255 * l:v)]
    endfor

    return printf(
                \   '%02x%02x%02x',
                \   min([l:rgb[0], 255]),
                \   min([l:rgb[1], 255]),
                \   min([l:rgb[2], 255]),
                \ )
endfunction

function! s:tocterm(color)
    let l:c = {
                \ 'r': float2nr((eval('0x' . a:color[0:1]) / 255.0) * 5),
                \ 'g': float2nr((eval('0x' . a:color[2:3]) / 255.0) * 5),
                \ 'b': float2nr((eval('0x' . a:color[4:5]) / 255.0) * 5),
                \ }

    return (16 + (36 * l:c.r) + (6 * l:c.g) + l:c.b)
endfunction

function! s:lum(color, black, white)
    let l:c = {
                \ 'r': eval('0x' . a:color[0:1]),
                \ 'g': eval('0x' . a:color[2:3]),
                \ 'b': eval('0x' . a:color[4:5]),
                \ }

    let l:yiq = ((l:c.r * 299) + (l:c.g * 587) + (l:c.b * 114))
    return (l:yiq >= 128000) ? a:black : a:white
endfunction

function! s:syntax(cs)
    if strlen(a:cs['pattern']) == 0
        exec 'syn keyword ' . a:cs['name'] . ' ' . a:cs['keyword']
    else
        exec 'syn match ' . a:cs['name'] . ' /' . escape(a:cs['pattern'], '/') . '/'
    endif
endfunction

function! s:highlight(hex, ...)
    let l:name = 'COL' . a:hex
    let l:hex = '#' . a:hex
    let l:cterm = s:tocterm(a:hex)
    let l:pattern = (a:0 >= 1) ? a:1 : ''
    let l:keyword = (a:0 >= 2) ? a:2 : ''

    exec join([
                \ 'hi',
                \ l:name,
                \ 'guibg=' . l:hex,
                \ 'guifg=' . s:lum(a:hex, '#000000', '#FFFFFF'),
                \ 'ctermbg=' . l:cterm,
                \ 'ctermfg=' . s:lum(a:hex, 0, 15),
                \ ], ' ')

    let l:cs = {
                \   'name': l:name,
                \   'pattern': l:pattern,
                \   'keyword': l:keyword,
                \   'hex': a:hex
                \ }

    call s:syntax(l:cs)
    let b:colorizer_store += [l:cs]

    return l:name
endfunction

function! s:color_names(colors)
    syn case ignore

    for [l:color, l:gradient] in items(a:colors)
        for [l:key, l:hex] in items(l:gradient)
            let l:name = s:highlight(
                        \   substitute(l:hex, '#', '', ''),
                        \   '',
                        \   l:color . l:key,
                        \ )

        endfor
    endfor
endfunction

function! s:create_syn_match()
    let l:pattern = submatch(0)

    if !empty(filter(
                \    copy(b:colorizer_store),
                \    '(v:val.pattern !=# "" && v:val.pattern =~# "^' .  l:pattern . '")',
                \ ))
        return
    endif

    let l:hex = submatch(1)
    let l:func = submatch(2)

    syn case ignore

    if strlen(l:hex) > 0
        if strlen(l:hex) == 3
            let l:hex = substitute(l:hex, '\(.\)', '\1\1', 'g')
        endif
    elseif strlen(l:func) > 0
        if l:func =~? '^rgba\?'
            let l:hex = s:rgb2hex(
                        \   submatch(3),
                        \   submatch(4),
                        \   submatch(5),
                        \ )
        elseif l:func =~? '^hsla\?'
            let l:hex = s:hsl2hex(
                        \   submatch(3),
                        \   submatch(4),
                        \   submatch(5),
                        \ )
        else
            let l:hex = s:detect2hex(
                        \   submatch(3),
                        \   submatch(4),
                        \   submatch(5),
                        \ )
        endif
    endif

    if l:pattern =~# '\>$'
        let l:pattern .= '\>'
    endif

    if strlen(l:hex) > 0
        let l:name = s:highlight(l:hex, l:pattern)
    endif
endfunction

function! s:parse_buffer()
    let l:hexcolor = '\%(' . join(
                \   g:colorizer_hexval,
                \   '\|',
                \ ) . '\)\(\x\{3}\|\x\{6}\)\>'

    let l:funcname = '\(' . join(
                \   g:colorizer_functions,
                \   '\|',
                \ ) . '\)'

    let l:numval = '\s*\([0-9.f]\+%\?\)'

    let l:funcexpr = l:funcname . '(' . l:numval . '\s*,' . l:numval .
                \ '\s*,' . l:numval . '\s*\%(,\s*[0-9.f]\+\)\?)'

    let l:leftcol = winsaveview().leftcol
    let l:left = max([l:leftcol - 15, 0])
    let l:width = &columns * 4
    call filter(
                \     range(
                \       line('w0'),
                \       line('w$'),
                \     ),
                \     'substitute('.
                \       'strpart('.
                \           'getline(v:val),'.
                \           'col([v:val, ' . l:left . ']),'.
                \           l:width .
                \       '),'.
                \       '''' . l:hexcolor . '\|' . l:funcexpr . ''','.
                \       '''\=s:create_syn_match()'','.
                \       '''g'''.
                \     ')'
                \ )
endfunction

function! s:toggle()
    if g:colorizer_enabled == 1
        let g:colorizer_enabled = 0

        for l:cs in b:colorizer_store
            exec 'syn clear ' . l:cs['name']
        endfor
            
        exec 'autocmd! Colorizer ' . join(g:colorizer_events, ',') . ' <buffer>'
    else
        let g:colorizer_enabled = 1

        if !exists('g:colorizer_loaded') || !exists('b:colorizer_store')
            call s:init()
            return
        endif

        for l:cs in b:colorizer_store
            call s:syntax(l:cs)
        endfor

        exec 'autocmd! Colorizer ' . join(g:colorizer_events, ',') . ' <buffer> call s:parse_buffer()'
    endif
endfunction

function! s:init()
    if g:colorizer_enabled != 1
        return
    endif

    if !exists('g:colorizer_loaded')
        let g:colorizer_loaded = 1
    endif

    if !exists('b:colorizer_store')
        let b:colorizer_store  = []
    endif

    for l:file in g:colorizer_colors
        if !exists('g:colorizer_colors_' . l:file)
            runtime! 'plugin/colorizer/' . l:file . '.vim'

            if exists('g:colorizer_colors_' . l:file)
                call s:color_names(eval('g:colorizer_colors_' . l:file))
            endif
        else
            call s:color_names(eval('g:colorizer_colors_' . l:file))
        endif
    endfor

    exec 'autocmd! Colorizer ' . join(g:colorizer_events, ',') . ' <buffer> call s:parse_buffer()'
    call s:parse_buffer()
endfunction

augroup Colorizer
    autocmd!
    autocmd BufReadPre,BufEnter * :call s:init()
augroup END

command! ColorizerToggle call s:toggle()
