# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::BlobService do
  let(:project) { create(:project, :repository) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:repository) { project.repository }
  let(:client) { described_class.new(repository) }

  describe '#get_new_lfs_pointers' do
    let(:revision) { 'master' }
    let(:limit) { 5 }
    let(:not_in) { %w[branch-a branch-b] }
    let(:expected_params) do
      { revisions: ["master", "--not", "branch-a", "branch-b"], limit: limit }
    end

    subject { client.get_new_lfs_pointers(revision, limit, not_in) }

    it 'sends a get_new_lfs_pointers message' do
      expect_any_instance_of(Gitaly::BlobService::Stub)
        .to receive(:list_lfs_pointers)
        .with(gitaly_request_with_params(expected_params), kind_of(Hash))
        .and_return([])

      subject
    end

    context 'with not_in = :all' do
      let(:not_in) { :all }
      let(:expected_params) do
        { revisions: ["master", "--not", "--all"], limit: limit }
      end

      it 'sends the correct message' do
        expect_any_instance_of(Gitaly::BlobService::Stub)
          .to receive(:list_lfs_pointers)
          .with(gitaly_request_with_params(expected_params), kind_of(Hash))
          .and_return([])

        subject
      end
    end

    context 'with hook environment' do
      let(:git_env) do
        {
          'GIT_OBJECT_DIRECTORY_RELATIVE' => '.git/objects',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => ['/dir/one', '/dir/two']
        }
      end

      let(:expected_params) do
        expected_repository = repository.gitaly_repository
        expected_repository.git_alternate_object_directories = Google::Protobuf::RepeatedField.new(:string)

        { limit: limit, repository: expected_repository }
      end

      it 'sends a list_all_lfs_pointers message' do
        allow(Gitlab::Git::HookEnv).to receive(:all).with(repository.gl_repository).and_return(git_env)

        expect_any_instance_of(Gitaly::BlobService::Stub)
          .to receive(:list_all_lfs_pointers)
          .with(gitaly_request_with_params(expected_params), kind_of(Hash))
          .and_return([])

        subject
      end
    end
  end

  describe '#get_all_lfs_pointers' do
    let(:expected_params) do
      { revisions: ["--all"], limit: 0 }
    end

    subject { client.get_all_lfs_pointers }

    it 'sends a get_all_lfs_pointers message' do
      expect_any_instance_of(Gitaly::BlobService::Stub)
        .to receive(:list_lfs_pointers)
        .with(gitaly_request_with_params(expected_params), kind_of(Hash))
        .and_return([])

      subject
    end
  end

  describe '#list_blobs' do
    let(:limit) { 0 }
    let(:bytes_limit) { 0 }
    let(:expected_params) { { revisions: revisions, limit: limit, bytes_limit: bytes_limit } }

    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    subject { client.list_blobs(revisions, limit: limit, bytes_limit: bytes_limit) }

    context 'with a single revision' do
      let(:revisions) { ['master'] }

      it 'sends a list_blobs message' do
        expect_next_instance_of(Gitaly::BlobService::Stub) do |service|
          expect(service)
            .to receive(:list_blobs)
            .with(gitaly_request_with_params(expected_params), kind_of(Hash))
            .and_return([])
        end

        subject
      end
    end

    context 'with multiple revisions' do
      let(:revisions) { ['master', '--not', '--all'] }

      it 'sends a list_blobs message' do
        expect_next_instance_of(Gitaly::BlobService::Stub) do |service|
          expect(service)
            .to receive(:list_blobs)
            .with(gitaly_request_with_params(expected_params), kind_of(Hash))
            .and_return([])
        end

        subject
      end
    end

    context 'with multiple revisions and limits' do
      let(:revisions) { ['master', '--not', '--all'] }
      let(:limit) { 10 }
      let(:bytes_lmit) { 1024 }

      it 'sends a list_blobs message' do
        expect_next_instance_of(Gitaly::BlobService::Stub) do |service|
          expect(service)
            .to receive(:list_blobs)
            .with(gitaly_request_with_params(expected_params), kind_of(Hash))
            .and_return([])
        end

        subject
      end
    end

    context 'with split contents' do
      let(:revisions) { ['master'] }

      it 'sends a list_blobs message', :aggregate_failures do
        expect_next_instance_of(Gitaly::BlobService::Stub) do |service|
          expect(service)
            .to receive(:list_blobs)
            .with(gitaly_request_with_params(expected_params), kind_of(Hash))
            .and_return([
              Gitaly::ListBlobsResponse.new(blobs: [
                Gitaly::ListBlobsResponse::Blob.new(oid: "012345", size: 8, data: "0x01"),
                Gitaly::ListBlobsResponse::Blob.new(data: "23")
              ]),
              Gitaly::ListBlobsResponse.new(blobs: [
                Gitaly::ListBlobsResponse::Blob.new(data: "45"),
                Gitaly::ListBlobsResponse::Blob.new(oid: "56", size: 4, data: "0x5"),
                Gitaly::ListBlobsResponse::Blob.new(data: "6")
              ]),
              Gitaly::ListBlobsResponse.new(blobs: [
                Gitaly::ListBlobsResponse::Blob.new(oid: "78", size: 4, data: "0x78")
              ])
            ])
        end

        blobs = subject.to_a
        expect(blobs.size).to be(3)

        expect(blobs[0].id).to eq('012345')
        expect(blobs[0].size).to eq(8)
        expect(blobs[0].data).to eq('0x012345')

        expect(blobs[1].id).to eq('56')
        expect(blobs[1].size).to eq(4)
        expect(blobs[1].data).to eq('0x56')

        expect(blobs[2].id).to eq('78')
        expect(blobs[2].size).to eq(4)
        expect(blobs[2].data).to eq('0x78')
      end
    end
  end
end
