def show_version
  version_message = <<-PUDDIDOC.gsub(/^  /, '')

   & & & & & & & & & & & & & & & & & & & & &
   & ☺                                      &
   &                                        &
   &                                      ☻ &
  ♦
   &                                        &
   & WARNING: Couldn't load copy of bots.rb &
   &          from GitHub. Attempting to    &
   &          run potentially out-of-date   &
   &          backup copy of @_dbooks.      &
   &                                        &
   &  ♣                                     &
   &  ♠                                     &
   &                                        &
   &          Unless this was intentional,  &
   &          please update manually to fix &
   &          this issue as soon as you     &
   &          can. You can also try         &
   &          checking Twitter to see if I  &
   &          have any news about what's    &
   &          what's going on, or ask me    &
   &          for help there.               &
   &                                        &
   &              ~ Pudding (@stawbewwi)    &
  ♦
    & & & & & & & & & & & & & & & & & & & & &

  PUDDIDOC
  # Version Name
  version_name = DBOOKS_VERSION_NAME
  version_name_length = version_name.length
  if version_name_length > 36
    version_name = version_name[0...36]
    version_name_length = 36
  end
  # Using this for spaces
  version_name_length -= 1
  version_message.gsub!(/☺ {#{version_name_length}}/, version_name)

  # Version String
  version_string = DBOOKS_VERSION
  version_string_length = version_string.length
  if version_string_length > 36
    version_string = version_string[0...36]
    version_string_length = 36
  end
  # Using this for spaces
  version_string_length -= 1
  version_message.gsub!(/ {#{version_string_length}}☻/, version_string)
  if ENV['URGH_ERROR'].empty?
    version_message.gsub!(/♦.*♦\r?\n/m, '')
  else
    version_message.gsub!(/♦\r?\n/, '')
    # Parse error string
    space_match = ENV['URGH_ERROR'].match(/ /)

    error_class = space_match.pre_match
    error_class_length = error_class.length
    if error_class_length > 36
      error_class = error_class[0...36]
      error_class_length = 36
    end

    error_message = space_match.post_match
    error_message_length = error_message.length
    if error_message_length > 36
      error_message = error_message[0...36]
      error_message_length = 36
    end
    # Using these numbers for spaces later.
    error_class_length -= 1
    error_message_length -= 1
    # Splice them in
    version_message.gsub!(/♣ {#{error_class_length}}/, error_class)
    version_message.gsub!(/♠ {#{error_message_length}}/, error_message)
  end
  STDOUT.print version_message
  STDOUT.flush
end
show_version
