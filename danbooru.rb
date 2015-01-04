require 'net/http'
require 'json'

module Danbooru
	class << self
		# Define some variables
		URL = 'http://danbooru.donmai.us/'
		FORMAT = '.json'
		LOGIN = ''
		API_KEY = ''
		SEARCH_TAGS = 'order:rating limit:1'

		attr_accessor :current_post_id, :post_queue, :delete_queue

		# Initialize variables
		def init
			@current_post_id = 0
			@post_queue = []
			@delete_queue = []
		end

		# HTTP_GET
		def get(bot = nil, query, parameters)
			# Normalize inputs
			query = query.to_s
			raise ArgumentError, 'parameters must be a hash' unless parameters.is_a? Hash

			# Add authentication if it exists
			unless LOGIN.empty? && API_KEY.empty?
				parameters['login'] = URI.escape LOGIN
				parameters['api_key'] = URI.escape API_KEY
			end

			# Build query string if necessary
			if parameters.empty?
				# It's not.
				query_string = ''
			else
				# Prepare string
				query_string = '?'
				# Iterate through parameters
				parameters.each do |key, value|
					key = URI.escape key.to_s
					value = URI.escape value.to_s
					query_string += "#{key}=#{value};"
				end
				# Chop off ending semicolon
				query_string = query_string[0...-1]
			end

			# Build URI and fetch data
			uri = URL + query + FORMAT + query_string
			response = Net::HTTP.get_response URI(uri)
			class << response
				def json
					JSON.parse body
				end

				def json=(value)
					body = value.to_json
				end
			end
			log_msg = "HTTP Request: GET #{uri} | #{response.code}: #{response.msg}"
			if defined? bot.log
				bot.log log_msg
			else
				log log_msg
			end
			response
		end

		# Store latest post as current_post_id
		def get_current_post(bot)
			bot.log 'Fetching latest post'
			# Grab a search
			data = get(bot, 'posts', {'tags' => SEARCH_TAGS})
			# Was it a valid result?
			raise "HTTP Error #{data.code}: #{data.msg}" unless data.code == '200'

			# Grab post ID
			id = data.json[0]['id']
			bot.log "Last Post ID Found: #{id}"
			@current_post_id = id
		end

		# Fetch new posts
		def get_new_posts(bot)
			bot.log 'Fetching new posts'
			# First post ID we need?
			first_id = @current_post_id + 1
			# Find tag string
			tags = "#{SEARCH_TAGS} id:#{first_id}.." # %20 is a space
			tags = tags[1..-1] if SEARCH_TAGS.empty? # Take off space if SEARCH_TAGS was empty
			# Grab the list of posts
			data = get(bot, 'posts', {'tags' => tags})
			# Account for invalid results
			unless data.code == '200'
				bot.log "HTTP Error #{data.code}: #{data.msg}"
				return
			end
			# Any new posts?
			if data.json.empty? then
				bot.log "No new posts to queue. Queue still contains #{@post_queue.length} posts"
				return
			end
			# Add new posts to queue
			new_post_id = data.json[0]['id']
			new_posts = data.json.reverse
			new_posts_count = new_posts.length
			new_count = new_posts_count + @post_queue.length
			bot.log "Adding #{new_posts_count} posts to queue for a total of #{new_count} posts."
			@post_queue += new_posts
			# Set new post id
			bot.log "New Current Post ID: #{new_post_id}"
			@current_post_id = new_post_id
		end

		def tweet_a_post(bot)
			# Any posts to tweet?
			if @post_queue.empty? then
				bot.log 'No posts to tweet'
				return
			end
			# Fetch first post from queue, but don't remove it yet.
			post = @post_queue.first
			bot.log "Preparing to tweet post \##{post['id']}"
			# Get ready to download image
			url = URL[0...-1] + post['large_file_url']
			bot.log "Attempting to download image: #{url}"
			# Find out what the extension is.
			if match_data = url.match(/(\.[A-z]+)$/)
				extension = match_data[1]
			else
				extension = ''
			end

			# Stop gap measure to only allow jpg and png files
			unless extension =~ /^\.(jpg|jpeg|png)$/i
				bot.log "Ignoring post with extension #{extension}"
				# Remove post from queue
				queue_left = @post_queue.length - 1
				bot.log "Removing post from queue. Posts left: #{queue_left}"
				@post_queue.shift
				return
			end

			# This variable is uri (I), the one above is url (L).
			uri = URI(url)
			destination_filename = "temp/post_#{post['id']}#{extension}"
			# Fetch it!
			before_download = Time.now
			Net::HTTP.start(uri.host, uri.port) do |http|
				http.request Net::HTTP::Get.new(uri) do |response|
					# Stuff went wrong?
					unless response.code == '200'
						bot.log "HTTP Error #{response.code}: #{response.msg}"
						return
					end

					# Write to file
					open(destination_filename, 'w') do |file|
						response.read_body do |chunk|
							file.write chunk
						end
					end
				end
			end
			download_time = Time.now - before_download
			filesize = (File.size destination_filename)/1024
			bot.log "Downloaded #{filesize}kb in #{download_time.to_f}s"
			if filesize == 0
				bot.log "Empty file downloaded. Marking for deletion and canceling."
				@delete_queue << destination_filename
			end
			# Is it sensitive?
			if post['rating'] == 's'
				sensitive = 'false'
			else
				sensitive = 'true'
			end

			# Figure out a data string
			data_string = create_tag_data_string post
			data_string = ' ' + data_string.trim_ellipsis(94) unless data_string.empty?

			bot.log "Preparing to tweet post #{post['id']}: #{destination_filename} (possibly_sensitive: #{sensitive})"
			# Tweet it!
			before_upload = Time.now
			begin
				bot.pictweet("https://danbooru.donmai.us/posts/#{post['id']}#{data_string}", destination_filename, { 'possibly_sensitive' => sensitive })
			rescue Twitter::Error => e
				bot.log "Tweet error #{e.class.to_s}: #{e.message}"
			end
			upload_time = Time.now - before_upload
			bot.log "Image tweeted in #{upload_time.to_f}. Marking file for deletion."
			# Clean up tweeted image
			@delete_queue << destination_filename
			# Remove post we just tweeted from queue
			queue_left = @post_queue.length - 1
			bot.log "Removing post from queue. Posts left: #{queue_left}"
			@post_queue.shift
		end

		# Genreates a little string to tweet with links.
		def create_tag_data_string(post)
			# Generate tag strings
			tags_character = get_tag_string post['tag_string_character'], true
			tags_copyright = get_tag_string post['tag_string_copyright']
			tags_artist = get_tag_string post['tag_string_artist']

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

		# Deletes stuff marked for deletion.
		def process_delete_queue(bot)
			@delete_queue.uniq!
			@delete_queue.delete_if do |filename|
				begin
					File.delete filename
					bot.log "Successfully deleted #{filename}"
					true
				rescue IOError => e
					bot.log "Couldn't delete file #{filename}: #{e.class.to_s} #{e.message}"
					false
				end
			end
		end
	end
end

class String
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