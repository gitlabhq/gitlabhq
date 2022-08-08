# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::CrossReferenced, :clean_gitlab_redis_cache do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  let(:issue_iid) { 999 }
  let(:issue) { create(:issue, project: project, iid: issue_iid) }
  let(:referenced_in) { build_stubbed(:issue, project: project, iid: issue_iid + 1) }
  let(:commit_id) { nil }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => 'cross-referenced',
      'source' => {
        'type' => 'issue',
        'issue' => {
          'number' => referenced_in.iid,
          'pull_request' => pull_request_resource
        }
      },
      'created_at' => '2022-04-26 18:30:53 UTC',
      'issue' => { 'number' => issue.iid }
    )
  end

  let(:pull_request_resource) { nil }
  let(:expected_note_attrs) do
    {
      system: true,
      noteable_type: Issue.name,
      noteable_id: issue.id,
      project_id: project.id,
      author_id: user.id,
      note: expected_note_body,
      created_at: issue_event.created_at
    }.stringify_keys
  end

  context 'when referenced in other issue' do
    let(:expected_note_body) { "mentioned in issue ##{referenced_in.iid}" }

    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(referenced_in.iid)
        allow(finder).to receive(:database_id).and_return(issue.id)
      end
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
      end
    end

    it 'creates expected note' do
      importer.execute(issue_event)

      expect(issue.notes.count).to eq 1
      expect(issue.notes[0]).to have_attributes expected_note_attrs
      expect(issue.notes[0].system_note_metadata.action).to eq 'cross_reference'
    end
  end

  context 'when referenced in pull request' do
    let(:referenced_in) { build_stubbed(:merge_request, project: project) }
    let(:pull_request_resource) { { 'id' => referenced_in.iid } }

    let(:expected_note_body) { "mentioned in merge request !#{referenced_in.iid}" }

    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(referenced_in.iid)
        allow(finder).to receive(:database_id).and_return(issue.id)
      end
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
      end
    end

    it 'creates expected note' do
      importer.execute(issue_event)

      expect(issue.notes.count).to eq 1
      expect(issue.notes[0]).to have_attributes expected_note_attrs
      expect(issue.notes[0].system_note_metadata.action).to eq 'cross_reference'
    end
  end

  context 'when referenced in out of project issue/pull_request' do
    it 'does not create expected note' do
      importer.execute(issue_event)

      expect(issue.notes.count).to eq 0
    end
  end
end
