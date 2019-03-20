let s:sessionId = 0

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
  let l:param = {"username": g:mt_username , "password": g:mt_password , "clientId": "mt_dataapi" , "remember": "1" }
  let res = webapi#http#post( dataapiurl . dataapiendpoint , l:param )
  " echo "in auth()"
  " echo res
  " echo res.status
  " echo res.message
  " echo res.header
  " echo res.content
  let jsonobj = webapi#json#decode(res.content)
  let s:accessToken = jsonobj.accessToken
  let s:sessionId = jsonobj.sessionId

  " let data = s:dumpdetail( "#" , jsonobj )
  " execute ":normal ggdGa" . data
endfunction

function! s:getNewToken() abort
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/token"
  let l:param = {"clientId": "mt_dataapi" }
  let res = webapi#http#post( dataapiurl . dataapiendpoint , l:param , "X-MT-Authorization: MTAuth sessionId=" . s:sessionId")
  " echo "in getNewToken()"
  " echo res
  " echo res.status
  " echo res.message
  " echo res.header
  " echo res.content
  let jsonobj = webapi#json#decode(res.content)
  let s:accessToken = jsonobj.accessToken

  " let data = s:dumpdetail( "#" , jsonobj )
  " execute ":normal ggdGa" . data
endfunction

function! s:updateAccessToken() abort
  if s:sessionId
    call s:getNewToken()
  else
    call s:auth()
  endif
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

function! mtdataapi#get( target ) abort
  let siteid=g:mt_siteid
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/sites/" . string(8) . "/entries"
  let l:param = {"limit": "1"}
  if a:target == "latest"
    " do nothing. use default param"
  elseif a:target == "recent"
    let l:param["limit"] = 50
  elseif type( a:target ) == 0
    let dataapiendpoint .= "/" . a:target
    let l:param = {}
  else
    echo "ERROR: in argument check"
  endif


  call s:updateAccessToken()
  let res = webapi#http#get( dataapiurl . dataapiendpoint , l:param , s:accessToken ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  " echo res
  " echo res.status
  " echo res.message
  " echo res.header
  " echo res.content
  let jsonobj = webapi#json#decode(res.content)
  " echo jsonobj
  " echo jsonobj.totalResults
  " echo "jsonobj.items"
  " echo jsonobj.items

  " echo "jsonobj.items[0]"
  " echo jsonobj.items[0]

  if type( a:target ) == 0
    let data = s:dumpobj( s:entryFields , "#" , jsonobj )
  else
    let data = s:dumpobj( s:summaryFields , "#" , jsonobj.items)
  endif
  execute ":normal ggdGa" . data
endfunction

function! s:readBuffer() abort
  let l:hash = {}
  let l:retstr = ""
  let l:lastlineno = line("$")

  call cursor(1,1)
  for f in s:entryFields
    let l:pos = search( "^# " . f . " #" , 'nW' , len( s:entryFields ) * 2 )
    if l:pos > 0
      if f == "body"
        let l:hash[ f ] = join( getline( l:pos + 1 , line("$") ) , "\n" )
      else
        " set next line
        let l:hash[ f ] = getline( l:pos + 1 )
      endif
    endif
  endfor
  for k in keys(l:hash )
    let l:retstr .= k . "=" . l:hash[k] . "&"
  endfor
  let l:retstr = substitute( l:retstr , "&$" , "" , "")
  return l:retstr

 endfunction

function! mtdataapi#createEntry( ) abort
  let siteid=g:mt_siteid
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/sites/" . string(8) . "/entries"
  " let l:param = {}
  let l:entryBody =  s:readBuffer()
  let l:param = "entry={" . webapi#http#encodeURI(l:entryBody) . "}&publish=1"
  " echo l:param

  call s:updateAccessToken()
  let res = webapi#http#post( dataapiurl . dataapiendpoint , l:param , s:accessToken != "" ? { "X-MT-Authorization": "MTAuth accessToken=" . s:accessToken } : {} )
  echo res
  " echo res.status
  " echo res.message
  " echo res.header
  " echo res.content
  let jsonobj = webapi#json#decode(res.content)
  " echo jsonobj
  " echo jsonobj.totalResults
  " echo "jsonobj.items"
  " echo jsonobj.items

  " echo "jsonobj.items[0]"
  " echo jsonobj.items[0]

  let data = s:dumpobj( s:entryFields , "#" , jsonobj )
  execute ":normal ggdGa" . data
endfunction

