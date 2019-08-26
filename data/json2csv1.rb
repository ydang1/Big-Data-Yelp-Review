require 'json'

def escape_csv(json_text)
  if json_text.instance_of? String
    '"' + json_text.gsub('"', '""') + '"'
  else
    json_text
  end
end

input_filename = ARGV[0] || 'yelp_academic_dataset_review.json'
output_filename = (input_filename[-5..-1].downcase == '.json' ? input_filename[0..-6] : input_filename) + '.csv'

csv = File.new(output_filename, 'w')
header = false
File.open(input_filename, 'r').each_line do |line|
  review = JSON.parse line
  unless header
    csv.write(review.keys.map{|s| escape_csv(s)}.join(',') + "\n")
    header = true
  end
  csv.write(review.values.map{|s| escape_csv(s)}.join(',') + "\n")
end

csv.close
