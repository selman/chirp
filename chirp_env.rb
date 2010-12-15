require 'bundler'

CHIRP_ENV = ENV['RACK_ENV'] || 'development'
Bundler.require(:default, CHIRP_ENV.to_sym)

# below code needed until Sinatra 1.2
module Sinatra
  module Templates
    def slim(template, options={}, locals={})
      render :slim, template, options, locals
    end
  end
end
#########

case CHIRP_ENV
when 'production'
  Slim::Engine.set_default_options
  DataMapper::Logger.new(STDOUT, :info)
  DataMapper.setup(:default, ENV['DATABASE_URL'])
when 'development'
  Slim::Engine.set_default_options :pretty => true
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, "sqlite://#{File.expand_path(File.dirname(__FILE__))}/development.db")
when 'test'
  Slim::Engine.set_default_options :pretty => true
  DataMapper.setup(:default, "sqlite:memory:")
end
