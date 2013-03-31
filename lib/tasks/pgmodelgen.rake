

# TODO Seperate parsing of postgresql meta data from model generating, the value of the
#      project would be much more. Also it would open up to suporting other dbs.



# TODO Add timestamp syntax validation
# TODO Update so that a unique constraint on a foreign key changes the has_many to has_one
# TODO Add hint where a foregin key is to a many to many table

# DONE Add warning about missing index on foreign keys
# DONE Fix foreign_key mistake
# DONE Make the result a bit nicer
# DONE Add file writing code and code that creates the models
# DONE Change so that foreign key canstraint name defines the bindings
#     (belongs_to:article),(has_a:video_url)

require 'active_support'


class PGGen
  
  
  
  def initialize model_name,schema_name,dbname,regex = nil
    
    puts "Generating for: #{dbname}.#{schema_name} with prefix #{model_name}"

    if regex
      @regex = Regexp.compile(regex) 
    else
      @regex = Regexp.compile(".*") 
    end
    @schema_name = schema_name;
    
    require 'pg'
    require 'FileUtils'
    
    con = PGconn.open(:dbname => dbname)
    con.exec "set search_path to #{@schema_name}"

    @model_name = model_name.capitalize
    allModelsContent = {}

    #
    # Get all the table names and oids
    #

    result = con.query "
    select

    	pg_class.oid
    	,pg_class.relname

    	from pg_class

    	join pg_namespace on pg_namespace.oid = pg_class.relnamespace

    	where
 
    		(relkind = 'r' or relkind = 'v')
    		and pg_namespace.nspname = '#{schema_name}'
    "
    
    
    #
    # Print matching tables
    #
    the_tables = []
    puts "\n\tCreating models for these tables\n\n"
    result.each do |row|
      
      if @regex.match(row['relname'])
        puts "\t\t#{row['relname']}"
        the_tables.push row['relname']
      end

    end
    
    
    
    #
    # Get dependancy tables
    #
    deps = {}
    result.each do |row|
      
      if @regex.match(row['relname'])
      
        table_oid = row['oid']
      
        con.query("
      
      
          select * from

          (

          select

          conname
          ,case /* c = check constraint, f = foreign key constraint, p = primary key constraint, u = unique constraint */
          	when contype = 'c' then 'check_constraint'
          	when contype = 'f' then 'foreign key constraint'
          	when contype = 'p' then 'primary key constraint'
          	when contype = 'u' then 'unique constraint'
          	else 'unknown constraint'
          end as contype
          ,foreign_class.relname as foreign_table_name
          ,conkey as attribute_column_numbers
          ,confkey as foreign_attribute_column_numbers
          ,consrc as condition_decleration_src
          ,conkey[0] = 0 as problem


          from pg_constraint

          left join pg_class as foreign_class on foreign_class.oid = confrelid


          where 

          	conrelid  = #{table_oid}

          union

          SELECT 

          	i.relname AS conname
          	,'unique constraint' as contype
          	,'' as foreign_table_name
          	,indkey as attribute_column_numbers
          	,null as foreign_attribute_column_numbers
          	,pg_get_indexdef(i.oid) as condition_decleration_src
          	,indkey[0] = 0 as problem

           FROM pg_index x
           JOIN pg_class c ON c.oid = x.indrelid
           JOIN pg_class i ON i.oid = x.indexrelid
           LEFT JOIN pg_tablespace t ON t.oid = i.reltablespace
          WHERE i.relkind = 'i' and c.oid = #{table_oid} and x.indisunique = true and x.indisprimary = false

          ) as bla

          order by conname,contype,foreign_table_name,attribute_column_numbers,condition_decleration_src,problem").each do |row|
          unless row['foreign_table_name'].nil? || row['foreign_table_name'].empty? || the_tables.include?(row['foreign_table_name'])
            deps[row['foreign_table_name']] = row['foreign_table_name']
          end
        end
      end
    end
    deps_tables = deps.keys
    
    if deps_tables.length > 0 && regex
      puts "\n\tWill also create models for these tables as other tables depend on them\n\n" 
      deps_tables.each do |table_name|
        puts "\t\t#{table_name}"
      end
      puts "\n"
    end
    
    result.each do |row|
      
      if @regex.match(row['relname']) || deps_tables.include?(row['relname'])
        allModelsContent[row['relname']] = {:constraint => "",:set => "", :binding => "", :columns => ""}
      end

    end

    result.each do |row|
      
      if @regex.match(row['relname']) || deps_tables.include?(row['relname'])
        get_columns( row['relname'],row['oid'] ,con,allModelsContent)
        get_constraints( row['relname'],row['oid'] ,con,allModelsContent)
      end

    end

    allModelsContent.each do |key,value| 

      class_name = table2class(check_class_name(key.capitalize));

      model_file_name = "./app/models/"+camle_case_2_file_name(@model_name ? @model_name + "/" : '')+"#{camle_case_2_file_name(class_name)}.rb".downcase

      FileUtils.makedirs(File.dirname(model_file_name))

      value[:set] = "\tset_table_name \"#{key}\"\n" + value[:set].to_s

      first_part = "# encoding: utf-8\n\n"
      first_part += "class #{get_class_name_with_namespace(class_name)} < ActiveRecord::Base \n"
      first_part += "\n"
      first_part += "# --- auto_gen_start ---\n"

      last_part = "# --- auto_gen_end ---\n"
      last_part += "\n"
      last_part += "end \n"
      last_part += "\n"


      if File.exist?(model_file_name)

        file_data = File.read(model_file_name)

        if file_data.split(/\t#--- auto_gen_start ---/m).length == 2

          first_part = file_data.split(/\t#--- auto_gen_start ---/m)[0]
          first_part += "\t#--- auto_gen_start ---\n"

          last_part = "\t#--- auto_gen_end ---"
          last_part += file_data.split(/\t#--- auto_gen_end ---/m)[1].to_s
          
        # Support for the old layout
        elsif file_data.split(/# --- auto_gen_start ---/m).length == 2

          first_part = file_data.split(/# --- auto_gen_start ---/m)[0]
          first_part += "\t#--- auto_gen_start ---\n"

          last_part = "\t#--- auto_gen_end ---"
          last_part += file_data.split(/# --- auto_gen_end ---/m)[1].to_s

        else

          first_part = file_data.split(/end[\s]*\z/m)[0]
          first_part += "\n\n\n"
          first_part += "\t#--- auto_gen_start ---\n"

          last_part = "\t#--- auto_gen_end ---\n"
          last_part += "end\n"

        end

      end
      
      first_part += "\t#\n"
      first_part += "\t# This is generate using gen_pg_models, dont make changes\n"
      first_part += "\t# within auto_gen_XXXXX as it will be overwriten next time\n"
      first_part += "\t# gen_pg_models is run.\n"
      first_part += "\t#\n"

      puts "\tWriting to #{model_file_name}"
      File.open(model_file_name,'w') do |io|

        io.write(first_part)
        io.write("\n\t# Columns\n")
        io.write("\n\t"+value[:columns].to_s.strip+"\n")
        io.write("\n\t# Table config \n")
        io.write("\n\t"+value[:set].to_s.strip+"\n")
        io.write("\n\t# Constraints \n")
        io.write("\n\t"+(value[:constraint].to_s.strip)+"\n")
        io.write("\n\t# Foreign keys \n")
        io.write("\n\t"+value[:binding].to_s.strip+"\n\n")
        io.write(last_part)

      end
    end
    
    puts "\n"
  end
  
  
  def get_class_name_with_namespace class_name

    unless @model_name.nil? || @model_name.empty?
      @model_name + "::" + class_name
    else  
      class_name
    end

  end


  def check_class_name class_name

    unusable_class_names = ['Thread','thread']

    if unusable_class_names.include? class_name
      class_name+"oooo"
    else
      class_name
    end
  end


  def is_there_an_index_on table_name,column_name,connection

    result = connection.query "

    select 

    	pg_class.relname as table_name
    	,pg_attribute.attname as column_name
    	,case when pg_index.indkey is not null then 't' else 'f' end as has_index

    	from pg_attribute

    		join pg_class on pg_class.oid = pg_attribute.attrelid
    		left join pg_index on pg_index.indrelid = pg_class.oid and array_to_string(pg_index.indkey,',') ilike '%' || pg_attribute.attnum || '%'

    	where

    		pg_class.relname = '#{table_name.downcase}' and pg_attribute.attname = '#{column_name.downcase}' and pg_index.indkey is not null"

    result.ntuples > 0
  end


  def table2class string
    string.camelize.singularize
  end

  def pad_string string,min_width
    while string.length < min_width
      string = string + " "
    end

    string
  end

  def camle_case_2_file_name string
    string.underscore
  end

  def get_attribute_name attribute_number,table_oid,connection
    
    result = connection.query "
    select 

    	pg_attribute.attnum as attribute_number
    	,pg_type.typname as type_name
    	,pg_attribute.attname as attribute_name
    	,pg_type.typlen as max_length
    	,pg_attribute.atttypmod as max_length_minus_4_for_varlen
    	,pg_attribute.attnotnull as not_null_constraint
    	,pg_attribute.attisdropped as attisdropped /* This column has been dropped and is no longer valid. A dropped column is still physically present in the table, but is ignored by the parser and so cannot be accessed via SQL. */
    	,pg_attribute.atthasdef as has_default_value
    	,pg_attrdef.adsrc as default_value_src

    	from pg_attribute

    	join pg_type on pg_type.oid = pg_attribute.atttypid
    	left join pg_attrdef on pg_attrdef.adrelid = pg_attribute.attrelid and pg_attrdef.adnum = pg_attribute.attnum

    	where
    		pg_attribute.attrelid = #{table_oid}
    		and pg_attribute.attnum = #{attribute_number}"

    result.first['attribute_name']
  end
  
  def get_attribute_row attribute_number,table_oid,connection
    
    result = connection.query "
    select 

    	pg_attribute.attnum as attribute_number
    	,pg_type.typname as type_name
    	,pg_attribute.attname as attribute_name
    	,pg_type.typlen as max_length
    	,pg_attribute.atttypmod as max_length_minus_4_for_varlen
    	,pg_attribute.attnotnull as not_null_constraint
    	,pg_attribute.attisdropped as attisdropped /* This column has been dropped and is no longer valid. A dropped column is still physically present in the table, but is ignored by the parser and so cannot be accessed via SQL. */
    	,pg_attribute.atthasdef as has_default_value
    	,pg_attrdef.adsrc as default_value_src

    	from pg_attribute

    	join pg_type on pg_type.oid = pg_attribute.atttypid
    	left join pg_attrdef on pg_attrdef.adrelid = pg_attribute.attrelid and pg_attrdef.adnum = pg_attribute.attnum

    	where
    		pg_attribute.attrelid = #{table_oid}
    		and pg_attribute.attnum = #{attribute_number}"

    result.first
  end

  def get_table_oid table_name,connection

    result = connection.query "
    select

    	pg_class.oid

    	from pg_class

    	join pg_namespace on pg_namespace.oid = pg_class.relnamespace

    	where

    		relkind = 'r' /* r = ordinary table, i = index, S = sequence, v = view, c = composite type, s = special, t = TOAST table */
    		and pg_namespace.nspname = '#{@schema_name}'
    		and pg_class.relname = '#{table_name}'
    "

    result.first['oid']
  end


  def get_table_name table_oid,connection

    result = connection.query "
    select

    	pg_class.relname

    	from pg_class

    	join pg_namespace on pg_namespace.oid = pg_class.relnamespace

    	where

    		relkind = 'r' /* r = ordinary table, i = index, S = sequence, v = view, c = composite type, s = special, t = TOAST table */
    		and pg_namespace.nspname = '#{@schema_name}'
    		and pg_class.oid = #{table_oid}
    "

    result.first['relname']
  end

  def get_default_value_src attribute_number,table_oid,connection 

    result = connection.query "
    select 

    	pg_attribute.attnum as attribute_number
    	,pg_type.typname as type_name
    	,pg_attribute.attname as attribute_name
    	,pg_type.typlen as max_length
    	,pg_attribute.atttypmod as max_length_minus_4_for_varlen
    	,pg_attribute.attnotnull as not_null_constraint
    	,pg_attribute.attisdropped as attisdropped /* This column has been dropped and is no longer valid. A dropped column is still physically present in the table, but is ignored by the parser and so cannot be accessed via SQL. */
    	,pg_attribute.atthasdef as has_default_value
    	,pg_attrdef.adsrc as default_value_src

    	from pg_attribute

    	join pg_type on pg_type.oid = pg_attribute.atttypid
    	left join pg_attrdef on pg_attrdef.adrelid = pg_attribute.attrelid and pg_attrdef.adnum = pg_attribute.attnum

    	where
    		pg_attribute.attrelid = #{table_oid}
    		and pg_attribute.attnum = #{attribute_number}"

    result.first['default_value_src']
  end

  def get_constraints table_name,table_oid,connection,models
    
    result = connection.query "
    
    
    

    select * from

    (

    select

    conname
    ,case /* c = check constraint, f = foreign key constraint, p = primary key constraint, u = unique constraint */
    	when contype = 'c' then 'check_constraint'
    	when contype = 'f' then 'foreign key constraint'
    	when contype = 'p' then 'primary key constraint'
    	when contype = 'u' then 'unique constraint'
    	else 'unknown constraint'
    end as contype
    ,foreign_class.relname as foreign_table_name
    ,conkey as attribute_column_numbers
    ,confkey as foreign_attribute_column_numbers
    ,consrc as condition_decleration_src
    ,conkey[0] = 0 as problem


    from pg_constraint

    left join pg_class as foreign_class on foreign_class.oid = confrelid


    where 

    	conrelid  = #{table_oid}

    union

    SELECT 

    	i.relname AS conname
    	,'unique constraint' as contype
    	,'' as foreign_table_name
    	,indkey as attribute_column_numbers
    	,null as foreign_attribute_column_numbers
    	,pg_get_indexdef(i.oid) as condition_decleration_src
    	,indkey[0] = 0 as problem

     FROM pg_index x
     JOIN pg_class c ON c.oid = x.indrelid
     JOIN pg_class i ON i.oid = x.indexrelid
     LEFT JOIN pg_tablespace t ON t.oid = i.reltablespace
    WHERE i.relkind = 'i' and c.oid = #{table_oid} and x.indisunique = true and x.indisprimary = false

    ) as bla

    order by conname,attribute_column_numbers,foreign_table_name"
    	
      #
      # Set serial for primary key
      #
      result.each do |row|
        if row['contype'] == 'primary key constraint' && row['problem'] != 't'

          columns = row['attribute_column_numbers'].gsub("{","").gsub("}","").split(',');
          match = get_default_value_src(columns.first,table_oid,connection).to_s.match("\'([a-zA-Z_]*)\'");

          models[table_name][:set] += "\tset_primary_key \"#{get_attribute_name(columns.first,table_oid,connection)}\"\n"
          models[table_name][:set] += "\tset_sequence_name \"#{match[1]}\"\n" if match
        end
      end

      #
      # set unique canstraints
      #
      temp_constraints = {}
      models[table_name][:constraint] += "\n"
      result.each do |row|
        if row['contype'] == 'unique constraint' && row['problem'] != 't'
          
          if row['attribute_column_numbers'].include? "="
            row['attribute_column_numbers'] = row['attribute_column_numbers'].split('=')[1]
          end
          
          columns = row['attribute_column_numbers'].gsub("{","").gsub("}","").split(',');
          column_rows = columns.map do |value|
            get_attribute_row(value,table_oid,connection)
          end
          
          allow_nil = ((column_rows.first['not_null_constraint'] != 't' or column_rows.first['has_default_value'] == 't') ? ", :allow_nil => true" : "")
          
          
          columns.map! do |value|
            ":"+get_attribute_name(value,table_oid,connection)
          end

          string = ""
          if columns.length > 1
            #
            # validates_uniqueness_of with scope dosent want to work at the moment so we add it be commented out.
            # It will sit there as a reminder that it could work if only ActiveRecord would work a bit more like i expect it to
            #
             string = "\t#validates_uniqueness_of #{columns.shift}, :scope => [#{columns.join(',')}]#{allow_nil}\n"
          else
            string = "\tvalidates_uniqueness_of #{columns.first}#{allow_nil}\n"
          end
          
          temp_constraints[string] = string
        end
      end
      models[table_name][:constraint] += temp_constraints.keys.join("")
      
      
      
      #
      # Warn about prolems
      #
      models[table_name][:constraint] += "\n"
      result.each do |row|
        if row['problem'] == 't'
          
          models[table_name][:constraint] += "# cant do anything with this\n"
          models[table_name][:constraint] += "# #{row['condition_decleration_src']}\n"
          models[table_name][:constraint] += "# validates_uniqueness_of ???\n"
          
          puts "\n WARNING! cant do anything with this \n"
          puts "#{row['condition_decleration_src']}\n\n"
        end
      end



      #
      # set check constraints
      #
      models[table_name][:constraint] += "\n"
      result.each do |row|
        if row['contype'] == 'check_constraint' && row['problem'] != 't'
          
          columns = row['attribute_column_numbers'].gsub("{","").gsub("}","").split(',');
          column_rows = columns.map do |value|
            get_attribute_row(value,table_oid,connection)
          end
          
          allow_nil = ((column_rows.first['not_null_constraint'] != 't' or column_rows.first['has_default_value'] == 't') ? ", :allow_nil => true" : "")

          if row['condition_decleration_src'].match('\)::text ~\* \'(.*)\'::text\)$')
            
            # Regex check constraint
            match = row['condition_decleration_src'].match('\)::text ~\* \'(.*)\'::text\)$')
            models[table_name][:constraint] += "\tvalidates_format_of :#{column_rows.first["attribute_name"]}, :with => /#{match[1].gsub('\\\\.','').gsub('/','\/')}/i#{allow_nil}\n"
            
          elsif row['condition_decleration_src'].match(/\(char_length\((.*)::text\) >= ([0-9]*)\)/)
            
            # Length constraint
            match = row['condition_decleration_src'].match(/^\(char_length\(\((.*)\)::text\) >= ([0-9]*)\)$/)
            models[table_name][:constraint] += "\tvalidates_length_of :#{match[1]}, :minimum => #{match[2]}\n"
            
          else
            
            models[table_name][:constraint] += "\t# unknown check constraint\n"
            models[table_name][:constraint] += "\t# #{row['condition_decleration_src']}\n"
          end

        end
      end
      
      
      

      #
      # Add foreign keys
      #
      models[table_name][:binding] += "\n"
      result.each do |row|
        if row['contype'] == 'foreign key constraint' && row['problem'] != 't'

          local_columns = row['attribute_column_numbers'].gsub("{","").gsub("}","").split(',');
          local_columns.map! do |value|
            get_attribute_name(value,table_oid,connection)
          end

          foreign_oid = get_table_oid(row['foreign_table_name'],connection)
          foreign_columns = row['foreign_attribute_column_numbers'].gsub("{","").gsub("}","").split(',');
          foreign_columns.map! do |value|
            get_attribute_name(value,foreign_oid,connection)
          end

          association_name = "fkey____#{table_name.upcase}_#{local_columns.first}____#{row['foreign_table_name'].upcase}_#{foreign_columns.first}____"

          unless is_there_an_index_on(table_name,local_columns.first,connection)
            models[table_name][:binding] += "\t# WARNING! might result in a slow query.  #{association_name} is missing a index on the foreign_key\n"
            models[row['foreign_table_name']][:binding] += "\t# WARNING! might result in a slow query.  #{association_name} is missing a index on the foreign_key\n"
          end

          models[table_name][:binding]                += "\tbelongs_to :#{association_name}, :foreign_key => :#{local_columns.first}, :primary_key => :#{foreign_columns.first}, :class_name => \"#{get_class_name_with_namespace(table2class(check_class_name(row['foreign_table_name'])))}\"\n"
          models[row['foreign_table_name']][:binding] += "\thas_many   :#{association_name}, :foreign_key => :#{local_columns.first}, :primary_key => :#{foreign_columns.first}, :class_name => \"#{get_class_name_with_namespace(table2class(check_class_name(table_name)))}\"\n"


        end
      end

  end

  def get_columns table_name,oid,connection,models

    result = connection.query "
    select 

    	pg_attribute.attnum as attribute_number
    	,pg_type.typname as type_name
    	,pg_attribute.attname as attribute_name
    	,pg_type.typlen as max_length
    	,pg_attribute.atttypmod as max_length_minus_4_for_varlen
    	,pg_attribute.attnotnull as not_null_constraint
    	,pg_attribute.attisdropped as attisdropped /* This column has been dropped and is no longer valid. A dropped column is still physically present in the table, but is ignored by the parser and so cannot be accessed via SQL. */
    	,pg_attribute.atthasdef as has_default_value
    	,pg_attrdef.adsrc as default_value_src

    	from pg_attribute

    	join pg_type on pg_type.oid = pg_attribute.atttypid
    	left join pg_attrdef on pg_attrdef.adrelid = pg_attribute.attrelid and pg_attrdef.adnum = pg_attribute.attnum

    	where
    		pg_attribute.attrelid = #{oid}
    		and pg_attribute.attnum > 0
    	
    	order by attribute_name;
    "

    columns_buffer = ""

    #
    # Add comment with the column names
    #
    result.each do |row|
      if row['has_default_value'] == 't'
        models[table_name][:columns] += "\t#\t\t#{pad_string(row['attribute_name'],20) }\t#{pad_string(row['type_name'],10)}\t #{row['default_value_src']} \n"
      else
        models[table_name][:columns] += "\t#\t\t#{pad_string(row['attribute_name'],20) }\t#{pad_string(row['type_name'],10)} \n"
      end
    end

    #
    # Add not null constraints
    #
    models[table_name][:constraint] += "\n"
    result.each do |row|
      if row['not_null_constraint'] == 't' and row['has_default_value'] == 'f'
        if row['type_name'] == 'bool'
        else
          models[table_name][:constraint] += "\tvalidates_presence_of :#{row['attribute_name']} \n"
        end
      end
    end
    
    models[table_name][:constraint] += "\n" unless models[table_name][:constraint][-1,1] == "\n"
    result.each do |row|
      if row['not_null_constraint'] == 't' and row['has_default_value'] == 'f'
        if row['type_name'] == 'bool'
          models[table_name][:constraint] += "\tvalidates_inclusion_of :#{row['attribute_name']}, :in => [true, false] \n"
        else
        end
      end
    end

    #
    # Add varchar length constraints
    #
    models[table_name][:constraint] += "\n"
    result.each do |row|
      if row['max_length_minus_4_for_varlen'].to_i > 0
        allow_nil = ((row['not_null_constraint'] != 't' or row['has_default_value'] == 't') ? ",:allow_nil => true" : "")
        models[table_name][:constraint] += "\tvalidates_length_of :#{row['attribute_name']}, :maximum => #{row['max_length_minus_4_for_varlen'].to_i - 4} #{allow_nil} \n"
      end
    end

    #
    # Add integer constraints
    #
    models[table_name][:constraint] += "\n"
    result.each do |row|
      if row['type_name'].include? "int" 
        allow_nil = ((row['not_null_constraint'] != 't' or row['has_default_value'] == 't') ? ",:allow_nil => true" : "")
        models[table_name][:constraint] += "\tvalidates_numericality_of :#{row['attribute_name']}, :only_integer => true #{allow_nil} \n"
      end
    end

  end
  
end


namespace :db do

  desc 'Generates/updates activerecord models based on current schema in the postgresql db'
  task :gen_models => :environment do |t,args|
    
    args = args.to_hash
    
    if args[:dbname].blank?
      args[:dbname] = ActiveRecord::Base.connection.current_database
    end
    
    args[:schema_name] = 'public' if args[:schema_name].nil? || args[:schema_name].empty?
    
    schema_name = args[:schema_name]
    dbname = args[:dbname]
    prefix = (args[:prefix]||'').capitalize
    
    PGGen.new(prefix,schema_name,dbname)
  end
  
  desc 'Generates/updates activerecord models based on current schema in the postgresql db for tables matching the supplied regex'
  task :gen_matching_models,[:regex] => [:environment] do |t,args|
    args = args.to_hash
    
    if args[:dbname].blank?
      args[:dbname] = ActiveRecord::Base.connection.current_database
    end
    
    args[:schema_name] = 'public' if args[:schema_name].nil? || args[:schema_name].empty?
    
    schema_name = args[:schema_name]
    dbname = args[:dbname]
    prefix = (args[:prefix]||'').capitalize
    
    PGGen.new(prefix,schema_name,dbname,args[:regex])
  end
  
  
end
