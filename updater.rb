NO_DOWNLOAD_ENV = 'NO_DOWNLOAD'
NO_DOWNLOAD_VALUE = 'true'
NO_DOWNLOAD_ERROR_MESSAGE = 'ENV Override  ♥'
DESTINATION_FILE = 'bots.rb'
SOURCE_FILE = 'v2.rb'
DOWNLOAD_URI = 'https://raw.githubusercontent.com/Stawberri/twitter_dbooks/biotags/v2.rb'
START_COMMAND = 'ebooks start'
GENERATED_FILE_HEADER = <<-PUDDIDOC.gsub(/^ {2}/, '')
  # ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥
  # ♥ DON'T EDIT THIS FILE!                  ♥
  # ♥                                        ♥
  # ♥ Changes to this file will be           ♥
  # ♥ overwritten every time your @_dbooks   ♥
  # ♥ is restarted.                          ♥
  # ♥                                        ♥
  # ♥ Instead, please edit bots_dev.rb and   ♥
  # ♥ set an ENV variable:                   ♥
  # ♥                                        ♥
  # ♥   #{NO_DOWNLOAD_ENV}=#{NO_DOWNLOAD_VALUE}
  # ♥                                        ♥
  # ♥              ~ Pudding (@stawbewwi)    ♥
  #  ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥

PUDDIDOC
NO_DOWNLOAD_MESSAGE = <<-PUDDIDOC.gsub(/^ {2}/, '')

   ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥
   ♥ WARNING: Couldn't load copy of bots.rb ♥
   ♥          from GitHub. Attempting to    ♥
   ♥          run out-of-date backup copy   ♥
   ♥          of @_dbooks from whenever you ♥
   ♥          installed this bot. Error:    ♥
   ♥                                        ♥
   ♥            ♦ERROR♦
   ♥                                        ♥
   ♥          Unless this was intensional,  ♥
   ♥          please update manually to fix ♥
   ♥          this issue as soon as you     ♥
   ♥          can. You can also try         ♥
   ♥          checking Twitter to see if I  ♥
   ♥          have any news about what's    ♥
   ♥          what's going on, or ask me    ♥
   ♥          for help there.               ♥
   ♥              ~ Pudding (@stawbewwi)    ♥
    ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥

PUDDIDOC

loop do
  begin
    raise NO_DOWNLOAD_ERROR_MESSAGE if ENV[NO_DOWNLOAD_ENV] == NO_DOWNLOAD_VALUE
    require 'open-uri'
    File.open DESTINATION_FILE, 'w' do |destination|
      open DOWNLOAD_URI do |source|
        destination.write GENERATED_FILE_HEADER
        until source.eof?
          destination.write source.read 1024
        end
      end
    end
  rescue => error
    STDOUT.print NO_DOWNLOAD_MESSAGE.gsub(/♦ERROR♦/, "#{error.class}: #{error.message}")
    STDOUT.flush
    File.open DESTINATION_FILE, 'w' do |destination|
      File.open SOURCE_FILE, 'r' do |source|
        destination.write GENERATED_FILE_HEADER
        until source.eof?
          destination.write source.read 1024
        end
      end
    end
  end

  system START_COMMAND
  break unless $?.exitstatus == 69
end
