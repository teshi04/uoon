# coding: utf-8

require 'rubygems' unless defined? ::Gem
require 'sinatra'
require 'erubis'
require 'oauth'
require 'rack/csrf'
require 'twitter'
require 'yaml'
require 'dalli'
require 'rack/session/dalli'

set :erb, :escape_html => true

configure do
  use Rack::Session::Dalli, :cache => Dalli::Client.new
end

begin
  $settings = YAML::load(open("./uoon.conf"))
rescue
  puts "config file load failed."
  exit
end

callback_url = $settings["address"] + 'callback'
consumer = OAuth::Consumer.new($settings['consumer_key'], $settings['consumer_secret'], :site => 'https://twitter.com')

get '/' do
  if session[:access_token]
    redirect '/uon'
  end
  
  erb :index
end

post '/' do
  request_token = consumer.get_request_token(:oauth_callback => callback_url)
  session[:request_token] = request_token
  redirect request_token.authorize_url

  erb :index
end

get '/callback' do
  request_token = session[:request_token]
  access_token = request_token.get_access_token(
    {},
    'oauth_token' => params['oauth_token'],
    'oauth_verifier' => params['oauth_verifier']
  )
  session[:access_token] = access_token.token
  session[:access_token_secret] = access_token.secret
  
  redirect $settings['address']+'uon' 
end

get '/uon' do
  erb :uon
end

post '/uon' do
  Twitter.configure do |config|
     config.consumer_key = $settings['consumer_key']
     config.consumer_secret = $settings['consumer_secret']
  end
  
  @client = Twitter::Client.new(
    :oauth_token => session[:access_token],
    :oauth_token_secret => session[:access_token_secret]
  )
  
  begin
    @client.update("うおオン　俺はまるで人間火力発電所だ #uoon_orehamarudeningenkaryokuhatudensyoda")
  rescue
    redirect '/error'
  end

  redirect '/exit'
end  

get '/error' do
  erb :error
end 

get '/exit' do
  erb :exit
end

