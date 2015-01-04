require 'twitter_ebooks'
require 'ostruct'

# Main twitterbot class
class DbooksBot < Ebooks::Bot
  # Config variable. Doesn't need to be an accessor.
  attr_reader :config

  # Inital twitterbot setup
  def configure
    # Load twitter configuration from environment variables.
    @consumer_key = ENV['TWITTER_KEY']
    @consumer_secret = ENV['TWITTER_SECRET']
    @access_token = ENV['TWITTER_TOKEN']
    @access_token_secret = ENV['TWITTER_TSECRET']

    # Load other configuration options
    @config = OpenStruct.new
    @config.danbooru_login = ENV['DANBOORU_LOGIN']
    @config.danbooru_key = ENV['DANBOORU_KEY']
    @config.danbooru_tags = ENV['DANBOORU_TAGS']
    @config.tweet_interval = ENV['TWEET_INTERVAL']
  end

  def on_startup
    scheduler.every config.tweet_interval do
    end
  end
end

# Make DbooksBot!
DbooksBot.new ''