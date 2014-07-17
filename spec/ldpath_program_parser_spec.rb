require 'spec_helper'

require 'parslet/convenience'
describe Ldpath::Program do
  subject { Ldpath::Program.new }
  context ".parse" do
    it "should work" do
      subject.parse ""
      subject.parse "\n\n"
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
    
    it "should parse uri mappings" do
      subject.parse("xyz = <info:a> ;\n")
    end
    
    it "should parse path mappings" do
      subject.parse_with_debug("xyz = info:a / info:b :: a:b;\n")
    end
  
  
  end
end
