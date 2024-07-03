# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Commented, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:issue, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.new(
      id: 1196850910,
      actor: { id: user.id, login: user.username },
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
    allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
      allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
    end
  end

  shared_examples 'new note' do
    it 'creates a note' do
      expect { importer.execute(issue_event) }.to change { Note.count }.by(1)

      expect(issuable.notes.last).to have_attributes(
        note: 'This is my note',
        author_id: user.id,
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
