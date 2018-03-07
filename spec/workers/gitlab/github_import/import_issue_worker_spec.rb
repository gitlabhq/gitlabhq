require 'spec_helper'

describe Gitlab::GithubImport::ImportIssueWorker do
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports an issue' do
      project = double(:project, full_path: 'foo/bar')
      client = double(:client)
      importer = double(:importer)
      hash = {
        'iid' => 42,
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

      expect(worker.counter)
        .to receive(:increment)
        .with(project: 'foo/bar')
        .and_call_original

      worker.import(project, client, hash)
    end
  end
end
