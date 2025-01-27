require 'google_maps_service'
require 'httparty'
require 'ascii_charts'

puts "========================================"
puts "    Will you need an umbrella today?    "
puts "========================================"
puts "\nWhere are you?"
location = gets.chomp
gmaps = GoogleMapsService::Client.new(key: GMAPS_KEY)

# Geocode the location
results = gmaps.geocode(location)
if results.empty?
  puts "Could not find the location."
  exit
end

coordinates = results[0][:geometry][:location]
latitude = coordinates[:lat]
longitude = coordinates[:lng]

puts "\nChecking the weather at #{location.capitalize}...."
puts "Your coordinates are #{latitude}, #{longitude}."

# Get weather data
response = HTTParty.get("https://api.pirateweather.net/forecast/#{PIRATE_WEATHER_KEY}/#{latitude},#{longitude}")
weather_data = response.parsed_response

current_temp = weather_data['currently']['temperature']
hourly_data = weather_data['hourly']['data']

puts "It is currently #{current_temp}°F."
puts "Next hour: #{weather_data['minutely'] ? weather_data['minutely']['summary'] : 'No minute data available.'}"
