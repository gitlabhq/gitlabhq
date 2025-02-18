# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedAssignee, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository, :with_import_url) }
  let_it_be(:author) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:issue, project: project) }

  let(:assignee) { { 'id' => 2000, 'login' => 'github_assignee' } }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => 1000, 'login' => 'github_author' },
      'event' => event_type,
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'assignee' => assignee,
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:note_attrs) do
    {
      noteable_id: issuable.id,
      noteable_type: issuable.class.name,
      project_id: project.id,
      author_id: author.id,
      system: true,
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at,
      imported_from: 'github'
    }.stringify_keys
  end

  let(:expected_system_note_metadata_attrs) do
    {
      action: "assignee",
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  shared_examples 'create expected notes' do
    it 'creates expected note' do
      expect { importer.execute(issue_event) }.to change { issuable.notes.count }
        .from(0).to(1)

      expect(issuable.notes.last)
        .to have_attributes(expected_note_attrs)
    end

    it 'creates expected system note metadata' do
      expect { importer.execute(issue_event) }.to change { SystemNoteMetadata.count }
        .from(0).to(1)

      expect(SystemNoteMetadata.last)
        .to have_attributes(
          expected_system_note_metadata_attrs.merge(
            note_id: Note.last.id
          )
        )
    end

    context 'when assignee is nil' do
      let(:assignee) { nil }

      it 'references `@ghost`' do
        importer.execute(issue_event)

        expect(issuable.notes.last.note).to end_with('`@ghost`')
      end
    end
  end

  shared_examples 'process assigned & unassigned events' do
    context 'when importing an assigned event' do
      let(:event_type) { 'assigned' }
      let(:expected_note_attrs) { note_attrs.merge(note: "assigned to `@github_assignee`") }

      it_behaves_like 'create expected notes'
    end

    context 'when importing an unassigned event' do
      let(:event_type) { 'unassigned' }
      let(:expected_note_attrs) { note_attrs.merge(note: "unassigned `@github_assignee`") }

      it_behaves_like 'create expected notes'
    end
  end

  shared_examples 'push a placeholder reference' do
    let(:event_type) { 'assigned' }

    it 'pushes the reference' do
      expect(subject)
      .to receive(:push_with_record)
      .with(
        an_instance_of(Note),
        :author_id,
        issue_event[:actor].id,
        an_instance_of(Gitlab::Import::SourceUserMapper)
      )

      importer.execute(issue_event)
    end
  end

  shared_examples 'do not push placeholder reference' do
    let(:event_type) { 'assigned' }

    it 'does not push any reference' do
      expect(subject)
      .not_to receive(:push_with_record)

      importer.execute(issue_event)
    end
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(issuable.id)
        allow(finder).to receive(:author_id_for).with(issue_event, author_key: :actor).and_return([author.id, true])
      end
    end

    context 'when user mapping is enabled' do
      let_it_be(:source_user) do
        create(
          :import_source_user,
          placeholder_user_id: author.id,
          source_user_identifier: 1000,
          source_username: 'github_author',
          source_hostname: project.import_url,
          namespace_id: project.root_ancestor.id
        )
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true })
      end

      context 'with Issue' do
        it_behaves_like 'process assigned & unassigned events'
        it_behaves_like 'push a placeholder reference'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        it_behaves_like 'process assigned & unassigned events'
        it_behaves_like 'push a placeholder reference'
      end
    end

    context 'when user mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
        allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          allow(finder).to receive(:find).with(1000, 'github_author').and_return(author.id)
        end
      end

      context 'with Issue' do
        it_behaves_like 'process assigned & unassigned events'
        it_behaves_like 'do not push placeholder reference'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        it_behaves_like 'process assigned & unassigned events'
        it_behaves_like 'do not push placeholder reference'
      end
    end
  end
end
