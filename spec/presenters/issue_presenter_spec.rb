# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:task) { create(:issue, :task, project: project) }

  let(:presented_issue) { issue }
  let(:presenter) { described_class.new(presented_issue, current_user: user) }

  before_all do
    group.add_developer(user)
  end

  describe '#web_url' do
    it 'returns correct path' do
      expect(presenter.web_url).to eq("http://localhost/#{group.name}/#{project.name}/-/issues/#{presented_issue.iid}")
    end

    context 'when issue type is task' do
      let(:presented_issue) { task }

      context 'when use_iid_in_work_items_path feature flag is disabled' do
        before do
          stub_feature_flags(use_iid_in_work_items_path: false)
        end

        it 'returns a work item url for the task' do
          expect(presenter.web_url).to eq(project_work_items_url(project, work_items_path: presented_issue.id))
        end
      end

      it 'returns a work item url using iid for the task' do
        expect(presenter.web_url).to eq(
          project_work_items_url(project, work_items_path: presented_issue.iid, iid_path: true)
        )
      end
    end
  end

  describe '#subscribed?' do
    subject { presenter.subscribed? }

    it 'returns not subscribed' do
      is_expected.to be(false)
    end

    it 'returns subscribed' do
      create(:subscription, user: user, project: project, subscribable: presented_issue, subscribed: true)

      is_expected.to be(true)
    end
  end

  describe '#issue_path' do
    it 'returns correct path' do
      expect(presenter.issue_path).to eq("/#{group.name}/#{project.name}/-/issues/#{presented_issue.iid}")
    end

    context 'when issue type is task' do
      let(:presented_issue) { task }

      context 'when use_iid_in_work_items_path feature flag is disabled' do
        before do
          stub_feature_flags(use_iid_in_work_items_path: false)
        end

        it 'returns a work item path for the task' do
          expect(presenter.issue_path).to eq(project_work_items_path(project, work_items_path: presented_issue.id))
        end
      end

      it 'returns a work item path using iid for the task' do
        expect(presenter.issue_path).to eq(
          project_work_items_path(project, work_items_path: presented_issue.iid, iid_path: true)
        )
      end
    end
  end

  describe '#project_emails_disabled?' do
    subject { presenter.project_emails_disabled? }

    it 'returns false when emails notifications is enabled for project' do
      is_expected.to be(false)
    end

    context 'when emails notifications is disabled for project' do
      before do
        allow(project).to receive(:emails_disabled?).and_return(true)
      end

      it { is_expected.to be(true) }
    end
  end
end
