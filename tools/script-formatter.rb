#Gives us the character limit.
require 'discordrb'

#read the file we want to split to an array, split by spaces
s = IO.read("script2.txt").split(" ")

#Character limit, hopefully this is up-to-date.
chrlimit = Discordrb::CHARACTER_LIMIT

#This array holds our result.
#We'll be storing this array in a separate file later.
a = []

#The position in the array we want to add this text at.
i = 0

#Set the text to empty just in case ruby wants to be weird.
#It wouldn't work as well if the variable was recreated every loop.
text = ""

#Set the first item in the array to an empty string so Ruby doesn't
#potentially complain about nilclass stuff.
a[i] = ""

while true do
	#Get a thing
	text = s.delete_at 0
	
	#No more text? We're done.
	if text.nil?
		break
	end
	
	#If this would go over the character limit, go to the next line.
	if (a[i].length + text.length) >= chrlimit
		i += 1
		a[i] = ""
	end
	
	#Add the text at the position
	a[i] += " #{text}"
	
	#Remove spaces at the beginning of the string, if needed.
	if a[i][0] == " "
		a[i][0] = ""
	end
end

#Now we wanna store this.
text_to_store = a.join("\n")
IO.write("script2-formatted.txt", text_to_store)
