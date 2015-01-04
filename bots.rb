require 'twitter_ebooks'
require 'ostruct'
require 'open-uri'
require 'json'

# Main twitterbot class
class DbooksBot < Ebooks::Bot
  # Config openstruct
  attr_reader :config
  # Default danbooru request parameters
  attr_reader :danbooru_default_params

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

    # Setup default danbooru params with danbooru login info
    @danbooru_default_params = {}
    unless config.danbooru_login.empty? && config.danbooru_key.empty?
      @danbooru_default_params['login'] = config.danbooru_login
      @danbooru_default_params['api_key'] = config.danbooru_key
    end
  end

  # Wrapper for danbooru requests
  def danbooru_get(query = 'posts', parameters = {})
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
  def danbooru_posts(tags = '', page = 1)
    danbooru_get 'posts', tags: tags, page: page
  end

  # When twitter bot starts up
  def on_startup
    # Repeat this every tweet_interval
    scheduler.every config.tweet_interval do
    end
  end
end

# Make DbooksBot!
DbooksBot.new ''