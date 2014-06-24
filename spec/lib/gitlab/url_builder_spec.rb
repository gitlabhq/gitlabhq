require 'spec_helper'

describe Gitlab::UrlBuilder do
  describe 'When asking for an issue' do
    it 'returns the issue url' do
      issue = create(:issue)
      url = Gitlab::UrlBuilder.new(:issue).build(issue.id)
      expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.to_param}/issues/#{issue.iid}"
    end
  end
end
