# vim-mtdataapi

This is vim plugin for Movable Type.

# Commands
There are several commands.

MtGet
MtEdit
MtCreate

# Usage
## MtGet

-MtGet "latest"
get the latest entry.

-MtGet <entry id>
get the entry specified id.
Ex. Mtget 8

-MtGet "recent"
get the summary of recent 50 entries .

## MtEdit
Update entry which is already exists.
Before edit, use MtGet "latest" or MtGet <entry id>.
Next, you edit current buffer.
Finally, execute MtEdit so that send the content of buffer to Movabe Type Server.

## MtCreate
Create new entry with the content of current buffer that is like followings:
    # status #
    Draft
    # title #
    Draft Entry
    # body #
    Draft Body

# Variables

-g:mt_siteid
Movable Type Site ID. (ex. 1)

-g:mt_dataapiurl
Movable Type Site URL. (ex. "https://www.example.com/mt-data-api.cgi" )

-g:mt_username
Movable Type Login User. (ex. "username" )

-g:mt_password
Movable TYpe Web Service Password. (ex. "password" )
