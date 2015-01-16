loop do
  begin

  rescue
    File.open 'bots.rb', 'w' do |destination|
      File.open 'bots_dev.rb', 'r' do |source|
        until source.eof?
          destination.write source.read 1024
        end
      end
    end
  end
  system 'ebooks start'
  case $?
  when 69
    break
  else
    break
  end
end
