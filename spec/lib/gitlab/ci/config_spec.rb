require 'spec_helper'

describe Gitlab::Ci::Config do
  let(:config) do
    described_class.new(yml)
  end

  context 'when config is valid' do
    let(:yml) do
      <<-EOS
        image: ruby:2.2

        rspec:
          script:
            - gem install rspec
            - rspec
      EOS
    end

    describe '#to_hash' do
      it 'returns hash created from string' do
        hash = {
          image: 'ruby:2.2',
          rspec: {
            script: ['gem install rspec',
                     'rspec']
          }
        }

        expect(config.to_hash).to eq hash
      end
    end

    context 'when config is invalid' do
      let(:yml) { '// invalid' }

      describe '.new' do
        it 'raises error' do
          expect { config }.to raise_error(
            Gitlab::Ci::Config::Loader::FormatError,
            /Invalid configuration format/
          )
        end
      end
    end
  end
end
