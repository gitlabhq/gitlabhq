# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::RemoteCiSecureFiles, feature_category: :geo_replication do
  include_examples 'remote object storage cleaner' do
    let(:bucket_name) { 'ci_secure_files' }
    let(:model_class) { ::Ci::SecureFile }
    let(:stub_object_storage_uploader_for_cleaner) { stub_ci_secure_file_object_storage }
    let(:model_with_file) { create(:ci_secure_file, :remote_store) }
    let(:tracked_file_path) { model_with_file.file.path }
    let(:unknown_path_format_file_path) { 'foo/bar' }
    let(:untracked_valid_file_path) do
      "#{non_existing_project_hashed_path}/secure_files/#{non_existing_record_id}/secret.key"
    end
  end

  describe '#query_for_row_tracking_the_file' do
    let(:cleaner) { described_class.new }

    before do
      stub_ci_secure_file_object_storage
    end

    context 'with a tracked file' do
      it 'returns a relation that includes the file' do
        query = cleaner.send(:query_for_row_tracking_the_file, tracked_file_path)

        expect(query.exists?).to be true
      end
    end

    context 'with an untracked file' do
      # A legitimate path structure but with an unexpected filename
      it 'returns a relation that does not find any file' do
        query = cleaner.send(:query_for_row_tracking_the_file, "#{tracked_file_path}.foo")

        expect(query.exists?).to be false
      end
    end
  end

  describe '#expected_file_path_format_regexp' do
    let(:cleaner) { described_class.new }
    let(:regexp) { cleaner.send(:expected_file_path_format_regexp) }

    it 'validates correct secure file paths' do
      expect('4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce/secure_files/123/secret.key'
        .match?(regexp)).to be true
    end

    it 'rejects invalid file paths' do
      expect('invalid/path/format.key'
        .match?(regexp)).to be false
    end

    it 'rejects paths that are similar but different to valid paths to avoid data loss' do
      # Be conservative; do not delete unless you are very sure it's correct
      expect('4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce/' \
        'secure_files/123/another_segment/secret.key'
        .match?(regexp)).to be false
    end
  end
end
