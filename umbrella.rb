require 'http'
require 'json'
require 'ascii_charts'
require 'dotenv/load' # Load .env variables

puts "========================================"
puts "    Will you need an umbrella today?    "
puts "========================================"
puts "\nWhere are you?"
user_location = gets.chomp

# Get coordinates from Google Maps API
gmaps_key = ENV.fetch("GMAPS_KEY")
gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{user_location}&key=#{gmaps_key}"

raw_gmaps_data = HTTP.get(gmaps_url)
parsed_gmaps_data = JSON.parse(raw_gmaps_data)
results_array = parsed_gmaps_data.fetch("results")
first_result_hash = results_array.at(0)
geometry_hash = first_result_hash.fetch("geometry")
location_hash = geometry_hash.fetch("location")

latitude = location_hash.fetch("lat")
longitude = location_hash.fetch("lng")

puts "\nChecking the weather at #{user_location.capitalize}...."
puts "Your coordinates are #{latitude}, #{longitude}."

# Get the weather from Pirate Weather API
pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
pirate_weather_url = "https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{latitude},#{longitude}"

raw_weather_data = HTTP.get(pirate_weather_url)
parsed_weather_data = JSON.parse(raw_weather_data)

current_temp = parsed_weather_data['currently']['temperature']
hourly_data = parsed_weather_data['hourly']['data']

puts "It is currently #{current_temp}°F."
puts "Next hour: #{parsed_weather_data['minutely'] ? parsed_weather_data['minutely']['summary'] : 'No minute data available.'}"

# Process precipitation probabilities for the next 12 hours
precip_data = []
umbrella_needed = false

(1..12).each do |hour|
  # Ensure data exists and sanitize probabilities
  hourly_precip = hourly_data[hour]
  next unless hourly_precip # Skip if the data is missing

  precip_prob = hourly_precip['precipProbability'] ? (hourly_precip['precipProbability'] * 100).to_i : 0
  precip_data << [hour, precip_prob]
  umbrella_needed ||= precip_prob > 10
end

# Ensure there is valid data to chart
if precip_data.empty?
  puts "\nNo precipitation data available for the next 12 hours."
else
  # Ensure no `nil` or invalid data is passed to ascii_charts
  precip_data.map! { |hour, prob| [hour, prob.nil? ? 0 : prob] }

  # Display chart
  puts "\nHours from now vs Precipitation probability\n"
  puts AsciiCharts::Cartesian.new(precip_data, bar: true, hide_zero: true).draw
end

# Print umbrella recommendation
if umbrella_needed
  puts "\nYou might want to take an umbrella!"
else
  puts "\nYou probably won’t need an umbrella today."
end
