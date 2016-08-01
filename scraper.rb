require 'scraperwiki'
require 'mechanize'

def extract_elems_from_paragraph(application_list, url)
  #For each application in a <p> elem, we split that into children.
  #We find our data by searching for substrings in children and selecting the next child element.

  record = {
    "info_url" => url,
    "comment_url" => "mailto:contactus@hume.vic.gov.au",
    "council_reference" => "",
    "address" => "",
    "on_notice_to" => "",
    "description" => "",
    "date_scraped" => Date.today.to_s
  }

  elems_to_analyse = application_list.children
  elems_to_analyse.each_with_index do |elem_to_extract, index|
    if elem_to_extract.to_s.include? "Application Reference"
      record["council_reference"] = elems_to_analyse[index + 1].inner_text.strip
    elsif elem_to_extract.to_s.include? "Property Address"
      record["address"] = "#{elems_to_analyse[index + 1].inner_text.strip}, VIC"
    elsif elem_to_extract.to_s.include? "No decision will be made prior to"
      day, month, year = elems_to_analyse[index + 1].inner_text.strip.split("/")
      record["on_notice_to"] = "#{year}-#{month}-#{day}"
    elsif elem_to_extract.to_s.include? "Proposal"
      record["description"] = elems_to_analyse[index + 1].inner_text.strip
    end
  end

  return record
end

def save_dev_application_data(record)
  #Save data to db file, but don't overwrite the entries that exist already.
  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
    puts "Saving record #{record['council_reference']}"
  else
    puts "Skipping already saved record #{record['council_reference']}"
  end
end

url = "https://www.hume.vic.gov.au/Building_Planning/Planning/Applications_at_Advertising"
agent = Mechanize.new
page = agent.get(url)

#For this LGA, all applications are on a single page, in a single div. Each is a p element
div_with_applications = page.search('div.content_article_body')
applications_all = div_with_applications.search('p')

applications_all.each_with_index do |application, index|
  #The first three <p> elements are not applications
  next if index < 3
  data_from_dev_application = extract_elems_from_paragraph(application, url)
  save_dev_application_data(data_from_dev_application)
end