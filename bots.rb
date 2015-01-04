require 'twitter_ebooks'
require 'ostruct'
require 'open-uri'
require 'json'

require_relative 'tweetpic'

# Module used to extend string with helper functions
module PuddiString
  # Trim a string, optionally adding a thing at the end.
  def trim(len)
    # Just call the other function.
    trim_cap(len, '')
  end
  def trim_ellipsis(len)
    # Special one for this hard to find character
    trim_cap(len, '…')
  end
  def trim_cap(len, cap)
    # Make sure inputs are the right type.
    len = len.to_i
    cap = cap.to_s
    # First, check if the string is already within the length.
    return self if length <= len
    # It's not, so find out how short we have to trim to.
    real_length = len - cap.length
    # Now just return the trimmed string!
    self[0...real_length] + cap
  end
end

# Module used to extend Ebooks with Danbooru features
module Danbooru
  # Default danbooru request parameters
  attr_reader :danbooru_default_params

  # Wrapper for danbooru requests
  def danbooru_get(query = 'posts', parameters = {})
    query ||= posts
    parameters ||= {}

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
        # Convert key to a string if it's a symbol
        parameters_array << "#{URI.escape key.to_s}=#{URI.escape value.to_s}"
      end
      # Merge them and add them to uri
      uri += parameters_array.join ';'
    end

    # Access URI and convert data from json
    open uri do |io|
      JSON.parse io.read
    end
  end

  # Fetch posts from danbooru
  def danbooru_posts(tags = @config.danbooru_tags, page = 1)
    tags ||= @config.danbooru_tags
    page ||= 1

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
  def danbooru_tweet_post(post)
    # Make post an OpenStruct
    post = post[0] if post.is_a? Array
    post = danbooru_get("posts/#{post}") unless post.is_a? Hash
    post = OpenStruct.new post

    # Is post in a format we like?
    return false unless ['jpg','jpeg','png'].include? post.file_ext

    # Is it sensitive?
    sensitive = post.rating != 's'

    # Get a tag string
    tag_string = danbooru_tag_string post
    tag_string.extend PuddiString
    tag_string = ' ' + tag_string.trim_ellipsis(94) unless tag_string.empty?

    # Get post URI
    post_uri = "https://danbooru.donmai.us/posts/#{post.id}"

    # Get image URI
    image_uri = "https://danbooru.donmai.us/#{post.large_file_url}"

    # Tweet post!
    log "Tweeting post #{post.id}, rating: #{post.rating}"
    pic_tweet("#{post_uri}#{tag_string}", image_uri, possibly_sensitive: sensitive)

    true
  end
end

# Main twitterbot class
class DbooksBot < Ebooks::Bot
  include Danbooru

  # Config openstruct
  attr_reader :config

  # Inital twitterbot setup
  def configure
    # Load configuration from environment variables
    @config = OpenStruct.new
    @config.twitter_key = ENV['TWITTER_KEY'].chomp
    @config.twitter_secret = ENV['TWITTER_SECRET'].chomp
    @config.twitter_token = ENV['TWITTER_TOKEN'].chomp
    @config.twitter_tsecret = ENV['TWITTER_TSECRET'].chomp
    @config.danbooru_login = ENV['DANBOORU_LOGIN'].chomp
    @config.danbooru_key = ENV['DANBOORU_KEY'].chomp
    @config.danbooru_tags = ENV['DANBOORU_TAGS'].chomp
    @config.tweet_interval = ENV['TWEET_INTERVAL'].chomp

    # Load configuration into twitter variables
    @consumer_key = config.twitter_key
    @consumer_secret = config.twitter_secret
    @access_token = config.twitter_token
    @access_token_secret = config.twitter_tsecret

    # Grab username if all of those variables have been set already
    @username = twitter.user.screen_name if @access_token && @access_token_secret && @consumer_key && @consumer_secret

    # Setup default danbooru params with danbooru login info
    @danbooru_default_params = {}
    unless config.danbooru_login.empty? && config.danbooru_key.empty?
      @danbooru_default_params['login'] = config.danbooru_login
      @danbooru_default_params['api_key'] = config.danbooru_key
    end
  end

  # When twitter bot starts up
  def on_startup
    danbooru_tweet_post danbooru_posts

    exit;

    # Repeat this every tweet_interval
    scheduler.every config.tweet_interval do
    end
  end
end

# Make DbooksBot!
DbooksBot.new ''