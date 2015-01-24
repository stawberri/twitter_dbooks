# Configuration module
module Biotags
  # Update @config
  def biotags_update
    # Fetch twitter description and grab its biotags
    if match_data = user.description.match(/@_dbooks/i)
      config match_data.post_match
    end
  end

  # Create an OpenStruct from parsing input string, if one is given
  def config(biotag_string = nil)
    # Return config if no string is given, or if string is identical to last one.
    # If config isn't defined, re-call this method with an empty string.
    return @config || config('') if biotag_string.nil?
    return @config if biotag_string == @biotag_string_previous

    # Save string for comparison next time
    @biotag_string_previous = biotag_string

    # Parse it.
    @config = biotags_parse "#{CONFIG_DEFAULT} #{@initialization_config} #{biotag_string}"
  end

  # Parses uris out of user descriptions, if there are any
  def biotags_parse_uri(text)
    # Return unless this is actually a string.
    return text unless text.is_a? String

    # Return unless user stuff is available
    return text unless user.is_a? Twitter::User
    return text unless user.description_uris?

    # Loop through uris we know about
    user.description_uris.each do |uri|
      text = text.gsub uri.url.to_s, uri.expanded_url.to_s
    end

    text
  end

  # Parse a biotag string into a openstruct.
  def biotags_parse(tag_string)
    # Create new openstruct
    ostruct = OpenStruct.new
    # Create a tags array to hold tags for now
    tags_array = []

    tag_string.split(' ').each do |item|
      # Is it a biotag?
      if item.start_with? '%'
        # It is. Remove identifier
        item = item[1..-1]
      else
        # It isn't. Make it one.
        item = "tag:#{item}"
      end

      # Is it a key/value?
      if match_data = item.match(/:/)
        key = match_data.pre_match
        value = match_data.post_match
      else
        key = item
        value = true
      end

      # Downcase and convert all non-word characters in key to underscores
      key.downcase!
      key.gsub!(/\W/,'_')

      # Is value empty?
      if value.is_a?(String) && value.empty?
        # Remove it from ostruct, if it exists.
        ostruct.delete_field key
      else
        # Parse tags in it.
        value = biotags_parse_uri value
        # Add it to ostruct!
        if key =~ /tags?/
          tags_array |= [value]
        else
          ostruct[key] = value
        end
      end
    end

    # Move tags_array into ostruct
    ostruct.tags = tags_array.join(' ')

    ostruct
  end

  # Default config options
  CONFIG_DEFAULT = '%every:never'
end
