# coding: utf-8
require 'rubygems' unless defined? ::Gem
require 'sinatra'
require 'erubis'
require 'oauth'
require 'rack/csrf'
require 'twitter'

set :erb, :escape_html => true

configure do
	use Rack::Session::Cookie, :secret => Digest::SHA1.hexdigest('teshiya')
	#use Rack::Csrf, :raise => true
end

callback_url = 'http://uon.tsur.jp/callback'
consumer = OAuth::Consumer.new('YxPd7gAtYLUNVZ5zWzu6A', '8MWW60k5QyBB5hNkjZ2LdAqSgwG9ZLadelkewtJDgk', :site => 'https://twitter.com')

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
	
	redirect 'http://uon.tsur.jp/uon'	
end

get '/uon' do
	erb :uon
end

post '/uon' do
	Twitter.configure do |config|
     config.consumer_key = 'YxPd7gAtYLUNVZ5zWzu6A'
     config.consumer_secret = '8MWW60k5QyBB5hNkjZ2LdAqSgwG9ZLadelkewtJDgk'
   end
	@client = Twitter::Client.new(
  	:oauth_token => session[:access_token],
    :oauth_token_secret => session[:access_token_secret]
  	)

	@client.update("うおオン　俺はまるで人間火力発電所だ 
#uoon_orehamarudeningenkaryokuhatudensyoda")
	erb :exit
end


