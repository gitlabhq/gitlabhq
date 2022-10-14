# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::IssuableFinder, :clean_gitlab_redis_cache do
  let(:project) { double(:project, id: 4, import_data: import_data) }
  let(:single_endpoint_optional_stage) { false }
  let(:import_data) do
    instance_double(
      ProjectImportData,
      data: {
        optional_stages: {
          single_endpoint_notes_import: single_endpoint_optional_stage
        }
      }.deep_stringify_keys
    )
  end

  let(:issue) { double(:issue, issuable_type: MergeRequest, issuable_id: 1) }
  let(:finder) { described_class.new(project, issue) }

  describe '#database_id' do
    it 'returns nil when no cache is in place' do
      expect(finder.database_id).to be_nil
    end

    it 'returns the ID of an issuable when the cache is in place' do
      finder.cache_database_id(10)

      expect(finder.database_id).to eq(10)
    end

    it 'raises TypeError when the object is not supported' do
      finder = described_class.new(project, double(:issue))

      expect { finder.database_id }.to raise_error(TypeError)
    end

    context 'when group is present' do
      context 'when settings single_endpoint_notes_import is enabled' do
        let(:single_endpoint_optional_stage) { true }

        it 'reads cache value with longer timeout' do
          expect(Gitlab::Cache::Import::Caching)
            .to receive(:read)
            .with(anything, timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT)

          described_class.new(project, issue).database_id
        end
      end

      context 'when settings single_endpoint_notes_import is disabled' do
        it 'reads cache value with default timeout' do
          expect(Gitlab::Cache::Import::Caching)
            .to receive(:read)
            .with(anything, timeout: Gitlab::Cache::Import::Caching::TIMEOUT)

          described_class.new(project, issue).database_id
        end
      end
    end
  end

  describe '#cache_database_id' do
    it 'caches the ID of a database row' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with('github-import/issuable-finder/4/MergeRequest/1', 10, timeout: 86400)

      finder.cache_database_id(10)
    end

    context 'when settings single_endpoint_notes_import is enabled' do
      let(:single_endpoint_optional_stage) { true }

      it 'caches value with longer timeout' do
        expect(Gitlab::Cache::Import::Caching)
          .to receive(:write)
          .with(anything, anything, timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT)

        described_class.new(project, issue).cache_database_id(10)
      end
    end

    context 'when settings single_endpoint_notes_import is disabled' do
      it 'caches value with default timeout' do
        expect(Gitlab::Cache::Import::Caching)
          .to receive(:write)
          .with(anything, anything, timeout: Gitlab::Cache::Import::Caching::TIMEOUT)

        described_class.new(project, issue).cache_database_id(10)
      end
    end
  end
end
