require 'digest/md5'

require_relative 'chirp_env'
require_relative 'models'
require_relative 'template_helpers'
require_relative 'app_helpers'

class Chirper < Sinatra::Base
  include AppHelpers
  enable :sessions
  set :root, File.dirname(__FILE__)
  use Rack::Flash

  error do
    flash[:error] = env['sinatra.error'].to_s
    redirect '/home'
  end

  ['/', '/home', ].each do |path|
    get path do
      if session[:userid].nil?
        slim :timeline
      else
        user = User.get(session[:userid])
        if user.nil?
          redirect "/logout"
        else
          redirect "/#{user.email}"
        end
      end
    end
  end

  get '/logout' do
    session[:userid] = nil
    redirect '/'
  end

  post '/login' do
    openid_user = get_user(params[:token])
    user = User.first_or_create({:identifier => openid_user[:identifier]}, {
                                  :nickname => openid_user[:nickname],
                                  :email => openid_user[:email],
                                  :photo_url => "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(openid_user[:email])}"
                                })
    session[:userid] = user.id # keep what is stored small
    redirect "/#{user.email}"
  end

  post '/chirp' do
    user = User.get(session[:userid])
    user.chirps.create(:text => params[:chirp])
    redirect "/#{user.email}"
  end

  ['/follows', '/followers'].each do |path|
    get path do
      @myself = User.get(session[:userid])
      @dm_count = dm_count
      erb :follows
    end
  end

  get '/register' do
    @myself = User.get(session[:userid])
    redirect '/' if @myself.nil?
    unless @myself.device.nil?
      @app_id = @myself.device.app_id
      @push_secret = @myself.device.push_secret
    else
      @app_id = nil
      @push_secret = nil
    end
    erb :register
  end

  post '/register' do
    @myself = User.get(session[:userid])
    redirect '/' if @myself.nil?
    if @myself.device.nil?
      @myself.device = Device.new
    end
    @myself.device.update(:app_id => params[:app_id], :push_secret => params[:push_secret])
    redirect '/home'
  end

  get '/:email' do
    @myself = User.get(session[:userid])
    redirect '/' if @myself.nil?
    @user = @myself.email == params[:email] ? @myself : User.first(:email => params[:email])
    @dm_count = dm_count
    slim :home
  end

  get '/follow/:email' do
    user = User.get(session[:userid])
    user.follows << User.first(:email => params[:email])
    user.follows.save
    redirect '/home'
  end

  delete '/follows/:user_id/:follows_id' do
    user = User.get(session[:userid])
    user.follows.get(params[:follow_id]).destroy
    redirect '/follows'
  end

  get '/direct_messages/:dir' do
    @myself = User.get(session[:userid])
    case params[:dir]
    when 'received'
      @chirps = Chirp.all(:recipient_id => @myself.id)
    when 'sent'
      @chirps = Chirp.all(:user_id => @myself.id, :recipient_id.not => nil)
    end
    @dm_count = dm_count
    erb :direct_messages
  end
end
