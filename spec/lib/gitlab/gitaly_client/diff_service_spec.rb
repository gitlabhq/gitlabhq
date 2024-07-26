# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::DiffService, feature_category: :gitaly do
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:repository_message) { repository.gitaly_repository }

  describe '#diff_blobs' do
    # SHAs used are from https://gitlab.com/gitlab-org/gitlab-test.
    let(:left_blob) { '1e292f8fedd741b75372e19097c76d327140c312' }
    let(:right_blob) { 'ddd0f15ae83993f5cb66a927a28673882e99100b' }
    let(:blob_pairs) do
      [
        Gitaly::DiffBlobsRequest::BlobPair.new(
          left_blob: left_blob,
          right_blob: right_blob
        )
      ]
    end

    subject(:diff_blobs) { described_class.new(repository).diff_blobs(blob_pairs) }

    it 'sends a RPC request' do
      request = Gitaly::DiffBlobsRequest.new(
        repository: repository_message,
        blob_pairs: blob_pairs
      )

      expect_any_instance_of(Gitaly::DiffService::Stub) do |instance|
        expect(instance).to receive(:diff_blobs)
          .with(request, kind_of(Hash))
      end

      diff_blobs
    end

    it 'returns a Gitlab::GitalyClient::DiffBlobsStitcher' do
      expect(diff_blobs).to be_kind_of(Gitlab::GitalyClient::DiffBlobsStitcher)
    end
  end
end
