require_relative '../../lib/repository_cache'

describe RepositoryCache, lib: true do
  let(:backend) { double('backend').as_null_object }
  let(:cache) { RepositoryCache.new('example', backend) }

  describe '#cache_key' do
    it 'includes the namespace' do
      expect(cache.cache_key(:foo)).to eq 'foo:example'
    end
  end

  describe '#expire' do
    it 'expires the given key from the cache' do
      cache.expire(:foo)
      expect(backend).to have_received(:delete).with('foo:example')
    end
  end

  describe '#fetch' do
    it 'fetches the given key from the cache' do
      cache.fetch(:bar)
      expect(backend).to have_received(:fetch).with('bar:example')
    end

    it 'accepts a block' do
      p = -> {}

      cache.fetch(:baz, &p)
      expect(backend).to have_received(:fetch).with('baz:example', &p)
    end
  end
end
