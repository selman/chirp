require 'bundler'

CHIRP_ENV = ENV['RACK_ENV'] || 'development'
Bundler.require(:default, CHIRP_ENV.to_sym)

require './chirper'
run Chirper
