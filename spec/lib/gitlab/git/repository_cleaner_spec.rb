# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::RepositoryCleaner, feature_category: :source_code_management do
  include HttpIOHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:head_sha) { repository.head_commit.id }
  let(:object_map_data) { "#{head_sha} #{Gitlab::Git::SHA1_BLANK_SHA}" }

  let(:clean_refs) { %W[refs/environments/1 refs/merge-requests/1 refs/keep-around/#{head_sha}] }
  let(:keep_refs) { %w[refs/heads/_keep refs/tags/_keep] }

  subject(:cleaner) { described_class.new(repository.raw) }

  shared_examples_for '#apply_bfg_object_map_stream' do
    before do
      (clean_refs + keep_refs).each { |ref| repository.create_ref(head_sha, ref) }
    end

    it 'removes internal references' do
      entries = []

      cleaner.apply_bfg_object_map_stream(object_map) do |rsp|
        entries.concat(rsp.entries)
      end

      aggregate_failures do
        clean_refs.each { |ref| expect(repository.ref_exists?(ref)).to be(false) }
        keep_refs.each { |ref| expect(repository.ref_exists?(ref)).to be(true) }

        expect(entries).to contain_exactly(
          Gitaly::ApplyBfgObjectMapStreamResponse::Entry.new(
            type: :COMMIT,
            old_oid: head_sha,
            new_oid: Gitlab::Git::SHA1_BLANK_SHA
          )
        )
      end
    end
  end

  describe '#apply_bfg_object_map_stream (from StringIO)' do
    let(:object_map) { StringIO.new(object_map_data) }

    include_examples '#apply_bfg_object_map_stream'
  end

  describe '#apply_bfg_object_map_stream (from Gitlab::HttpIO)' do
    let(:url) { 'http://example.com/bfg_object_map.txt' }
    let(:tempfile) { Tempfile.new }
    let(:object_map) { Gitlab::HttpIO.new(url, object_map_data.size) }

    around do |example|
      tempfile.write(object_map_data)
      tempfile.close

      stub_remote_url_200(url, tempfile.path)

      example.run
    ensure
      tempfile.unlink
    end

    include_examples '#apply_bfg_object_map_stream'
  end

  describe '#rewrite_history' do
    subject(:rewrite_history) { cleaner.rewrite_history(blobs: blobs, redactions: redactions) }

    let_it_be(:project) { create(:project, :empty_repo) }
    let(:blobs) { ['53855584db773c3df5b5f61f72974cb298822fbb'] }
    let(:redactions) { %w[hello world] }

    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    it 'rewrites repository history' do
      expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
        expect(instance).to receive(:rewrite_history)
          .with(array_including(
            gitaly_request_with_params(blobs: blobs),
            gitaly_request_with_params(redactions: redactions)
          ), kind_of(Hash))
          .and_return(Gitaly::RewriteHistoryResponse.new)
      end

      expect(rewrite_history).to eq(Gitaly::RewriteHistoryResponse.new)
    end

    context 'when Gitaly returns an error' do
      let(:generic_error) do
        GRPC::BadStatus.new(
          GRPC::Core::StatusCodes::FAILED_PRECONDITION,
          "error message"
        )
      end

      it 'wraps the error' do
        expect_next_instance_of(Gitaly::CleanupService::Stub) do |instance|
          expect(instance).to receive(:rewrite_history)
            .with(array_including(
              gitaly_request_with_params(blobs: blobs),
              gitaly_request_with_params(redactions: redactions)
            ), kind_of(Hash))
            .and_raise(generic_error)
        end

        expect { rewrite_history }.to raise_error(Gitlab::Git::CommandError)
      end
    end

    context 'when blobs and redactions are missing' do
      let(:blobs) { [] }
      let(:redactions) { [] }

      it 'returns an ArgumentError' do
        expect { rewrite_history }.to raise_error(ArgumentError)
      end
    end
  end
end
