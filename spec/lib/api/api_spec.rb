# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::API do
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
      expect(described_class.versions).to eq %w[v3 v4]
    end
  end
end
