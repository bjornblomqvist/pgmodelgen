class MetadataExtractor
  
  def initialize(db_connection)
    @db_connection = db_connection
  end
  
  def metadata
    {:schema => schemas, :db_name => db_name}
  end
  
  private
  
  def schemas
    toReturn = {}
    schema_names.each do |schema_name|
      toReturn[schema_name] = tables(schema_name)
    end
    
    toReturn
  end
  
  def schema_names
    @db_connection.query("show search_path;").to_a.first['search_path'].split(/,/).delete_if{|value| value.match(/\$/) }
  end
  
  def tables(schema_name)
    to_return = {}
    table_names(schema_name).each do |table_name|
      to_return[table_name] = table(schema_name,table_name)
    end
    
    to_return
  end
  
  def table(schema_name, table_name) 
    {:oid => oid(schema_name, table_name), :columns => columns(schema_name, table_name)}
  end
  
  def oid(schema_name, table_name)
    @db_connection.query("
select
  pg_class.oid as table_oid
  from pg_class
  join pg_namespace on pg_namespace.oid = pg_class.relnamespace
  where (relkind = 'r') and pg_namespace.nspname = '#{schema_name}' and pg_class.relname = '#{table_name}' ").to_a.map{|row| row['table_oid'] }.first
  end
  
  def table_names(schema_name)
    @db_connection.query("
select
  pg_class.relname as table_name
  from pg_class
  join pg_namespace on pg_namespace.oid = pg_class.relnamespace
  where (relkind = 'r') and pg_namespace.nspname = '#{schema_name}' ").to_a.map{|row| row['table_name'] }
  end
  
end