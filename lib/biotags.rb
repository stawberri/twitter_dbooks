require 'ostruct'

# Configuration module
module Biotags
  # Default config options
  CONFIG_DEFAULT = '%every:never'

  # Tags that become strung together instead of being overwritten
  CONFIG_DUPLICATABLE = {
    'tags' => ' ',
    'blacklist' => ' '
  }

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

  # Parse a biotag string into a openstruct.
  def biotags_parse(tag_string)
    # Create new openstruct
    ostruct = OpenStruct.new

    tag_string.split(' ').each do |item|
      # Is it a biotag?
      if item.start_with? '%'
        # It is. Remove identifier
        item = item[1..-1]
      else
        # It isn't. Make it one.
        item = "tags:#{item}"
      end

      # Process shortcut %tags

      item = item\
        .gsub(/\A-/, 'blacklist:')

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
        # Expand shortened urls in it.
        value = value.extend(PuddiString).expand_tcos if value.is_a? String
        # Is this key already set?
        if CONFIG_DUPLICATABLE.has_key?(key) && ostruct[key].is_a?(String)
          # It is, so append it unless it's 'true'.
          ostruct[key] = "#{ostruct[key]}#{CONFIG_DUPLICATABLE[key]}#{value}" unless value == true
        else
          # It isn't, so just set it.
          ostruct[key] = value
        end
      end
    end

    # Ensure that 'tags' exists.
    ostruct.tags ||= ''

    ostruct
  end
end
