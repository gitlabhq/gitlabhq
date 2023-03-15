# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::CreateExternalCrossReferenceWorker, feature_category: :integrations do
  include AfterNextHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :with_jira_integration, :repository) }
  let_it_be(:author) { create(:user) }
  let_it_be(:commit) { project.commit }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:note) { create(:note, project: project) }
  let_it_be(:snippet) { create(:project_snippet, project: project) }

  let(:project_id) { project.id }
  let(:external_issue_id) { 'JIRA-123' }
  let(:mentionable_type) { 'Issue' }
  let(:mentionable_id) { issue.id }
  let(:author_id) { author.id }
  let(:job_args) { [project_id, external_issue_id, mentionable_type, mentionable_id, author_id] }

  def perform
    described_class.new.perform(*job_args)
  end

  before do
    allow(Project).to receive(:find_by_id).and_return(project)
  end

  it_behaves_like 'an idempotent worker' do
    before do
      allow(project.external_issue_tracker).to receive(:create_cross_reference_note)
    end

    it 'can run multiple times with the same arguments' do
      subject

      expect(project.external_issue_tracker).to have_received(:create_cross_reference_note)
        .exactly(worker_exec_times).times
    end
  end

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    expect(described_class.get_deduplication_options).to include({ including_scheduled: true })
  end

  # These are the only models where we currently support cross-references,
  # although this should be expanded to all `Mentionable` models.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/343975
  where(:mentionable_type, :mentionable_id) do
    'Commit'       | lazy { commit.id }
    'Issue'        | lazy { issue.id }
    'MergeRequest' | lazy { merge_request.id }
    'Note'         | lazy { note.id }
    'Snippet'      | lazy { snippet.id }
  end

  with_them do
    it 'creates a cross reference' do
      expect(project.external_issue_tracker).to receive(:create_cross_reference_note).with(
        be_a(ExternalIssue).and(have_attributes(id: external_issue_id, project: project)),
        be_a(mentionable_type.constantize).and(have_attributes(id: mentionable_id)),
        be_a(User).and(have_attributes(id: author_id))
      )

      perform
    end
  end

  describe 'error handling' do
    shared_examples 'does not create a cross reference' do
      it 'does not create a cross reference' do
        expect(project).not_to receive(:external_issue_tracker) if project

        perform
      end
    end

    context 'project_id does not exist' do
      let(:project_id) { non_existing_record_id }
      let(:project) { nil }

      it_behaves_like 'does not create a cross reference'
    end

    context 'author_id does not exist' do
      let(:author_id) { non_existing_record_id }

      it_behaves_like 'does not create a cross reference'
    end

    context 'mentionable_id does not exist' do
      let(:mentionable_id) { non_existing_record_id }

      it_behaves_like 'does not create a cross reference'
    end

    context 'mentionable_type is not a Mentionable' do
      let(:mentionable_type) { 'User' }

      before do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(kind_of(ArgumentError))
      end

      it_behaves_like 'does not create a cross reference'
    end

    context 'mentionable_type is not a defined constant' do
      let(:mentionable_type) { 'FooBar' }

      before do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(kind_of(ArgumentError))
      end

      it_behaves_like 'does not create a cross reference'
    end

    context 'mentionable is a Commit and mentionable_id does not exist' do
      let(:mentionable_type) { 'Commit' }
      let(:mentionable_id) { non_existing_record_id }

      it_behaves_like 'does not create a cross reference'
    end
  end
end
