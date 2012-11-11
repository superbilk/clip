require 'bundler'
Bundler.require :default

require './main'

run Sinatra::Application
