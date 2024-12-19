# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::ImportIssueWorker, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:some_key) { 'some-key' }

  describe 'modules' do
    it { expect(described_class).to include_module(ApplicationWorker) }
    it { expect(described_class).to include_module(Gitlab::JiraImport::QueueOptions) }
    it { expect(described_class).to include_module(Gitlab::Import::DatabaseHelpers) }
    it { expect(described_class).to include_module(Gitlab::Import::NotifyUponDeath) }
  end

  subject { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    let(:issue_type) { ::WorkItems::Type.default_issue_type }

    let(:parent_field) do
      { 'key' => 'FOO-2', 'id' => '1050', 'fields' => { 'summary' => 'parent issue FOO' } }
    end

    let(:fields) do
      {
        'labels' => %w[bug dev backend frontend]
      }
    end

    # rubocop: disable RSpec/VerifiedDoubles -- instance doubles don't return expected values
    let(:assignee_ids) { double(attrs: { 'displayName' => 'Solver', 'accountId' => '1234' }) }

    let(:jira_issue) do
      double(
        id: '1234',
        key: 'PROJECT-5',
        summary: 'some title',
        description: 'basic description',
        created: '2020-01-01 20:00:00',
        updated: '2020-01-10 20:00:00',
        assignee: assignee_ids,
        reporter: nil,
        status: double(statusCategory: { 'key' => 'new' }),
        fields: fields
      )
    end
    # rubocop: enable RSpec/VerifiedDoubles

    let(:params) { { iid: 5 } }
    let(:issue_attrs) do
      Gitlab::JiraImport::IssueSerializer.new(
        project,
        jira_issue,
        user.id,
        issue_type,
        params
      ).execute
    end

    context 'when any exception raised while inserting to DB' do
      before do
        allow(subject).to receive(:insert_and_return_id).and_raise(StandardError)
        expect(Gitlab::JobWaiter).to receive(:notify)

        subject.perform(project.id, 1050, issue_attrs, some_key)
      end

      it 'record a failed to import issue' do
        expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(1)
      end
    end

    context 'when record is successfully inserted' do
      let(:label) { create(:label, project: project) }

      context 'when import label does not exist' do
        it 'does not record import failure' do
          subject.class.perform_inline(project.id, 1050, issue_attrs, some_key)

          expect(label.issues.count).to eq(0)
          expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(0)
        end
      end

      context 'when import label exists' do
        def perform_inline
          subject.class.perform_inline(project.id, 1050, issue_attrs, some_key)
        end

        let(:delay_exec) { false }

        before do
          Gitlab::JiraImport.cache_import_label_id(project.id, label.id)
          Gitlab::JiraImport.cache_users_mapping(project.id, { '1234' => user.id })

          perform_inline unless delay_exec
        end

        it 'does not record import failure' do
          expect(label.issues.count).to eq(1)
          expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(0)
        end

        it 'creates an issue with the correct attributes' do
          issue = Issue.last

          expect(issue.title).to eq('[PROJECT-5] some title')
          expect(issue.project).to eq(project)
          expect(issue.namespace).to eq(project.project_namespace)
          expect(issue.labels).to eq(project.labels)
          expect(issue.assignees).to eq([user])
          expect(issue.correct_work_item_type_id).to eq(issue_type.correct_id)
          expect(issue.work_item_type_id).to eq(issue_type.id)
        end

        context 'when legacy work_item_type_id was part of the attributes (backward compatibility)' do
          # Using 0 to make sure there's not another match by different columns
          let(:old_id) { 0 }
          let(:issue_type) { ::WorkItems::Type.default_issue_type.tap { |type| type.update!(old_id: old_id) } }
          let(:work_item_type_id) { old_id }
          let(:issue_attrs) do
            Gitlab::JiraImport::IssueSerializer.new(
              project,
              jira_issue,
              user.id,
              issue_type,
              params
            ).execute.except(:correct_work_item_type_id).merge(work_item_type_id: work_item_type_id)
          end

          it 'creates an issue with the correct type' do
            issue = Issue.last

            expect(issue.correct_work_item_type_id).to eq(issue_type.correct_id)
            expect(issue.work_item_type_id).to eq(issue_type.id)
          end
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
