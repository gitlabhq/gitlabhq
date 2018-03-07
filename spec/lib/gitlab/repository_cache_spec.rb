require 'spec_helper'

describe Gitlab::RepositoryCache do
  let(:backend) { double('backend').as_null_object }
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:#{project.id}" }
  let(:cache) { described_class.new(repository, backend: backend) }

  describe '#cache_key' do
    subject { cache.cache_key(:foo) }

    it 'includes the namespace' do
      expect(subject).to eq "foo:#{namespace}"
    end

    context 'with a given namespace' do
      let(:extra_namespace) { 'my:data' }
      let(:cache) do
        described_class.new(repository, extra_namespace: extra_namespace,
                                        backend: backend)
      end

      it 'includes the full namespace' do
        expect(subject).to eq "foo:#{namespace}:#{extra_namespace}"
      end
    end
  end

  describe '#expire' do
    it 'expires the given key from the cache' do
      cache.expire(:foo)
      expect(backend).to have_received(:delete).with("foo:#{namespace}")
    end
  end

  describe '#fetch' do
    it 'fetches the given key from the cache' do
      cache.fetch(:bar)
      expect(backend).to have_received(:fetch).with("bar:#{namespace}")
    end

    it 'accepts a block' do
      p = -> {}

      cache.fetch(:baz, &p)
      expect(backend).to have_received(:fetch).with("baz:#{namespace}", &p)
    end
  end
end
