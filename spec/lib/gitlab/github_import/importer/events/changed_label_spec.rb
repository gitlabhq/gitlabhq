# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedLabel do
  subject(:importer) { described_class.new(project, user_finder) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:user_finder) { Gitlab::GithubImport::UserFinder.new(project, client) }
  let(:issue) { create(:issue, project: project) }
  let!(:label) { create(:label, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => event_type,
      'commit_id' => nil,
      'label_title' => label.title,
      'issue_db_id' => issue.id,
      'created_at' => '2022-04-26 18:30:53 UTC'
    )
  end

  let(:event_attrs) do
    {
      user_id: user.id,
      issue_id: issue.id,
      label_id: label.id,
      created_at: issue_event.created_at
    }.stringify_keys
  end

  shared_examples 'new event' do
    it 'creates a new label event' do
      expect { importer.execute(issue_event) }.to change { issue.resource_label_events.count }
        .from(0).to(1)
      expect(issue.resource_label_events.last)
        .to have_attributes(expected_event_attrs)
    end
  end

  before do
    allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(label.id)
    allow(user_finder).to receive(:find).with(user.id, user.username).and_return(user.id)
  end

  context 'when importing a labeled event' do
    let(:event_type) { 'labeled' }
    let(:expected_event_attrs) { event_attrs.merge(action: 'add') }

    it_behaves_like 'new event'
  end

  context 'when importing an unlabeled event' do
    let(:event_type) { 'unlabeled' }
    let(:expected_event_attrs) { event_attrs.merge(action: 'remove') }

    it_behaves_like 'new event'
  end
end
