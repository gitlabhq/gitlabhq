# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportPullRequestWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports a pull request' do
      import_state = create(:import_state, :started)
      project = double(:project, full_path: 'foo/bar', id: 1, import_state: import_state)
      client = double(:client)
      importer = double(:importer)
      hash = {
        'iid' => 42,
        'github_id' => 42,
        'title' => 'My Pull Request',
        'description' => 'This is my pull request',
        'source_branch' => 'my-feature',
        'source_branch_sha' => '123abc',
        'target_branch' => 'master',
        'target_branch_sha' => '456def',
        'source_repository_id' => 400,
        'target_repository_id' => 200,
        'source_repository_owner' => 'alice',
        'state' => 'closed',
        'milestone_number' => 4,
        'user' => { 'id' => 4, 'login' => 'alice' },
        'assignee' => { 'id' => 4, 'login' => 'alice' },
        'created_at' => Time.zone.now.to_s,
        'updated_at' => Time.zone.now.to_s,
        'merged_at' => Time.zone.now.to_s
      }

      expect(Gitlab::GithubImport::Importer::PullRequestImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::PullRequest),
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

    describe '#importer_class' do
      it { expect(worker.importer_class).to eq Gitlab::GithubImport::Importer::PullRequestImporter }
    end

    describe '#representation_class' do
      it { expect(worker.representation_class).to eq Gitlab::GithubImport::Representation::PullRequest }
    end

    describe '#object_type' do
      it { expect(worker.object_type).to eq(:pull_request) }
    end

    describe '#parallel_import_batch' do
      it { expect(worker.parallel_import_batch).to eq({ size: 200, delay: 1.minute }) }
    end
  end
end
