# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::ImportIssueWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_issue_label_1) { create(:label, project: project) }
  let_it_be(:jira_issue_label_2) { create(:label, project: project) }

  let(:some_key) { 'some-key' }

  describe 'modules' do
    it { expect(described_class).to include_module(ApplicationWorker) }
    it { expect(described_class).to include_module(Gitlab::NotifyUponDeath) }
    it { expect(described_class).to include_module(Gitlab::JiraImport::QueueOptions) }
    it { expect(described_class).to include_module(Gitlab::Import::DatabaseHelpers) }
  end

  subject { described_class.new }

  describe '#perform', :clean_gitlab_redis_cache do
    let(:assignee_ids) { [user.id] }
    let(:issue_attrs) do
      build(:issue, project_id: project.id, title: 'jira issue')
        .as_json.merge(
          'label_ids' => [jira_issue_label_1.id, jira_issue_label_2.id], 'assignee_ids' => assignee_ids
        ).except('issue_type')
        .compact
    end

    context 'when any exception raised while inserting to DB' do
      before do
        allow(subject).to receive(:insert_and_return_id).and_raise(StandardError)
        expect(Gitlab::JobWaiter).to receive(:notify)

        subject.perform(project.id, 123, issue_attrs, some_key)
      end

      it 'record a failed to import issue' do
        expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(1)
      end
    end

    context 'when record is successfully inserted' do
      let(:label) { create(:label, project: project) }

      context 'when import label does not exist' do
        it 'does not record import failure' do
          subject.perform(project.id, 123, issue_attrs, some_key)

          expect(label.issues.count).to eq(0)
          expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(0)
        end
      end

      context 'when import label exists' do
        before do
          Gitlab::JiraImport.cache_import_label_id(project.id, label.id)

          subject.perform(project.id, 123, issue_attrs, some_key)
        end

        it 'does not record import failure' do
          expect(label.issues.count).to eq(1)
          expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(0)
        end

        it 'creates an issue with the correct attributes' do
          issue = Issue.last

          expect(issue.title).to eq('jira issue')
          expect(issue.project).to eq(project)
          expect(issue.labels).to match_array([label, jira_issue_label_1, jira_issue_label_2])
          expect(issue.assignees).to eq([user])
        end

        context 'when assignee_ids is nil' do
          let(:assignee_ids) { nil }

          it 'creates an issue without assignee' do
            expect(Issue.last.assignees).to be_empty
          end
        end

        context 'when assignee_ids is an empty array' do
          let(:assignee_ids) { [] }

          it 'creates an issue without assignee' do
            expect(Issue.last.assignees).to be_empty
          end
        end
      end
    end
  end
end
