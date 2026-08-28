# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::IssuableFinder, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project) { build(:project, id: 20) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:issue) { double(:issue, issuable_type: 'MergeRequest', issuable_id: merge_request.iid) }
  let(:finder) { described_class.new(project, issue) }

  describe '#database_id' do
    it 'returns nil if object does not exist' do
      missing_issue = double(:issue, issuable_type: 'MergeRequest', issuable_id: 999)

      expect(described_class.new(project, missing_issue).database_id).to be_nil
    end

    it 'fetches object id from database if not in cache' do
      expect(finder.database_id).to eq(merge_request.id)
    end

    it 'fetches object id from cache if present' do
      finder.cache_database_id(10)

      expect(finder.database_id).to eq(10)
    end

    it 'returns nil and skips database read if cache has no record' do
      finder.cache_database_id(-1)

      expect(finder.database_id).to be_nil
    end

    it 'raises TypeError when the object is not supported' do
      finder = described_class.new(project, double(:issue))

      expect { finder.database_id }.to raise_error(TypeError)
    end

    context 'when group is present' do
      # single_endpoint_notes_import is hardcoded to enabled in Settings#write for new imports,
      # so these contexts stub Settings#enabled? directly to keep the disabled branch (kept as a
      # rollback safety net) covered even though it's currently unreachable in production.
      context 'when settings single_endpoint_notes_import is enabled' do
        before do
          allow_next_instance_of(Gitlab::GithubImport::Settings) do |settings|
            allow(settings).to receive(:enabled?).with(:single_endpoint_notes_import).and_return(true)
          end
        end

        it 'reads cache value with longer timeout' do
          expect(Gitlab::Cache::Import::Caching)
            .to receive(:read)
            .with(anything, timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT, refresh: true)

          described_class.new(project, issue).database_id
        end
      end

      context 'when settings single_endpoint_notes_import is disabled' do
        before do
          allow_next_instance_of(Gitlab::GithubImport::Settings) do |settings|
            allow(settings).to receive(:enabled?).with(:single_endpoint_notes_import).and_return(false)
          end
        end

        it 'reads cache value with default timeout' do
          expect(Gitlab::Cache::Import::Caching)
            .to receive(:read)
            .with(anything, timeout: Gitlab::Cache::Import::Caching::TIMEOUT, refresh: true)

          described_class.new(project, issue).database_id
        end
      end
    end
  end

  describe '#cache_database_id' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::Settings) do |settings|
        allow(settings).to receive(:enabled?).with(:single_endpoint_notes_import).and_return(false)
      end
    end

    it 'caches the ID of a database row' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with("github-import/issuable-finder/20/MergeRequest/#{merge_request.iid}", 10, timeout: 86400)

      finder.cache_database_id(10)
    end

    context 'when settings single_endpoint_notes_import is enabled' do
      before do
        allow_next_instance_of(Gitlab::GithubImport::Settings) do |settings|
          allow(settings).to receive(:enabled?).with(:single_endpoint_notes_import).and_return(true)
        end
      end

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
