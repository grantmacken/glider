function($Map as map(*)) as element() {
element html {
  attribute lang {'en'},
  element head {
 element meta {
    attribute charset {'UTF-8'}},
    element meta {
      attribute name { 'viewport'},
      attribute content { 'width=device-width, initial-scale=1'}},
    element title { $Map?title },
    element link { 
      attribute rel {'icon'},
      attribute href { '/assets/images/favicon.ico'},
      attribute sizes {'any'}},
    element link { 
      attribute rel {'stylesheet'},
      attribute href {'/assets/styles/missing/' || $Map?assets?missing || '/missing.css'},
      attribute type {'text/css'}},
    element link { 
      attribute rel {'stylesheet'},
      attribute href {'/assets/styles/missing/' || $Map?assets?missing || '/missing-prism.css'},
      attribute type {'text/css'}},
    element link { 
      attribute rel {'stylesheet'},
      attribute href {'/assets/styles/asciinema/' || $Map?assets?asciinema || '/asciinema-player.css'},
      attribute type {'text/css'}},
    element script { attribute src {'/assets/scripts/prismjs/' || $Map?assets?prismjs || '/components/prism-core.min.js'}},
    element script { attribute src {'/assets/scripts/prismjs/' || $Map?assets?prismjs || '/plugins/autoloader/prism-autoloader.min.js'}},
    element script { attribute src {'/assets/scripts/prismjs/' || $Map?assets?prismjs || '/components/prism-xquery.min.js'}},
    element script { attribute src {'/assets/scripts/asciinema/v3.0.1/asciinema-player.min.js'}},
    element script { attribute src {'/assets/scripts/htmx/' || $Map?assets?htmx || '/htmx.js'}},
    element script { text {'htmx.onLoad(function(){
    Prism.highlightAll();
    AsciinemaPlayer.create("/assets/casts/xqerl-up-and-flying.cast", 
    document.getElementById("demo"), 
    {poster: "npt:1:00",fit: false }); 
    })'}},
    element style { text {' 
    :root {
      --main-font: "IBM Plex Sans", sans-serif;
      --secondary-font: "IBM Plex Serif", serif;
      --mono-font: "IBM Plex Mono", monospace, monospace;
      }
    '}}},
  element body {
    element header { 
      element h1 { 
        element span { 
          attribute class { 'allcaps' },
          text {$Map?title },
          element v-h {':'}},
        element sub-title { $Map?subtitle }},
      element nav { 
        element p { 
          attribute class { 'tool-bar' },
          element a { attribute href { '/'}, text { 'docs'}}}}},
    element main { $Map?content }}}
}
