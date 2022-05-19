# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SafeRequestPurger do
  let(:resource_key) { '_key_' }
  let(:resource_ids) { ['foo'] }
  let(:args) { { resource_key: resource_key, resource_ids: resource_ids } }
  let(:resource_data) { { 'foo' => 'bar' } }

  before do
    Gitlab::SafeRequestStore[resource_key] = resource_data
  end

  describe '.execute', :request_store do
    subject(:execute_instance) { described_class.execute(**args) }

    it 'purges an entry from the store' do
      execute_instance

      expect(Gitlab::SafeRequestStore.fetch(resource_key)).to be_empty
    end
  end

  describe '#execute' do
    subject(:execute_instance) { described_class.new(**args).execute }

    context 'when request store is active', :request_store do
      it 'purges an entry from the store' do
        execute_instance

        expect(Gitlab::SafeRequestStore.fetch(resource_key)).to be_empty
      end

      context 'when there are multiple resource_ids to purge' do
        let(:resource_data) do
          {
            'foo' => 'bar',
            'two' => '_two_',
            'three' => '_three_',
            'four' => '_four_'
          }
        end

        let(:resource_ids) { %w[two three] }

        it 'purges an entry from the store' do
          execute_instance

          expect(Gitlab::SafeRequestStore.fetch(resource_key)).to eq resource_data.slice('foo', 'four')
        end
      end

      context 'when there is no matching resource_ids' do
        let(:resource_ids) { ['_bogus_resource_id_'] }

        it 'purges an entry from the store' do
          execute_instance

          expect(Gitlab::SafeRequestStore.fetch(resource_key)).to eq resource_data
        end
      end
    end

    context 'when request store is not active' do
      let(:resource_ids) { ['_bogus_resource_id_'] }

      it 'does offer the ability to interact with data store' do
        expect(execute_instance).to eq({})
      end
    end
  end
end
