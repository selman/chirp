class Chirper < Sinatra::Base
  helpers do
    def conf
      @conf ||= AppConfig.load
      @conf[Sinatra::Base.environment.to_s]
    end

    def time_ago_in_words(timestamp)
      minutes = (((Time.now - timestamp).abs)/60).round
      return nil if minutes < 0

      case minutes
      when 0               then 'less than a minute ago'
      when 0..4            then 'less than 5 minutes ago'
      when 5..14           then 'less than 15 minutes ago'
      when 15..29          then 'less than 30 minutes ago'
      when 30..59          then 'more than 30 minutes ago'
      when 60..119         then 'more than 1 hour ago'
      when 120..239        then 'more than 2 hours ago'
      when 240..479        then 'more than 4 hours ago'
      else                 timestamp.strftime('%I:%M %p %d-%b-%Y')
      end
    end
  end
end

class AppConfig
  def self.load
    YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "chirp.conf")))
  end
end
