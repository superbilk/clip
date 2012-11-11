# encoding: UTF-8
require 'bundler'

require "./sipgate_web_api"

Bundler.require :default

require 'sinatra'
require 'haml'

set :haml, :format => :html5 # default Haml format is :xhtml
enable :sessions

before do
  content_type 'text/html', :charset => 'utf-8'
end

get '/' do
  unless session[:username].nil?
    @username = session[:username]
    @last_clip = session[:last_clip]
    me = SipgateWebApi.new(@username)
    @number = me.clip
    @extension = me.extension(:mobile)
    haml :index
  else
    redirect to('/login')
  end
end

get '/login' do
  haml :login
end

post '/login' do
  @username = params[:username]
  @password = params[:password]
  me = SipgateWebApi.new(@username, @password)
  if me.logged_in?
    session[:username] = params[:username]
    redirect to('/')
  else
    redirect to('/login')
  end
end

get '/logout' do
  session[:username] = nil
  redirect to('/')
end

get '/change/:clip' do |clip|
  unless session[:username].nil?
    me = SipgateWebApi.new(session[:username])
    session[:last_clip] = me.clip
    me.clip = clip
    redirect to('/')
  else
    redirect to('/login')
  end
end

post '/change' do
  unless session[:username].nil?
    me = SipgateWebApi.new(session[:username])
    session[:last_clip] = me.clip
    me.clip = params[:clip]
    redirect to('/')
  else
    redirect to('/login')
  end
end

