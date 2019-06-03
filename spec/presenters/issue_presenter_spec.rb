# frozen_string_literal: true

require 'spec_helper'

describe IssuePresenter do
  include Gitlab::Routing.url_helpers

  let(:user)      { create(:user) }
  let(:group)     { create(:group) }
  let(:project)   { create(:project, group: group) }
  let(:issue)     { create(:issue, project: project) }
  let(:presenter) { described_class.new(issue, current_user: user) }

  before do
    group.add_developer(user)
  end

  describe '#web_url' do
    it 'returns correct path' do
      expect(presenter.web_url).to eq "http://localhost/#{group.name}/#{project.name}/issues/#{issue.iid}"
    end
  end

  describe '#issue_path' do
    it 'returns correct path' do
      expect(presenter.issue_path).to eq "/#{group.name}/#{project.name}/issues/#{issue.iid}"
    end
  end
end
