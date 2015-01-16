DBOOKS_VERSION = 'twitter_dbooks v2.0.0-exitcode'

require 'ostruct'
require 'open-uri'
require 'json'
require 'twitter_ebooks'

version_message = <<-PUDDIDOC

 ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥
 ♥ Tagging Along                          ♥
 ♥                                        ♥
 ♥                                      ☻ ♥
♦
 ♥                                        ♥
 ♥ WARNING: Couldn't load copy of bots.rb ♥
 ♥          from GitHub. Attempting to    ♥
 ♥          run out-of-date backup copy   ♥
 ♥          of @_dbooks. Error message:   ♥
 ♥                                        ♥
 ♥  ♣                                     ♥
 ♥  ♠                                     ♥
 ♥                                        ♥
 ♥          Unless this was intentional,  ♥
 ♥          please update manually to fix ♥
 ♥          this issue as soon as you     ♥
 ♥          can. You can also try         ♥
 ♥          checking Twitter to see if I  ♥
 ♥          have any news about what's    ♥
 ♥          what's going on, or ask me    ♥
 ♥          for help there.               ♥
 ♥                                        ♥
 ♥              ~ Pudding (@stawbewwi)    ♥
♦
  ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥

PUDDIDOC
version_string = DBOOKS_VERSION
version_string_length = version_string.length
if version_string_length > 36
  version_string = version_string[0...36]
  version_string_length = 36
