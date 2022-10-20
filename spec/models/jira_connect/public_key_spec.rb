# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::PublicKey do
  describe '.create!' do
    let(:key) { 'key123' }

    subject(:create_public_key) { described_class.create!(key: key) }

    it 'only accepts valid public keys' do
      expect { create_public_key }.to raise_error(ArgumentError, 'Invalid public key')
    end

    shared_examples 'creates a jira connect public key' do
      it 'generates a Uuid' do
        expect(create_public_key.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
      end

      it 'sets the key attribute' do
        expect(create_public_key.key).to eq(expected_key)
      end

      it 'persists the values' do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).to receive(:set).with(anything, expected_key, anything)
        end

        create_public_key
      end
    end

    context 'with OpenSSL::PKey::RSA object' do
      let(:key) { OpenSSL::PKey::RSA.generate(3072).public_key }
      let(:expected_key) { key.to_s }

      it_behaves_like 'creates a jira connect public key'
    end

    context 'with string public key' do
      let(:key) { OpenSSL::PKey::RSA.generate(3072).public_key.to_s }
      let(:expected_key) { key }

      it_behaves_like 'creates a jira connect public key'
    end
  end

  describe '.find' do
    let(:uuid) { '1234' }

    subject(:find_public_key) { described_class.find(uuid) }

    it 'raises an error' do
      expect { find_public_key }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when the public key exists' do
      let_it_be(:key) { OpenSSL::PKey::RSA.generate(3072).public_key }
      let_it_be(:public_key) { described_class.create!(key: key) }

      let(:uuid) { public_key.uuid }

      it 'loads the public key', :aggregate_failures do
        expect(find_public_key).to be_kind_of(described_class)
        expect(find_public_key.uuid).to eq(public_key.uuid)
        expect(find_public_key.key).to eq(key.to_s)
      end
    end
  end

  describe '#save!' do
    let(:key) { OpenSSL::PKey::RSA.generate(3072).public_key }
    let(:public_key) { described_class.new(key: key, uuid: '123') }
    let(:jira_connect_installation) { build(:jira_connect_installation) }

    subject(:save_public_key) { public_key.save! }

    it 'persists the values' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:set).with(anything, key.to_s, ex: 5.minutes.to_i)
      end

      save_public_key
    end

    it 'returns itself' do
      expect(save_public_key).to eq(public_key)
    end
  end
end
