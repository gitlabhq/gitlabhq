# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::ComposableHash, :aggregate_failures do
  let(:valid_config) do
    {
      DATABASE_SECRET: 'passw0rd',
      API_TOKEN: 'passw0rd2',
      ACCEPT_PASSWORD: false
    }
  end

  let(:config) { valid_config }

  shared_examples 'composes a hash' do
    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end

      context 'is invalid' do
        let(:config) { %w[one two] }

        it { expect(entry).not_to be_valid }
      end
    end

    describe '#value' do
      context 'when config is a hash' do
        it 'returns key value' do
          expect(entry.value).to eq config
        end
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
        expect(entry[:DATABASE_SECRET]).to be_a(Gitlab::Config::Entry::Node)
        expect(entry[:DATABASE_SECRET].description).to eq('DATABASE_SECRET node definition')
        expect(entry[:DATABASE_SECRET].key).to eq(:DATABASE_SECRET)
        expect(entry[:DATABASE_SECRET].metadata).to eq(name: :DATABASE_SECRET)
        expect(entry[:DATABASE_SECRET].parent.class).to eq(described_class)
        expect(entry[:DATABASE_SECRET].value).to eq('passw0rd')
        expect(entry[:API_TOKEN]).to be_a(Gitlab::Config::Entry::Node)
        expect(entry[:API_TOKEN].description).to eq('API_TOKEN node definition')
        expect(entry[:API_TOKEN].key).to eq(:API_TOKEN)
        expect(entry[:API_TOKEN].metadata).to eq(name: :API_TOKEN)
        expect(entry[:API_TOKEN].parent.class).to eq(described_class)
        expect(entry[:API_TOKEN].value).to eq('passw0rd2')
        expect(entry[:ACCEPT_PASSWORD]).to be_a(Gitlab::Config::Entry::Node)
        expect(entry[:ACCEPT_PASSWORD].description).to eq('ACCEPT_PASSWORD node definition')
        expect(entry[:ACCEPT_PASSWORD].key).to eq(:ACCEPT_PASSWORD)
        expect(entry[:ACCEPT_PASSWORD].metadata).to eq(name: :ACCEPT_PASSWORD)
        expect(entry[:ACCEPT_PASSWORD].parent.class).to eq(described_class)
        expect(entry[:ACCEPT_PASSWORD].value).to eq(false)
      end

      describe '#descendants' do
        it 'creates descendant nodes' do
          expect(entry.descendants.first).to be_a(Gitlab::Config::Entry::Node)
          expect(entry.descendants.first.value).to eq('passw0rd')
          expect(entry.descendants.second).to be_a(Gitlab::Config::Entry::Node)
          expect(entry.descendants.second.value).to eq('passw0rd2')
        end
      end
    end
  end

  context 'when ComposableHash is instantiated' do
    let(:entry) { described_class.new(config) }

    before do
      allow(entry).to receive(:composable_class).and_return(Gitlab::Config::Entry::Node)
    end

    it_behaves_like 'composes a hash'
  end

  context 'when ComposableHash entry is configured in the parent class' do
    let(:composable_hash_parent_class) do
      Class.new(Gitlab::Config::Entry::Node) do
        include ::Gitlab::Config::Entry::Configurable

        entry :secrets, ::Gitlab::Config::Entry::ComposableHash,
          description: 'Configured secrets for this job',
          inherit: false,
          default: { hello: :world },
          metadata: { composable_class: Gitlab::Config::Entry::Node }
      end
    end

    let(:entry) do
      parent_entry = composable_hash_parent_class.new({ secrets: config })
      parent_entry.compose!

      parent_entry[:secrets]
    end

    it_behaves_like 'composes a hash'

    it 'creates entry with configuration from parent class' do
      expect(entry.default).to eq({ hello: :world })
      expect(entry.metadata).to eq(composable_class: Gitlab::Config::Entry::Node)
    end
  end
end
