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
      attribute sizes {'any'},
    element link { 
      attribute rel {'stylesheet'},
      attribute href {'/assets/styles/index.css'},
      attribute type {'text/css'}},
    element script { attribute src {'/assets/scripts/htmx.min.js'}},
    element script { attribute src {'/assets/scripts/prism.js'}},
    element script { text {'htmx.onLoad(function(){Prism.highlightAll();})'}}}},
    element header {
      attribute role { 'banner' },
      element h1 { $Map?title  }},
  element main { $Map?content},
  element footer { }}
}

