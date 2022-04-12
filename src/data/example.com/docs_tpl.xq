function($map) {
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
      attribute href { "/assets/styles/index.css"},
      attribute type {"text/css"}
    },  
    element link { 
      attribute rel {"icon"},
      attribute href { "/assets/images/favicon.ico"},
      attribute sizes {"any"}
    },
    element script {
      attribute src { '/assets/scripts/prism.js' }
    }
  },
  element body{
    element img { 
     attribute src { "/assets/images/logo.png" },
     attribute alt { "xqerl logo" }
     },
    element h1 {  $map?title   },
    element main { $map('content') }
    }
  }
}

