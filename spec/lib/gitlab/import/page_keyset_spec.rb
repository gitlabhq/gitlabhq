# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::PageKeyset, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project) { instance_double(Project, id: 1) }
  let(:keyset) { described_class.new(project, :issues, 'bitbucket-import') }

  describe '#initialize' do
    it 'sets the initial next url to be nil when no value is cached' do
      expect(keyset.current).to eq(nil)
    end

    it 'sets the initial next url to the cached value when one is present' do
      Gitlab::Cache::Import::Caching.write(keyset.cache_key, 'https://example.com/nextpresent')

      expect(described_class.new(project, :issues, 'bitbucket-import').current).to eq('https://example.com/nextpresent')
    end
  end

  describe '#set' do
    it 'sets the next url' do
      keyset.set('https://example.com/next')
      expect(keyset.current).to eq('https://example.com/next')
    end
  end

  describe '#expire!' do
    it 'expires the current next url' do
      keyset.set('https://example.com/next')

      keyset.expire!

      expect(Gitlab::Cache::Import::Caching.read(keyset.cache_key)).to be_nil
      expect(keyset.current).to eq(nil)
    end
  end
end
