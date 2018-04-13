fun page (ptitle : string) (hdr : xbody) (onloadf : transaction unit) (content : xbody) : page =
    <xml>
      <head>
        <title>{[ptitle]}</title>
        <link rel="stylesheet" type="text/css" href="/style.css" />
        <link rel="stylesheet" type="text/css" href="/spinner.css" />
      </head>
      <body onload={onloadf}>
        <header>
          {hdr}
        </header>
        {content}
      </body>
    </xml>

val nohdr = <xml/>

val noload = return ()

fun errorHandler (body : xbody) : transaction page =
    return (page "Error" nohdr noload body)

style sk_cube_grid
style sk_cube
style sk_cube1
style sk_cube2
style sk_cube3
style sk_cube4
style sk_cube5
style sk_cube6
style sk_cube7
style sk_cube8
style sk_cube9

val spinner =
    <xml>
      <div class="sk_cube-grid">
        <div class="sk_cube sk_cube1"></div>
        <div class="sk_cube sk_cube2"></div>
        <div class="sk_cube sk_cube3"></div>
        <div class="sk_cube sk_cube4"></div>
        <div class="sk_cube sk_cube5"></div>
        <div class="sk_cube sk_cube6"></div>
        <div class="sk_cube sk_cube7"></div>
        <div class="sk_cube sk_cube8"></div>
        <div class="sk_cube sk_cube9"></div>
      </div>
    </xml>
