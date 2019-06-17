" Vim global plugin for Movable Type
" File:         mtdataapi.vim
" Author:	Seiyo Hiramatsu <hseiyo@gmail.com>
" License:	MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:sessionId = 0
let s:accessToken = "dummystring"
let s:clientId = "mt_dataapi"

" Using Vital.vim
let s:V = vital#mtdataapi#new()
let s:http = s:V.import("Web.HTTP")
let s:json = s:V.import("Web.JSON")


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
  let res = s:http.post( dataapiurl . dataapiendpoint , l:param )

  if res.status != 200
    " at below line, throw is better than echoe?
    echohl ErrorMsg
    echoe "in auth() in s:auth()\n got status: " . res.status . " with messages followings\n" . res.content
    echohl Normal
    " echo res.status
    " echo res.message
    " echo res.header
    " echo res.content
  endif
  let jsonobj = s:json.decode(res.content)
  let s:accessToken = jsonobj.accessToken
  let s:sessionId = jsonobj.sessionId

endfunction

function! s:getNewToken() abort
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/token"
  let l:param = {"clientId": s:clientId }

  let res = s:http.post( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )

  if res.status != 200
    call s:auth()
    return
  endif

  " echo "in s:getNewToken(), got status: " . res.status . " with messages followings"
  " echo res.content
  " echo res.status
  " echo res.message
  " echo res.header
  " echo res.content

  let jsonobj = s:json.decode(res.content)
  let s:accessToken = jsonobj.accessToken

endfunction

