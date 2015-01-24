require 'open-uri'
require 'json'

# Module used to extend Danbooru with Gelbooru features
module Gelbooru
  # This isn't a full history population method, but a method that's called by danbooru's.
  def gelbooru_populate_history(uri)
    # Is it a gelbooru-like url?
    if match = uri.expanded_url.to_s.match(%r (?<api>s?://[\w\.:]*)/index\.php\?page=post&s=view&id=(?<post_id>\d+) i)
      # Add it.
      danbooru_history_add "gelbooru#{match['api'].downcase} #{match['post_id']}"
    end
  end

  # Called by danbooru_get to return the same stuff danbooru_get returns.
  def gelbooru_get(query, parameters)
    # Figure out api
    api = config.gelbooru
    # Does it start with a protocol?
    if match = api.match(%r ^\w+?(?<s>s)?:// i)
      api = "#{match['s']}://#{match.post_match}"
    else
      api = "://#{api}"
    end
    api.downcase!

    gelbooru_params = {}

    if query == 'posts'
      # Generate uri
      uri = "http#{api}/index.php?page=dapi&s=post&q=index&json=1"

      # Translate parameters
      {
        limit: 'limit',
        page: 'pid',
        tags: 'tags'
      }.each do |old_key, new_key|
        gelbooru_params[new_key] = parameters[old_key] if parameters.has_key? old_key
        gelbooru_params[new_key] = parameters[old_key.to_s] if parameters.has_key? old_key.to_s
      end

      # Loop through parameters if necessary
      unless gelbooru_params.empty?
        uri += '&'
        # Create an array of parameters
        parameters_array = []
        gelbooru_params.each do |key, value|
          # Ensure key and value are strings, or URI.escape will be sad
          parameters_array << "#{URI.escape key.to_s}=#{URI.escape value.to_s}"
        end
        # Merge them and add them to uri
        uri += parameters_array.join '&'
      end

      # Access URI and convert data from json
      begin
        open uri do |io|
          parsed_data = JSON.parse io.read
          parsed_data.map do |post|
            gelbooru_post_convert api, post
          end
        end
      rescue OpenURI::HTTPError => error
        error_message = "#{error.message} - #{uri}\n\t"
        body = error.io.read
        begin
          data = JSON.parse body
          if data.has_key?('message')
            error_message << "#{data['message']}\n"
          else
            # This is a bit of a cheating way to get the rescue statment down there to run.
            raise JSON::ParserError
          end
        rescue JSON::ParserError
          error_message << body.gsub(/\n\t?/, "\n\t")
        end
        dm_owner "#{error.class}: #{error.message}" if config.errors
        log "#{error_message}\n\t#{error.backtrace.join("\n\t")}"
        {}
      rescue JSON::ParserError => error
        dm_owner "#{error.class}: #{error.message}" if config.errors
        log "#{error.class}: #{error.message}\n\t#{error.backtrace.join("\n\t")}"
        {}
      end
    end
  end

  # Converts posts from gelbooru to danbooru format
  def gelbooru_post_convert(api, post)
    {
      'id' => "gelbooru#{api} #{post['id']}",
      'file_ext' => post['image'].match(/\.(?<ext>\w+)\z/)['ext'],
      'rating' => post.empty? ? '' : post['rating'][0],
      'tag_string_character' => '',
      'tag_string_copyright' => post['tags'],
      'tag_string_artist' => '',
      '__api' => api,
      '__api_type' => :gelbooru,
      '__directory' => post['directory'],
      '__image' => post['image'],
      '__sample' => post['sample']
    }
  end

  # Generate a uri to link to
  def gelbooru_post_uri(id)
    # Return if id isn't a string
    return false unless id.is_a? String

    # Split id
    id_array = id.split ' '

    # Return false if it's not a gelbooru type id
    return false unless id_array.length == 2
    return false unless match_api = id_array[0].match(/^gelbooru(?<s>s)?/)

    # Generate post_uri
    "http#{match_api['s']}#{match_api.post_match}/index.php?page=post&s=view&id=#{id_array[1]}"
  end

  # Generate an image uri
  def gelbooru_image_uri(post)
    # Return if this isn't a gelbooru post
    return false unless post.__api_type == :gelbooru

    # Start building uri
    uri = "http#{post.__api}/"
    # Is there a sample image?
    uri += post.__sample ? 'samples' : 'images'
    # Add on directory
    uri += "/#{post.__directory}/"
    # Again, is there a sample image?
    uri +=  post.__sample ? 'sample_' : ''
    # Finish off.
    uri += "#{post.__image}"
  end
end
