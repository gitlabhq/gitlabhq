require 'spec_helper'

describe Gitlab::RepositoryCacheAdapter do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:cache) { repository.send(:cache) }

  describe '#cache_method_output', :use_clean_rails_memory_store_caching do
    let(:fallback) { 10 }

    context 'with a non-existing repository' do
      let(:project) { create(:project) } # No repository

      subject do
        repository.cache_method_output(:cats, fallback: fallback) do
          repository.cats_call_stub
        end
      end

      it 'returns the fallback value' do
        expect(subject).to eq(fallback)
      end

      it 'avoids calling the original method' do
        expect(repository).not_to receive(:cats_call_stub)

        subject
      end
    end

    context 'with a method throwing a non-existing-repository error' do
      subject do
        repository.cache_method_output(:cats, fallback: fallback) do
          raise Gitlab::Git::Repository::NoRepository
        end
      end

      it 'returns the fallback value' do
        expect(subject).to eq(fallback)
      end

      it 'does not cache the data' do
        subject

        expect(repository.instance_variable_defined?(:@cats)).to eq(false)
        expect(cache.exist?(:cats)).to eq(false)
      end
    end

    context 'with an existing repository' do
      it 'caches the output' do
        object = double

        expect(object).to receive(:number).once.and_return(10)

        2.times do
          val = repository.cache_method_output(:cats) { object.number }

          expect(val).to eq(10)
        end

        expect(repository.send(:cache).exist?(:cats)).to eq(true)
        expect(repository.instance_variable_get(:@cats)).to eq(10)
      end
    end
  end

  describe '#expire_method_caches' do
    it 'expires the caches of the given methods' do
      expect(cache).to receive(:expire).with(:readme)
      expect(cache).to receive(:expire).with(:gitignore)

      repository.expire_method_caches(%i(readme gitignore))
    end
  end
end
