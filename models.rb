require 'open-uri'

class ChirpConf
  include DataMapper::Resource

  property :id,           Serial
  property :environment,  String
  property :api_key,      String
  property :realm,        String
  property :callback_url, String

end

URL_REGEXP = Regexp.new('\b ((https?|telnet|gopher|file|wais|ftp) : [\w/#~:.?+=&%@!\-] +?) (?=[.:?\-] * (?: [^\w/#~:.?+=&%@!\-]| $ ))', Regexp::EXTENDED)
AT_REGEXP = Regexp.new('\s@[\w.@_-]+', Regexp::EXTENDED)

class User
  include DataMapper::Resource

  property :id,         Serial
  property :email,      String, :length => 255
  property :nickname,   String, :length => 255
  property :identifier, String, :length => 255
  property :photo_url,  String, :length => 255

  has n, :chirps
  has n, :direct_messages, 'Chirp'
  has n, :friendships
  has n, :followers, self, :through => :friendships, :via => :target
  has n, :follows,   self, :through => :friendships, :via => :target
  has 1, :device

  def displayed_chirps
    chirps = []
    chirps += self.chirps.all(:recipient_id => nil, :limit => 10, :order => [:created_at.desc]) # don't show direct messsages
    self.follows.each do |follows|
      chirps += follows.chirps.all(:recipient_id => nil, :limit => 10, :order => [:created_at.desc])
    end if @myself == @user
    chirps.sort! { |x,y| y.created_at <=> x.created_at }
    chirps[0..10]    
  end

end

class Friendship
  include DataMapper::Resource

  property :user_id,   Integer, :key => true, :min => 1
  property :target_id, Integer, :key => true, :min => 1

  belongs_to :user, :key => true
  belongs_to :target, 'User', :key => true
end

class Device
  include DataMapper::Resource

  property :app_id, String
  property :push_secret, String

  belongs_to :user, :key => true
end

class Chirp
  include DataMapper::Resource

  property :id, Serial
  property :text, String, :length => 140
  property :created_at,  DateTime

  belongs_to :user, :key => true
  belongs_to :recipient, 'User', :required => false

  before :save do
    starts_with?('dm ') ? process_dm : process
  end

  # general scrubbing of chirp
  def process
    # process url
    urls = self.text.scan(URL_REGEXP)
    urls.each { |url|
      tiny_url = open("http://tinyurl.com/api-create.php?url=#{url[0]}") {|s| s.read}
      self.text.sub!(url[0], "<a href='#{tiny_url}'>#{tiny_url}</a>")
    }
    # process @
    ats = self.text.scan(AT_REGEXP)
    ats.each { |at| self.text.sub!(at, "<a href='/#{at[2,at.length]}'>#{at}</a>") }
  end

  # process direct messages 
  def process_dm
    self.recipient = User.first(:email => self.text.split[1])  
    self.text = self.text.split[2..self.text.split.size].join(' ') # remove the first 2 words
    unless self.recipient.device.nil?
      user = self.recipient.device.app_id
      pass = self.recipient.device.push_secret
      url = "https://#{user}:#{pass}@appush.com/api/notification"
      data = {
        "tags" => ["chirp"],
        "payload" => {
          "aps" => {
            "alert" => self.text,
            "sound" => "meow.caf"
          }
      }}
      json_data = JSON.generate(data)
      RestClient.post url, json_data, :accept => 'application/json', :content_type => 'application/json'
    end
    process
  end

  # process follow commands
  def process_follow
    Friendship.create(:user => User.first(:email => self.text.split[1]), :follower => self.user)
    throw :halt # don't save
  end

  def starts_with?(prefix)
    prefix = prefix.to_s
    self.text[0, prefix.length] == prefix
  end  
end

DataMapper.finalize
