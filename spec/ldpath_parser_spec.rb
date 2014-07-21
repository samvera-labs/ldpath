require 'spec_helper'
require 'pp'
require 'parslet/convenience'
describe Ldpath::Parser do
  subject { Ldpath::Parser.new }
  context ".parse" do
    
    describe "lines" do
      it "should parse line-oriented data" do
        subject.lines.parse " \n \n"
      end
    end
    
    describe "line" do
      it "may be a line ending in a newline" do
        subject.line.parse " \n"
      end
      
      it "may be a line ending in EOF" do
        subject.line.parse("/* abc */")
      end
    end
    
    describe "newline" do
      it 'may be a \n character' do
        subject.newline.parse("\n")
      end
      
      it 'may be a \n\r' do
        subject.newline.parse("\n\r")
      end
    end
    
    describe "eof" do
      it "is the eof" do
        subject.eof.parse ""
      end
    end
    
    describe "wsp" do
      it "may be a space" do
        subject.wsp.parse " "
      end
      
      it "may be a tab" do
        subject.wsp.parse "\t"
      end
      
      it "may be a multiline comment" do
        subject.wsp.parse "/* xyz */"
      end
    end
    
    describe "expression" do
      it "may be whitespace" do
        subject.expression.parse " "
      end
      
      it "may be a namespace declaration" do
        subject.expression.parse "@prefix x : info:x ;"
      end
      
      it "may be a graph" do
        subject.expression.parse "@graph test:context, foo:ctx, test:bar ;"
      end
      
      it "may be a mapping" do
        subject.expression.parse "id = . ;"
      end
    end
    
    describe "uri" do
      it "may be a bracketed uri" do
        result = subject.uri.parse "<info:x>"
        expect(result[:uri]).to eq "info:x"
      end
      
      it "may be a namespace and local name" do
        result = subject.uri.parse "info:x"
        expect(result[:uri][:prefix]).to eq "info"
        expect(result[:uri][:localName]).to eq "x"
      end
    end
    
    describe "identifier" do
      it "must start with an alphanumeric character" do
        subject.identifier.parse "a"
        subject.identifier.parse "J"
        subject.identifier.parse "4"
        subject.identifier.parse "_"
      end
      
      it "may have additional alphanumeric characters" do
        subject.identifier.parse "aJ0_.-"
      end
    end
    
    describe "strlit" do
      it "is the content between \"" do
        subject.strlit.parse '"abc"'
      end
      
      it "should handle escaped characters" do
        subject.strlit.parse '"a\"b"'
      end
    end
    
    describe "node" do
      it "may be a uri" do
        subject.node.parse "info:x"
      end
      
      it "may be a literal" do
        subject.node.parse '"a"'
      end
    end
    
    describe "selectors" do  
      it "should parse mappings" do
        subject.parse("xyz = . ;\n")
      end
      
      it "should parse wildcards" do
        subject.parse("xyz = * ;\n")
      end
      
      it "should parse reverse properties" do
        subject.parse("xyz = ^info:a ;\n")
      end
      
      it "should parse uri mappings" do
        subject.parse("xyz = <info:a> ;\n")
      end
      
      it "should parse path mappings" do
        subject.parse("xyz = info:a / info:b :: a:b;\n")
      end
      
      it "recursive_path_selector" do
        subject.recursive_path_selector.parse("(foo:go)*")
      end
      
      it "function_selector" do
        subject.selector.parse('fn:concat(foaf:givename," ",foaf:surname)')
      end
    end
    
    describe "integration tests" do
      it "should parse the foaf example" do
        subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "foaf_example.program")))
      end
      
      it "should parse the program.ldpath" do
        subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "program.ldpath")))
      end
      
      it "should parse the namespaces.ldpath" do
        subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "namespaces.ldpath")))
      end
    end  
  end
end
