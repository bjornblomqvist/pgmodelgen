# pgmodelgen

Rake task that generates/updates activerecord models based on current schema in a postgresql DB.

```
rake db:gen_model
```

output

```
Generating for: my_db.public with prefix 

	Creating models for these tables

		user
		account
	Writing to ./app/models//user.rb
	Writing to ./app/models//account.rb

```

The resulting models

## user.rb

```ruby
# encoding: utf-8

class User < ActiveRecord::Base 
  
	#--- auto_gen_start ---
	#
	# This is generate using gen_pg_models, dont make changes
	# within auto_gen_XXXXX as it will be overwriten next time
	# gen_pg_models is run.
	#

	# Columns

	#		email_address       	text       
	#		password_hash       	text       
	#		user_id             	int4      	 nextval('user_user_id_seq'::regclass)
	#		account_id            int4      	 

	# Table config 

	self.table_name = "user"
	self.primary_key = "user_id"
	self.sequence_name = "user_user_id_seq"

	# Constraints 

	validates_presence_of :email_address 
	validates_presence_of :password_hash 


	validates_numericality_of :user_id, :only_integer => true ,:allow_nil => true 
	validates_numericality_of :account_id, :only_integer => true

	validates_uniqueness_of :email_address

	# Foreign keys 

  belongs_to :fkey____ACCOUNT_account_id____ACCOUNT_account_id____, :foreign_key => :account_id, :primary_key => :account_id, :class_name => "Account"

	#--- auto_gen_end ---

end
```

## account.rb

```ruby
# encoding: utf-8

class Account < ActiveRecord::Base 

	#--- auto_gen_start ---
	#
	# This is generate using gen_pg_models, dont make changes
	# within auto_gen_XXXXX as it will be overwriten next time
	# gen_pg_models is run.
	#

	# Columns

	#		account_id          	int4      	 nextval('account_account_id_seq'::regclass) 
	#		name                	text

	# Table config 

	self.table_name = "account"
	self.primary_key = "account_id"
	self.sequence_name = "account_account_id_seq"

	# Constraints 

	validates_presence_of :name 


	validates_numericality_of :account_id, :only_integer => true ,:allow_nil => true 

	validates_uniqueness_of :name

	# Foreign keys 

	has_many   :fkey____USER_account_id____ACCOUNT_account_id____, :foreign_key => :account_id, :primary_key => :account_id, :class_name => "User"

	#--- auto_gen_end ---

end 



```


# Contributing to pgmodelgen
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Fork the project.
* _Start a feature/bugfix branch_.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history.

# Copyright

Copyright (c) 2013 Darwin. See LICENSE.txt for
further details.

