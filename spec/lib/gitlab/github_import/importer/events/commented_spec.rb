# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Commented, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled
    )
  end

  let_it_be(:source_user) { generate_source_user(project, 1000) }

  let(:client) { instance_double('Gitlab::GithubImport::Client', web_endpoint: 'https://github.com') }
  let(:issuable) { create(:issue, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.new(
      id: 1196850910,
      actor: { id: source_user.source_user_identifier, login: source_user.source_username },
      event: 'commented',
      created_at: '2022-07-27T14:41:11Z',
      updated_at: '2022-07-27T14:41:11Z',
      body: 'This is my note',
      issue: { number: issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(issuable.id)
    end
  end

  shared_examples 'new note' do
    it 'creates a note' do
      expect { importer.execute(issue_event) }.to change { Note.count }.by(1)

      expect(issuable.notes.last).to have_attributes(
        note: 'This is my note',
        author_id: source_user.mapped_user_id,
        noteable_type: issuable.class.name.to_s,
        imported_from: 'github'
      )
    end
  end

  context 'with Issue' do
    it_behaves_like 'new note'
  end

  context 'with MergeRequest' do
    let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like 'new note'
  end
end
