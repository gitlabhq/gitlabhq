# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Reopened, :aggregate_failures do
  subject(:importer) { described_class.new(project, user.id) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:issue) { create(:issue, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => 4, 'login' => 'alice' },
      'event' => 'reopened',
      'created_at' => '2022-04-26 18:30:53 UTC',
      'issue_db_id' => issue.id
    )
  end

  let(:expected_event_attrs) do
    {
      project_id: project.id,
      author_id: user.id,
      target_id: issue.id,
      target_type: Issue.name,
      action: 'reopened',
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  let(:expected_state_event_attrs) do
    {
      user_id: user.id,
      state: 'reopened',
      created_at: issue_event.created_at
    }.stringify_keys
  end

  it 'creates expected event and state event' do
    importer.execute(issue_event)

    expect(issue.events.count).to eq 1
    expect(issue.events[0].attributes)
      .to include expected_event_attrs

    expect(issue.resource_state_events.count).to eq 1
    expect(issue.resource_state_events[0].attributes)
      .to include expected_state_event_attrs
  end
end