end
# Using this for spaces
version_string_length -= 1
version_message.gsub!(/ {#{version_string_length}}☻/, version_string)
if ENV['UPDATER_ERROR'].empty?
  version_message.gsub!(/♦.*♦\r?\n/m, '')
else
  version_message.gsub!(/♦\r?\n/, '')
  # Parse error string
  space_match = ENV['UPDATER_ERROR'].match(/ /)
  error_class = space_match.pre_match
  error_class_length = error_class.length
  if error_class_length > 36
    error_class = error_class[0...36]
    error_class_length = 36
  end
  error_message = space_match.post_match
  error_message_length = error_message.length
  if error_message_length > 36
    error_message = error_message[0...36]
    error_message_length = 36
  end
  # Using these numbers for spaces later.
  error_class_length -= 1
  error_message_length -= 1
  # Splice them in
  version_message.gsub!(/♣ {#{error_class_length}}/, error_class)
  version_message.gsub!(/♠ {#{error_message_length}}/, error_message)
end
STDOUT.print version_message
STDOUT.flush

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

    # Are we trimming to nothing?
    if real_length < 1
      # Does cap fit in remaining length?
      if cap.length == len
        return cap
      else
        return ''
      end
    end

    # Now just return the trimmed string!
    self[0...real_length] + cap
  end
end

# Module used to extend Ebooks with Danbooru features
module Danbooru
  # Default danbooru request parameters
  attr_reader :danbooru_default_params

  # Initialization for danbooru methods
  def danbooru_configure
    # Setup default danbooru params with danbooru login info
    @danbooru_default_params = {}
    if config.danbooru_login && config.danbooru_api_key
      @danbooru_default_params['login'] = config.danbooru_login
      @danbooru_default_params['api_key'] = config.danbooru_api_key
    end

    # Populate history
    danbooru_populate_history
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
        end
      end
    end
  end

  # Add a post id to history
  def danbooru_history_add(post_id)
    # Create a history array if it doesn't already exist
    @danbooru_post_history ||= []

    post_id = [post_id.to_i]

    # Convert it to an integer and then add it
    @danbooru_post_history |= post_id

    post_id
  end

  # Check if a post id is in history
  def danbooru_history_include?(post_id)
    return false unless defined? @danbooru_post_history

    @danbooru_post_history.include? post_id.to_i
  end

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
      log "#{error_message}\n\t#{error.backtrace.join("\n\t")}"
      {}
    rescue JSON::ParserError => error
      log "#{error.class.to_s}: #{error.message}\n\t#{error.backtrace.join("\n\t")}"
      {}
    end
  end

  # Fetch posts from danbooru
  def danbooru_posts(tags = config.tags, page = 1)
    tags ||= config.tags
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
  def danbooru_tweet_post(post, bypass = false)
    # Make post an OpenStruct
    unless post.is_a? OpenStruct
      post = post[0] if post.is_a? Array
      post = danbooru_get("posts/#{post}") unless post.is_a? Hash
      # Ensure that it contains an id.
      return unless post.has_key? 'id'
      post = OpenStruct.new post
    end

    # Is post deleted, and we don't want deleted posts?
    return false if !bypass && config.no_deleted && post.is_deleted

    # Is post in a format we like?
    return false unless ['jpg','jpeg','png'].include? post.file_ext

    # Is it sensitive?
    sensitive = post.rating != 's'

    # Get a tag string
    tag_string = danbooru_tag_string post
    tag_string.extend PuddiString
    # 93 = 140 - 2 (spaces) - 23 (https url) - 22 (http url)
    tag_string = ' ' + tag_string.trim_ellipsis(93) unless tag_string.empty?

    # Get post URI
    post_uri = "https://danbooru.donmai.us/posts/#{post.id}"

    # Get image URI
    image_uri = "https://danbooru.donmai.us#{post.large_file_url}"

    # Tweet post!
    log "Tweeting post #{post.id}, rating: #{post.rating}"
    begin
      pic_tweet("#{post_uri}#{tag_string}", image_uri, possibly_sensitive: sensitive)
    rescue Twitter::Error => error
      log "#{error.class.to_s}: #{error.message}\n\t#{error.backtrace.join("\n\t")}"
      false
    end
  end

  # Pick and tweet a post based on tag settings.
  def danbooru_select_and_tweet_post(tag_string = config.tags)
    tag_string ||= config.tags

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
          # Add post to history, since we've seen it now
          danbooru_history_add post.id

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
    return @config || config('') unless biotag_string.is_a? String
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

      # Add it to ostruct!
      if key =~ /tags?/
        tags_array |= [value]
      else
        ostruct[key] = value
      end
    end

    # Move tags_array into ostruct
    ostruct.tags = tags_array.join(' ')

    ostruct
  end

  # Default config options
  CONFIG_DEFAULT = '%every:never'
end

# Main twitterbot class
class DbooksBot < Ebooks::Bot
  include Danbooru, Biotags

  # Current user data
  attr_reader :user
  # Time stream was started
  attr_reader :connection_established_time

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

    if access_token && access_token_secret && consumer_key && consumer_secret
      update_user
    end
  end

  # Update @user. In a separate function because configure needs it twice
  def update_user(current_user = twitter.user)
    current_user = twitter.user unless current_user.is_a? Twitter::User
    @user = current_user

    # Update username
    @username = user.screen_name
    # Update config
    biotags_update

    # Get owner object
    manage_owner_object
    # Update tweet timer
    manage_tweet_timer if @tweet_timer
  end

  def manage_owner_object
    if owner_variable = config.owner
      # Is config.owner an integer?
      if owner_variable =~ /\A\d+\z/
        # Convert to integer
        owner_variable = owner_variable.to_i
        # Return if owner is still the same.
        return if @owner_user.is_a?(Twitter::User) && owner_variable == @owner_user.id
      else
        # Remove leading @ if there is one
        owner_variable.gsub!(/\A@/, '')
        # Return if owner is still the same.
        return if @owner_user.is_a?(Twitter::User) && owner_variable.downcase == @owner_user.screen_name.downcase
      end
      begin
        # Save owner
        @owner_user = twitter.user owner_variable
        # Follow them too
        follow(@owner_user.screen_name)
        # Say hello
        dm_owner "Running #{DBOOKS_VERSION}"
      rescue Twitter::Error::NotFound
        # Owner not found
        @owner_user = nil
      end
    else
      @owner_user = nil
    end
  end

  # Listen in on events
  alias_method :dbooks_override_receive_event, :receive_event
  def receive_event(event)
    # Intercept user_update event
    if event.is_a?(Twitter::Streaming::Event) && event.name == :user_update
      update_user event.source
    elsif event.is_a? Array
      fire(:dbooks_connect)
    end

    # Call original method
    dbooks_override_receive_event event
  end

  # If the tweet timer isn't running at the desired speed, edit it.
  def manage_tweet_timer
    # Return if everything is fine
    if @tweet_timer
      return if @tweet_timer.original == config.every

      # Delete old @tweet_timer
      @tweet_timer.unschedule
    end

    # Create a last time, if it doesn't already exist.
    @tweet_timer_last_time ||= Time.new 0

    begin
      # Repeat this, saving it as a new @tweet_timer
      @tweet_timer = scheduler.schedule_every config.every do
        # Update last time variable
        @tweet_timer_last_time = Time.now
        danbooru_select_and_tweet_post
      end
      # Correct when it should happen next
      @tweet_timer.next_time -= Time.now - @tweet_timer_last_time
    rescue ArgumentError
      # config.every is invalid, so create a fake timer.
      @tweet_timer = OpenStruct.new original: config.every, unschedule: true
    end
  end

  # When twitter bot starts up
  def on_dbooks_connect
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

  def dm_owner(text, *args)
    log "> #{text}"
    twitter.create_direct_message @owner_user, text, *args if @owner_user.is_a? Twitter::User
  rescue Twitter::Error
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
          dm_owner DBOOKS_VERSION
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
          tweet = danbooru_tweet_post posts.sample, true unless posts.empty?
          dm_owner tweet.uri.to_s if tweet
        end

        # Was a restart requested?
        if dm_data.restart
          # Get time elapsed
          remaining_time = (60*10 - connection_uptime).ceil
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

#####################################################################
# tweetpic.rb
#####################################################################

# encoding: utf-8
require 'rufus/scheduler'
require 'open-uri'
require 'tempfile'

module Ebooks
  class Bot
    # Tweet something containing an image
    # Only four images are allowed per tweet, but you can pass as many as you want
    # The first four to be uploaded sucessfully will be included in your tweet
    # Provide a block if you would like to modify your files before they're uploaded
    # @param tweet_text [String] text content for tweet
    # @param pic_list [String, Array<String>] a string or array of strings containing pictures to tweet
    #   provide only a file extension to create an empty file of that type. this won't work unless you also provide a block to generate imgaes.
    # @param tweet_options [Hash] options hash that will be passed along with your tweet
    # @param upload_options [Hash] options hash passed while uploading images
    # @yield [file_name] provides full filenames of files after they have been fetched, but before they're uploaded to twitter
    # @raise [StandardError] first exception, if no files could be uploaded
    def pic_tweet(tweet_text, pic_list, tweet_options = {}, upload_options = {}, &block)
      tweet_options ||= {}
      upload_options ||= {}

      media_options = Ebooks::TweetPic.process self, pic_list, upload_options, &block

      tweet tweet_text, tweet_options.merge(media_options)
    end
    alias_method :pictweet, :pic_tweet

    # Reply to a tweet with a message containing an image. Does not work with DMs
    # Only four images are allowed per tweet, but you can pass as many as you want
    # The first four to be uploaded sucessfully will be included in your tweet
    # Provide a block if you would like to modify your files before they're uploaded
    # @param reply_tweet [Twitter::Tweet, Twitter::DirectMessage] tweet to reply to
    # @param (see #pic_tweet)
    # @yield (see #pic_tweet)
    # @raise (see #pic_tweet)
    # @raise [ArgumentError] if reply_tweet is a direct message
    def pic_reply(reply_tweet, tweet_text, pic_list = nil, tweet_options = {}, upload_options = {}, &block)
      pic_list ||= meta(reply_tweet).media_uris('large')

      tweet_options ||= {}
      upload_options ||= {}

      raise ArgumentError, 'reply_tweet can\'t be a direct message' if reply_tweet.is_a? Twitter::DirectMessage

      media_options = Ebooks::TweetPic.process self, pic_list, upload_options, &block

      reply reply_tweet, tweet_text, tweet_options.merge(media_options)
    end
    alias_method :picreply, :pic_reply

    # Does the same thing as {#pic_reply}, but doesn't do anything if pic_list is empty.
    # Safe to place directly inside reply with no checks for media beforehand.
    # @param (see #pic_reply)
    # @yield (see #pic_reply)
    def pic_reply?(reply_tweet, tweet_text, pic_list = nil, tweet_options = {}, upload_options = {}, &block)
      pic_list ||= meta(reply_tweet).media_uris('large')

      unless pic_list.empty?
        pic_reply reply_tweet, tweet_text, pic_list, tweet_options, upload_options, &block
      end
    end
  end

  # A singleton that uploads pictures to twitter for tweets and stuff
  module TweetPic
    # Default file prefix
    DEFAULT_PREFIX = 'tweet-pic'
    private_constant :DEFAULT_PREFIX

    # Characters for random string generation
    RANDOM_CHARACTERS = [*'a'..'z', *'A'..'Z', *'1'..'9', '_']

    # Supported filetypes and their extensions
    SUPPORTED_FILETYPES = {
      '.jpg' => '.jpg',
      '.jpeg' => '.jpg',
      'image/jpeg' => '.jpg',
      '.png' => '.png',
      'image/png' => '.png',
      '.gif' => '.gif',
      'image/gif' => '.gif'
    }

    # Exceptions
    Error = Class.new RuntimeError
    FiletypeError = Class.new Error
    EmptyFileError = Class.new Error
    NoSuchFileError = Class.new Error

    # Singleton
    class << self

      # List all files inside virtual directory
      # @note not to be confused with {#file}
      # @return [Array<String>] array of filenames inside virtual directory
      def files
        # Return an empty array if file hash hasn't even been made yet
        return [] unless defined? @file_hash

        # Otherwise, return everything
        @file_hash.keys
      end

      # Create a new file inside virtual directory
      # @param file_extension [String] file extension to append to filename
      # @return [String] new virtual filename
      # @raise [Ebooks::TweetPic::FiletypeError] if extension isn't one supported by Twitter
      def file(file_extension)
        # Try to find an appropriate filetype.
        catch :extension_found do
          # Make file_extension lowercase if it isn't already
          file_extension.downcase
          # Does it already match?
          if SUPPORTED_FILETYPES.has_key? file_extension
            # It does, so standardize our file extension
            file_extension = SUPPORTED_FILETYPES[file_extension]
            throw :extension_found
          end
          # It doesn't. Is it missing a .?
          unless file_extension.start_with? '.'
            # Add it in
            file_extension.prepend('.')
            # Try again
            if SUPPORTED_FILETYPES.has_key? file_extension
              # Found it now!
              file_extension = SUPPORTED_FILETYPES[file_extension]
              throw :extension_found
            end
          end
          # File-extension isn't supported.
          raise FiletypeError, "'#{file_extension}' isn't a supported filetype"
        end

        # Create file hash if it doesn't exist yet.
        @file_hash ||= {}

        # Increment file name
        virtual_filename = @file_variable = @file_variable.to_i.next

        # Make a filename, adding on a random part to make it harder to find
        virtual_filename = "#{random_word 7..13}-#{virtual_filename}-#{random_word 13..16}"

        # Do we have a prefix yet?
        @file_prefix ||= "#{DEFAULT_PREFIX}-#{Time.now.to_f.to_s.gsub(/\./, '-')}"

        # Create a new real file(name)
        real_file = Tempfile.create(["#{@file_prefix}-#{virtual_filename}-", file_extension])
        real_file.close

        # Store virtual filename and realfile into file_hash
        full_virtual_filename = "#{virtual_filename}#{file_extension}"
        @file_hash[full_virtual_filename] = real_file

        full_virtual_filename
      ensure
        # Ensure that it's not left open, no matter what happens.
        real_file.close if real_file.respond_to?(:close) && !real_file.closed?
      end
      private :file

      # Create a random string of word characters (filename friendly)
      # @param character_number_array [Integer, Range<Integer>, Array<Integer, Range<Integer>>] number of characters to generate.
      #   types including multiple integers will pick a random one.
      # @param extra_characters [Array<String>] extra characters
      # @return [String] random string with length asked for
      def random_word(character_number_array, extra_characters = [])
        extra_characters ||= []

        # If it's not an array, make it one.
        character_number_array = [character_number_array] unless character_number_array.is_a? Array
        # Make a new array to hold expanded stuff
        number_of_characters = []
        # Iterate through array
        character_number_array.each do |element|
          if element.is_a? Range
            # It's a range, so expand it and add it to number_of_characters
            number_of_characters |= [*element]
          else
            # It's not a range, so just add it.
            number_of_characters << element
          end
        end

        # Get our actual number
        number_of_characters = number_of_characters.uniq.sample
        # Create array with random characters.
        extra_characters = RANDOM_CHARACTERS | extra_characters
        # Create a string to hold characters in
        random_string = ''
        # Repeat this number_of_characters times
        number_of_characters.times do
          # Add another character to string
          random_string += extra_characters.sample
        end

        random_string
      end
      private :random_word

      # Fetch a file object
      # @param virtual_filename [String] object to look for
      # @return [Tempfile] file object
      # @raise [Ebooks::TweetPic::NoSuchFileError] if file doesn't actually exist
      def fetch(virtual_filename)
        raise NoSuchFileError, "#{virtual_filename} doesn't exist" unless @file_hash.has_key? virtual_filename

        @file_hash[virtual_filename]
      end
      private :fetch

      # Get a real path for a virtual filename
      # @param (see ::fetch)
      # @return [String] path of file
      # @raise (see ::fetch)
      def path(virtual_filename)
        fetch(virtual_filename).path
      end
      private :path

      # Creates a scheduler
      # @return [Rufus::Scheduler]
      def scheduler
        @scheduler_variable ||= Rufus::Scheduler.new
      end
      private :scheduler

      # Queues a file for deletion and deletes all queued files if possible
      # @param trash_files [String, Array<String>] files to queue for deletion
      # @return [Array<String>] files still in deletion queue
      def delete(trash_files = [])
        trash_files ||= []

        # Turn trash_files into an array if it isn't one.
        trash_files = [trash_files] unless trash_files.is_a? Array

        # Create queue if necesscary
        @delete_queue ||= []
        # Iterate over trash files
        trash_files.each do |trash_item|
          # Retrieve trash_item's real path
          file_object = @file_hash.delete trash_item
          # Was trash_item in hash?
          unless file_object.nil?
            # It was. Add it to queue
            @delete_queue << file_object.path
          end
        end

        # Make sure there aren't duplicates
        @delete_queue.uniq!

        # Iterate through delete_queue
        @delete_queue.delete_if do |current_file|
          begin
            # Attempt to delete file if it exists
            File.delete current_file if File.file? current_file
          rescue
            # Deleting file failed. Just move on.
            false
          else
            true
          end
        end

        unless @delete_queue.empty?
          # Schedule another deletion in a minute.
          scheduler.in('1m') do
            delete
          end
        end

        @delete_queue
      end

      # Downloads a file into directory
      # @param uri_string [String] uri of image to download
      # @return [String] filename of downloaded file
      # @raise [Ebooks::TweetPic::FiletypeError] if content-type isn't one supported by Twitter
      # @raise [Ebooks::TweetPic::EmptyFileError] if downloaded file is empty for some reason
      def download(uri_string)
        # Make a variable to hold filename
        destination_filename = ''

        # Prepare to return an error if file is empty
        empty_file_detector = lambda { |file_size| raise EmptyFileError, "'#{uri_string}' produced an empty file" if file_size == 0 }
        # Grab file off the internet. open-uri will provide an exception if this errors.
        URI(uri_string).open(content_length_proc: empty_file_detector) do |downloaded_file|
          content_type = downloaded_file.content_type
          if SUPPORTED_FILETYPES.has_key? content_type
            destination_filename = file SUPPORTED_FILETYPES[content_type]
          else
            raise FiletypeError, "'#{uri_string}' is an unsupported content-type: '#{content_type}'"
          end

          # Everything seems okay, so write to file.
          File.open path(destination_filename), 'w' do |opened_file|
            until downloaded_file.eof?
              opened_file.write downloaded_file.read 1024
            end
          end
        end

        # If we haven't exited from an exception yet, so everything is fine!
        destination_filename
      end
      private :download

      # Copies a file into directory
      # @param source_filename [String] relative path of image to copy or an extension for an empty file
      # @return [String] filename of copied file
      def copy(source_filename)
        file_extension = ''

        # Find file-extension
        if match_data = source_filename.match(/(\.\w+)$/)
          file_extension = match_data[1]
        end

        # Create destination filename
        destination_filename = file file_extension

        # Do copying, but just leave empty if source_filename is just an extension
        FileUtils.copy(source_filename, path(destination_filename)) unless source_filename == file_extension

        destination_filename
      end
      private :copy

      # Puts a file into directory, downloading or copying as necesscary
      # @param source_file [String] relative path or internet address of image
      # @return [String] filename of file in directory
      def get(source_file)
        # Is source_file a url?
        if source_file =~ /^(ftp|https?):\/\//i # Starts with http(s)://, case insensitive
          download(source_file)
        else
          copy(source_file)
        end
      end

      # Allows editing of files through a block.
      # @param file_list [String, Array<String>] names of files to edit
      # @yield [file_name] provides full filenames of files for block to manipulate
      # @raise [Ebooks::TweetPic::NoSuchFileError] if files don't exist
      # @raise [ArgumentError] if no block is given
      def edit(file_list, &block)
        # Turn file_list into an array if it's not an array
        file_list = [file_list] unless file_list.is_a? Array

        # First, make sure file_list actually contains actual files.
        file_list &= files

        # Raise if we have no files to work with
        raise NoSuchFileError, 'Files don\'t exist' if file_list.empty?

        # This method doesn't do anything without a block
        raise ArgumentError, 'block expected but none given' unless block_given?

        # Iterate over files, giving their full filenames over to the block
        file_list.each do |file_list_each|
          yield path(file_list_each)
        end
      end

      # Upload an image file to Twitter
      # @param twitter_object [Twitter] a twitter object to upload file with
      # @param file_name [String] name of file to upload
      # @return [Integer] media id from twitter
      # @raise [Ebooks::TweetPic::EmptyFileError] if file is empty
      def upload(twitter_object, file_name, upload_options = {})
        upload_options ||= {}

        # Does file exist, and is it empty?
        raise EmptyFileError, "'#{file_name}' is empty" if File.size(path(file_name)) == 0
        # Open file stream
        file_object = File.open path(file_name)
        # Upload it
        media_id = twitter_object.upload(file_object, upload_options)
        # Close file stream
        file_object.close

        media_id
      end

      # @overload limit()
      #   Find number of images permitted per tweet
      #   @return [Integer] number of images permitted per tweet
      # @overload limit(check_list)
      #   Check if a list's length is equal to, less than, or greater than limit
      #   @param check_list [#length] object to check length of
      #   @return [Integer] difference between length and the limit, with negative values meaning length is below limit.
      def limit(check_list = nil)
        # Twitter's API page just says, "You may associated[sic] up to 4 media to a Tweet," with no information on how to dynamically get this value.
        tweet_picture_limit = 4

        if check_list
          check_list.length - tweet_picture_limit
        else
          tweet_picture_limit
        end
      end

      # Gets media ids parameter ready for a tweet
      # @param bot_object [Ebooks::Bot] an ebooks bot to upload files with
      # @param pic_list [String, Array<String>] an array of relative paths or uris to upload, or a string if there's only one
      # @param upload_options [Hash] options hash passed while uploading images
      # @param [Proc] a proc meant to be passed to {#edit}
      # @return [Hash{Symbol=>String}] A hash containing a single :media_ids key/value pair for update options
      # @raise [StandardError] first error if no files in pic_list could be uploaded
      def process(bot_object, pic_list, upload_options, &block)
        # If pic_list isn't an array, make it one.
        pic_list = [pic_list] unless pic_list.is_a? Array

        # If pic_list is an empty array or an array containing an empty string, just return an empty hash. People know what they're doing, right?
        return {} if pic_list == [] or pic_list == ['']

        # Create an array to store media IDs from Twitter
        successful_images = []
        uploaded_media_ids = []

        first_exception = nil

        # Iterate over picture list
        pic_list.each do |pic_list_each|
          # Stop now if uploaded_media_ids is long enough.
          break if limit(uploaded_media_ids) >= 0

          # This entire block is wrapped in a rescue, so we can skip over things that went wrong. Errors will be dealt with later.
          begin
            # Make current image a string, just in case
            source_path = pic_list_each.to_s
            # Fetch image
            temporary_path = get(source_path)
            # Allow people to modify image
            edit(temporary_path, &block) if block_given?
            # Upload image to Twitter
            uploaded_media_ids << upload(bot_object.twitter, temporary_path, upload_options)
            # If we made it this far, we've pretty much succeeded
            successful_images << source_path
            # Delete image. It's okay if this fails.

            delete(temporary_path)
          rescue => exception
            # If something went wrong, just skip on. No need to log anything.
            first_exception ||= exception
          end
        end

        raise first_exception if uploaded_media_ids.empty?

        # This shouldn't be necessary, but trim down array if it needs to be.
        successful_images = successful_images[0...limit] unless limit(successful_images) < 0
        uploaded_media_ids = uploaded_media_ids[0...limit] unless limit(uploaded_media_ids) < 0

        # Report that we just uploaded images to log
        successful_images_joined = successful_images.join ' '
        bot_object.log "Uploaded to Twitter: #{successful_images_joined}"

        # Return options hash
        {:media_ids => uploaded_media_ids.join(',')}
      end
    end
  end
end
