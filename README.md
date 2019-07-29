# vim-mtdataapi

This is vim plugin for Movable Type.

[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)

# Commands
There are several commands.

- MtOpen
- MtVew
- MtNew
- MtCreate
- MtSave
- MtDownload
- MtMDToHTML
- MtHTMLToMD

# Usage
## MtOpen
-MtOpen <entry id>
open a entry file.
if specified file does not exist, the entry will be downloaded from Movable Type to a file.

## MtView
-MtView "latest"
get the latest entry.
This is similar to MtOpen, but MtView always download from Movable type althogh the entry file exists.
And MtView does not open a file, so the downloaded data is in new buffer.

-MtView <entry id>
get the entry specified id.
Ex. MtView 8

-MtView "recent"
get the summary of recent 50 entries .

## MtNew
Open new buffer with skeleton for entry.
If you want to upload the contents, use MtCreate.

## MtCreate
Create new entry with the content of current buffer that is like followings:

    # status #
    Draft
    # title #
    Draft Entry
    # body #
    Draft Body

If success to upload, new entry is created and downloaded as a file.
Then, open the file.

## MtSave
Update entry on Movable Type.
Before edit, use MtOpen <entry id> or MtCreate.
Next, you edit current buffer.
Finally, execute MtSave.

## MtDownload
Download entries from Movable Type to local disk.

-MtDownload <entry id>
Download one entry to a file.

-MtDownload
Download all entry to files.( up to 9999 entries)

## MtMDToHTML
Convert visual selected text from Markdown to HTML

## MtHTMLToMD
Convert visual selected text from HTML to Markdown

# Variables

- g:mt_siteid

Movable Type Site ID. (ex. 1)

- g:mt_dataapiurl

Movable Type Site URL. (ex. "https://www.example.com/mt-data-api.cgi" )

- g:mt_username

Movable Type Login User. (ex. "username" )

- g:mt_password

Movable TYpe Web Service Password. (ex. "password" )

- g:mt_basedir

destination directory for download
