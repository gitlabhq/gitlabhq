# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::CrossReferenced, :clean_gitlab_redis_cache do
  subject(:importer) { described_class.new(project, user.id) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sawyer_stub) { Struct.new(:iid, :issuable_type, keyword_init: true) }

  let(:issue) { create(:issue, project: project) }
  let(:referenced_in) { build_stubbed(:issue, project: project) }
  let(:commit_id) { nil }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => 4, 'login' => 'alice' },
      'event' => 'cross-referenced',
      'source' => {
        'type' => 'issue',
        'issue' => {
          'number' => referenced_in.iid,
          'pull_request' => pull_request_resource
        }
      },
      'created_at' => '2022-04-26 18:30:53 UTC',
      'issue_db_id' => issue.id
    )
  end

  let(:pull_request_resource) { nil }
  let(:expected_note_attrs) do
    {
      system: true,
      noteable_type: Issue.name,
      noteable_id: issue_event.issue_db_id,
      project_id: project.id,
      author_id: user.id,
      note: expected_note_body,
      created_at: issue_event.created_at
    }.stringify_keys
  end

  context 'when referenced in other issue' do
    let(:expected_note_body) { "mentioned in issue ##{issue.iid}" }

    before do
      other_issue_resource = sawyer_stub.new(iid: referenced_in.iid, issuable_type: 'Issue')
      Gitlab::GithubImport::IssuableFinder.new(project, other_issue_resource)
        .cache_database_id(referenced_in.iid)
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
      other_issue_resource =
        sawyer_stub.new(iid: referenced_in.iid, issuable_type: 'MergeRequest')
      Gitlab::GithubImport::IssuableFinder.new(project, other_issue_resource)
        .cache_database_id(referenced_in.iid)
    end

    it 'creates expected note' do
      importer.execute(issue_event)

      expect(issue.notes.count).to eq 1
      expect(issue.notes[0]).to have_attributes expected_note_attrs
      expect(issue.notes[0].system_note_metadata.action).to eq 'cross_reference'
    end
  end

  context 'when referenced in out of project issue/pull_request' do
    it 'creates expected note' do
      importer.execute(issue_event)

      expect(issue.notes.count).to eq 0
    end
  end
end
