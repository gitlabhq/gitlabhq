# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Git::RepositoryCleaner do
  include HttpIOHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:head_sha) { repository.head_commit.id }
  let(:object_map_data) { "#{head_sha} #{Gitlab::Git::BLANK_SHA}" }

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
            new_oid: Gitlab::Git::BLANK_SHA
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
end
