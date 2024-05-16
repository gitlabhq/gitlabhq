# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::MilestoneFinder, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:finder) { described_class.new(project) }

  describe '#id_for' do
    let(:issuable) { double(:issuable, milestone_number: milestone.iid) }

    context 'with a cache in place' do
      before do
        finder.build_cache
      end

      it 'returns the milestone ID of the given issuable' do
        expect(finder.id_for(issuable)).to eq(milestone.id)
      end

      it 'returns nil if object does not exist' do
        missing_issuable = double(:issuable, milestone_number: 999)

        expect(finder.id_for(missing_issuable)).to be_nil
      end

      it 'fetches object id from database if not in cache' do
        key = finder.cache_key_for(milestone.iid)

        Gitlab::Cache::Import::Caching.write(key, '')

        expect(finder.id_for(issuable)).to eq(milestone.id)
      end

      it 'returns nil for an issuable with a non-existing milestone' do
        expect(finder.id_for(double(:issuable, milestone_number: 5))).to be_nil
      end

      it 'returns nil and skips database read if cache has no record' do
        key = finder.cache_key_for(milestone.iid)

        Gitlab::Cache::Import::Caching.write(key, -1)

        expect(finder.id_for(issuable)).to be_nil
      end
    end

    context 'without a cache in place' do
      it 'caches the ID of a database row and returns the ID' do
        expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with("github-import/milestone-finder/#{project.id}/1", milestone.id)
        .and_call_original

        expect(finder.id_for(issuable)).to eq(milestone.id)
      end
    end
  end

  describe '#build_cache' do
    it 'builds the cache of all project milestones' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write_multiple)
        .with({ "github-import/milestone-finder/#{project.id}/1" => milestone.id })
        .and_call_original

      finder.build_cache
    end
  end

  describe '#cache_key_for' do
    it 'returns the cache key for an IID' do
      expect(finder.cache_key_for(10))
        .to eq("github-import/milestone-finder/#{project.id}/10")
    end
  end
end
