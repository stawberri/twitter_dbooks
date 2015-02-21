require 'open-uri'
require 'ostruct'
require 'json'

require 'gelbooru'

# Module used to extend Ebooks with Danbooru features
module Danbooru
  # Default danbooru request parameters
  attr_reader :danbooru_default_params

  # Include alternate apis
  include Gelbooru

  # Initialization for danbooru methods
  def danbooru_configure
    # Setup default danbooru params with danbooru login info
    @danbooru_default_params ||= {}
    if config.danbooru_login && config.danbooru_api_key
      @danbooru_default_params['login'] = config.danbooru_login
      @danbooru_default_params['api_key'] = config.danbooru_api_key
    end
  end

  # Populate post history from twitter
  def danbooru_populate_history(tweet_count = 200)
    # Get past tweets
    my_tweets = twitter.user_timeline username, count: tweet_count

    # Iterate through them, adding them to history if they contain a danbooru uri
    my_tweets.each do |tweet|
      # Loop through each tweet's uri
      tweet.uris.each do |uri|
        if match_data = uri.expanded_url.to_s.match(%r //danbooru\.donmai\.us/posts/(?<post_id>\d+) i)
          # If it matches, add it to history
          danbooru_history_add match_data['post_id']

          # If it hasn't been set, set last tweet time to time of this tweet
          @last_timed_tweet_time ||= tweet.created_at
        else
          gelbooru_populate_history uri
        end
      end
    end

    # Just to future proof, update tweet timer.
    update_tweet_timer
  end

  # Add a post id to history
  def danbooru_history_add(post_id)
    # Create a history array if it doesn't already exist
    @danbooru_post_history ||= []

    post_id = [post_id.to_s]

    # Convert it to an integer and then add it
    @danbooru_post_history |= post_id

    post_id
  end

  # Check if a post id is in history
  def danbooru_history_include?(post_id)
    return false unless defined? @danbooru_post_history

    @danbooru_post_history.include? post_id.to_s
  end

  # Wrapper for danbooru requests
  def danbooru_get(query = nil, parameters = {})
    query ||= 'posts'

    # Call gelbooru_get instead if it's enabled
    return gelbooru_get query, parameters if config.gelbooru

    # Begin generating a URI
    uri = "https://danbooru.donmai.us/#{query}.json"

    # Add default parameters to parameters
    parameters = danbooru_default_params.merge parameters

    # Loop through parameters if necessary
    unless parameters.empty?
      uri += '?'
      # Create an array of parameters
      parameters_array = []
      parameters.each do |key, value|
        # Ensure key and value are strings, or URI.escape will be sad
        parameters_array << "#{URI.escape key.to_s}=#{URI.escape value.to_s}"
      end
      # Merge them and add them to uri
      uri += parameters_array.join ';'
    end

    # Access URI and convert data from json
    begin
      open uri do |io|
        JSON.parse io.read
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

  # Fetch posts from danbooru
  def danbooru_posts(tags = nil, page = 1)
    tags ||= config.tags

    danbooru_get 'posts', page: page, limit: 100, tags: tags
  end

  # Genreates a little string to tweet with links.
  def danbooru_tag_string(post)
    # Convert a string with just spaces into a friendly comma separated form with ands.
    def get_tag_string(spaced_string, remove_quotes = false)
      working_array = spaced_string.split ' '
      if remove_quotes
        working_array.map! do |string|
          str = string.gsub(/_\(.*\z/, '')
          str.gsub(/_/, ' ')
        end
      else
        working_array.map! do |string|
          string.gsub(/_/, ' ')
        end
      end

      case working_array.length
      when 0
        nil
      when 1
        working_array[0]
      when 2
        working_array.join ' and '
      else
        working_array[-1] = 'and ' + working_array[-1]
        working_array.join ', '
      end
    end

    # Generate tag strings
    tags_character = get_tag_string post.tag_string_character, true
    tags_copyright = get_tag_string post.tag_string_copyright
    tags_artist = get_tag_string post.tag_string_artist

    output = ''
    if tags_character.nil?
      if tags_copyright.nil?
        # No character or copyright
        output = 'drawn'
      else
        # No character, but has copyright
        output = tags_copyright
      end
    else
      # Has characters
      output = tags_character
      unless tags_copyright.nil?
        output += " (#{tags_copyright})"
      end
    end

    output += ' by ' + tags_artist unless tags_artist.nil?

    output
  end

  # Tweet a post with its post data
  def danbooru_tweet_post(post, options = {})
    options = {bypass_history: false, keep_timer: false}.merge options
    options = OpenStruct.new options

    # Make post an OpenStruct
    unless post.is_a? OpenStruct
      post = post[0] if post.is_a? Array
      post = danbooru_get("posts/#{post}") unless post.is_a? Hash
      # Ensure that it contains an id.
      return unless post.has_key? 'id'
      post = OpenStruct.new post
    end

    # Is post deleted, and we don't want deleted posts?
    return false if !options.bypass && config.no_deleted && post.is_deleted

    # Add post to history, since we're planning to either tweet it or never tweet it now.
    danbooru_history_add post.id

    # Is post in a format we like?
    return false unless ['jpg','jpeg','png'].include? post.file_ext

    # Is it sensitive?
    sensitive = post.rating != 's'

    if config.hide_tags
      tag_string = ''
    else
      # Get a tag string
      tag_string = danbooru_tag_string post
      tag_string.extend PuddiString
      # 93 = 140 - 2 (spaces) - 23 (https url) - 22 (http url)
      tag_string = ' ' + tag_string.trim_ellipsis(93) unless tag_string.empty?
    end

    # Get post URI
    post_uri = gelbooru_post_uri(post.id) || "https://danbooru.donmai.us/posts/#{post.id}"

    # Get image URI
    image_uri = gelbooru_image_uri(post) || "https://danbooru.donmai.us#{post.large_file_url}"

    # Tweet post!
    log "Tweeting post #{post.id}, rating: #{post.rating}"
    begin
      tweet_return = pic_tweet("#{post_uri}#{tag_string}", image_uri, possibly_sensitive: sensitive)

      unless options.keep_timer
        # Update last time variable
        @last_timed_tweet_time = Time.now
        update_tweet_timer
      end

      tweet_return
    rescue Twitter::Error => error
      dm_owner "#{error.class}: #{error.message}" if config.errors
      log "#{error.class}: #{error.message}\n\t#{error.backtrace.join("\n\t")}"
      false
    rescue OpenURI::HTTPError => error
      error_message = "#{error.message} - while tweeting image\n\t"
      body = error.io.read
      error_message << body.gsub(/\n\t?/, "\n\t")
      dm_owner "#{error.class}: #{error.message}" if config.errors
      log "#{error_message}\n\t#{error.backtrace.join("\n\t")}"
      false
    end
  end

  # Pick and tweet a post based on tag settings.
  def danbooru_select_and_tweet_post(tag_string = config.tags)
    # Hold tweeted post in a variable
    posted_tweet = false

    # Everyone hates catching, but it seems more elegant than a done variable.
    catch :success do
      # Create variable to hold current page
      search_page = 0
      loop do
        # Increment search_page
        search_page += 1
        # Fetch posts
        posts = danbooru_posts(tag_string, search_page)
        # Just break if we don't have posts
        break if posts.empty?
        # Now loop down each post, attempting to post it.
        posts.each do |post|
          post = OpenStruct.new post

          # Skip this post if it's already in our history
          next if danbooru_history_include? post.id

          # Attempt to tweet post, heading to next one if it didn't work
          next unless posted_tweet = danbooru_tweet_post(post)
          # It worked!
          throw :success
        end
      end
    end

    # This will either return false if nothing tweeted, or a tweet if something did.
    posted_tweet
  end
end
