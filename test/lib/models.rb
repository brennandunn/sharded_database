module Connection ; end

class Connection::One < ActiveRecord::Base
  establish_connection :shard_one
  self.abstract_class = true
end

class Connection::Two < ActiveRecord::Base
  establish_connection :shard_two
  self.abstract_class = true
end

class GlobalConnection < ActiveRecord::Base
  establish_connection :master
  self.abstract_class = true
end

class AggregateEmployee < GlobalConnection
  belongs_to :gun
  include ShardedDatabase::Aggregate
  self.foreign_id   = :other_id
  preserve_attributes :source
  
  def sharded_connection_klass
    "Connection::#{source.classify}".constantize
  end
  
end

class Company < ActiveRecord::Base
  has_many :items
end

class Employee < ActiveRecord::Base
  belongs_to :company
  has_many :items
  
  def call_company
    company
  end
  
end

class Item < ActiveRecord::Base
  belongs_to :employee
end