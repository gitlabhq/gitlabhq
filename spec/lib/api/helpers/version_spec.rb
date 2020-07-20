# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Version do
  describe '.new' do
    it 'is possible to initialize it with existing API version' do
      expect(described_class.new('v4').to_s).to eq 'v4'
    end

    it 'raises an error when unsupported API version is provided' do
      expect { described_class.new('v111') }.to raise_error ArgumentError
    end
  end

  describe '#root_path' do
    it 'returns a root path of the API version' do
      expect(described_class.new('v4').root_path).to eq '/api/v4'
    end
  end

  describe '#root_url' do
    it 'returns an URL for a root path for the API version' do
      expect(described_class.new('v4').root_url)
        .to eq 'http://localhost/api/v4'
    end
  end
end
