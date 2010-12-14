require 'net/http'
require 'net/https'

module AppHelpers
  def dm_count
    Chirp.count(:recipient_id => session[:userid]) + Chirp.count(:user_id => session[:userid], :recipient_id.not => nil)
  end

  def get_user(token)
    u = URI.parse('https://rpxnow.com/api/v2/auth_info')
    req = Net::HTTP::Post.new(u.path)
    req.form_data = {'token' => token, 'apiKey' => conf.api_key, 'format' => 'json'}
    http = Net::HTTP.new(u.host,u.port)
    http.use_ssl = true if u.scheme == 'https'
    json = JSON.parse(http.request(req).body)

    if json['stat'] == 'ok'
      identifier = json['profile']['identifier']
      nickname = json['profile']['preferredUsername']
      nickname = json['profile']['displayName'] if nickname.nil?
      email = json['profile']['email']
      {:identifier => identifier, :nickname => nickname, :email => email}
    else
      raise LoginFailedError, 'Cannot log in. Try another account!'
    end
  end
end
