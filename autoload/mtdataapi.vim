" Vim global plugin for Movable Type
" File:         mtdataapi.vim
" Author:	Seiyo Hiramatsu <hseiyo@gmail.com>
" License:	MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:sessionId = 0
let s:clientId = "mt_dataapi"

" Using Vital.vim
let s:V = vital#mtdataapi#new()
let s:Http = s:V.import("Web.HTTP")
let s:Json = s:V.import("Web.JSON")


"""""""""""" fields """"""""""""""
" individual entry
" let invisibleFields = [ "more" , "trackbackCount" , "customFields" , "updatable" , "assets" , "allowTrackbacks" , "comments" , "author" , "commentCount" , "createdDate" , "modifiedDate" , "date", "pingsSentUrl" , "allowComments" , "trackbacks" , "class" , "blog"]
" top level
let s:entryFields = [ "id" , "status" , "permalink" ,"basename" , "categories" , "keywords" , "tags" , "modifiedDate", "title" , "excerpt" , "body" ]
" second level
let s:entryFields += [ "label" ]"

"
" entries
" top level
let s:summaryFields = [ "id" , "status" , "permalink" , "title" ]
let s:detailFields = [ "id" , "status" , "permalink" , "categories" , "keywords" , "tags" , "modifiedDate" , "title" ]

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
    " at below line, throw is better than echoe?
    echoe "in auth() in s:auth()\n got status: " . res.status . " with messages followings" . res.content
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
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
    if res.status == 401 " if expired
      if s:sessionId != ""
	" echo res
	call s:updateAccessToken()
      else
	" echo res
	" at below line, throw is better than echoe?
	echoe "in not empty"
      endif
    endif
    echo "in s:getNewToken(), got status: " . res.status . " with messages followings"
    echo res.content
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
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
    elseif k == "body"
      let l:ret .= system( 'pandoc -f html -t markdown' , a:obj[k] )
    else
      let l:ret .= a:obj[k] . "\n"
    endif
  endfor
  return l:ret
endfunction


function! s:dumpSummary( list, obj ) abort
  let l:ret = ""

  if type( a:obj ) != 3
    echo "ERROR: argument: obj is not array"
    echo obj
    return
  endif

  for ent in a:obj
    for k in a:list
      if k == "categories"
        let l:ret .= k . "\n"
        for category in ent[k]
          let l:ret .= category.id . ":" . category.label . "\n"
        endfor
      elseif k == "tags"
        let l:ret .= k . "\n"
        for tags in ent[k]
          let l:ret .= tags . "\n"
        endfor
      else
        let l:ret .= k . ": " . ent[k] . "\n"
      endif
    endfor
    let l:ret .= "\n"
  endfor
  return l:ret
endfunction

function! s:dumpSummaryDetail( obj ) abort
  return s:dumpSummary( s:detailFields, a:obj )
endfunction

function! s:dumpSummarySimple( obj ) abort
  return s:dumpSummary( s:summaryFields, a:obj )
endfunction

function! mtdataapi#getEntry( target ) abort
  set paste
  let siteid=g:mt_siteid
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/sites/" . string(8) . "/entries"

  try
    if a:target == "latest"
      let l:param = {"limit": "1"}
    elseif a:target == "recent"
      let l:param = {"limit": "50"}
    elseif a:target == "simple"
      let l:param = {"limit": "50"}
    elseif a:target == "detail"
      let l:param = {"limit": "50"}
    elseif type( a:target ) == 0
      let dataapiendpoint .= "/" . a:target
      let l:param = {}
    else
      echoe "ERROR: in argument check"
    endif

    try
      call s:updateAccessToken()
    catch
      echo "get entries without authentication." v:exception
    endtry

    let res = s:Http.get( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
    if res.status != 200
      echoe "getting entries failed in s:mtdataapi#getEntry()\n got status: " . res.status . " with messages followings" . res.content
      " echo "url: " . dataapiurl . dataapiendpoint
      " echo "access token: " . s:accessToken
      " echo "session id: " . s:sessionId
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
    elseif a:target == "simple"
      let data = s:dumpSummarySimple( jsonobj.items)
    elseif a:target == "detail"
      let data = s:dumpSummaryDetail( jsonobj.items)
    else
      let data = s:dumpSummarySimple( jsonobj.items)
    endif
    execute ":normal ggdGa" . data
    execute ":normal gg"
  catch
    echo v:exception
  endtry
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
        let l:body = join( getline( l:pos + 1 , line("$") ) , "\n" )
        let l:hash[ f ] = system( 'pandoc -f markdown -t html' , l:body )
      elseif f == "categories"
        call cursor( l:pos + 1 , 1 )
        let l:hash[ f ] = map( getline( l:pos + 1 , search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 ) , function('s:str2dict') )
      elseif f == "tags"
        call cursor( l:pos + 1 , 1 )
        let l:hash[ f ] = getline( l:pos + 1 , search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 )
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

  try
    let l:entryBody =  s:readBuffer()
    let l:param = s:Json.encode( l:entryBody )
    let l:param = { "entry": l:param , "publish": "1" }

    call s:updateAccessToken()
    let res = s:Http.post( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
    if res.status != 200
      echoe "in s:mtdataapi#createEntry(),\n got status: " . res.status . " with messages followings"
      return
    endif

    let jsonobj = s:Json.decode(res.content)
    let data = s:dumpEntry( jsonobj )
    execute ":normal ggdGa" . data
  catch
    echo v:exception
  endtry
endfunction

function! mtdataapi#editEntry( ) abort
  let siteid=g:mt_siteid
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/sites/" . string(8) . "/entries"

  try
    let l:entryBody =  s:readBuffer()
    if has_key( l:entryBody , "id" )
      let dataapiendpoint .= "/" . l:entryBody["id"]
      unlet l:entryBody["id"]
      let l:entryBody["__method"] = "PUT"
    endif
    let l:param = s:Json.encode( l:entryBody )
    let l:param = { "entry": l:param , "publish": "1" }

    call s:updateAccessToken()
    let res = s:Http.request( { "url": dataapiurl . dataapiendpoint , "data": l:param , "headers": s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} , "method": "PUT" } )
    if res.status != 200
      echoe "got abnormal status code  by http request in s:mtdataapi#editEntry()\n got status: " . res.status . " with messages followings"
      return
    endif

    let jsonobj = s:Json.decode(res.content)
    let data = s:dumpEntry( jsonobj )
    execute ":normal ggdGa" . data
  catch
    echo v:exception
  endtry
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
