require 'spec_helper'

describe Gitlab::Ci::Config::Node::Environment do
  let(:entry) { described_class.new(config) }

  before { entry.compose! }

  context 'when configuration is a string' do
    let(:config) { 'production' }

    describe '#string?' do
      it 'is string configuration' do
        expect(entry).to be_string
      end
    end

    describe '#hash?' do
      it 'is not hash configuration' do
        expect(entry).not_to be_hash
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to eq(name: 'production')
      end
    end

    describe '#name' do
      it 'returns environment name' do
        expect(entry.name).to eq 'production'
      end
    end

    describe '#url' do
      it 'returns environment url' do
        expect(entry.url).to be_nil
      end
    end
  end

  context 'when configuration is a hash' do
    let(:config) do
      { name: 'development', url: 'https://example.gitlab.com' }
    end

    describe '#string?' do
      it 'is not string configuration' do
        expect(entry).not_to be_string
      end
    end

    describe '#hash?' do
      it 'is hash configuration' do
        expect(entry).to be_hash
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to eq config
      end
    end

    describe '#name' do
      it 'returns environment name' do
        expect(entry.name).to eq 'development'
      end
    end

    describe '#url' do
      it 'returns environment url' do
        expect(entry.url).to eq 'https://example.gitlab.com'
      end
    end
  end

  context 'when variables are used for environment' do
    let(:config) do
      { name: 'review/$CI_BUILD_REF_NAME',
        url: 'https://$CI_BUILD_REF_NAME.review.gitlab.com' }
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  context 'when close is used' do
    context 'when close is a boolean' do
      let(:config) do
        { name: 'review/$CI_BUILD_REF_NAME',
          close: true }
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when close is a string' do
      let(:config) do
        { name: 'review/$CI_BUILD_REF_NAME',
          close: 'string' }
      end

      describe '#valid?' do
        it 'is invalid' do
          expect(entry).not_to be_valid
        end
      end
    end
  end

  context 'when configuration is invalid' do
    context 'when configuration is an array' do
      let(:config) { ['env'] }

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end

      describe '#errors' do
        it 'contains error about invalid type' do
          expect(entry.errors)
            .to include 'environment config should be a hash or a string'
        end
      end
    end

    context 'when environment name is not present' do
      let(:config) { { url: 'https://example.gitlab.com' } }

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end

      describe '#errors?' do
        it 'contains error about missing environment name' do
          expect(entry.errors)
            .to include "environment name can't be blank"
        end
      end
    end

    context 'when invalid URL is used' do
      let(:config) { { name: 'test', url: 'invalid-example.gitlab.com' } }

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end

      describe '#errors?' do
        it 'contains error about invalid URL' do
          expect(entry.errors)
            .to include "environment url must be a valid url"
        end
      end
    end
  end
end
