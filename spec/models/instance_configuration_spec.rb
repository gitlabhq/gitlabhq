require 'spec_helper'

RSpec.describe InstanceConfiguration do
  context 'without cache' do
    describe '#settings' do
      describe '#ssh_algorithms_hashes' do
        let(:md5) { '54:e0:f8:70:d6:4f:4c:b1:b3:02:44:77:cf:cd:0d:fc' }
        let(:sha256) { '9327f0d15a48c4d9f6a3aee65a1825baf9a3412001c98169c5fd022ac27762fc' }

        it 'does not return anything if file does not exist' do
          stub_pub_file(exist: false)

          expect(subject.settings[:ssh_algorithms_hashes]).to be_empty
        end

        it 'does not return anything if file is empty' do
          stub_pub_file

          allow(File).to receive(:read).and_return('')

          expect(subject.settings[:ssh_algorithms_hashes]).to be_empty
        end

        it 'returns the md5 and sha256 if file valid and exists' do
          stub_pub_file

          result = subject.settings[:ssh_algorithms_hashes].select { |o| o[:md5] == md5 && o[:sha256] == sha256 }

          expect(result.size).to eq(InstanceConfiguration::SSH_ALGORITHMS.size)
        end

        def stub_pub_file(exist: true)
          path = 'spec/fixtures/ssh_host_example_key.pub'
          path << 'random' unless exist
          allow(subject).to receive(:ssh_algorithm_file).and_return(Rails.root.join(path))
        end
      end

      describe '#host' do
        it 'returns current instance host' do
          allow(Settings.gitlab).to receive(:host).and_return('exampledomain')

          expect(subject.settings[:host]).to eq(Settings.gitlab.host)
        end
      end

      describe '#gitlab_pages' do
        let(:gitlab_pages) { subject.settings[:gitlab_pages] }
        it 'returns Settings.pages' do
          gitlab_pages.delete(:ip_address)

          expect(gitlab_pages).to eq(Settings.pages.symbolize_keys)
        end

        it 'returns the Gitlab\'s pages host ip address' do
          expect(gitlab_pages.keys).to include(:ip_address)
        end

        it 'returns the ip address as nil if the domain is invalid' do
          allow(Settings.pages).to receive(:host).and_return('exampledomain')

          expect(gitlab_pages[:ip_address]).to eq nil
        end

        it 'returns the ip address of the domain' do
          allow(Settings.pages).to receive(:host).and_return('localhost')

          expect(gitlab_pages[:ip_address]).to eq('127.0.0.1').or eq('::1')
        end
      end

      describe '#gitlab_ci' do
        let(:gitlab_ci) { subject.settings[:gitlab_ci] }
        it 'returns Settings.gitalb_ci' do
          gitlab_ci.delete(:artifacts_max_size)

          expect(gitlab_ci).to eq(Settings.gitlab_ci.symbolize_keys)
        end

        it 'returns the key artifacts_max_size' do
          expect(gitlab_ci.keys).to include(:artifacts_max_size)
        end
      end
    end
  end

  context 'with cache', :use_clean_rails_memory_store_caching do
    it 'caches settings content' do
      expect(Rails.cache.read(described_class::CACHE_KEY)).to be_nil

      settings = subject.settings

      expect(Rails.cache.read(described_class::CACHE_KEY)).to eq(settings)
    end

    describe 'cached settings' do
      before do
        subject.settings
      end

      it 'expires after EXPIRATION_TIME' do
        allow(Time).to receive(:now).and_return(Time.now + described_class::EXPIRATION_TIME)
        Rails.cache.cleanup

        expect(Rails.cache.read(described_class::CACHE_KEY)).to eq(nil)
      end
    end
  end
end
