val nohdr = <xml/>

val noload = return ()

fun page (ptitle : string) (hdr : xbody) (onloadf : transaction unit) (content : xbody) : page =
    <xml>
      <head>
        <title>{[ptitle]}</title>
        <link rel="stylesheet" type="text/css" href="/style.css" />
      </head>
      <body onload={onloadf}>
        <header>
          {hdr}
        </header>
        <section>
          {content}
        </section>
      </body>
    </xml>

fun errorHandler (body : xbody) : transaction page =
    return (page "Error" nohdr noload body)
