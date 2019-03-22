" Vim global plugin for Movable Type
" File:         mtdataapi.vim
" Author:	Seiyo Hiramatsu <hseiyo@gmail.com>
" License:	MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:sessionId = 0
let s:clientId = "mt_dataapi"

" for Vital.vim
let s:V = vital#mtdataapi#new()
let s:Http = s:V.import("Web.HTTP")
let s:Json = s:V.import("Web.JSON")


"""""""""""" fields """"""""""""""
" individual entry
" let invisibleFields = [ "more" , "trackbackCount" , "customFields" , "updatable" , "assets" , "allowTrackbacks" , "comments" , "author" , "commentCount" , "pingsSentUrl" , "allowComments" , "trackbacks" , "class" , "blog"]
" top level
let s:entryFields = [ "id" , "status" , "permalink" ,"basename" , "categories" , "keywords" , "tags" , "createdDate" , "modifiedDate" , "date", "title" , "excerpt" , "body" ]
" second level
let s:entryFields += [ "label" ]"

"
" entries
" top level
let s:summaryFields = [ "id" , "status" , "permalink" , "categories" , "keywords" , "tags" , "createdDate" , "modifiedDate" , "date", "title" ]
" second level
let s:summaryFields += [ "label" ]"

"
" tokens
" top level
" let s:authFields = [ "accessToken" , "sessionId" , "expiresIn" , "remember" ]

