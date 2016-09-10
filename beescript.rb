module BeeScript
  extend Discordrb::Commands::CommandContainer
	extend Discordrb::EventContainer
	
	
	
	#####################
	######VARIABLES######
	#####################
	
	# @return [true, false] Used in the posting threads to know when the bot is shutting down.
	attr_accessor :bot_stopping
	
	# @return [Array<String>] What we want to post on join.
	attr_accessor :script
	
	# @return [Array<Integer>] List of server IDs we want to ignore.
	attr_accessor :ignored_servers
	
	# @return [Array<Integer>] List of server IDs that we've finished posting to.
	attr_accessor :finished_servers
	
	# @return [Hash<Integer => Integer>] A list of servers that are unfinished when it comes
	#   to posting the script. We'll save this data to disk at regular intervals.
	#   Format: {
	#             SERVER_ID => {"servjoints"=>SERVER_JOIN_TIMESTAMP, "lastlinets"=>LAST_LINE_TIMESTAMP, "linessent"=>LINES_SENT},
	#             112233445566778899 => {"servjoints"=>1473455550, "lastlinets"=>1473508919, "linessent"=>13},
	#             112233445566778900 => {"servjoints"=>1473455550, "lastlinets"=>1473508919, "linessent"=>15}
	#           }
	attr_accessor :unfinished_servers
	
	# @return [Hash<Integer => Thread>] Temporary storage for threads that are posting the script.
	attr_accessor :threads
	
	# @return [Thread] The thread that uploads new stats to Discord Bots every whenever.
	#attr_accessor :dbthread
	
	# @return [Thread] This thread saves stats every 5 or so minutes.
	attr_accessor :statsavethread
	
	
	
	#####################
	#######EVENTS########
	#####################
	
	#When Discordrb is ready for input...
	ready() do |event|
		@bot_stopping = false
		
		@script = read_stats("script.txt", false, [])
		
		@ignored_servers = read_stats("ignored_servers.txt", false, [])
		@finished_servers = read_stats("finished_servers.txt", false, [])
		@unfinished_servers = read_stats("unfinished_servers.json", true, {})
		
		@threads = {}
		
		check_new_servers(event.bot)
		
		@statsavethread = Thread.new do
			loop do
				sleep 60 * 5
				save_stats!
			end
		end
		
		#Commented out incase someone actually tries to run this bot without looking at the code first.
		#@dbthread = Thread.new do
		#	botid = event.bot.profile.id
		#	time_to_sleep = 60 * 60
		#	
		#	sleep (time_to_sleep/2)
		#	loop do
		#		server_count = @finished_servers.size + @unfinished_servers.size
		#		json_data = JSON["server_count": server_count]
		#		#RestClient.post "https://bots.discord.pw/api/bots/#{botid}/stats", json_data, Authorization: "<auth code :)>"
		#		sleep time_to_sleep
		#	end
		#end
	end
	
	#When we've joined a server...
	server_create() do |event|
		on_server_join(event.bot, event.server)
	end
	
	#When we quit or are kicked off Discord for whatever reason...
	disconnected() do |event|
		@bot_stopping = true
		#Wait for threads to stop.
		while !@threads.empty? do
			sleep 1
		end
		
		save_stats!
	end
	
	
	
	#####################
	######FUNCTIONS######
	#####################
	
	# bot = Bot, CommandBot
	#server = Server
	def self.on_server_join(bot, server)
		sleep 1
		#Check if we're ignoring this specific server ID. Don't do anything if we are.
		servid = server.resolve_id
		return if @ignored_servers.include? servid
		
		@unfinished_servers[servid] = {}
		update_stats(servid, Time.now.to_i, 0, 0)
		
		c = make_new_channel(bot, server)
		
		if c.nil?
			sleep 1
			server.leave
		else
			script_thread(bot, servid, c)
		end
	end
	
	def self.script_thread(bot, servid, channel)
		@threads[servid] = Thread.new do
			post_script!(bot, channel)
			bot.server(servid).leave unless @bot_stopping
			@threads.delete servid
		end
	end
	
	# Post the script by calling this.
	# @param bot [Bot, CommandBot] We need this so we can actually send the message.
	# @param channel [Channel, Integer] The channel to post in.
	# @return [true, false] If it finished without error.
	def self.post_script!(bot, channel)
		chan = channel.resolve_id
		serv = channel.server.resolve_id
		
		@script.each_index {|line|
			next if @unfinished_servers[serv]["linessent"] > line
			
			if check_conditions?(bot, chan) then
				bot.send_message(chan, @script[line], false)
				
				update_stats(serv, nil, Time.now.to_i, @unfinished_servers[serv]["linessent"]+1)
				
				sleep 5
			else
				break
			end
		}
	end
	
	# Used internally to check various conditions, such as if the bot has permissions
	# to do what it wants, if it's been kicked, etc.
	# @param bot [Bot, CommandBot] So we can check the cache.
	# @param channel [Channel, Integer] We'll need to check if we have permissions.
	# @return [true, false] True if it's still safe to keep sending messages, false if it's not.
	def self.check_conditions?(bot, channel)
		begin
			chan = channel.resolve_id
			serv = bot.channel(chan).server.resolve_id
			
			( !@bot_stopping &&   #Is the bot stopping?
				!(bot.server(serv).nil?) &&   #Has it been kicked from the server?
				!(bot.channel(chan).nil?) &&   #Does the channel just not exist?
				bot.profile.on(serv).permission?(:send_messages, bot.channel(chan)) #Does the bot have permission to send messages?
			)
		rescue
			false
		end
	end
	
	def self.make_new_channel(bot, server)
		serv = server.resolve_id
		
		#Short-circuit if we've already got a channel for this.
		#c = bot.find_channel("bee-movie-script", server)
		c = nil
		bot.server(serv).channels.each{|i|
			c = i if (i.name == "bee-movie-script" && i.type == 'text')
		}
		return c if !c.nil?
		
		if bot.profile.on(serv).permission?(:manage_channels)
			c = bot.server(serv).create_channel("bee-movie-script")
		else
			nil
		end
	end
	
	# Checks for new servers not in any list, as well as unfinished servers.
	def self.check_new_servers(bot)
		servlist = bot.servers
		
		servlist.delete_if {|k,v| @ignored_servers.include? k }
		servlist.delete_if {|k,v| @finished_servers.include? k }
		
		servlist.each_pair {|k,v|
			if @unfinished_servers.has_key? k
				script_thread(bot, k, bot.channel('bee-movie-script', k))
			else
				on_server_join(bot, k)
			end
		}
	end
	
	
	
	#####################
	########STATS########
	#####################
	
	# Helper function to read from a file into an array.
	# @param file [String] The filename to read from.
	# @param json [true, false] Whether to read the file as JSON data.
	# @param default [Object] Return this if the file doesn't exist.
	# @return [default, Object] The returned data.
	def self.read_stats(file, json = false, default = nil)
		if File.exist?(file)
			if json
				j = JSON.parse(IO.read(file))
				
				#JSON doesn't like Integers as key names for some reason.
				j.inject({}){|memo,(k,v)| memo[k.to_i] = v; memo}
			else
				stuff = IO.readlines(file)
				stuff.each_index {|i| stuff[i] = stuff[i].chomp.to_i }
				stuff
			end
		else
			default
		end
	end
	
	# Updates the stats for a server. Leave any param besides server empty to not change it.
	# @param server [Server, Integer] The server to update.
	# @param servjoints [Integer] The time that the server was joined.
	# @param lastlinets [Integer] The last time a line was sent.
	# @param linessent [Integer] How many lines out of the script have been sent.
	def self.update_stats(server, servjoints = nil, lastlinets = nil, linessent = nil)
		servjoints ||= @unfinished_servers[server]["servjoints"]
		lastlinets ||= @unfinished_servers[server]["lastlinets"]
		linessent ||= @unfinished_servers[server]["linessent"]
		
		@unfinished_servers[server]["servjoints"] = servjoints
		@unfinished_servers[server]["lastlinets"] = lastlinets
		@unfinished_servers[server]["linessent"] = linessent
	end
	
	# Cleans out the stats.
	def self.clean_stats!
		@unfinished_servers.delete_if {|k,v|
			if v["linessent"] == @script.size
				@finished_servers.push k
				true
			else
				false
			end
		}
	end
	
	# Saves the stats to their respective files.
	def self.save_stats!
		clean_stats!
		
		IO.write("ignored_servers.txt", @ignored_servers.join("\n"))
		IO.write("finished_servers.txt", @finished_servers.join("\n"))
		IO.write("unfinished_servers.json", JSON.generate(@unfinished_servers))
	end
end
