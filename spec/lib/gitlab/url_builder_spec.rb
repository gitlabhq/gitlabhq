require 'spec_helper'

describe Gitlab::UrlBuilder do
  describe 'When asking for an issue' do
    it 'returns the issue url' do
      issue = create(:issue)
      url = Gitlab::UrlBuilder.new(:issue).build(issue.id)
      expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.to_param}/issues/#{issue.iid}"
    end
  end

  describe 'When asking for a merge request' do
    it 'returns the merge request url' do
      merge_request = create(:merge_request)
      url = Gitlab::UrlBuilder.new(:merge_request).build(merge_request.id)
      expect(url).to eq Settings.gitlab['url'] +
        "/#{merge_request.project.to_param}/merge_requests/#{merge_request.iid}"
    end
  end
end
