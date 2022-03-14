# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SafeRequestLoader, :aggregate_failures do
  let(:resource_key) { '_key_' }
  let(:resource_ids) { [] }
  let(:args) { { resource_key: resource_key, resource_ids: resource_ids } }
  let(:block) { proc { {} } }

  describe '.execute', :request_store do
    let(:resource_data) { { 'foo' => 'bar' } }

    before do
      Gitlab::SafeRequestStore[resource_key] = resource_data
    end

    subject(:execute_instance) { described_class.execute(**args, &block) }

    it 'gets data from the store and returns it' do
      expect(execute_instance.keys).to contain_exactly(*resource_data.keys)
      expect(execute_instance).to match(a_hash_including(resource_data))
      expect_store_to_be_updated
    end
  end

  describe '#execute' do
    subject(:execute_instance) { described_class.new(**args).execute(&block) }

    context 'without a block' do
      let(:block) { nil }

      it 'raises an error' do
        expect { execute_instance }.to raise_error(ArgumentError, 'Block is mandatory')
      end
    end

    context 'when a resource_id is nil' do
      let(:block) { proc { {} } }
      let(:resource_ids) { [nil] }

      it 'contains resource_data with nil key' do
        expect(execute_instance.keys).to contain_exactly(nil)
        expect(execute_instance).to match(a_hash_including(nil => nil))
      end
    end

    context 'with SafeRequestStore considerations' do
      let(:resource_data) { { 'foo' => 'bar' } }

      before do
        Gitlab::SafeRequestStore[resource_key] = resource_data
      end

      context 'when request store is active', :request_store do
        it 'gets data from the store' do
          expect(execute_instance.keys).to contain_exactly(*resource_data.keys)
          expect(execute_instance).to match(a_hash_including(resource_data))
          expect_store_to_be_updated
        end

        context 'with already loaded resource_ids', :request_store do
          let(:resource_key) { 'foo_data' }
          let(:existing_resource_data) { { 'foo' => 'zoo' } }
          let(:block) { proc { { 'foo' => 'bar' } } }
          let(:resource_ids) { ['foo'] }

          before do
            Gitlab::SafeRequestStore[resource_key] = existing_resource_data
          end

          it 'does not re-fetch data if resource_id already exists' do
            expect(execute_instance.keys).to contain_exactly(*resource_ids)
            expect(execute_instance).to match(a_hash_including(existing_resource_data))
            expect_store_to_be_updated
          end

          context 'with mixture of new and existing resource_ids' do
            let(:existing_resource_data) { { 'foo' => 'bar' } }
            let(:resource_ids) { %w[foo bar] }

            context 'when block does not filter for only the missing resource_ids' do
              let(:block) { proc { { 'foo' => 'zoo', 'bar' => 'foo' } } }

              it 'overwrites existing keyed data with results from the block' do
                expect(execute_instance.keys).to contain_exactly(*resource_ids)
                expect(execute_instance).to match(a_hash_including(block.call))
                expect_store_to_be_updated
              end
            end

            context 'when passing the missing resource_ids to a block that filters for them' do
              let(:block) { proc { |rids| { 'foo' => 'zoo', 'bar' => 'foo' }.select { |k, _v| rids.include?(k) } } }

              it 'only updates resource_data with keyed items that did not exist' do
                expect(execute_instance.keys).to contain_exactly(*resource_ids)
                expect(execute_instance).to match(a_hash_including({ 'foo' => 'bar', 'bar' => 'foo' }))
                expect_store_to_be_updated
              end
            end

            context 'with default_value for resource_ids that did not exist in the results' do
              context 'when default_value is provided' do
                let(:args) { { resource_key: resource_key, resource_ids: resource_ids, default_value: '_value_' } }

                it 'populates a default value' do
                  expect(execute_instance.keys).to contain_exactly(*resource_ids)
                  expect(execute_instance).to match(a_hash_including({ 'foo' => 'bar', 'bar' => '_value_' }))
                  expect_store_to_be_updated
                end
              end

              context 'when default_value is not provided' do
                it 'populates a default_value of nil' do
                  expect(execute_instance.keys).to contain_exactly(*resource_ids)
                  expect(execute_instance).to match(a_hash_including({ 'foo' => 'bar', 'bar' => nil }))
                  expect_store_to_be_updated
                end
              end
            end
          end
        end
      end

      context 'when request store is not active' do
        let(:block) { proc { { 'foo' => 'bar' } } }
        let(:resource_ids) { ['foo'] }

        it 'has no data added from the store' do
          expect(execute_instance).to eq(block.call)
        end

        context 'with mixture of new and existing resource_ids' do
          let(:resource_ids) { %w[foo bar] }

          context 'when block does not filter out existing resource_data keys' do
            let(:block) { proc { { 'foo' => 'zoo', 'bar' => 'foo' } } }

            it 'overwrites existing keyed data with results from the block' do
              expect(execute_instance.keys).to contain_exactly(*resource_ids)
              expect(execute_instance).to match(a_hash_including(block.call))
            end
          end

          context 'when passing the missing resource_ids to a block that filters for them' do
            let(:block) { proc { |rids| { 'foo' => 'zoo', 'bar' => 'foo' }.select { |k, _v| rids.include?(k) } } }

            it 'only updates resource_data with keyed items that did not exist' do
              expect(execute_instance.keys).to contain_exactly(*resource_ids)
              expect(execute_instance).to match(a_hash_including({ 'foo' => 'zoo', 'bar' => 'foo' }))
            end
          end

          context 'with default_value for resource_ids that did not exist in the results' do
            context 'when default_value is provided' do
              let(:args) { { resource_key: resource_key, resource_ids: resource_ids, default_value: '_value_' } }

              it 'populates a default value' do
                expect(execute_instance.keys).to contain_exactly(*resource_ids)
                expect(execute_instance).to match(a_hash_including({ 'foo' => 'bar', 'bar' => '_value_' }))
              end
            end

            context 'when default_value is not provided' do
              it 'populates a default_value of nil' do
                expect(execute_instance.keys).to contain_exactly(*resource_ids)
                expect(execute_instance).to match(a_hash_including({ 'foo' => 'bar', 'bar' => nil }))
              end
            end
          end
        end
      end
    end
  end

  def expect_store_to_be_updated
    expect(execute_instance).to match(a_hash_including(Gitlab::SafeRequestStore[resource_key]))
    expect(execute_instance.keys).to contain_exactly(*Gitlab::SafeRequestStore[resource_key].keys)
  end
end
