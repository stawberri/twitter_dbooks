require 'open-uri'
require 'tempfile'
ENVSetting = Class.new RuntimeError
env = {}
begin
  raise ENVSetting, 'urgh disabled' if ENV['URGH'] == 'off'
  env['UPDATER_ERROR'] = ''
  Tempfile.create 'urgh' do |urgh|
    open 'https://github.com/Stawberri/twitter_dbooks/archive/master.tar.gz' do |github|
      until github.eof?
        urgh.write github.read 1024
      end
    end
    urgh.close
    system "tar -xzf #{urgh.path} --strip-components=1"
  end
rescue => error
  env['UPDATER_ERROR'] = "#{error.class}: #{error.message}"
end
system env, 'bundle exec ruby updater.rb'
# system env, 'bundle exec ebooks start
