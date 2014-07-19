require 'parslet'

module Ldpath
  class Parser < Parslet::Parser
    root :lines
    rule(:lines) { line.repeat }
    rule(:line) { expression >> nl_or_eof }
    rule(:newline) {  (str("\n") >> str("\r").maybe).repeat(1) }
    rule(:nl_or_eof) { newline | any.absent? }
    rule(:expression) { wsp | multiline_comment | namespace | mapping | graph }
    
    rule(:multiline_comment) { wsp? >> (str('/*') >> (str('*/').absent? >> any).repeat >> str('*/') >> wsp?) }
    
    rule(:int) { match("\\d+") }
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
    
    rule(:wsp) { (match["\\t "]).repeat(1) }
    rule(:wsp?) { wsp.maybe }
    
    # todo: fixme
    rule(:uri) { (str("<") >> (str(">").absent? >> any).repeat.as(:uri) >> str(">")) | (identifier.as(:prefix) >> str(":") >> identifier.as(:localName) ).as(:uri)}
    rule(:identifier) { match["a-zA-Z0-9_"] >> (match["a-zA-Z0-9_'\\.-"]).repeat }

    rule(:namespace) { 
      (
      wsp? >>
      k_prefix >>
      wsp? >>
      identifier.as(:id) >>
      wsp? >>
      colon >>
      wsp? >>
      uri.as(:uri) >>
      wsp? >>
      scolon.maybe >>
      wsp?
      ).as(:namespace)
    }
    
    rule(:graph) {
      k_graph >> wsp? >> uri_list.as(:graphs) >> wsp? >> scolon
    }
    
    rule(:uri_list) {
      wsp? >> 
      uri.as(:uri) >>
      (wsp? >> comma >> wsp? >> uri_list.as(:rest)).repeat
    }
    
    rule(:mapping) {
      name_selector_mapping.as(:mapping)
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
        uri.as(:field_type)
      ).maybe >>
      wsp? >>
      scolon
    }
    
    rule(:selector) {
      (
        compound_selector |
        testing_selector |
        atomic_selector
      )
    }
    
    rule(:compound_selector) {
      (
        union_selector |
        intersection_selector |
        path_selector
      )
    }
    
    rule(:grouped_selector) {
      wsp? >>
      str("(") >> wsp? >> selector >> wsp? >> str(")") >> wsp?
    }
    
    rule(:path_selector) {
      (
      wsp? >>
      atomic_or_testing_selector.as(:left) >>
      wsp? >>
      p_sep >>
      wsp? >>
      atomic_or_testing_or_path_selector.as(:right) >>
      wsp?
      ).as(:path)
    }
    
    rule(:intersection_selector) {
      (
      wsp? >>
      atomic_or_testing_or_path_selector.as(:left) >>
      wsp? >>
      and_op >>
      wsp? >>
      selector.as(:right) >>
      wsp?
      ).as(:intersection)
    }
    
    rule(:union_selector) {
      (
      wsp? >>
      atomic_or_testing_or_path_selector.as(:left) >>
      
      wsp? >>
      or_op >>
      
      wsp? >>
      selector.as(:right) >>
      
      wsp?
      ).as(:union)
    }
    
    rule(:atomic_or_testing_or_path_selector) {
      (path_selector | atomic_or_testing_selector)
    }
    
    rule(:atomic_or_testing_selector) {
      (testing_selector | atomic_selector)
    }
    
    rule(:atomic_selector) {
      (
        self_selector |
        function_selector |
        property_selector |
        wildcard_selector | 
        reverse_property_selector |
        string_constant_selector |
        recursive_path_selector |
        grouped_selector
      )
    }
    
    rule(:string_constant_selector) {
      strlit
    }
    
    rule(:recursive_path_selector) {
      (
      wsp? >> 
      str("(") >> 
      selector.as(:delegate) >>
      wsp? >> 
      str(")") >>
      (
        star |
        plus |
        (str("{") >> wsp? >> int.as(:min).maybe >> wsp? >>str(",") >> wsp? >> int.as(:max).maybe >> wsp? >>str("}") ).as(:range)
      ).as(:repeat)
      ).as(:recursive)
    }
    
    rule(:self_selector) {
      wsp? >> self_op.as(:self) >> wsp?
    }
    
    rule(:property_selector) {
      wsp? >> uri.as(:property) >> wsp?
    }
    
    rule(:reverse_property_selector) {
      (wsp? >> inverse >> uri.as(:reverse_property) >> wsp?)
    }
    
    rule(:wildcard_selector) {
      wsp? >> star.as(:wildcard) >> wsp?
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
      literal_language_test |
      literal_type_test |
      is_a_test |
      path_equality_test |
      function_test |
      path_test
    }
    
    rule(:literal_language_test) {
      wsp? >> lang >> identifier.as(:lang) >> wsp?
    }
    
    rule(:literal_type_test) {
      wsp? >> type >> uri.as(:type) >> wsp?
    }
    
    rule(:not_test) {
      wsp? >> not_op >> node_test.as(:delegate) >> wsp?
    }
    
    rule(:and_test) {
      (wsp? >> atomic_node_test.as(:left) >> wsp? >> and_op >> wsp? >> node_test.as(:right) >> wsp?).as(:and_test)
    }
    
    rule(:or_test) {
      (wsp? >> atomic_node_test.as(:left) >> wsp? >> or_op >> wsp? >> node_test.as(:right) >> wsp?).as(:or_test)
    }
    
    rule(:strlit) {
      wsp? >> str('"') >> (str('"').absent? >> any).repeat.as(:literal) >> str('"') >> wsp?
    }
    
    rule(:node) {
      uri.as(:uri) | strlit.as(:literal)
    }
    
    rule(:is_a_test) {
      (wsp? >> is_a >> wsp? >> node.as(:node) >> wsp?).as(:is_a)
    }
    
    rule(:path_equality_test) {
      (selector.as(:path) >> is >> node.as(:node)).as(:is)
    }
    
    rule(:arglist) {
      wsp? >>
      selector >> 
      (wsp? >> comma >> wsp? >> selector).repeat >>
      wsp?
    }
    
    rule(:function_selector) {
        func >> identifier.as(:fname) >> str("()") |
        func >> identifier.as(:fname) >> str("(") >>
          arglist.as(:arglist) >>
        str(")")
    }
    
    rule(:function_test) {
      func >> identifier.as(:fname) >> str("()") |
      func >> identifier.as(:fname) >> str("(") >>
          arglist.as(:arglist) >>
      str(")")
    }
    
    rule(:path_test) {
      (
        path_selector |
        testing_selector |
        atomic_selector
      )
    }
  end
end
