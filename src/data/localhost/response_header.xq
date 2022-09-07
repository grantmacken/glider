function($Map as map(*)) as element() {
element rest:response {
  element http:response {
  attribute status { $Map?status },
  attribute message {$Map?message },
  element http:header {
    attribute name {'Content-Type'},
    attribute value {'text/html'}}}}
}