"""""""""""""""""""""""""""""""""

  function! s:auth() abort
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/authentication"
  let l:param = {"username": g:mt_username , "password": g:mt_password , "clientId": s:clientId , "remember": "1" }
  let res = s:Http.post( dataapiurl . dataapiendpoint , l:param )
  if res.status != 200
    echo "in s:auth(), got status: " . res.status . " with messages followings"
    echo res.content
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
    return
  endif
  let jsonobj = s:Json.decode(res.content)
  let s:accessToken = jsonobj.accessToken
  let s:sessionId = jsonobj.sessionId

endfunction

function! s:getNewToken() abort
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/token"
  let l:param = {"clientId": s:clientId }
  let res = s:Http.post( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  if res.status != 200
    echo "in s:getNewToken(), got status: " . res.status . " with messages followings"
    echo res.content
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
    return
  endif

  let jsonobj = s:Json.decode(res.content)
  let s:accessToken = jsonobj.accessToken

endfunction

function! s:updateAccessToken() abort
  if s:sessionId != ""
    call s:getNewToken()
  else
    call s:auth()
  endif
endfunction

function! s:dumpEntry( obj) abort
  let l:ret = ""

  if type( a:obj ) != 4
    echo "ERROR: argument: obj is not dictionary"
    echo obj
    return
  endif

  let viewlist = []
  for v in s:entryFields 
    if match( keys( a:obj ) , v ) >= 0
      call add(viewlist, v)
    endif
  endfor

  for k in viewlist
    let l:ret .=  "# " . k . " #\n"
    if k == "categories"
      for category in a:obj[k]
        let l:ret .= category.id . ":" . category.label . "\n"
      endfor
    elseif k == "tags"
      for tags in a:obj[k]
        let l:ret .= tags . "\n"
      endfor
    else
      let l:ret .= a:obj[k] . "\n"
    endif
  endfor
  return l:ret
endfunction



function! s:dumpobj(showlist, header, obj) abort
  let l:ret = ""

  if type( a:obj ) == 0
    let l:ret .= string(a:obj) . "\n"
  elseif type( a:obj ) == 1
    let l:ret .= a:obj . "\n"
  elseif type( a:obj ) == 3
    let l:ret .=  a:header . " " . " #:array" . "\n"
    for i in a:obj
      let l:ret .= s:dumpobj( a:showlist , a:header . "#" , i )
    endfor
  elseif type( a:obj ) == 4

    let viewlist = []
    for v in a:showlist
      if match( keys( a:obj ) , v ) >= 0
        call add(viewlist, v)
      endif
    endfor

    for k in viewlist
      let l:ret .=  a:header . " " . k . " #:dictionary" . "\n"
      let l:ret .= s:dumpobj( a:showlist , a:header . "#" , a:obj[k] )
    endfor
  else
    echo "ERROR: ??? " . type( a:obj ) . a.obj
  endif
  return l:ret
endfunction

function! mtdataapi#getEntry( target ) abort
  let siteid=g:mt_siteid
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/sites/" . string(8) . "/entries"
  let lparam ={}
  if a:target == "latest"
    let l:param = {"limit": "1"}
  elseif a:target == "recent"
    let l:param = {"limit": "50"}
  elseif type( a:target ) == 0
    let dataapiendpoint .= "/" . a:target
    " let l:param = {}
  else
    echo "ERROR: in argument check"
  endif


  call s:updateAccessToken()

  let res = s:Http.get( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  if res.status != 200
    echo "in s:mtdataapi#getEntry(), got status: " . res.status . " with messages followings"
    echo "url: " . dataapiurl . dataapiendpoint
    echo "access token: " . s:accessToken
    echo "session id: " . s:sessionId
    " echo res.message
    echo res.content
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
    return
  endif

  let jsonobj = s:Json.decode(res.content)
  " echo jsonobj
  " echo jsonobj.totalResults
  " echo "jsonobj.items"
  " echo jsonobj.items

  " echo "jsonobj.items[0]"
  " echo jsonobj.items[0]

  if type( a:target ) == 0
    let data = s:dumpEntry( jsonobj )
  elseif a:target == "latest"
    let data = s:dumpEntry( jsonobj.items[0] )
  else
    let data = s:dumpobj( s:summaryFields , "#" , jsonobj.items)
  endif
  execute ":normal ggdGa" . data
endfunction

function! s:str2dict(ind, val ) abort
  let l:a = split( a:val , ":" )
  " l:a[0] is "id"
  " l:a[1] is a label string that is ignored here.
  let l:d = { "id": l:a[0] }
  return l:d
endfunction

function! s:readBuffer() abort
  let l:hash = {}
  let l:retstr = ""
  let l:lastlineno = line("$")

  for f in s:entryFields
    call cursor(1,1)
    let l:pos = search( "^# " . f . " #" , 'cnW' , len( s:entryFields ) * 2 )
    if l:pos > 0
      if f == "body"
        let l:hash[ f ] = join( getline( l:pos + 1 , line("$") ) , "\n" )
      elseif f == "categories"
        call cursor( l:pos + 1 , 1 )
        echo getline( l:pos + 1 , search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 )
        let l:hash[ f ] = map( getline( l:pos + 1 , search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 ) , function('s:str2dict') )
        echo "categories::::"
        echo l:hash[ f]
      elseif f == "tags"
        call cursor( l:pos + 1 , 1 )
        let l:hash[ f ] = getline( l:pos + 1 , search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 )
        echo "tags::::"
        echo l:hash[ f]
      else
        " set next line
        let l:hash[ f ] = getline( l:pos + 1 )
      endif
    endif
  endfor

  return l:hash

 endfunction

function! mtdataapi#createEntry( ) abort
  let siteid=g:mt_siteid
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/sites/" . string(8) . "/entries"
  " let l:param = {}
  let l:entryBody =  s:readBuffer()
  let l:param = s:Json.encode( l:entryBody )
  let l:param = { "entry": l:param , "publish": "1" }

  call s:updateAccessToken()
  let res = s:Http.post( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  if res.status != 200
    echo "in s:mtdataapi#createEntry(), got status: " . res.status . " with messages followings"
    echo res.content
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
    return
  endif

  let jsonobj = s:Json.decode(res.content)
  let data = s:dumpEntry( jsonobj )
  execute ":normal ggdGa" . data
endfunction

function! mtdataapi#editEntry( ) abort
  let siteid=g:mt_siteid
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/sites/" . string(8) . "/entries"
  let l:entryBody =  s:readBuffer()
  if has_key( l:entryBody , "id" )
    let dataapiendpoint .= "/" . l:entryBody["id"]
    unlet l:entryBody["id"]
    let l:entryBody["__method"] = "PUT"
  endif
  let l:param = s:Json.encode( l:entryBody )
  let l:param = { "entry": l:param , "publish": "1" }

  echo dataapiurl . dataapiendpoint
  call s:updateAccessToken()
  let res = s:Http.request( { "url": dataapiurl . dataapiendpoint , "data": l:param , "headers": s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} , "method": "PUT" } )
  if res.status != 200
    echo "in s:mtdataapi#editEntry(), got status: " . res.status . " with messages followings"
    echo res.content
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
    return
  endif

  let jsonobj = s:Json.decode(res.content)
  let data = s:dumpEntry( jsonobj )
  execute ":normal ggdGa" . data
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
