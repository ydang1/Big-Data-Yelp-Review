require 'json'
require 'csv'

input_filename = ARGV[0] || 'yelp_academic_dataset_review.json'
output_filename = (input_filename[-5..-1].downcase == '.json' ? input_filename[0..-6] : input_filename) + '.csv'

header = false
CSV.open(output_filename, 'wb') do |csv|
  File.open(input_filename, 'r').each_line do |line|
    review = JSON.parse line
    unless header
      csv << review.keys
      header = true
    end
    csv << review.values
  end
end
