require 'rails_helper'
describe 'Application', type: :feature do
  it "sees all users on index page" do
    visit '/'
    User.downloaded_users.each do |user|
      expect(page).to have_content(user.name)
    end
  end
  
  it "opens /user/galkovsky" do
    visit '/user/galkovsky'
    
    expect(page).to have_selector('div.card.year', count: 17)
    expect(page).to have_selector('li.post', count: 1047)
  end

  it "opens /user/krylov" do
    visit '/user/krylov'
  
    expect(page).not_to have_selector('div.card.year')
    expect(page).to have_selector('ul.years li', count: 14)
  end

  it "opens /user/krylov/year/2006" do
    visit '/user/krylov/year/2006'
  
    expect(page).to have_selector('div.card.year', count: 1)
    expect(page).to have_selector('li.post', count: 575)
  end
  
  it "opens a post" do
    visit '/user/galkovsky/2335'
    
    expect(page).to have_selector('h1')
    expect(find('h1').text).to eql('9. ОБОЗРЕВАЯ СЕБЯ, ЛЮБИМОГО')

    expect(page).to have_selector('iframe.ljsave')

    expect(find('link[rel="home"]', visible: false)['href']).to eql("https://ljsave.com")
  end
end