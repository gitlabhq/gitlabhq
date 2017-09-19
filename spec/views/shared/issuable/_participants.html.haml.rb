require 'spec_helper'
require 'nokogiri'

def expect_lazy_load_image(author)
  avatar = author.find('img')

  expect(avatar[:src]).to eql?('data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==')
  expect(avatar[:"data-src"]).to exist
end

describe 'shared/issuable/_participants.html.haml' do
  let(:project) { create(:project) }
  let(:participants)  { create_list(:user, 10) }

  before do
    allow(view).to receive_messages(project: project,
                                    participants: participants)
  end

  it 'displays' do
    render 'shared/issuable/participants'

    html = Nokogiri::HTML(rendered)

    authors = html.css('.participants-author')
    p authors
    p authors.size
    visible_authors = authors[0..6]
    hidden_authors = authors[7..-1]

    visible_authors.each do |author|
      expect(author).not_to have_selector('js-participants-hidden')
      expect_lazy_load_image(author)
    end

    hidden_authors.each do |author|
      expect(author).to have_selector('js-participants-hidden')
      expect_lazy_load_image(author)
    end
  end
end
