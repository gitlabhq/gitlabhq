# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::PraefectInfoService do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:gitaly_repository) { repository.gitaly_repository }
  let(:client) { described_class.new(repository) }

  describe '#repository_replicas', :praefect do
    it 'sends an RPC request' do
      request = Gitaly::RepositoryReplicasRequest.new(repository: gitaly_repository)

      expect_any_instance_of(Gitaly::PraefectInfoService::Stub).to receive(:repository_replicas).with(request, kind_of(Hash))

      client.replicas
    end
  end
end
