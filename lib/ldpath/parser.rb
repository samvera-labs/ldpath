require 'parslet'

module Ldpath
  class Parser < Parslet::Parser
    root :lines
    rule(:lines) { line.repeat }
    rule(:line) { ((wsp >> expression) | expression) >> space_not_newline? >> (newline | eof) }

    rule(:newline) {  (str("\n") >> str("\r").maybe).repeat(1) }
    rule(:eof) { any.absent? }

    rule(:space) { match('\s').repeat(1) }
    rule(:spaces?) { space.maybe }
    rule(:space_not_newline) { str("\n").absent? >> space }
    rule(:space_not_newline?) { space_not_newline.maybe }

    rule(:wsp) { (space | multiline_comment).repeat(1) }
    rule(:wsp?) { wsp.maybe }
    rule(:multiline_comment) { (str('/*') >> (str('*/').absent? >> any).repeat >> str('*/') ) }

    rule(:expression) { wsp | namespace | mapping | graph | filter }
    
    rule(:int) { match("\\d+") }
    
    rule(:comma) { str(",") }
    rule(:scolon) { str(";") }
    rule(:colon) { str(":") }
    rule(:dcolon) { str("::") }
    rule(:assign) { str("=") }
    rule(:k_prefix) { str("@prefix")}
    rule(:k_graph) { str("@graph")}
    rule(:k_filter) { str("@filter")}
    
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
      str('"') >> (str("\\") >> str("\"") | (str('"').absent? >> any)).repeat.as(:literal) >> str('"')
    }

    rule(:node) {
      uri.as(:uri) | strlit.as(:literal)
    }

    # @prefix id = uri ;
    rule(:namespace) { 
      (
      k_prefix >> wsp? >>
      identifier.as(:id) >> wsp? >>
      colon >> wsp? >>
      uri.as(:uri) >> space_not_newline? >> scolon.maybe
      ).as(:namespace)
    }
    
    # @graph uri, uri, uri ;
    rule(:graph) {
      k_graph >> wsp? >> 
      uri_list.as(:graphs) >> wsp? >> scolon
    }
    
    rule(:uri_list) {
      uri.as(:uri) >>
      (
        wsp? >> 
        comma >> wsp? >> 
        uri_list.as(:rest)
      ).repeat
    }

    # @filter selector ;
    rule(:filter) {
      (k_filter >> wsp? >> node_test.as(:test) >> wsp? >> scolon).as(:filter)
    }
    
    # id = . ;
    rule(:mapping) {
      (
        identifier.as(:name) >> wsp? >>
        assign >> wsp? >>
        selector.as(:selector) >>
        ( wsp? >> 
          dcolon >> wsp? >>
          uri.as(:field_type)
        ).maybe >> wsp? >> scolon
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
      atomic_selector.as(:delegate) >>
      str("[") >> wsp? >>
      node_test.as(:test) >> wsp? >>
      str("]")
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
        atomic_or_testing_selector.as(:left) >> wsp? >>
        p_sep >> wsp? >>
        atomic_or_testing_or_path_selector.as(:right)
      ).as(:path)
    }
    
    ## x & y
    rule(:intersection_selector) {
      (
        atomic_or_testing_or_path_selector.as(:left) >> wsp? >>
        and_op >> wsp? >>
        selector.as(:right)
      ).as(:intersection)
    }
    
    ## x | y
    rule(:union_selector) {
      (
        atomic_or_testing_or_path_selector.as(:left) >> wsp? >>
        or_op >> wsp? >>
        selector.as(:right)
      ).as(:union)
    }

    # Atomic Selectors
    rule(:self_selector) {
      self_op.as(:self)
    }
    
    # fn:x() or fn:x(1,2,3)
    rule(:function_selector) {
      func >> identifier.as(:fname) >> str("()") |
      func >> identifier.as(:fname) >> str("(") >> wsp? >> arglist.as(:arglist) >> wsp? >> str(")")
    }
    
    rule(:arglist) {
      selector >> 
      (
        wsp? >> 
        comma >> wsp? >> 
        selector
      ).repeat
    }
    
    # xyz
    rule(:loose_property_selector) {
      loose >> 
      wsp? >> 
      uri.as(:loose_property)
    }

    # xyz
    rule(:property_selector) {
      uri.as(:property)
    }

    # *
    rule(:wildcard_selector) {
      star.as(:wildcard)
    }

    # ^xyz
    rule(:reverse_property_selector) {
      inverse >> uri.as(:reverse_property)
    }
    
    rule(:string_constant_selector) {
      strlit
    }
    
    # (x)*
    rule(:recursive_path_selector) {
      (
        str("(") >> wsp? >>
        selector.as(:delegate) >> wsp? >> 
        str(")") >>
        (
          star |
          plus |
          (str("{") >> wsp? >> int.as(:min).maybe >> wsp? >>str(",") >> wsp? >> int.as(:max).maybe >> wsp? >>str("}") ).as(:range)
        ).as(:repeat)
      ).as(:recursive)
    }
    
    rule(:grouped_selector) {
      str("(") >> wsp? >> 
      selector >> wsp? >> 
      str(")")
    }

    rule(:tap_selector) {
      tap >>
      str("<") >> wsp? >>
      identifier.as(:identifier) >> wsp? >>
      str(">") >> wsp? >>
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
      str("(")  >> wsp? >> 
      node_test >> wsp? >> 
      str(")") 
    }
    
    rule(:not_test) {
      (
        not_op >> node_test.as(:delegate)
      ).as(:not)
    }
    
    rule(:and_test) {
      (
        atomic_node_test.as(:left) >> wsp? >> 
        and_op >> wsp? >> 
        node_test.as(:right)
      ).as(:and)
    }
    
    rule(:or_test) {
      (
        atomic_node_test.as(:left) >> wsp? >> 
        or_op >> wsp? >> 
        node_test.as(:right)
      ).as(:or)
    }

    # @en
    rule(:literal_language_test) {
      lang >> identifier.as(:lang)
    }
    
    # ^^xyz
    rule(:literal_type_test) {
      type >> uri.as(:type)
    }
    
    rule(:is_a_test) {
      (
        is_a >> wsp? >> 
        node.as(:right)
      ).as(:is_a)
    }
    
    rule(:path_equality_test) {
      (
        selector >> wsp? >>
        is >> wsp? >>
        node.as(:right)
      ).as(:is)
    }
    
    rule(:function_test) {
      (
      func >> identifier.as(:fname) >> str("()") |
      func >> identifier.as(:fname) >> str("(") >>
        wsp? >> 
          arglist.as(:arglist) >>
        wsp? >> 
      str(")")
      )
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
