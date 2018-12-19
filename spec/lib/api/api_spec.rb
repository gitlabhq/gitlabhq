require 'spec_helper'

describe API::API do
  describe '.prefix' do
    it 'has a prefix defined' do
      expect(described_class.prefix).to eq :api
    end
  end

  describe '.version' do
    it 'uses most recent version of the API' do
      expect(described_class.version).to eq 'v4'
    end
  end

  describe '.versions' do
    it 'returns all available versions' do
      expect(described_class.versions).to eq ['v3', 'v4']
    end
  end

  describe '.root_path' do
    it 'returns predefined API version path' do
      expect(described_class.root_path).to eq '/api/v4'
    end

    it 'returns a version provided as keyword argument' do
      expect(described_class.root_path(version: 'v3')).to eq '/api/v3'
    end

    it 'raises an error if version is not known' do
      expect { described_class.root_path(version: 'v10') }
        .to raise_error ArgumentError
    end
  end
end
