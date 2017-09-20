require 'spec_helper'
require 'nokogiri'

describe 'shared/issuable/_participants.html.haml' do
  let(:project) { create(:project) }
  let(:participants)  { create_list(:user, 100) }

  before do
    allow(view).to receive_messages(project: project,
                                    participants: participants)
  end

  it 'renders lazy loaded avatars' do
    render 'shared/issuable/participants'

    html = Nokogiri::HTML(rendered)

    avatars = html.css('.participants-author img')

    avatars.each do |avatar|
      expect(avatar[:class]).to include('lazy')
      expect(avatar[:src]).to eql('data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==')
      expect(avatar[:"data-src"]).to match('http://www.gravatar.com/avatar/')
    end
  end
end
