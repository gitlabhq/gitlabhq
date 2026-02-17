# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::ImportIssueWorker, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:issue_type) { create(:work_item_type, :issue) }

  let(:some_key) { 'some-key' }

  describe 'modules' do
    it { expect(described_class).to include_module(ApplicationWorker) }
    it { expect(described_class).to include_module(Gitlab::JiraImport::QueueOptions) }
    it { expect(described_class).to include_module(Gitlab::Import::NotifyUponDeath) }
  end

  subject(:worker) { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    let(:issue_attrs) do
      {
        'iid' => 5,
        'project_id' => project.id,
        'namespace_id' => project.project_namespace_id,
        'description' => 'basic description',
        'title' => '[PROJECT-5] some title',
        'state_id' => Issue.available_states[:opened],
        'updated_at' => '2020-01-10 20:00:00',
        'created_at' => '2020-01-01 20:00:00',
        'author_id' => user.id,
        'assignee_ids' => assignee_ids,
        'label_ids' => label_ids,
        'work_item_type_id' => issue_type.id,
        'imported_from' => 'jira'
      }
    end

    let(:assignee_ids) { [user.id] }
    let(:label_ids) { [] }

    context 'when project does not exist' do
      it 'does not create an issue' do
        expect(Gitlab::JobWaiter).to receive(:notify)

        expect { worker.perform(non_existing_record_id, 1050, issue_attrs, some_key) }
          .not_to change { Issue.count }
      end
    end

    context 'when any exception raised while inserting to DB' do
      before do
        allow_next_instance_of(Issue) do |issue|
          allow(issue).to receive(:save!).and_raise(StandardError)
        end
        expect(Gitlab::JobWaiter).to receive(:notify)

        worker.perform(project.id, 1050, issue_attrs, some_key)
      end

      it 'records a failed to import issue' do
        expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(1)
      end
    end

    context 'when record is successfully inserted' do
      before do
        allow(Gitlab::JobWaiter).to receive(:notify)
      end

      context 'when import label does not exist' do
        it 'does not record import failure' do
          worker.perform(project.id, 1050, issue_attrs, some_key)

          expect(label.issues.count).to eq(0)
          expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(0)
        end
      end

      context 'when import label exists' do
        before do
          Gitlab::JiraImport.cache_import_label_id(project.id, label.id)
        end

        it 'does not record import failure' do
          worker.perform(project.id, 1050, issue_attrs, some_key)

          expect(label.issues.count).to eq(1)
          expect(Gitlab::Cache::Import::Caching.read(Gitlab::JiraImport.failed_issues_counter_cache_key(project.id)).to_i).to eq(0)
        end

        it 'creates the issue' do
          expect { worker.perform(project.id, 1050, issue_attrs, some_key) }
            .to change { Issue.count }.by(1)
        end

        it 'creates an issue with the correct attributes' do
          worker.perform(project.id, 1050, issue_attrs, some_key)

          expect(Issue.last).to have_attributes(
            iid: 5,
            title: '[PROJECT-5] some title',
            description: 'basic description',
            project_id: project.id,
            namespace_id: project.project_namespace_id,
            work_item_type_id: issue_type.id,
            imported_from: 'jira'
          )
        end

        it 'assigns the issue to mapped users' do
          worker.perform(project.id, 1050, issue_attrs, some_key)

          expect(Issue.last.assignees).to eq([user])
        end

        it 'applies the import label to the issue' do
          worker.perform(project.id, 1050, issue_attrs, some_key)

          expect(Issue.last.labels).to include(label)
        end

        it 'sets the correct namespace_id on label links' do
          worker.perform(project.id, 1050, issue_attrs, some_key)

          expect(Issue.last.label_links.pluck(:namespace_id).uniq).to contain_exactly(project.project_namespace_id)
        end

        it 'creates search data for the issue' do
          worker.perform(project.id, 1050, issue_attrs, some_key)

          expect(Issue.last.search_data).to be_present
        end

        context 'when assignee is not mapped to a user' do
          let(:assignee_ids) { [] }

          it 'creates an issue without assignee' do
            worker.perform(project.id, 1050, issue_attrs, some_key)

            expect(Issue.last.assignees).to be_empty
          end
        end

        context 'when assignee_ids is nil' do
          let(:assignee_ids) { nil }

          it 'creates an issue without assignee' do
            worker.perform(project.id, 1050, issue_attrs, some_key)

            expect(Issue.last.assignees).to be_empty
          end
        end

        context 'when jira issue has labels' do
          let_it_be(:bug_label) { create(:label, project: project, title: 'bug') }
          let_it_be(:urgent_label) { create(:label, project: project, title: 'urgent') }

          let(:label_ids) { [bug_label.id, urgent_label.id] }

          it 'applies the jira labels and import label to the issue' do
            worker.perform(project.id, 1050, issue_attrs, some_key)

            expect(Issue.last.labels).to match_array([bug_label, urgent_label, label])
          end
        end
      end
    end
  end
end
