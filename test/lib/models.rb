module Connection ; end

class Connection::One < ActiveRecord::Base
  establish_connection :one_db
  self.abstract_class = true
end

class Connection::Two < ActiveRecord::Base
  establish_connection :two_db
  self.abstract_class = true
end

Connections = { :one => Connection::One, :two => Connection::Two }

class GlobalConnection < ActiveRecord::Base
  establish_connection :master
  self.abstract_class = true
end

class AggregateEstimate < GlobalConnection
  include ShardedDatabase::Aggregate
  
  def determine_connection
    Connections[source.to_sym]
  end
  
end

class Estimate < ActiveRecord::Base  
  has_many :items
end

class Item < ActiveRecord::Base
  belongs_to :estimate
end