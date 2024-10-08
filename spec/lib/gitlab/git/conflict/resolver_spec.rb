# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::Conflict::Resolver do
  let(:repository) { instance_double(Gitlab::Git::Repository) }
  let(:our_commit_oid) { 'our-commit-oid' }
  let(:their_commit_oid) { 'their-commit-oid' }
  let(:gitaly_conflicts_client) { instance_double(Gitlab::GitalyClient::ConflictsService) }
  let(:allow_tree_conflicts) { false }
  let(:skip_content) { false }

  subject(:resolver) do
    described_class.new(
      repository,
      our_commit_oid,
      their_commit_oid,
      allow_tree_conflicts: allow_tree_conflicts,
      skip_content: skip_content
    )
  end

  describe '#conflicts' do
    let(:conflicts) { [double] }

    before do
      allow(repository).to receive(:gitaly_conflicts_client).and_return(gitaly_conflicts_client)
    end

    it 'returns list of conflicts' do
      expect(gitaly_conflicts_client)
        .to receive(:list_conflict_files)
        .with(allow_tree_conflicts: false, skip_content: false)
        .and_return(conflicts)

      expect(resolver.conflicts).to eq(conflicts)
    end

    context 'when allow_tree_conflicts is set to true' do
      let(:allow_tree_conflicts) { true }

      it 'returns list of conflicts with allow_tree_conflicts as true' do
        expect(gitaly_conflicts_client)
          .to receive(:list_conflict_files)
          .with(allow_tree_conflicts: true, skip_content: false)
          .and_return(conflicts)

        expect(resolver.conflicts).to eq(conflicts)
      end
    end

    context 'when skip_content is set to true' do
      let(:skip_content) { true }

      it 'returns list of conflicts with skip_content as true' do
        expect(gitaly_conflicts_client)
          .to receive(:list_conflict_files)
          .with(allow_tree_conflicts: false, skip_content: true)
          .and_return(conflicts)

        expect(resolver.conflicts).to eq(conflicts)
      end
    end

    context 'when GRPC::FailedPrecondition is raised' do
      it 'rescues and raises Gitlab::Git::Conflict::Resolver::ConflictSideMissing' do
        expect(gitaly_conflicts_client).to receive(:list_conflict_files).and_raise(GRPC::FailedPrecondition)
        expect { resolver.conflicts }.to raise_error(Gitlab::Git::Conflict::Resolver::ConflictSideMissing)
      end
    end
  end
end
