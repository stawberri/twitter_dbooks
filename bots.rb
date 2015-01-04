require 'twitter_ebooks'
require_relative 'auth'
require_relative 'danbooru'

# This is an example bot definition with event handlers commented out
# You can define as many of these as you like; they will run simultaneously

Ebooks::Bot.new(Pudding::Auth::NAME) do |bot|
  Pudding::Auth.login(bot)

  bot.on_startup do
    Danbooru.init
    Danbooru.get_current_post bot
  end

=begin
  bot.on_message do |dm|
    # Reply to a DM
    # bot.reply(dm, "secret secrets")
  end

  bot.on_follow do |user|
    # Follow a user back
    # bot.follow(user[:screen_name])
  end

  bot.on_mention do |tweet, meta|
    # Reply to a mention
    # bot.reply(tweet, meta[:reply_prefix] + "oh hullo")
  end

  bot.on_timeline do |tweet, meta|
    # Reply to a tweet in the bot's timeline
    # bot.reply(tweet, meta[:reply_prefix] + "nice tweet")
  end
=end

  bot.scheduler.every '885' do
    # Tweet something every 24 hours
    # See https://github.com/jmettraux/rufus-scheduler
    # bot.tweet("hi")
    # bot.pictweet("hi", "cuteselfie.jpg", ":possibly_sensitive => true")
    Danbooru.get_new_posts bot
    Danbooru.process_delete_queue bot
    Danbooru.tweet_a_post bot
  end
end
