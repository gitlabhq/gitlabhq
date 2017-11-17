require 'spec_helper'

describe Gitlab::GithubImport::Representation do
  describe '.symbolize_hash' do
    it 'returns a Hash with the keys as Symbols' do
      hash = described_class.symbolize_hash('number' => 10)

      expect(hash).to eq({ number: 10 })
    end

    it 'parses timestamp fields into Time instances' do
      hash = described_class.symbolize_hash('created_at' => '2017-01-01 12:00')

      expect(hash[:created_at]).to be_an_instance_of(Time)
    end
  end
end
