require 'spec_helper'
require 'pp'
require 'parslet/convenience'
describe Ldpath::Parser do
  subject { Ldpath::Parser.new }
  context ".parse" do
    it "should work" do
      subject.parse ""
      subject.parse "\t\t\n"
    end
    
    it "should parse whitespace" do
      subject.wsp.parse("\t\t\t")
    end
    
    it "should not parse comments" do
      subject.line.parse "/* xyz */"
    end
    
    it "should parse namespaces" do
      subject.namespace.parse "@prefix a : <xyz>"
    end
    
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
    it "strlit" do
      subject.strlit.parse('" "')
    end
    it "function_selector" do
      subject.selector.parse('fn:concat(foaf:givename," ",foaf:surname)')
    end
    
    it "should parse the foaf example" do
      subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "foaf_example.program")))
    end
    
    it "should parse the program.ldpath" do
      subject.parse File.read(File.expand_path(File.join(__FILE__, "..", "fixtures", "program.ldpath")))
    end
  
  
  end
end
