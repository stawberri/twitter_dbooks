require 'twitter_ebooks'
require 'ostruct'

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
      @danbooru_default_params['login'] = URI.escape config.danbooru_login
      @danbooru_default_params['api_key'] = URI.escape config.danbooru_key
    end
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