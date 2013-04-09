require 'spec_helper'

describe MetadataExtractor do

  describe "#metadata" do
    
    context "with a basic database" do
      
      before(:each) do
        DB_CONNECTION.exec("create table simple (a_text text);")
      end
      
      it "should return schema with with one table with one column" do
        
        me = MetadataExtractor.new(DB_CONNECTION)
        me.metadata.should == {:schema => {:public => {:tables => {
          :simple => {:columns => {:a_text => {:type => "text"}}}
        }}}}
        
      end
      
    end
    
  end
  
end