let s:sessionId = 0


  " for create post
  " entry={"excerpt" ,"status" ,"allowComments" ,"body" ,"keywords" ,"allowTrackbacks" ,"basename" ,"title" ,"more" ,"customFields" }
  " entry={
  "       \ "excerpt" : "We are excited to announce that Six Apar-",
  "       \ "status" : "Publish",
  "       \ "allowComments" : true,
  "       \ "body" : "¥u003cp¥u003e¥u003cspan¥u003eWe are excited to announce that Six Apart has acquired Topics, a dynamic online publishing product. This offering will provide Six Apart customers with an easy and cost-effective way to adapt existing content to evolving digital platforms.¥u003c/span¥u003e¥u003c/p¥u003e¥n¥u003cp¥u003e¥u003cspan¥u003eThis new product will save Six Apart customers a significant amount of time and money by allowing users to upgrade their websites and applications without migrating from their current content management systems. Clients who need to scale large amounts of data or even revamp a website on an entirely new platform can now achieve these changes with minimal effort.¥u003c/span¥u003e¥u003c/p¥u003e¥n¥u003cp¥u003e¥u003cspan¥u003eSix Apart customers will benefit not only from saved time and money, but also from ease of use. Topics does not have a user interface, so there is no new software to learn. Instead, it exists as a middle layer between the data library and the published page - automatically gathering, organizing and redistributing data.¥u003c/span¥u003e¥u003c/p¥u003e",
  "       \ "keywords" : "",
  "       \ "allowTrackbacks" : false,
  "       \ "basename" : "six_apart_acquires_topics_server_to_simplify_site_upgrades",
  "       \ "title" : "Six Apart Acquires Topics Server to Simplify Site Upgrades",
  "       \ "more" : "",
  "       \ "customFields" : [
  "       \ {"basename" : "place",
  "       \ "value" : "New York City"},
  "       \ {"basename" : "agenda",
  "       \ "value" : "Movable Type¥nTopics"}]
  "       \ }



function! mtdataapi#dumpobj(showlist, header, obj) abort
  let l:ret = ""

  if type( a:obj ) == 0
    let l:ret .= string(a:obj) . "\n"
  elseif type( a:obj ) == 1
    let l:ret .= a:obj . "\n"
  elseif type( a:obj ) == 3
    let l:ret .=  a:header . " " . " #:array" . "\n"
    for i in a:obj
      let l:ret .= mtdataapi#dumpobj( a:showlist , a:header . "#" , i ) 
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
      let l:ret .= mtdataapi#dumpobj( a:showlist , a:header . "#" , a:obj[k] ) 
    endfor
  else
    echo "ERROR: ??? " . type( a:obj ) . a.obj
  endif
  return l:ret
endfunction

function! mtdataapi#dumpdetail( header, obj) abort
  " let invisible = [ "more" , "trackbackCount" , "customFields" , "updatable" , "assets" , "allowTrackbacks" , "comments" , "author" , "commentCount" , "pingsSentUrl" , "allowComments" , "trackbacks" , "class" , "blog"]
  " top level
  let visible = [ "id" , "status" , "permalink" ,"basename" , "categories" , "keywords" , "tags" , "createdDate" , "modifiedDate" , "date", "title" , "excerpt" , "body" ]
  " second level
  let visible += [ "label" ]"
  return mtdataapi#dumpobj( visible , a:header , a:obj )
endfunction

function! mtdataapi#dumpsummary( header, obj) abort
  " top level
  let visible = [ "id" , "status" , "permalink" , "categories" , "keywords" , "tags" , "createdDate" , "modifiedDate" , "date", "title" ]
  " second level
  let visible += [ "label" ]"
  return mtdataapi#dumpobj( visible , a:header , a:obj )
endfunction

function! mtdataapi#dumpauth( header, obj) abort
  " top level
  let visible = [ "accessToken" , "sessionId" , "expiresIn" , "remember" ]
  return mtdataapi#dumpobj( visible , a:header , a:obj )
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
    let data = mtdataapi#dumpdetail( "#" , jsonobj )
  else
    let data = mtdataapi#dumpsummary( "#" , jsonobj.items)
  endif
  execute ":normal ggdGa" . data
endfunction

function! s:auth() abort
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/authentication"
  let l:param = {"username": g:mt_username , "password": g:mt_password , "clientId": "mt_dataapi" , "remember": "1" }
  let res = webapi#http#post( dataapiurl . dataapiendpoint , l:param )
  " echo res
  " echo res.status
  " echo res.message
  " echo res.header
  " echo res.content
  let jsonobj = webapi#json#decode(res.content)
  let s:accessToken = jsonobj.accessToken
  let s:sessionId = jsonobj.sessionId

  " let data = mtdataapi#dumpdetail( "#" , jsonobj )
  " execute ":normal ggdGa" . data
endfunction

function! s:getNewToken() abort
  let dataapiurl=g:mt_dataapiurl
  let dataapiendpoint="/v4/token"
  let l:param = {"clientId": "mt_dataapi" }
  let res = webapi#http#post( dataapiurl . dataapiendpoint , l:param , "X-MT-Authorization: MTAuth sessionId=" . s:sessionId")
  " echo res
  " echo res.status
  " echo res.message
  " echo res.header
  " echo res.content
  let jsonobj = webapi#json#decode(res.content)
  let s:accessToken = jsonobj.accessToken

  " let data = mtdataapi#dumpdetail( "#" , jsonobj )
  " execute ":normal ggdGa" . data
endfunction

function! s:updateAccessToken() abort
  if s:sessionId
    call s:getNewToken()
  else
    call s:auth()
  endif
endfunction

