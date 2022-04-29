function($map as map(*)) as element() {
  element html {
  attribute lang {'en'},
    element head {
    element title { $map?title },
    element meta {
      attribute http-equiv { "Content-Type"},
      attribute content { "text/html; charset=UTF-8"}
      },
    element link { 
      attribute rel {"stylesheet"},
      attribute href { "/assets/styles/sakura.css"},
      attribute type {"text/css"}
    },  
    element link { 
      attribute rel {"icon"},
      attribute href { "/assets/images/favicon.ico"},
      attribute sizes {"any"}
    }
  },
  element body{
    element img { 
     attribute src { "/assets/images/logo.png" },
     attribute alt { "xqerl logo" }
     },
    element h1 { $map?title   },
    element main { $map('content') }
    }
  }
}
