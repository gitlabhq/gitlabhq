require 'spec_helper'

describe Gitlab::GitalyClient::ConflictsService do
  let(:project) { create(:project, :repository) }
  let(:target_project) { create(:project, :repository) }
  let(:source_repository) { project.repository.raw }
  let(:target_repository) { target_project.repository.raw }
  let(:target_gitaly_repository) { target_repository.gitaly_repository }
  let(:our_commit_oid) { 'f00' }
  let(:their_commit_oid) { 'f44' }
  let(:client) do
    described_class.new(target_repository, our_commit_oid, their_commit_oid)
  end

  describe '#list_conflict_files' do
    let(:request) do
      Gitaly::ListConflictFilesRequest.new(
        repository: target_gitaly_repository, our_commit_oid: our_commit_oid,
        their_commit_oid: their_commit_oid
      )
    end
    let(:our_path) { 'our/path' }
    let(:their_path) { 'their/path' }
    let(:our_mode) { 0744 }
    let(:header) do
      double(repository: target_gitaly_repository, commit_oid: our_commit_oid,
             our_path: our_path, our_mode: 0744, their_path: their_path)
    end
    let(:response) do
      [
        double(files: [double(header: header), double(content: 'foo', header: nil)]),
        double(files: [double(content: 'bar', header: nil)])
      ]
    end
    let(:file) { subject[0] }

    subject { client.list_conflict_files }

    it 'sends an RPC request' do
      expect_any_instance_of(Gitaly::ConflictsService::Stub).to receive(:list_conflict_files)
        .with(request, kind_of(Hash)).and_return([])

      subject
    end

    it 'forms a Gitlab::Git::ConflictFile collection from the response' do
      allow_any_instance_of(Gitaly::ConflictsService::Stub).to receive(:list_conflict_files)
        .with(request, kind_of(Hash)).and_return(response)

      expect(subject.size).to be(1)
      expect(file.content).to eq('foobar')
      expect(file.their_path).to eq(their_path)
      expect(file.our_path).to eq(our_path)
      expect(file.our_mode).to be(our_mode)
      expect(file.repository).to eq(target_repository)
      expect(file.commit_oid).to eq(our_commit_oid)
    end
  end

  describe '#resolve_conflicts' do
    let(:user) { create(:user) }
    let(:files) do
      [{ old_path: 'some/path', new_path: 'some/path', content: '' }]
    end
    let(:source_branch) { 'master' }
    let(:target_branch) { 'feature' }
    let(:commit_message) { 'Solving conflicts' }
    let(:resolution) do
      Gitlab::Git::Conflict::Resolution.new(user, files, commit_message)
    end

    subject do
      client.resolve_conflicts(source_repository, resolution, source_branch, target_branch)
    end

    it 'sends an RPC request' do
      expect_any_instance_of(Gitaly::ConflictsService::Stub).to receive(:resolve_conflicts)
        .with(kind_of(Enumerator), kind_of(Hash)).and_return(double(resolution_error: ""))

      subject
    end

    it 'raises a relevant exception if resolution_error is present' do
      expect_any_instance_of(Gitaly::ConflictsService::Stub).to receive(:resolve_conflicts)
        .with(kind_of(Enumerator), kind_of(Hash)).and_return(double(resolution_error: "something happened"))

      expect { subject }.to raise_error(Gitlab::Git::Conflict::Resolver::ResolutionError)
    end
  end
end
