require 'spec_helper'

describe Gitlab::GithubImport::MilestoneFinder, :clean_gitlab_redis_cache do
  let!(:project) { create(:project) }
  let!(:milestone) { create(:milestone, project: project) }
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

      it 'returns nil for an empty cache key' do
        key = finder.cache_key_for(milestone.iid)

        Gitlab::GithubImport::Caching.write(key, '')

        expect(finder.id_for(issuable)).to be_nil
      end

      it 'returns nil for an issuable with a non-existing milestone' do
        expect(finder.id_for(double(:issuable, milestone_number: 5))).to be_nil
      end
    end

    context 'without a cache in place' do
      it 'returns nil' do
        expect(finder.id_for(issuable)).to be_nil
      end
    end
  end

  describe '#build_cache' do
    it 'builds the cache of all project milestones' do
      expect(Gitlab::GithubImport::Caching)
        .to receive(:write_multiple)
        .with("github-import/milestone-finder/#{project.id}/1" => milestone.id)
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
