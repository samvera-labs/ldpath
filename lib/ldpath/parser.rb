require 'parslet'

module Ldpath
  class Parser < Parslet::Parser
    root :doc
    rule(:doc) { prologue? >> statements? >> eof}

    rule(:prologue) { wsp? >> directive?.repeat(1,1) >> (eol >> wsp? >> directive >> wsp? ).repeat >> wsp? >> eol? }
    rule(:prologue?) { prologue.maybe }
    rule(:directive) { prefixID | graph | filter | boost }
    rule(:directive?) { directive.maybe }

    rule(:statements) { wsp? >> statement?.repeat(1,1) >> (eol >> wsp? >> statement >> wsp? ).repeat >> wsp? >> eol? }
    rule(:statements?) { statements.maybe }
    rule(:statement) { mapping }
    rule(:statement?) { mapping.maybe }

    # whitespace rules
    rule(:eol) {  (str("\n") >> str("\r").maybe).repeat(1) }
    rule(:eol?) { eol.maybe }
    rule(:eof) { any.absent? }
    rule(:space) { str("\n").absent? >> match('\s').repeat(1) }
    rule(:space?) { space.maybe }
    rule(:wsp) { (space | multiline_comment | single_line_comment ).repeat(1) }
    rule(:wsp?) { wsp.maybe }
    rule(:multiline_comment) { (str('/*') >> (str('*/').absent? >> any).repeat >> str('*/') ) }
    rule(:single_line_comment) { str('#') >> (eol.absent? >> any).repeat }

    # simple types
    rule(:integer) { match("[+-]").maybe >> match("\\d+") }
    rule(:decimal) { match("[+-]").maybe >> match("\\d*") >> str('.') >> match("\\d+") }
    rule(:double) do
      match("[+-]").maybe >> (
        (match("\\d+") >> str('.') >> match("\\d*") >> exponent) |
        (str('.') >> match("\\d+") >> exponent) |
        (match("\\d+") >> exponent)
      )
    end

    rule(:exponent) { match('[Ee]') >> match("[+-]").maybe >> match("\\d+") }
    rule(:numeric_literal) { integer | decimal | double }
    rule(:boolean_literal) { str('true') | str('false') }
    
    # operators
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

    # strings
    rule(:comma) { str(",") }
    rule(:scolon) { str(";") }
    rule(:colon) { str(":") }
    rule(:dcolon) { str("::") }
    rule(:assign) { str("=") }
    rule(:k_prefix) { str("@prefix")}
    rule(:k_graph) { str("@graph")}
    rule(:k_filter) { str("@filter")}
    rule(:k_boost) { str("@boost")}

    rule(:iri) do
      iriref |
      prefixed_name
    end
    
    rule(:iriref) do
      str("<") >> (match("[^[[:cntrl:]]<>\"{}|^`\\\\]") | uchar).repeat.as(:iri) >> str('>')
    end
    
    rule(:uchar) do
      str('\u') >> hex.repeat(4,4) | hex.repeat(6,6)
    end

    rule(:echar) do
      str('\\') >> match("[tbnrf\"'\\\\]")
    end

    rule(:hex) do
      match("[[:xdigit:]]")
    end

    rule(:prefixed_name) do
      (identifier.as(:prefix) >> str(":") >> identifier.as(:localName)).as(:iri)
    end
    
    rule(:identifier) { pn_chars_base >> (str('.').maybe >> pn_chars).repeat }

    rule(:pn_chars_base) {
      # also \u10000-\uEFFFF
      match("[A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]")
    }

    rule(:pn_chars) {
      pn_chars_base | match("[0-9\u00B7\u0300-\u036F\u203F-\u2040_-]")
    }

    rule(:string) { string_literal_quote | string_literal_single_quote | string_literal_long_single_quote | string_literal_long_quote }

    rule(:string_literal_quote) {
      str('"') >> (match("[^\\\"\\\\\\r\\n]") | echar | uchar).repeat.as(:literal) >> str('"')
    }

    rule(:string_literal_single_quote) {
      str("'") >> (match("[^'\\\\\\r\\n]") | echar | uchar).repeat.as(:literal) >> str("'")
    }

    rule(:string_literal_long_quote) {
      str('"""') >> (str('"""').absent? >> match("[^\\\\]") | echar | uchar).repeat.as(:literal) >> str('"""')
    }

    rule(:string_literal_long_single_quote) {
      str("'''") >> (str("'''").absent? >> match("[^\\\\]") | echar | uchar).repeat.as(:literal) >> str("'''")
    }

    rule(:literal) {
      rdf_literal | numeric_literal | boolean_literal
    }

    rule(:rdf_literal) {
      string >> (literal_language_test | literal_type_test).maybe
    }

    rule(:node) {
      iri.as(:iri) | literal.as(:literal)
    }

    # @prefix id = iri ;
    rule(:prefixID) { 
      (
      k_prefix >> wsp? >>
      (identifier | str("")).as(:id) >> wsp? >>
      colon >> wsp? >>
      iriref >> space? >> scolon.maybe
      ).as(:prefixID)
    }
    
    # @graph iri, iri, iri ;
    rule(:graph) {
      k_graph >> wsp? >> 
      iri_list.as(:graphs) >> wsp? >> scolon
    }
    
    rule(:iri_list) {
      iri.as(:iri) >>
      (
        wsp? >> 
        comma >> wsp? >> 
        iri_list.as(:rest)
      ).repeat
    }

    # @filter test ;
    rule(:filter) {
      (k_filter >> wsp? >> node_test.as(:test) >> wsp? >> scolon).as(:filter)
    }

    # @boost selector ;
    rule(:boost) {
      (k_boost >> wsp? >> selector.as(:selector) >> wsp? >> scolon).as(:boost)
    }

    # id = . ;
    rule(:mapping) {
      (
        label.as(:name) >> wsp? >>
        assign >> wsp? >>
        selector.as(:selector) >>
        ( wsp? >> 
          dcolon >> wsp? >> field_type
        ).maybe >> wsp? >> scolon
      ).as(:mapping)
    }

    rule(:label) {
      iri | identifier
    }

    rule(:field_type) {
      iri.as(:field_type) >> field_type_options.maybe
    }

    rule(:field_type_options) {
      str("(") >> wsp? >> (field_type_option >> (wsp? >> comma >> wsp? >> field_type_option).repeat).as(:options) >> wsp? >> str(")")
    }

    rule(:field_type_option) {
      identifier.as(:key) >> wsp? >> assign >> wsp? >> string.as(:value)
    }
    
    # selector groups
    rule(:selector) {
      (
        compound_or_path_selector |
        testing_selector |
        atomic_selector
      )
    }

    rule(:compound_operator) { and_op | or_op }

    rule(:compound_or_path_selector) {
      path_selector | compound_selector
    }
    rule(:compound_selector) {
      atomic_or_testing_or_path_selector.as(:left) >> wsp? >>
      compound_operator.as(:op) >> wsp? >>
      selector.as(:right)
    }

    rule(:path_selector) {
      atomic_or_testing_selector.as(:left) >> wsp? >>
      p_sep.as(:op) >> wsp? >>
      atomic_or_testing_or_path_selector.as(:right)
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
      iri.as(:loose_property)
    }

    # xyz
    rule(:property_selector) {
      iri.as(:property)
    }

    # *
    rule(:wildcard_selector) {
      star.as(:wildcard)
    }

    # ^xyz
    rule(:reverse_property_selector) {
      inverse >> iri.as(:reverse_property)
    }
    
    rule(:string_constant_selector) {
      string
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
          (str("{") >> wsp? >> integer.as(:min).maybe >> wsp? >>str(",") >> wsp? >> integer.as(:max).maybe >> wsp? >>str("}") ).as(:range)
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
      type >> iri.as(:type)
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
