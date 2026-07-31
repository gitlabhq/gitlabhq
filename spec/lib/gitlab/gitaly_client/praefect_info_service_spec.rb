# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::PraefectInfoService do
  let_it_be(:project) { create(:project, :small_repo) }
  let(:repository) { project.repository }
  let(:gitaly_repository) { repository.gitaly_repository }
  let(:client) { described_class.new(repository) }

  describe '#repository_replicas', :praefect do
    it 'sends an RPC request' do
      request = Gitaly::RepositoryReplicasRequest.new(repository: gitaly_repository)
      operation = instance_double(GRPC::ActiveCall::Operation,
        execute: Gitaly::RepositoryReplicasResponse.new,
        trailing_metadata: {})

      expect_any_instance_of(Gitaly::PraefectInfoService::Stub)
        .to receive(:repository_replicas).with(request, kind_of(Hash)).and_return(operation)

      client.replicas
    end
  end
end
