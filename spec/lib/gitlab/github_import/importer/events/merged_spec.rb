# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Merged, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:commit_id) { nil }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => 'merged',
      'created_at' => '2022-04-26 18:30:53 UTC',
      'commit_id' => commit_id,
      'issue' => { 'number' => merge_request.iid, pull_request: true }
    )
  end

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(merge_request.id)
    end
    allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
      allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
    end
  end

  it 'creates expected event and state event' do
    importer.execute(issue_event)

    expect(merge_request.events.count).to eq 1
    expect(merge_request.events.first).to have_attributes(
      project_id: project.id,
      author_id: user.id,
      target_id: merge_request.id,
      target_type: merge_request.class.name,
      action: 'merged',
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    )

    expect(merge_request.resource_state_events.count).to eq 1
    expect(merge_request.resource_state_events.first).to have_attributes(
      user_id: user.id,
      merge_request_id: merge_request.id,
      state: 'merged',
      created_at: issue_event.created_at,
      close_after_error_tracking_resolve: false,
      close_auto_resolve_prometheus_alert: false
    )
  end

  it 'creates a merged by note' do
    expect { importer.execute(issue_event) }.to change { Note.count }.by(1)

    last_note = merge_request.notes.last
    expect(last_note.created_at).to eq(issue_event.created_at)
    expect(last_note.author).to eq(project.owner)
    expect(last_note.note).to eq("*Merged by: #{user.username} at #{issue_event.created_at}*")
  end

  context 'when commit ID is present' do
    let!(:commit) { create(:commit, project: project) }
    let(:commit_id) { commit.id }

    it 'creates expected event and state event' do
      importer.execute(issue_event)

      expect(merge_request.events.count).to eq 1
      state_event = merge_request.resource_state_events.last
      expect(state_event.source_commit).to eq commit_id[0..40]
    end
  end
end
