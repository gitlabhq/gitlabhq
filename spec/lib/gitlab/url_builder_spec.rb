require 'spec_helper'

describe Gitlab::UrlBuilder do
  describe 'When asking for an issue' do
    it 'returns the issue url' do
      issue = create(:issue)
      url = Gitlab::UrlBuilder.new(:issue).build(issue.id)
      expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.path_with_namespace}/issues/#{issue.iid}"
    end
  end

  describe 'When asking for an merge request' do
    it 'returns the merge request url' do
      merge_request = create(:merge_request)
      url = Gitlab::UrlBuilder.new(:merge_request).build(merge_request.id)
      expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.path_with_namespace}/merge_requests/#{merge_request.iid}"
    end
  end
end
