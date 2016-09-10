# beeboat
A bot that joins servers, creates the #bee-movie-script channel, posts the Bee Movie script to #bee-movie-script, then leaves.



In case you decide to run this yourself:

finished_servers.txt - a line-separated list of servers that have been finished.

ignored_servers.txt - a line-separated list of servers that are ignored. Useful for home servers.

unfinished_servers.json - a JSON data set for servers that are still in the process of having the script sent to them.

script.txt - Where the script that is sent is stored. Check the Tools directory for a script that will automatically split the messages every 2000 characters.

Also make sure you actually look at the code, and have a decent knowledge of ruby. I will not help debug the bot if you run it.

# Errors and stuff?
I don't know what's causing the current errors. It seems like it's discordrb's thing as it's not running through my code. So if you get errors in your console from this, I don't know how to help. I will try to ensure this works with discordrb v3.0.0 nonetheless.
