DBOOKS_VERSION = '@_dbooks v4.1.1'
DBOOKS_VERSION_NAME = 'Jelly Cubes'

require 'ostruct'
require 'open-uri'
require 'json'
require 'twitter_ebooks'

$:.unshift "#{File.dirname __FILE__}/lib"
require 'tweetpic'
require 'show-version'
require 'puddistring'
require 'danbooru'
require 'biotags'
require 'puddibot'

# Main twitterbot class
class DbooksBot < Ebooks::Bot
  include Danbooru, Biotags

  # Current user data
  attr_reader :user

  # Inital twitterbot setup
  def configure
    # Load username into initialization config variable
    @initialization_config = @username
    @username = ''

    # Load configuration into twitter variables
    @consumer_key = config.twitter_key
    @consumer_secret = config.twitter_secret
    @access_token = config.twitter_token
    @access_token_secret = config.twitter_token_secret

    danbooru_configure
  end

  def manage_owner_object
    if owner_variable = config.owner
      # Is config.owner an integer?
      if owner_variable =~ /\A\d+\z/
        # Convert to integer
        owner_variable = owner_variable.to_i
        # Return if owner is still the same.
        return @owner_user if @owner_user.is_a?(Twitter::User) && owner_variable == @owner_user.id
        # Return if owner is myself
        if owner_variable == user.id
          return @owner_user = nil
        end
      else
        # Remove leading @ if there is one
        owner_variable.gsub!(/\A@/, '')
        # Return if owner is still the same.
        return if @owner_user.is_a?(Twitter::User) && owner_variable.downcase == @owner_user.screen_name.downcase
        # Return if owner is myself
        if owner_variable.downcase == username.downcase
          return @owner_user = nil
        end
      end
      begin
        # Save owner
        @owner_user = twitter.user owner_variable

        # Ensure owner really isn't bot
        if @owner_user.id == user.id
          return @owner_user = nil
        end

        # Follow them
        follow @owner_user.screen_name

        # Send version number
        dm_version_owner

        # This is here to return @owner_user, to match other returns.
        @owner_user
      rescue Twitter::Error::NotFound
        # Owner not found
        @owner_user = nil
      end
    else
      @owner_user = nil
    end
  end

  # DM version to owner
  def dm_version_owner(allow_duplicate_messages = false)
    version_dm = "Running #{DBOOKS_VERSION}: #{DBOOKS_VERSION_NAME}".strip.extend(PuddiString).trim_ellipsis 140
    return dm_owner version_dm if allow_duplicate_messages

    # Load and iterate through recently sent direct messages
    twitter.direct_messages_sent(count: 200).each do |msg|
      if msg.recipient.id == @owner_user.id
        unless msg.text.strip == version_dm
          # Say hello
          dm_owner version_dm
        end
        # Found most recent message to owner, so don't continue.
        break
      end
    end
  end

  # Corrects timer
  def update_tweet_timer
    # Modify timer by difference from current time.
    @tweet_timer.next_time = @last_timed_tweet_time + @tweet_timer.frequency if @tweet_timer.is_a? Rufus::Scheduler::Job
  end

  # If the tweet timer isn't running at the desired speed, edit it.
  def manage_tweet_timer
    # Return if everything is fine
    if @tweet_timer
      return if @tweet_timer.original == config.every

      # Delete old @tweet_timer now that we've gotten rid of cases where it already exists
      @tweet_timer.unschedule if @tweet_timer.is_a? Rufus::Scheduler::Job
    end

    begin
      # Repeat this, saving it as a new @tweet_timer
      @tweet_timer = scheduler.schedule_every config.every do
        danbooru_select_and_tweet_post
      end

      # Create a last time, if it doesn't already exist.
      @last_timed_tweet_time ||= Time.new 0

      # Update tweet timer now that we've created it.
      update_tweet_timer
    rescue ArgumentError
      # config.every is invalid, so create a fake timer.
      @tweet_timer = OpenStruct.new original: config.every
    end
  end

  # When twitter bot starts up
  def on_dbooks_connect(friend_ids)
    # Set connection_uptime
    connection_uptime
    # Schedule tweeting
    manage_tweet_timer
  end

  # How long has it been since we connected?
  def connection_uptime
    @connection_uptime ||= Time.now
    Time.now - @connection_uptime
  end

  # Send a DM to owner. Will be truncated to 140 characters.
  def dm_owner(text, no_log = false)
    text.extend PuddiString
    log "> #{text}" unless no_log
    text = text.trim_ellipsis 140
    twitter.create_direct_message @owner_user, text if @owner_user.is_a? Twitter::User
  rescue Twitter::Error
  end

  # Update @user. In a separate function because configure needs it twice
  def on_user_update()
    # Update config
    biotags_update

    # Get owner object
    manage_owner_object
    # Update tweet timer
    manage_tweet_timer
  end

  # When receiving a dm
  def on_message(dm)
    # Was this dm sent by owner?
    if @owner_user.is_a?(Twitter::User) && dm.sender.id == @owner_user.id
      # Find out if dm.text contains @_dbooks
      if match = dm.text.match(/@_dbooks/i)
        # Parse it
        dm_data = biotags_parse match.post_match

        # Version request?
        if dm_data.version
          dm_version_owner true
        end

        # Uptime request?
        if dm_data.uptime
          dm_owner "Connected to Twitter for #{Rufus::Scheduler.to_duration connection_uptime.round}."
        end

        # Parse tags to post
        unless dm_data.tags.empty?
          # Treat dm like a tag string.
          posts = danbooru_posts dm_data.tags
          # Select a random post from first page
          tweet = danbooru_tweet_post posts.sample, bypass_history: true unless posts.empty?
          dm_owner tweet.uri.to_s if tweet
        end

        # Was a restart requested?
        if dm_data.restart
          # Get time elapsed
          remaining_time = (609 - connection_uptime).ceil
          # Check if enough time has passed yet
          if remaining_time > 0
            dm_owner "Restarting too frequently can cause Heroku or Twitter issues. Please try again in #{Rufus::Scheduler.to_duration remaining_time}, or restart manually."
          else
            dm_owner 'Restarting all bots associated with this app.'
            # Bypass ebooks start's handler
            exit! 0
          end
        end
      end
    end
  end
end

# Separate env variable settings into comma separated biotag strings and make a bot of each!
ENV['DBOOKS'].split(',').each do |tags|
  DbooksBot.new tags
end
