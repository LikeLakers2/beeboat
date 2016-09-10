require 'discordrb'
require 'json'
require 'rest-client'
require_relative './beescript'

$bot = Discordrb::Commands::CommandBot.new(
	token: '<token>',
	application_id: 4PP1D,
	type: :bot,
	name: "BeeBoat/1.0 made by MichiRecRoom#9507",
	#prefix: '@BeeBoat#3658',   #Apparently this doesn't work?
	prefix: '?',
	advanced_functionality: false,
	help_command: false,
	command_doesnt_exist_message: false,
	#spaces_allowed: true   #The bot will work off mentions.
	spaces_allowed: false   #NEVERMIND
)

@ownerid = 112233445566778899  #Replace with your own ID.

$bot.include! BeeScript

#Eval command
$bot.command(:eval, help_available: false) do |event, *code|
	break unless event.user.id == @ownerid
	
	begin
		eval code.join(' ')
	rescue => exc
	  puts exc.inspect
		"An error occured :disappointed:"
	end
end

$bot.command(:quit, help_available: false) do |event|
	break unless event.user.id == @ownerid
	$bot.stop
end

$bot.command(:source, help_available: false) do |event|
	event.respond "I'm BeeBoat, made by MichiRecRoom#9507. You can look at my source code at https://github.com/LikeLakers2/beeboat"
end

puts "This bot's invite URL is #{$bot.invite_url}."
puts 'Click on it to invite it to your server.'

$bot.run