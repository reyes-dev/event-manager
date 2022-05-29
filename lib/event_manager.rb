require 'date'
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def tr_phone_number(phone_number)
  phone_number.to_s.tr('()', '').tr('-', '').tr(' ', '')
end

def clean_phone_number(phone_number)
  if phone_number.length == 11 && phone_number[0] == '1'
    phone_number = phone_number[0..9]
    phone_number
  elsif phone_number.length == 11 && phone_number[0] != '1'|| phone_number.length > 11
    phone_number = 'BAD NUMBER'
  elsif phone_number.length == 10
    phone_number
  end
end

def find_peak_hours(hours)
  Time.strptime(hours, '%m/%d/%Y %k:%M').hour.to_s + ':00'
end

def find_peak_days(days)
  case Time.strptime(days, '%m/%d/%Y %k:%M').wday
  when 0
    'Sunday'
  when 1
    'Monday'
  when 2
    'Tuesday'
  when 3
    'Wednesday'
  when 4
    'Thursday'
  when 5
    'Friday'
  when 6
    'Saturday'
  when 7
    'Sunday'
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
peak_hours = []
peak_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_number(tr_phone_number(row[:homephone]))
  peak_hours.push(find_peak_hours(row[:regdate]))
  peak_days.push(find_peak_days(row[:regdate]))

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "The Hours most people registered were: #{peak_hours.group_by{ |x| x }.sort_by{|k, v| -v.size}.map(&:first)[0..3].join(', ')}"

puts "The Days most people registered were: #{peak_days.group_by{ |x| x }.sort_by{|k, v| -v.size}.map(&:first)[0..2].join(', ')}"