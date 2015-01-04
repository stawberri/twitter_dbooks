module Pudding
	module Auth
		NAME = ""
		def self.login(bot)
			# Consumer details come from registering an app at https://dev.twitter.com/
			# OAuth details can be fetched with https://github.com/marcel/twurl
			bot.consumer_key = "" # Your app consumer key
			bot.consumer_secret = "" # Your app consumer secret
			bot.oauth_token = "" # Token connecting the app to this account
			bot.oauth_token_secret = "" # Secret connecting the app to this account
		end
	end
end