# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Reviewed, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      id: 1196850910,
      actor: { id: user.id, login: user.username },
      event: 'reviewed',
      submitted_at: '2022-07-27T14:41:11Z',
      body: 'This is my review',
      state: state,
      issue: { number: merge_request.iid, pull_request: true }
    )
  end

  let(:state) { 'commented' }

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(merge_request.id)
    end
    allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
      allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
    end
  end

  it 'creates a review note', :aggregate_failures do
    expect { importer.execute(issue_event) }.to change { Note.count }.by(1)

    last_note = merge_request.notes.last
    expect(last_note.note).to include("This is my review")
    expect(last_note.author).to eq(user)
    expect(last_note.created_at).to eq(issue_event.submitted_at)
    expect(last_note.imported_from).to eq('github')
  end

  it 'does not create a reviewer for the Merge Request', :aggregate_failures do
    expect { importer.execute(issue_event) }.not_to change { MergeRequestReviewer.count }
  end

  context 'when stage is approved' do
    let(:state) { 'approved' }

    it 'creates an approval for the Merge Request', :aggregate_failures do
      expect { importer.execute(issue_event) }.to change { Approval.count }.by(1).and change { Note.count }.by(2)

      expect(merge_request.approved_by_users.reload).to include(user)
      expect(merge_request.approvals.last.created_at).to eq(issue_event.submitted_at)

      note = merge_request.notes.where(system: false).last
      expect(note.note).to include("This is my review")
      expect(note.author).to eq(user)
      expect(note.created_at).to eq(issue_event.submitted_at)
      expect(note.imported_from).to eq('github')

      system_note = merge_request.notes.where(system: true).last
      expect(system_note.note).to eq('approved this merge request')
      expect(system_note.author).to eq(user)
      expect(system_note.created_at).to eq(issue_event.submitted_at)
      expect(system_note.system_note_metadata.action).to eq('approved')
    end
  end
end
