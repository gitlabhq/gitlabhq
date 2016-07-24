require 'spec_helper'

describe RepositoryCache, lib: true do
  let(:project) { create(:project) }
  let(:backend) { double('backend').as_null_object }
  let(:cache) { RepositoryCache.new('example', project.id, backend) }

  describe '#cache_key' do
    it 'includes the namespace' do
      expect(cache.cache_key(:foo)).to eq "foo:example:#{project.id}"
    end
  end

  describe '#expire' do
    it 'expires the given key from the cache' do
      cache.expire(:foo)
      expect(backend).to have_received(:delete).with("foo:example:#{project.id}")
    end
  end

  describe '#fetch' do
    it 'fetches the given key from the cache' do
      cache.fetch(:bar)
      expect(backend).to have_received(:fetch).with("bar:example:#{project.id}")
    end

    it 'accepts a block' do
      p = -> {}

      cache.fetch(:baz, &p)
      expect(backend).to have_received(:fetch).with("baz:example:#{project.id}", &p)
    end
  end
end
