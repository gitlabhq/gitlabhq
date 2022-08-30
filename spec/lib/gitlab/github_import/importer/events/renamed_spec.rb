# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Renamed do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository) }
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
      updated_at: issue_event.created_at
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
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
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

    context 'with Issue' do
      it_behaves_like 'import renamed event'
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      it_behaves_like 'import renamed event'
    end
  end
end
