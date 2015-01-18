require 'open-uri'

NO_DOWNLOAD_ENV = 'UPDATER_OFF'
NO_DOWNLOAD_VALUE = 'true'
NO_DOWNLOAD_ERROR_MESSAGE = "ENV Manual Override #{NO_DOWNLOAD_ENV}=#{NO_DOWNLOAD_VALUE}"
ERROR_ENV = 'UPDATER_ERROR'
DESTINATION_FILE = 'bots.rb'
SOURCE_FILE = 'v2.rb'
DOWNLOAD_URI = 'https://raw.githubusercontent.com/Stawberri/twitter_dbooks/master/v2.rb'
START_COMMAND = 'ebooks start'

begin
  error_message = ''
  raise IOError, NO_DOWNLOAD_ERROR_MESSAGE if ENV[NO_DOWNLOAD_ENV] == NO_DOWNLOAD_VALUE
  File.open DESTINATION_FILE, 'w' do |destination|
    open DOWNLOAD_URI do |source|
      until source.eof?
        destination.write source.read 1024
      end
    end
  end
rescue => error
  error_message = "#{error.class} #{error.message}"
  File.open DESTINATION_FILE, 'w' do |destination|
    File.open SOURCE_FILE do |source|
      until source.eof?
        destination.write source.read 1024
      end
    end
  end
end
begin
  system({ERROR_ENV => error_message}, START_COMMAND)
ensure
  File.delete DESTINATION_FILE rescue nil
end
