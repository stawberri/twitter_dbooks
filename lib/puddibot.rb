require 'twitter_ebooks'

# Custom modifications to primary bots.drb methods
class Ebooks::Bot
  # Redefine prepare
  def prepare
    # Sanity check
    if @username.nil?
      raise ConfigurationError, "bot username cannot be nil"
    end

    if @consumer_key.nil? || @consumer_key.empty? ||
       @consumer_secret.nil? || @consumer_key.empty?
      log "Missing consumer_key or consumer_secret. These details can be acquired by registering a Twitter app at https://apps.twitter.com/"
      exit 1
    end

    if @access_token.nil? || @access_token.empty? ||
       @access_token_secret.nil? || @access_token_secret.empty?
      log "Missing access_token or access_token_secret. Please run `ebooks auth`."
      exit 1
    end

    # Save old name
    old_name = username
    # Load user object and actual username
    update_myself
    # Warn about mismatches unless it was clearly intentional
    log "warning: bot expected to be @#{old_name} but connected to @#{username}" unless username == old_name || old_name.empty?

    fire(:startup)
  end

  # Updates @user and calls on_user_update.
  def update_myself(new_me = twitter.user)
    @user = new_me if @user.nil? || new_me.id == @user.id
    @username = user.screen_name
    log 'User information updated'
    fire(:user_update)
  end

  # Listen in on events
  alias_method :dbooks_override_receive_event, :receive_event
  def receive_event(event)
    # Intercept user_update event
    if event.is_a?(Twitter::Streaming::Event) && event.name == :user_update
      update_myself event.source
    elsif event.is_a? Array
      fire(:dbooks_connect, event)
    end

    # Call original method
    dbooks_override_receive_event event
  end
end
