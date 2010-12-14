require_relative 'chirp_env'
require_relative 'models'

desc "Run Datamapper.auto_migrate! (wipes all data) and configure Janrain with given arguments"
task :migrate_config, :api_key, :realm, :callback_url do |t, args|
  DataMapper.auto_migrate!
  janrain_config args
end

desc "Run Datamapper.auto_upgrade! and configure Janrain with given arguments"
task :upgrade_config, :api_key, :realm, :callback_url do |t, args|
  DataMapper.auto_upgrade!
  janrain_config args
end

def janrain_config args
  conf = ChirpConf.first_or_create({:environment => CHIRP_ENV})
  conf.update(:api_key      => args[:api_key],
              :realm        => args[:realm],
              :callback_url => args[:callback_url])
end
