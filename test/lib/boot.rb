require 'rubygems'
require 'yaml'
require 'test/unit'
require 'active_record'
require 'active_support'
require 'fileutils'
require 'shoulda'
require 'quietbacktrace'

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__)+'/../debug.log')
ActiveRecord::Base.configurations = $config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

class ActiveRecord::ConnectionAdapters::MysqlAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
  def log_info(sql, name, runtime)
    if @logger && @logger.debug?
      name = "#{name.nil? ? "SQL" : name} (DB:#{@config[:database]}) (#{sprintf("%f", runtime)})"
      @logger.debug format_log_entry(name, sql.squeeze(' '))
    end
  end
end