pwd = File.dirname(__FILE__)

# adding current path
$LOAD_PATH.unshift(pwd)

#require "#{File.dirname(__FILE__)}/vendor/bundler_gems/environment"

require 'chirp'
run Sinatra::Application
