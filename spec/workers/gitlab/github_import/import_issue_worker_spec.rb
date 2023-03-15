# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportIssueWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports an issue' do
      import_state = create(:import_state, :started)
      project = double(:project, full_path: 'foo/bar', id: 1, import_state: import_state)
      client = double(:client)
      importer = double(:importer)
      hash = {
        'iid' => 42,
        'github_id' => 42,
        'title' => 'My Issue',
        'description' => 'This is my issue',
        'milestone_number' => 4,
        'state' => 'opened',
        'assignees' => [{ 'id' => 4, 'login' => 'alice' }],
        'label_names' => %w[bug],
        'user' => { 'id' => 4, 'login' => 'alice' },
        'created_at' => Time.zone.now.to_s,
        'updated_at' => Time.zone.now.to_s,
        'pull_request' => false
      }

      expect(Gitlab::GithubImport::Importer::IssueAndLabelLinksImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::Issue),
          project,
          client
        )
        .and_return(importer)

      expect(importer)
        .to receive(:execute)

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .and_call_original

      worker.import(project, client, hash)
    end
  end

  describe '#increment_object_counter?' do
    context 'when github issue is a pull request' do
      let(:issue) { double(:issue, pull_request?: true) }
      let(:project) { double(:project) }

      it 'returns false' do
        expect(worker).not_to be_increment_object_counter(issue)
      end
    end
  end
end
