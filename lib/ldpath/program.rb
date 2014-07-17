require 'parslet'

class Ldpath::Program < Parslet::Parser
  root :lines
  rule(:lines) { line.repeat }
  rule(:line) { expression >> newline }
  rule(:newline) { any.absent? | str("\n") >> str("\r").maybe }
  rule(:expression) { wsp | multiline_comment | namespace | mapping }
  
  rule(:multiline_comment) { (str('/*') >> (str('*/').absent? >> any).repeat >> str('*/')) }
  
  rule(:comma) { str(",") }
  rule(:scolon) { str(";") }
  rule(:colon) { str(":") }
  rule(:dcolon) { str("::") }
  rule(:assign) { str("=") }
  rule(:k_prefix) { str("@prefix")}
  rule(:k_graph) { str("@graph")}
  
  rule(:self_op) { str(".") }
  rule(:and_op) { str("&") }
  rule(:or_op) { str("|") }
  rule(:p_sep) { str("/") }
  rule(:plus) { str("+") }
  rule(:star) { str("*") }
  rule(:not_op) { str("!") }
  rule(:inverse) { str("^") }
  rule(:is) { str "is" }
  rule(:is_a) { str "is-a" }
  rule(:func) { str "fn:"}
  rule(:type) { str "^^" }
  rule(:lang) { str "@" }
  
  rule(:wsp) { (match["\s"] | str("\n")).repeat(1) }
  rule(:wsp?) { wsp.maybe }
  
  # todo: fixme
  rule(:uri) { (str("<") >> (str(">").absent? >> any).repeat >> str(">")) | (identifier.as(:prefix) >> str(":") >> identifier.as(:localName) )}
  rule(:identifier) { match["a-zA-Z0-9_"] >> (match["a-zA-Z0-9_'\\.-"]).repeat }

  rule(:namespace) { 
    k_prefix >>
    wsp? >>
    identifier.as(:id) >>
    wsp? >>
    colon >>
    wsp? >>
    uri.as(:uri) >>
    wsp? >>
    scolon.maybe
  }
  
  rule(:mapping) {
    name_selector_mapping
  }
  
  rule(:name_selector_mapping) {
    identifier.as(:name) >>
    wsp? >>
    assign >>
    wsp? >>
    selector.as(:selector) >>
    wsp? >>
    (
      dcolon >> wsp? >>
      uri.as(:type)
    ).maybe >>
    wsp? >>
    scolon
  }
  
  rule(:selector) {
    (
      compound_selector |
      testing_selector |
      atomic_selector
    ).as(:result)
  }
  
  rule(:compound_selector) {
    (
      union_selector |
      intersection_selector |
      path_selector
    ).as(:result)
  }
  
  rule(:grouped_selector) {
    wsp? >>
    str("(") >> wsp? >> selector.as(:result) >> wsp? >> str(")") >> wsp?
  }
  
  rule(:path_selector) {
    wsp? >>
    atomic_or_testing_selector.as(:left) >>
    wsp? >>
    p_sep >>
    wsp? >>
    atomic_or_testing_or_path_selector.as(:right) >>
    wsp?
  }
  
  rule(:intersection_selector) {
    wsp? >>
    atomic_or_testing_or_path_selector.as(:left) >>
    wsp? >>
    and_op >>
    wsp? >>
    selector.as(:right) >>
    wsp?
  }
  
  rule(:union_selector) {
    wsp? >>
    atomic_or_testing_or_path_selector.as(:left) >>
    
    wsp? >>
    or_op >>
    
    wsp? >>
    selector.as(:right) >>
    
    wsp?
  }
  
  rule(:atomic_or_testing_or_path_selector) {
    (path_selector | atomic_or_testing_selector).as(:result)
  }
  
  rule(:atomic_or_testing_selector) {
    (testing_selector | atomic_selector).as(:result)
  }
  
  rule(:atomic_selector) {
    (
      self_selector |
      property_selector |
      wildcard_selector | 
      reverse_property_selector |
      function_selector |
      # string_constant_selector |
      # recursive_path_selector |
      grouped_selector
    ).as(:result)
  }
  
  rule(:self_selector) {
    wsp? >> self_op >> wsp?
  }
  
  rule(:property_selector) {
    wsp? >> uri >> wsp?
  }
  
  rule(:reverse_property_selector) {
    wsp? >> inverse >> uri.as(:uri) >> wsp?
  }
  
  rule(:wildcard_selector) {
    wsp? >> star >> wsp?
  }
  
  rule(:testing_selector) {
    wsp? >>
    atomic_selector.as(:delegate) >>
    str("[") >>
    wsp? >>
    node_test.as(:test) >>
    wsp? >>
    str("]") >> wsp?
  }
  
  rule(:node_test) {
    grouped_test |
    not_test |
    and_test |
    or_test |
    atomic_node_test
  }
  
  rule(:grouped_test) {
    wsp? >> str("(") >> wsp? >> node_test >> wsp? >> str(")") >> wsp?
  }
  
  rule(:atomic_node_test) {
    # literal_language_test |
    # literal_type_test |
    is_a_test |
    path_equality_test |
    function_test |
    path_test
  }
  
  rule(:not_test) {
    wsp? >> not_op >> node_test.as(:delegate) >> wsp?
  }
  
  rule(:and_test) {
    wsp? >> atomic_node_test >> wsp? >> and_op >> wsp? >> node_test >> wsp?
  }
  
  rule(:or_test) {
    wsp? >> atomic_node_test >> wsp? >> or_op >> wsp? >> node_test >> wsp?
  }
  
  rule(:strlit) {
    wsp? >> str('"') >> (str('"').absent? >> any).repeat >> str('"') >> wsp?
  }
  
  rule(:node) {
    uri.as(:uri) | strlit.as(:literal)
  }
  
  rule(:is_a_test) {
    wsp? >> is_a >> wsp? >> node.as(:node) >> wsp?
  }
  
  rule(:path_equality_test) {
    selector.as(:path) >> is >> node.as(:node)
  }
  
  rule(:function_selector) {
    (
      func >> identifier.as(:fname) >> str("()") |
      func >> identifier.as(:fname) >> str("(") >>
        wsp? >>
        (selector.as(:argument)) >>
        (
          (wsp? >> str(",") >> wsp? >> selector.as(:argument)).repeat
        ).maybe >>
        wsp? >>
      str(")")
    )
  }
  
  rule(:function_test) {
    (
      func >> identifier.as(:fname) >> str("()") |
      func >> identifier.as(:fname) >> str("(") >>
        wsp? >>
        (selector.as(:argument)) >>
        (
          (wsp? >> str(",") >> wsp? >> selector.as(:argument)).repeat
        ).maybe >>
        wsp? >>
      str(")")
    )
  }
  
  rule(:path_test) {
    (
      path_selector |
      testing_selector |
      atomic_selector
    ).as(:path)
  }
  

end
