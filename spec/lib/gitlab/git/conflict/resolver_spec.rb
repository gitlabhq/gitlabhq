# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::Conflict::Resolver do
  let(:repository) { instance_double(Gitlab::Git::Repository) }
  let(:our_commit_oid) { 'our-commit-oid' }
  let(:their_commit_oid) { 'their-commit-oid' }
  let(:gitaly_conflicts_client) { instance_double(Gitlab::GitalyClient::ConflictsService) }

  subject(:resolver) { described_class.new(repository, our_commit_oid, their_commit_oid) }

  describe '#conflicts' do
    before do
      allow(repository).to receive(:gitaly_conflicts_client).and_return(gitaly_conflicts_client)
    end

    it 'returns list of conflicts' do
      conflicts = [double]

      expect(gitaly_conflicts_client).to receive(:list_conflict_files).and_return(conflicts)
      expect(resolver.conflicts).to eq(conflicts)
    end

    context 'when GRPC::FailedPrecondition is raised' do
      it 'rescues and raises Gitlab::Git::Conflict::Resolver::ConflictSideMissing' do
        expect(gitaly_conflicts_client).to receive(:list_conflict_files).and_raise(GRPC::FailedPrecondition)
        expect { resolver.conflicts }.to raise_error(Gitlab::Git::Conflict::Resolver::ConflictSideMissing)
      end
    end
  end
end
