# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Renamed, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository, :with_import_url) }
  let_it_be(:user) { create(:user) }

  let(:issuable) { create(:issue, project: project) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => 'renamed',
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'old_title' => 'old title',
      'new_title' => 'new title',
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:expected_note_attrs) do
    {
      noteable_id: issuable.id,
      noteable_type: issuable.class.name,
      project_id: project.id,
      author_id: user.id,
      note: "changed title from **{-old-} title** to **{+new+} title**",
      system: true,
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at,
      imported_from: 'github'
    }.stringify_keys
  end

  let(:expected_system_note_metadata_attrs) do
    {
      action: "title",
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(issuable.id)
      end
    end

    shared_examples 'import renamed event' do
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
    end

    shared_examples 'push a placeholder reference' do
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
      it 'does not push any reference' do
        expect(subject)
        .not_to receive(:push_with_record)

        importer.execute(issue_event)
      end
    end

    context 'when user mapping is enabled' do
      let_it_be(:source_user) do
        create(
          :import_source_user,
          placeholder_user_id: user.id,
          source_user_identifier: user.id,
          source_username: user.username,
          source_hostname: project.import_url,
          namespace_id: project.root_ancestor.id
        )
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true })
      end

      context 'with Issue' do
        it_behaves_like 'import renamed event'
        it_behaves_like 'push a placeholder reference'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        it_behaves_like 'import renamed event'
        it_behaves_like 'push a placeholder reference'
      end
    end

    context 'when user mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
        allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
        end
      end

      context 'with Issue' do
        it_behaves_like 'import renamed event'
        it_behaves_like 'do not push placeholder reference'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        it_behaves_like 'import renamed event'
        it_behaves_like 'do not push placeholder reference'
      end
    end
  end
end
