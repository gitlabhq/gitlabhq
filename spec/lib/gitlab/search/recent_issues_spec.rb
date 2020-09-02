# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Search::RecentIssues, :clean_gitlab_redis_shared_state do
  let(:user) { create(:user) }
  let(:issue) { create(:issue, title: 'hello world 1', project: project) }
  let(:recent_issues) { described_class.new(user: user, items_limit: 5) }
  let(:project) { create(:project, :public) }

  before do
    stub_feature_flags(recent_items_search: true)
  end

  describe '#log_viewing' do
    it 'adds the item to the recent items' do
      recent_issues.log_view(issue)

      results = recent_issues.search('hello')

      expect(results).to eq([issue])
    end

    it 'removes an item when it exceeds the size items_limit' do
      (1..6).each do |i|
        recent_issues.log_view(create(:issue, title: "issue #{i}", project: project))
      end

      results = recent_issues.search('issue')

      expect(results.map(&:title)).to contain_exactly('issue 6', 'issue 5', 'issue 4', 'issue 3', 'issue 2')
    end

    it 'expires the items after expires_after' do
      recent_issues = described_class.new(user: user, expires_after: 0)

      recent_issues.log_view(issue)

      results = recent_issues.search('hello')

      expect(results).to be_empty
    end

    it 'does not include results logged for another user' do
      another_user = create(:user)
      another_issue = create(:issue, title: 'hello world 2', project: project)
      described_class.new(user: another_user).log_view(another_issue)
      recent_issues.log_view(issue)

      results = recent_issues.search('hello')

      expect(results).to eq([issue])
    end

    context 'when recent_items_search feature flag is disabled' do
      before do
        stub_feature_flags(recent_items_search: false)
      end

      it 'does not store anything' do
        recent_issues.log_view(issue)

        # Re-enable before searching to prove that the `log_view` call did
        # not persist it
        stub_feature_flags(recent_items_search: true)

        results = recent_issues.search('hello')

        expect(results).to be_empty
      end
    end
  end

  describe '#search' do
    let(:issue1) { create(:issue, title: "matching issue 1", project: project) }
    let(:issue2) { create(:issue, title: "matching issue 2", project: project) }
    let(:issue3) { create(:issue, title: "matching issue 3", project: project) }
    let(:non_matching_issue) { create(:issue, title: "different issue", project: project) }
    let!(:non_viewed_issued) { create(:issue, title: "matching but not viewed issue", project: project) }

    before do
      recent_issues.log_view(issue1)
      recent_issues.log_view(issue2)
      recent_issues.log_view(issue3)
      recent_issues.log_view(non_matching_issue)
    end

    it 'matches partial text in the issue title' do
      expect(recent_issues.search('matching')).to contain_exactly(issue1, issue2, issue3)
    end

    it 'returns results sorted by recently viewed' do
      recent_issues.log_view(issue2)

      expect(recent_issues.search('matching')).to eq([issue2, issue3, issue1])
    end

    it 'does not leak issues you no longer have access to' do
      private_project = create(:project, :public, namespace: create(:group))
      private_issue = create(:issue, project: private_project, title: 'matching issue title')

      recent_issues.log_view(private_issue)

      private_project.update!(visibility_level: Project::PRIVATE)

      expect(recent_issues.search('matching')).not_to include(private_issue)
    end

    context 'when recent_items_search feature flag is disabled' do
      it 'does not return anything' do
        recent_issues.log_view(issue)

        # Disable after persisting to prove that the `search` is not searching
        # anything
        stub_feature_flags(recent_items_search: false)

        results = recent_issues.search('hello')

        expect(results).to be_empty
      end
    end
  end
end
