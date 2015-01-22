def show_version
  version_message = <<-PUDDIDOC.gsub(/^  /, '')

   & & & & & & & & & & & & & & & & & & & & &
   & ☺                                      &
   &                                        &
   &                                      ☻ &
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
  STDOUT.print version_message
  STDOUT.flush
end
show_version
