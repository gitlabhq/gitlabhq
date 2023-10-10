# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LinkedProjectIssueEntity do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:issue_link) { create(:issue_link) }

  let(:request) { double('request') }
  let(:issue_type) { :task }
  let(:related_issue) { issue_link.source.related_issues(user).first }
  let(:entity) { described_class.new(related_issue, request: request, current_user: user) }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:issuable).and_return(issue_link.source)
    issue_link.target.project.add_developer(user)
  end

  subject(:serialized_entity) { entity.as_json }

  describe 'issue_link_type' do
    it { is_expected.to include(link_type: 'relates_to') }
  end

  describe 'type' do
    it 'returns the issue type' do
      expect(serialized_entity).to include(type: 'ISSUE')
    end

    context 'when related issue is a task' do
      let_it_be(:issue_link) { create(:issue_link, target: create(:issue, :task)) }

      it 'returns a work item issue type' do
        expect(serialized_entity).to include(type: 'TASK')
      end
    end
  end

  describe 'path' do
    it 'returns an issue path' do
      expect(serialized_entity).to include(path: project_issue_path(related_issue.project, related_issue.iid))
    end

    context 'when related issue is a task' do
      let_it_be(:issue_link) { create(:issue_link, target: create(:issue, :task)) }

      it 'returns a work items path using iid' do
        expect(serialized_entity).to include(
          path: project_work_item_path(related_issue.project, related_issue.iid)
        )
      end
    end
  end
end