function! s:updateAccessToken() abort
  "if accessToken is valid
  if s:sessionId != "0"
    call s:getNewToken()

    "if accessToken is invalid
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
      let l:ret .=  a:obj[k]
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
  let siteid=get(b: , 'mt_siteid' , g:mt_siteid )
  let dataapiurl=get(b: , 'mt_dataapiurl' , g:mt_dataapiurl )
  let dataapiendpoint="/v4/sites/" . string(siteid) . "/entries"

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
    echohl ErrorMsg
    echoe "ERROR: in argument check"
    echohl Normal
  endif

  call s:updateAccessToken()

  let res = s:http.get( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  if res.status != 200
    echohl ErrorMsg
    echoe "getting entries failed in s:mtdataapi#getEntry()\n got status: " . res.status . " with messages followings" . res.content
    echohl Normal
    " echo "url: " . dataapiurl . dataapiendpoint
    " echo "access token: " . s:accessToken
    " echo "session id: " . s:sessionId
    return
  endif

  let jsonobj = s:json.decode(res.content)
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
  let l:pasteOption = &paste
  set paste
  execute ":normal ggdGa" . data
  execute ":normal gg"
  let &paste = l:pasteOption
endfunction

function! mtdataapi#getCategory( target ) abort
  let siteid=get(b: , 'mt_siteid' , g:mt_siteid )
  let dataapiurl=get(b: , 'mt_dataapiurl' , g:mt_dataapiurl )
  let dataapiendpoint="/v4/sites/" . string(siteid) . "/categories"
  let l:returnStr = ""

  if a:target == ""
    let l:param = {"limit": 1000 }
  elseif a:target != ""
    let l:param = {"search": a:target}
  else
    echohl ErrorMsg
    echoe "ERROR: in argument check"
    echohl Normal
  endif

  call s:updateAccessToken()

  let res = s:http.get( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  if res.status != 200
    echohl ErrorMsg
    echoe "getting categories failed in s:mtdataapi#getCategory()\n got status: " . res.status . " with messages followings" . res.content
    echohl Normal
    " echo "url: " . dataapiurl . dataapiendpoint
    " echo "access token: " . s:accessToken
    " echo "session id: " . s:sessionId
    return
  endif

  let jsonobj = s:json.decode(res.content)
  " echo jsonobj
  " echo jsonobj.totalResults
  " echo jsonobj.items
  " echo jsonobj.items

  " echo jsonobj.items[0]
  " echo jsonobj.items[0]

  for l:c in jsonobj.items
    let l:returnStr .= l:c.id . ":" . l:c.label . "\n"
  endfor

  return l:returnStr
  " execute ":normal ggdGa" . data
  " execute ":normal gg"
  let &paste = l:pasteOption
endfunction

function! mtdataapi#makeEmpty() abort
  let l:emptyEntry = ""
  let l:emptyEntry .= "# status # Draft or Publish\n"
  let l:emptyEntry .= "Draft\n"
  let l:emptyEntry .= "# categories # delete line if you don't that is not suitable for this entry\n"
  let l:emptyEntry .= mtdataapi#getCategory( "" )
  let l:emptyEntry .= "# title # \n"
  let l:emptyEntry .= "title of this entry\n"
  let l:emptyEntry .= "# body # \n"
  let l:emptyEntry .= "body of this entry\n"
  enew
  execute ":normal a" . l:emptyEntry
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

  "read and delete lines
  for f in s:entryFields
    call cursor(1,1)
    let l:pos = search( "^# " . f . " #" , 'cnW' , len( s:entryFields ) * 2 )
    if l:pos > 0
      if f == "body"
        let l:body = join( getline( l:pos + 1 , line("$") ) , "\n" )
        let l:hash[ f ] = l:body
        execute ":" . l:pos + 1 . ",$delete"
      elseif f == "categories"
        call cursor( l:pos + 1 , 1 )
        let l:hash[ f ] = map( getline( l:pos + 1 , search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 ) , function('s:str2dict') )
        execute ":" . l:pos + 1 . "," . search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 . "delete"
      elseif f == "tags"
        call cursor( l:pos + 1 , 1 )
        let l:hash[ f ] = getline( l:pos + 1 , search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 )
        execute ":" . l:pos + 1 . "," . search( "^# " , 'cnW' , len( s:entryFields ) * 2 ) - 1 . "delete"
      else
        " set next line
        let l:hash[ f ] = getline( l:pos + 1 )
        execute ":delete " . l:pos + 1
      endif
    endif
  endfor

  "restore lines are deleted
  call cursor(1,1)
  execute ":normal A" . s:dumpEntry( l:hash )

  return l:hash

endfunction

function! mtdataapi#createEntry( ) abort
  let siteid=get(b: , 'mt_siteid' , g:mt_siteid )
  let dataapiurl=get(b: , 'mt_dataapiurl' , g:mt_dataapiurl )
  let dataapiendpoint="/v4/sites/" . string(siteid) . "/entries"

  let l:entryBody =  s:readBuffer()

  if l:entryBody["title"] =~ "^[\s]*$"
    echohl ErrorMsg
    echoe "title is empty! Specify something!"
    echohl Normal
    return
  endif

  let l:param = s:json.encode( l:entryBody )
  let l:param = { "entry": l:param , "publish": "1" }

  call s:updateAccessToken()

  let res = s:http.post( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  if res.status != 200
    echohl ErrorMsg
    echoe "in s:mtdataapi#createEntry(),\n got status: " . res.status . " with messages followings"
    echohl Normal
    return
  endif

  let jsonobj = s:json.decode(res.content)
  let data = s:dumpEntry( jsonobj )
  let l:pasteOption = &paste
  set paste
  execute ":normal ggdGa" . data
  execute ":normal gg"
  let &paste = l:pasteOption
endfunction

function! mtdataapi#editEntry( ) abort
  let siteid=get(b: , 'mt_siteid' , g:mt_siteid )
  let dataapiurl=get(b: , 'mt_dataapiurl' , g:mt_dataapiurl )
  let dataapiendpoint="/v4/sites/" . string(siteid) . "/entries"

  let l:entryBody =  s:readBuffer()

  if l:entryBody["title"] =~ "^[\s]*$"
    echohl ErrorMsg
    echoe "title is empty! Specify something!"
    echohl Normal
    return
  endif

  if has_key( l:entryBody , "id" )
    let dataapiendpoint .= "/" . l:entryBody["id"]
    unlet l:entryBody["id"]
    let l:entryBody["__method"] = "PUT"
  else
    "do nothing
    return
  endif
  let l:param = s:json.encode( l:entryBody )
  let l:param = { "entry": l:param , "publish": "1" }

  call s:updateAccessToken()
  let res = s:http.request( { "url": dataapiurl . dataapiendpoint , "data": l:param , "headers": s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} , "method": "PUT" } )
  if res.status != 200
    echohl ErrorMsg
    echoe "got abnormal status code  by http request in s:mtdataapi#editEntry()\n got status: " . res.status . " with messages followings"
    echohl Normal
    return
  endif

  let jsonobj = s:json.decode(res.content)
  let data = s:dumpEntry( jsonobj )

  let l:pasteOption = &paste
  set paste
  execute ":normal ggdGa" . data
  let &paste = l:pasteOption
endfunction

function! mtdataapi#markdownToHTML( ) range abort
  echo "line is " . a:firstline  . "," . a:lastline
  let l:orgstr = join( getline( a:firstline , a:lastline ) , "\n" )
  let l:newstr = system( 'pandoc -f markdown -t html' , l:orgstr )
  execute a:firstline . "," . a:lastline . "delete"
  execute a:firstline - 1
  execute "normal o" . l:newstr
endfunction

function! mtdataapi#HTMLToMarkdown( ) range abort
  " TODO: add pandoc's version check or condition for raw option
  " let l:ret .= system( 'pandoc -R -f html -t markdown' , a:obj[k] )

  echo "line is " . a:firstline  . "," . a:lastline
  let l:orgstr = join( getline( a:firstline , a:lastline ) , "\n" )
  let l:newstr = system( 'pandoc -f html+raw_html -t markdown' , l:orgstr )
  execute a:firstline . "," . a:lastline . "delete"
  execute a:firstline - 1
  execute "normal o" . l:newstr
endfunction

function! mtdataapi#downloadSiteToFile( ) abort
  set paste
  let siteid=get(b: , 'mt_siteid' , g:mt_siteid )
  let dataapiurl=get(b: , 'mt_dataapiurl' , g:mt_dataapiurl )
  let basedir=g:mt_basedir . "/" . siteid . "/"
  let dataapiendpoint="/v4/sites/" . string(siteid) . "/entries"
  let l:param = {"limit": "9999"}

  call mkdir( basedir, "p" , 0700)

  call s:updateAccessToken()

  let res = s:http.get( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  if res.status != 200
    echohl ErrorMsg
    echoe "getting entries failed in s:mtdataapi#getEntry()\n got status: " . res.status . " with messages followings" . res.content
    echohl Normal
    " echo "url: " . dataapiurl . dataapiendpoint
    " echo "access token: " . s:accessToken
    " echo "session id: " . s:sessionId
    return
  endif

  let jsonobj = s:json.decode(res.content)
  " echo jsonobj
  " echo jsonobj.totalResults
  " echo "jsonobj.items"
  " echo jsonobj.items

  " echo "jsonobj.items[0]"
  " echo jsonobj.items[0]

  let l:pasteOption = &paste
  set paste
  execute ":new"

  "write siteid to .siteconfig in basedir"
  execute ":normal ggdGa" . "let b:mt_siteid = " . siteid
  execute ":normal o" . "let b:mt_dataapiurl = " . '"' . dataapiurl . '"'
  execute ":w! " . basedir . ".siteconfig"

  "write each entries to file"
  for itm in jsonobj.items
    let data = s:dumpEntry( itm )

    execute ":normal ggdGa" . data
    execute ":normal gg"
    execute ":w! " . basedir . itm.id
  endfor
  execute ":q!"
  let &paste = l:pasteOption
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
