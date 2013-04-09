require 'spec_helper'

describe MetadataExtractor do

  describe "#metadata" do
    
    context "with a basic database" do
      
      it "should return schema with with one table with one column" do
        
        me = MetadataExtractor.new(nil)
        me.should_receive(:schemas).and_return({:public => {}})
        me.should_receive(:db_name).and_return("dummy_db")
        
        me.metadata.should == {:schema => {:public => {}},:db_name => "dummy_db"}
        
      end
      
    end
  end
  
  describe "#schemas" do
    
    it 'should return all the schemas and all its parts' do
      
      me = MetadataExtractor.new(nil)
      
      me.should_receive(:schema_names).and_return(['first','second'])
      me.should_receive(:tables).with("first").and_return(:tables => {})
      me.should_receive(:tables).with("second").and_return(:tables => {})
      
      me.send(:schemas).should == {'first' => {:tables => {}}, 'second' => {:tables => {}}}
      
    end
    
  end
  
  describe "#tables" do
    
    it 'should return all the tables for the given schema' do
      
      table_info1 = mock('table_info1')
      table_info2 = mock('table_info2')
      
      me = MetadataExtractor.new(nil)
      
      me.should_receive(:table_names).with("public").and_return(['dummy_table','dummy_table2'])
      me.should_receive(:table).with('public','dummy_table').and_return(table_info1)
      me.should_receive(:table).with('public','dummy_table2').and_return(table_info2)
      
      me.send(:tables,"public").should == {'dummy_table' => table_info1,'dummy_table2' => table_info2}
      
    end
    
  end
  
  describe "#table_names" do
    
    it 'should return the names of all the tables in the given schema' do
      
      connection = mock("connection")
      me = MetadataExtractor.new(connection)
      
      connection.should_receive(:query).with("
select
  pg_class.relname as table_name
  from pg_class
  join pg_namespace on pg_namespace.oid = pg_class.relnamespace
  where (relkind = 'r') and pg_namespace.nspname = 'public' ").and_return(mock(:to_a => [{'table_name' => 'dummy_table1'}, {'table_name' => 'dummy_table2'}]))
      
      me.send(:table_names,"public").should == ['dummy_table1','dummy_table2']
    end
    
  end
  
  describe "#table" do
    
    it 'should return meta data for the given schema and table name' do
      
      columns = mock('columns')
      oid = mock("oid")
      me = MetadataExtractor.new(nil)
      me.should_receive(:columns).with("dummy_schema_name","dummy_table_name").and_return(columns)
      me.should_receive(:oid).with("dummy_schema_name","dummy_table_name").and_return(oid)
      
      me.send(:table,'dummy_schema_name','dummy_table_name').should == {:oid => oid, :columns => columns}
    end
    
  end
  
  describe "#oid" do
    
    it 'should return the oid for the given table or view' do
      
      oid = mock('oid')
      connection = mock("connection")
      me = MetadataExtractor.new(connection)
      
      connection.should_receive(:query).with("
select
  pg_class.oid as table_oid
  from pg_class
  join pg_namespace on pg_namespace.oid = pg_class.relnamespace
  where (relkind = 'r') and pg_namespace.nspname = 'public' and pg_class.relname = 'dummy_table_name' ").and_return(mock(:to_a => [{'table_oid' => oid}]))
  
      
      me.oid('public','dummy_table_name').should == oid
      
    end
    
  end
  
  describe "#schema_names" do
    
    it 'should return all the schema names found in the db' do
      
      connection = mock("connection")
      me = MetadataExtractor.new(connection)
      
      connection.should_receive(:query).with("show search_path;").and_return(mock(:to_a => [{"search_path"=>"schema1,schema2"}]))
      
      me.send(:schema_names).should == ['schema1','schema2']
      
    end
    
    it 'should exclude any special variable schemas' do
      
      connection = mock("connection")
      me = MetadataExtractor.new(connection)
      
      connection.should_receive(:query).with("show search_path;").and_return(mock(:to_a => [{"search_path"=>"\"$user\",public"}]))
      
      me.send(:schema_names).should == ['public']
      
    end
    
  end
  
end