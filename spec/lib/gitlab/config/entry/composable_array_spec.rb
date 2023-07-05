# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::ComposableArray, :aggregate_failures do
  let(:valid_config) do
    [
      {
        DATABASE_SECRET: 'passw0rd'
      },
      {
        API_TOKEN: 'passw0rd2'
      }
    ]
  end

  let(:config) { valid_config }
  let(:entry) { described_class.new(config) }

  before do
    allow(entry).to receive(:composable_class).and_return(Gitlab::Config::Entry::Node)
  end

  describe '#valid?' do
    it 'is valid' do
      expect(entry).to be_valid
    end

    context 'is invalid' do
      let(:config) { { hello: :world } }

      it { expect(entry).not_to be_valid }
    end
  end

  describe '#compose!' do
    before do
      entry.compose!
    end

    it 'composes child entry with configured value' do
      expect(entry.value).to eq(config)
    end

    it 'composes child entries with configured values' do
      expect(entry[0]).to be_a(Gitlab::Config::Entry::Node)
      expect(entry[0].description).to eq('node definition')
      expect(entry[0].key).to eq('node')
      expect(entry[0].metadata).to eq({})
      expect(entry[0].parent.class).to eq(described_class)
      expect(entry[0].value).to eq(DATABASE_SECRET: 'passw0rd')
      expect(entry[1]).to be_a(Gitlab::Config::Entry::Node)
      expect(entry[1].description).to eq('node definition')
      expect(entry[1].key).to eq('node')
      expect(entry[1].metadata).to eq({})
      expect(entry[1].parent.class).to eq(described_class)
      expect(entry[1].value).to eq(API_TOKEN: 'passw0rd2')
    end

    describe '#descendants' do
      it 'creates descendant nodes' do
        expect(entry.descendants.first).to be_a(Gitlab::Config::Entry::Node)
        expect(entry.descendants.first.value).to eq(DATABASE_SECRET: 'passw0rd')
        expect(entry.descendants.second).to be_a(Gitlab::Config::Entry::Node)
        expect(entry.descendants.second.value).to eq(API_TOKEN: 'passw0rd2')
      end
    end
  end
end
