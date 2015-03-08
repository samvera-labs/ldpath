require 'parslet'

module Ldpath
  class Parser < Parslet::Parser
    root :lines
    rule(:lines) { line.repeat }
    rule(:line) { expression >> wsp? >> (newline | eof) }

    rule(:newline) {  (str("\n") >> str("\r").maybe).repeat(1) }
    rule(:eof) { any.absent? }
    rule(:wsp) { (match["\\t "] | multiline_comment).repeat(1) }
    rule(:wsp?) { wsp.maybe }
    rule(:multiline_comment) { (str('/*') >> (str('*/').absent? >> any).repeat >> str('*/') ) }

    rule(:expression) { wsp | namespace | mapping | graph }
    
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
    rule(:tap) { str("?") }
    rule(:is) { str "is" }
    rule(:is_a) { str "is-a" }
    rule(:func) { str "fn:"}
    rule(:type) { str "^^" }
    rule(:lang) { str "@" }
    rule(:loose) { str("~") }
    
    # todo: fixme
    rule(:uri) do
      uri_in_brackets | 
      prefix_and_localname
    end
    
    rule(:uri_in_brackets) do
      str("<") >> (str(">").absent? >> any).repeat.as(:uri) >> str(">")
    end
    
    rule(:prefix_and_localname) do
      (identifier.as(:prefix) >> str(":") >> identifier.as(:localName)).as(:uri)
    end
    
    rule(:identifier) { match["a-zA-Z0-9_"] >> (match["a-zA-Z0-9_'\\.-"]).repeat }

    rule(:strlit) {
      wsp? >> 
      str('"') >> (str("\\") >> str("\"") | (str('"').absent? >> any)).repeat.as(:literal) >> str('"') >> 
      wsp?
    }

    rule(:node) {
      uri.as(:uri) | strlit.as(:literal)
    }

    # @prefix id = uri ;
    rule(:namespace) { 
      (
      wsp? >>
      k_prefix >> wsp? >>
      identifier.as(:id) >> wsp? >>
      colon >> wsp? >>
      uri.as(:uri) >> wsp? >>
      scolon.maybe >> wsp?
      ).as(:namespace)
    }
    
    # @graph uri, uri, uri ;
    rule(:graph) {
      k_graph >> wsp? >> 
      uri_list.as(:graphs) >> wsp? >> 
      scolon
    }
    
    rule(:uri_list) {
      wsp? >> 
      uri.as(:uri) >>
      (
        wsp? >> 
        comma >> wsp? >> 
        uri_list.as(:rest)
      ).repeat
    }
    
    # id = . ;
    rule(:mapping) {
      (
        identifier.as(:name) >> wsp? >>
        assign >> wsp? >>
        selector.as(:selector) >> wsp? >>
        (
          dcolon >> wsp? >>
          uri.as(:field_type)
        ).maybe >> wsp? >>
        scolon
      ).as(:mapping)
    }


    # selector groups
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
    
    rule(:testing_selector) {
      wsp? >>
      atomic_selector.as(:delegate) >>
      str("[") >> wsp? >>
      node_test.as(:test) >> wsp? >>
      str("]") >> wsp?
    }

    rule(:atomic_selector) {
      (
        self_selector |
        function_selector |
        property_selector |
        loose_property_selector |
        wildcard_selector | 
        reverse_property_selector |
        string_constant_selector |
        recursive_path_selector |
        grouped_selector |
        tap_selector
      )
    }    


    rule(:atomic_or_testing_selector) {
      (testing_selector | atomic_selector)
    }

    rule(:atomic_or_testing_or_path_selector) {
      (path_selector | atomic_or_testing_selector)
    }

    # Compound selectors
    ## x / y
    rule(:path_selector) {
      (
        wsp? >>
        atomic_or_testing_selector.as(:left) >> wsp? >>
        p_sep >> wsp? >>
        atomic_or_testing_or_path_selector.as(:right) >> wsp?
      ).as(:path)
    }
    
    ## x & y
    rule(:intersection_selector) {
      (
        wsp? >>
        atomic_or_testing_or_path_selector.as(:left) >> wsp? >>
        and_op >> wsp? >>
        selector.as(:right) >> wsp?
      ).as(:intersection)
    }
    
    ## x | y
    rule(:union_selector) {
      (
        wsp? >>
        atomic_or_testing_or_path_selector.as(:left) >> wsp? >>
        or_op >> wsp? >>
        selector.as(:right) >> wsp?
      ).as(:union)
    }

    # Atomic Selectors
    rule(:self_selector) {
      wsp? >> 
      self_op.as(:self) >> wsp?
    }
    
    # fn:x() or fn:x(1,2,3)
    rule(:function_selector) {
      func >> identifier.as(:fname) >> str("()") |
      func >> identifier.as(:fname) >> str("(") >> arglist.as(:arglist) >> str(")")
    }
    
    rule(:arglist) {
      wsp? >>
      selector >> 
      (
        wsp? >> 
        comma >> wsp? >> 
        selector
      ).repeat >>
      wsp?
    }
    
    # xyz
    rule(:loose_property_selector) {
      wsp? >> 
      loose >> 
      wsp? >> 
      uri.as(:loose_property) >> wsp?
    }

    # xyz
    rule(:property_selector) {
      wsp? >> 
      uri.as(:property) >> wsp?
    }

    # *
    rule(:wildcard_selector) {
      wsp? >> 
      star.as(:wildcard) >> wsp?
    }

    # ^xyz
    rule(:reverse_property_selector) {
      wsp? >> 
      inverse >> uri.as(:reverse_property) >> wsp?
    }
    
    rule(:string_constant_selector) {
      strlit
    }
    
    # (x)*
    rule(:recursive_path_selector) {
      (
        wsp? >> 
        str("(") >> wsp? >>
        selector.as(:delegate) >> wsp? >> 
        str(")") >>
        (
          star |
          plus |
          (str("{") >> wsp? >> int.as(:min).maybe >> wsp? >>str(",") >> wsp? >> int.as(:max).maybe >> wsp? >>str("}") ).as(:range)
        ).as(:repeat) >> wsp?
      ).as(:recursive)
    }
    
    rule(:grouped_selector) {
      wsp? >>
      str("(") >> wsp? >> 
      selector >> wsp? >> 
      str(")") >> wsp?
    }

    rule(:tap_selector) {
      wsp? >>
      tap >>
      str("<") >>
      identifier.as(:identifier) >>
      str(">") >>
      (atomic_selector).as(:tap)
    }
    
    # Testing Selectors
    
    rule(:node_test) {
      grouped_test |
      not_test |
      and_test |
      or_test  |
      atomic_node_test
    }

    rule(:atomic_node_test) {
      literal_language_test |
      literal_type_test |
      is_a_test |
      path_equality_test |
      function_test |
      path_test
    }

    rule(:grouped_test) {
      wsp? >> 
      str("(")  >> wsp? >> 
      node_test >> wsp? >> 
      str(")")  >> wsp?
    }
    
    rule(:not_test) {
      (
        wsp? >> 
        not_op >> node_test.as(:delegate) >> 
        wsp?
      ).as(:not)
    }
    
    rule(:and_test) {
      (
        wsp? >> 
        atomic_node_test.as(:left) >> wsp? >> 
        and_op >> wsp? >> 
        node_test.as(:right) >> wsp?
      ).as(:and)
    }
    
    rule(:or_test) {
      (
        wsp? >> 
        atomic_node_test.as(:left) >> wsp? >> 
        or_op >> wsp? >> 
        node_test.as(:right) >> wsp?
      ).as(:or)
    }

    # @en
    rule(:literal_language_test) {
      wsp? >> 
      lang >> identifier.as(:lang) >> 
      wsp?
    }
    
    # ^^xyz
    rule(:literal_type_test) {
      wsp? >> 
      type >> uri.as(:type) >> 
      wsp?
    }
    
    rule(:is_a_test) {
      (
        wsp? >> 
        is_a >> wsp? >> 
        node.as(:right) >> 
        wsp?
      ).as(:is_a)
    }
    
    rule(:path_equality_test) {
      (
        wsp? >>
        selector >> wsp? >>
        is >> wsp? >>
        node.as(:right) >> wsp?
      ).as(:is)
    }
    
    rule(:function_test) {
      wsp? >>
      (
      func >> identifier.as(:fname) >> str("()") |
      func >> identifier.as(:fname) >> str("(") >>
          arglist.as(:arglist) >>
      str(")")
      ) >> wsp?
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
