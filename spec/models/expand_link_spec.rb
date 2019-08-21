require 'rails_helper'

RSpec.describe Downloader::ExpandLink do
  let(:browser) {Downloader::Chrome.create(headless: true)}
  
  it "finds ExpandLinks on page" do
    file_path = 'spec/html_data/palaman_362622.html'
    browser.get("file://#{File.absolute_path(file_path)}")
    
    found_links = Downloader::ExpandLink.find_on_page(browser)
    expect(found_links.count).to eql(32)

    top_level_links = Downloader::ExpandLink.top_level_links(found_links)
    expect(top_level_links.count).to eql(6)
    
    
  end
end