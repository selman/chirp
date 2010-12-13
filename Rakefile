require 'bundler'

CHIRP_ENV = ENV['RACK_ENV'] || 'development'
Bundler.require(:default, CHIRP_ENV.to_sym)

require_relative 'models'

DataMapper::Logger.new(STDOUT, :info)

case CHIRP_ENV
when 'production'
  DataMapper.setup(:default, ENV['DATABASE_URL'])
when 'development'
  DataMapper.setup(:default, "sqlite://#{File.expand_path(File.dirname(__FILE__))}/development.db")
else
  puts "You can't run rake tasks at test environment"
end

desc "Run Datamapper.auto_migrate! (wipes all data) and configure Janrain with given arguments"
task :migrate_config, :api_key, :realm, :callback_url do |t, args|
  DataMapper.auto_migrate!
  janrain_config args
end

desc "Run Datamapper.auto_upgrade! and configure Janrain with given arguments"
task :upgrade_config, :api_key, :realm, :callback_url do |t, args|
  DataMapper.auto_upgrade!
  janrain_config args
end

def janrain_config args
  conf = ChirpConf.first_or_create({:environment => CHIRP_ENV})
  conf.update(:api_key      => args[:api_key],
              :realm        => args[:realm],
              :callback_url => args[:callback_url])
end
