# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::MultiStore, feature_category: :redis do
  include RedisHelpers

  let_it_be(:redis_store_class) { define_helper_redis_store_class }
  let_it_be(:primary_db) { 1 }
  let_it_be(:secondary_db) { 2 }
  let_it_be(:primary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
  let_it_be(:secondary_store) { create_redis_store(redis_store_class.params, db: secondary_db, serializer: nil) }
  let_it_be(:primary_pool) { ConnectionPool.new { primary_store } }
  let_it_be(:secondary_pool) { ConnectionPool.new { secondary_store } }
  let_it_be(:instance_name) { 'TestStore' }
  let_it_be(:multi_store) { described_class.create_using_pool(primary_pool, secondary_pool, instance_name) }

  subject do
    multi_store.with_borrowed_connection do
      multi_store.send(name, *args)
    end
  end

  before do
    skip_default_enabled_yaml_check
  end

  after(:all) do
    primary_store.with(&:flushdb)
    secondary_store.with(&:flushdb)
  end

  describe '.create_using_client' do
    it 'initialises a MultiStore instance' do
      expect(described_class.create_using_client(primary_store, secondary_store, instance_name))
        .to be_instance_of(described_class)
    end

    context 'when primary_store is nil' do
      let(:multi_store) { described_class.create_using_client(nil, secondary_store, instance_name) }

      it 'fails with exception' do
        expect { multi_store }.to raise_error(ArgumentError, /either primary_store or primary_pool is required/)
      end
    end

    context 'when secondary_store is nil' do
      let(:multi_store) { described_class.create_using_client(primary_store, nil, instance_name) }

      it 'fails with exception' do
        expect { multi_store }.to raise_error(ArgumentError, /either secondary_store or secondary_pool is required/)
      end
    end

    context 'when instance_name is nil' do
      let(:instance_name) { nil }
      let(:multi_store) { described_class.create_using_client(primary_store, secondary_store, instance_name) }

      it 'fails with exception' do
        expect { multi_store }.to raise_error(ArgumentError, /instance_name is required/)
      end
    end

    context 'when primary_store is not a ::Redis instance' do
      it 'fails with exception' do
        expect { described_class.create_using_client('primary', secondary_store, instance_name) }
          .to raise_error(ArgumentError, /invalid primary_store/)
      end
    end

    context 'when secondary_store is not a ::Redis instance' do
      it 'fails with exception' do
        expect { described_class.create_using_client(primary_store, 'secondary', instance_name) }
          .to raise_error(ArgumentError, /invalid secondary_store/)
      end
    end
  end

  describe '.create_using_pool' do
    it 'initialises a MultiStore instance' do
      expect(described_class.create_using_pool(primary_pool, secondary_pool, instance_name))
        .to be_instance_of(described_class)
    end

    context 'when primary_pool is nil' do
      let(:multi_store) { described_class.create_using_pool(nil, secondary_pool, instance_name) }

      it 'fails with exception' do
        expect { multi_store }.to raise_error(ArgumentError, /either primary_store or primary_pool is required/)
      end
    end

    context 'when secondary_pool is nil' do
      let(:multi_store) { described_class.create_using_pool(primary_pool, nil, instance_name) }

      it 'fails with exception' do
        expect { multi_store }.to raise_error(ArgumentError, /either secondary_store or secondary_pool is required/)
      end
    end

    context 'when instance_name is nil' do
      let(:instance_name) { nil }
      let(:multi_store) { described_class.create_using_pool(primary_pool, secondary_pool, instance_name) }

      it 'fails with exception' do
        expect { multi_store }.to raise_error(ArgumentError, /instance_name is required/)
      end
    end

    context 'when primary_store is not a ::Redis instance' do
      before do
        allow(primary_store).to receive(:is_a?).with(::Redis).and_return(false)
        allow(primary_store).to receive(:is_a?).with(::Redis::Cluster).and_return(false)
      end

      it 'fails with exception' do
        expect { described_class.create_using_pool(primary_pool, secondary_pool, instance_name) }
          .to raise_error(ArgumentError, /invalid primary_pool/)
      end
    end

    context 'when secondary_store is not a ::Redis instance' do
      before do
        allow(secondary_store).to receive(:is_a?).with(::Redis).and_return(false)
        allow(secondary_store).to receive(:is_a?).with(::Redis::Cluster).and_return(false)
      end

      it 'fails with exception' do
        expect { described_class.create_using_pool(primary_pool, secondary_pool, instance_name) }
          .to raise_error(ArgumentError, /invalid secondary_pool/)
      end
    end
  end

  context 'with READ redis commands' do
    let(:args) { 'args' }
    let(:kwargs) { { match: '*:set:key2*' } }

    subject do
      multi_store.with_borrowed_connection do
        multi_store.send(name, *args, **kwargs)
      end
    end

    RSpec.shared_examples_for 'secondary store' do
      it 'execute on the secondary instance' do
        expect(secondary_store).to receive(name).with(*expected_args)

        subject
      end

      it 'does not execute on the primary store' do
        expect(primary_store).not_to receive(name)

        subject
      end
    end

    described_class::READ_COMMANDS.each do |name|
      describe name.to_s do
        let(:expected_args) { [*args, { **kwargs }] }
        let(:name) { name }

        before do
          allow(primary_store).to receive(name)
          allow(secondary_store).to receive(name)
        end

        context 'when reading from the primary is successful' do
          it 'returns the correct value' do
            expect(primary_store).to receive(name).with(*expected_args)

            subject
          end
        end

        context 'when reading from default instance is raising an exception' do
          before do
            multi_store.with_borrowed_connection do
              allow(multi_store.default_store).to receive(name).with(*expected_args).and_raise(StandardError)
            end
            allow(Gitlab::ErrorTracking).to receive(:log_exception)
          end

          it 'logs the exception and re-raises the error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
              hash_including(:multi_store_error_message,
                instance_name: instance_name, command_name: name))

            expect { subject }.to raise_error(an_instance_of(StandardError))
          end
        end

        context 'when the command is executed within pipelined block' do
          subject do
            multi_store.with_borrowed_connection do
              multi_store.pipelined do |pipeline|
                pipeline.send(name, *args, **kwargs)
              end
            end
          end

          it 'is executed only 1 time on primary and secondary instance' do
            expect(primary_store).to receive(:pipelined).and_call_original
            expect(secondary_store).to receive(:pipelined).and_call_original

            2.times do
              expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
                expect(pipeline).to receive(name).with(*expected_args).once
              end
            end

            subject
          end
        end

        context 'when block provided' do
          subject do
            multi_store.with_borrowed_connection do
              multi_store.send(name, expected_args) { nil }
            end
          end

          it 'only default store to execute' do
            expect(primary_store).to receive(:send).with(name, expected_args)
            expect(secondary_store).not_to receive(:send)

            subject
          end
        end

        context 'with both primary and secondary store using same redis instance' do
          let(:primary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
          let(:secondary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
          let(:primary_pool) { ConnectionPool.new { primary_store } }
          let(:secondary_pool) { ConnectionPool.new { secondary_store } }
          let(:multi_store) { described_class.create_using_pool(primary_pool, secondary_pool, instance_name) }

          it_behaves_like 'secondary store'
        end

        context 'when use_primary_and_secondary_stores feature flag is disabled' do
          before do
            stub_feature_flags(use_primary_and_secondary_stores_for_test_store: false)
          end

          context 'when using secondary store as default' do
            before do
              stub_feature_flags(use_primary_store_as_default_for_test_store: false)
            end

            it 'executes only on secondary redis store', :aggregate_failures do
              expect(secondary_store).to receive(name).with(*expected_args)
              expect(primary_store).not_to receive(name).with(*expected_args)

              subject
            end
          end

          context 'when using primary store as default' do
            it 'executes only on primary redis store', :aggregate_failures do
              expect(primary_store).to receive(name).with(*expected_args)
              expect(secondary_store).not_to receive(name).with(*expected_args)

              subject
            end
          end
        end
      end
    end
  end

  context 'with nested command in block' do
    let(:skey) { "test_set" }
    let(:values) { %w[{x}a {x}b {x}c] }

    before do
      primary_store.set('{x}a', 1)
      primary_store.set('{x}b', 2)
      primary_store.set('{x}c', 3)

      secondary_store.set('{x}a', 10)
      secondary_store.set('{x}b', 20)
      secondary_store.set('{x}c', 30)
    end

    subject do
      multi_store.with_borrowed_connection do
        multi_store.mget(values) do |v|
          multi_store.sadd(skey, v)
        end
      end
    end

    context 'when using both stores' do
      context 'when primary instance is default store' do
        it 'ensures primary instance is executing the block' do
          expect(primary_store).to receive(:send).with(:mget, values).and_call_original
          expect(primary_store).to receive(:send).with(:sadd, skey, %w[1 2 3]).and_call_original

          expect(secondary_store).not_to receive(:send)

          subject
        end
      end

      context 'when secondary instance is default store' do
        before do
          stub_feature_flags(use_primary_store_as_default_for_test_store: false)
        end

        it 'ensures secondary instance is executing the block' do
          expect(primary_store).not_to receive(:send)

          expect(secondary_store).to receive(:send).with(:mget, values).and_call_original
          expect(secondary_store).to receive(:send).with(:sadd, skey, %w[10 20 30]).and_call_original

          subject
        end
      end
    end

    context 'when using 1 store only' do
      before do
        stub_feature_flags(use_primary_and_secondary_stores_for_test_store: false)
      end

      context 'when primary instance is default store' do
        it 'ensures only primary instance is executing the block' do
          expect(secondary_store).not_to receive(:send)

          expect(primary_store).to receive(:send).with(:mget, values).and_call_original
          expect(primary_store).to receive(:send).with(:sadd, skey, %w[1 2 3]).and_call_original

          subject
        end
      end

      context 'when secondary instance is default store' do
        before do
          stub_feature_flags(use_primary_store_as_default_for_test_store: false)
        end

        it 'ensures only secondary instance is executing the block' do
          expect(secondary_store).to receive(:send).with(:mget, values).and_call_original
          expect(secondary_store).to receive(:send).with(:sadd, skey, %w[10 20 30]).and_call_original

          expect(primary_store).not_to receive(:send)

          subject
        end
      end
    end
  end

  context 'with WRITE redis commands' do
    described_class::WRITE_COMMANDS.each do |name|
      describe name.to_s do
        let(:args) { "dummy_args" }
        let(:name) { name }

        before do
          allow(primary_store).to receive(name)
          allow(secondary_store).to receive(name)
        end

        context 'when executing on primary instance is successful' do
          it 'executes on both primary and secondary redis store', :aggregate_failures do
            expect(primary_store).to receive(name).with(*args)
            expect(secondary_store).to receive(name).with(*args)

            subject
          end
        end

        context 'when use_primary_and_secondary_stores feature flag is disabled' do
          before do
            stub_feature_flags(use_primary_and_secondary_stores_for_test_store: false)
          end

          context 'when using secondary store as default' do
            before do
              stub_feature_flags(use_primary_store_as_default_for_test_store: false)
            end

            it 'executes only on secondary redis store', :aggregate_failures do
              expect(secondary_store).to receive(name).with(*args)
              expect(primary_store).not_to receive(name).with(*args)

              subject
            end
          end

          context 'when using primary store as default' do
            it 'executes only on primary redis store', :aggregate_failures do
              expect(primary_store).to receive(name).with(*args)
              expect(secondary_store).not_to receive(name).with(*args)

              subject
            end
          end
        end

        context 'when executing on the default instance is raising an exception' do
          before do
            multi_store.with_borrowed_connection do
              allow(multi_store.default_store).to receive(name).with(*args).and_raise(StandardError)
            end

            allow(Gitlab::ErrorTracking).to receive(:log_exception)
          end

          it 'raises error and does not execute on non default instance', :aggregate_failures do
            multi_store.with_borrowed_connection do
              expect(multi_store.non_default_store).not_to receive(name).with(*args)
            end

            expect { subject }.to raise_error(StandardError)
          end
        end

        context 'when executing on the non default instance is raising an exception' do
          before do
            multi_store.with_borrowed_connection do
              allow(multi_store.non_default_store).to receive(name).with(*args).and_raise(StandardError)
            end
            allow(Gitlab::ErrorTracking).to receive(:log_exception)
          end

          it 'logs the exception and execute on default instance', :aggregate_failures do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
              hash_including(:multi_store_error_message,
                command_name: name, instance_name: instance_name))
            multi_store.with_borrowed_connection do
              expect(multi_store.default_store).to receive(name).with(*args)
            end

            subject
          end
        end

        context 'when the command is executed within pipelined block' do
          subject do
            multi_store.with_borrowed_connection do
              multi_store.pipelined do |pipeline|
                pipeline.send(name, *args)
              end
            end
          end

          it 'is executed only 1 time on each instance', :aggregate_failures do
            expect(primary_store).to receive(:pipelined).and_call_original
            expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
              expect(pipeline).to receive(name).with(*args).once
            end

            expect(secondary_store).to receive(:pipelined).and_call_original
            expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
              expect(pipeline).to receive(name).with(*args).once
            end

            subject
          end
        end
      end
    end
  end

  RSpec.shared_examples_for 'verify that store contains values' do |store|
    it "#{store} redis store contains correct values", :aggregate_failures do
      subject

      redis_store = multi_store.with_borrowed_connection { multi_store.send(store) }

      if expected_value.is_a?(Array)
        # :smembers does not guarantee the order it will return the values
        expect(redis_store.send(verification_name, *verification_args)).to match_array(expected_value)
      else
        expect(redis_store.send(verification_name, *verification_args)).to eq(expected_value)
      end
    end
  end

  RSpec.shared_examples_for 'pipelined command' do |name|
    let_it_be(:key1) { "redis:{1}:key_a" }
    let_it_be(:value1) { "redis_value1" }
    let_it_be(:value2) { "redis_value2" }
    let_it_be(:expected_value) { value1 }
    let_it_be(:verification_name) { :get }
    let_it_be(:verification_args) { key1 }

    before do
      primary_store.flushdb
      secondary_store.flushdb
    end

    describe "command execution in a pipelined command" do
      let(:counter) { Gitlab::Metrics::NullMetric.instance }

      before do
        allow(Gitlab::Metrics).to receive(:counter).with(
          :gitlab_redis_multi_store_pipelined_diff_error_total,
          'Redis MultiStore pipelined command diff between stores'
        ).and_return(counter)
      end

      subject do
        multi_store.with_borrowed_connection do
          multi_store.send(name) do |redis|
            redis.set(key1, value1)
          end
        end
      end

      context 'when executing on primary instance is successful' do
        it 'executes on both primary and secondary redis store', :aggregate_failures do
          expect(primary_store).to receive(name).and_call_original
          expect(secondary_store).to receive(name).and_call_original

          subject
        end

        include_examples 'verify that store contains values', :primary_store
        include_examples 'verify that store contains values', :secondary_store
      end

      context 'when executing on the default instance is raising an exception' do
        before do
          multi_store.with_borrowed_connection do
            allow(multi_store.default_store).to receive(name).and_raise(StandardError)
          end
        end

        it 'raises error and does not execute on non default instance', :aggregate_failures do
          multi_store.with_borrowed_connection do
            expect(multi_store.non_default_store).not_to receive(name)
          end

          expect { subject }.to raise_error(StandardError)
        end
      end

      context 'when executing on the non default instance is raising an exception' do
        before do
          multi_store.with_borrowed_connection do
            allow(multi_store.non_default_store).to receive(name).and_raise(StandardError)
          end
          allow(Gitlab::ErrorTracking).to receive(:log_exception)
        end

        it 'logs the exception and execute on default instance', :aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
            hash_including(:multi_store_error_message, command_name: name))
          multi_store.with_borrowed_connection do
            expect(multi_store.default_store).to receive(name).and_call_original
          end

          subject
        end

        include_examples 'verify that store contains values', :default_store
      end

      describe 'return values from a pipelined command' do
        RSpec::Matchers.define :pipeline_diff_error_with_stacktrace do |message|
          match do |object|
            expect(object).to be_a(Gitlab::Redis::MultiStore::PipelinedDiffError)
            expect(object.backtrace).not_to be_nil
            expect(object.message).to eq(message)
          end
        end

        subject do
          multi_store.with_borrowed_connection do
            multi_store.send(name) do |redis|
              redis.get(key1)
            end
          end
        end

        context 'when the value exists on both and are equal' do
          before do
            primary_store.set(key1, value1)
            secondary_store.set(key1, value1)
          end

          it 'returns the value' do
            expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

            expect(subject).to eq([value1])
          end
        end

        context 'when the value exists on both but differ' do
          before do
            multi_store.with_borrowed_connection do
              multi_store.non_default_store.set(key1, value1)
              multi_store.default_store.set(key1, value2)
            end
          end

          it 'returns the value from the secondary store, logging an error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              pipeline_diff_error_with_stacktrace(
                'Pipelined command executed on both stores successfully but results differ between them. ' \
                  "Result from the non-default store: [#{value1.inspect}]. " \
                  "Result from the default store: [#{value2.inspect}]."
              ),
              hash_including(command_name: name, instance_name: instance_name)
            ).and_call_original
            expect(counter).to receive(:increment).with(command: name, instance_name: instance_name)

            expect(subject).to eq([value2])
          end
        end

        context 'when the value does not exist on the non-default store but it does on the default' do
          before do
            multi_store.with_borrowed_connection { multi_store.default_store.set(key1, value2) }
          end

          it 'returns the value from the secondary store, logging an error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              pipeline_diff_error_with_stacktrace(
                'Pipelined command executed on both stores successfully but results differ between them. ' \
                  "Result from the non-default store: [nil]. Result from the default store: [#{value2.inspect}]."
              ),
              hash_including(command_name: name, instance_name: instance_name)
            )
            expect(counter).to receive(:increment).with(command: name, instance_name: instance_name)

            expect(subject).to eq([value2])
          end
        end

        context 'when the value does not exist in either' do
          it 'returns nil without logging an error' do
            expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
            expect(counter).not_to receive(:increment)

            expect(subject).to eq([nil])
          end
        end
      end

      context 'when use_primary_and_secondary_stores feature flag is disabled' do
        before do
          stub_feature_flags(use_primary_and_secondary_stores_for_test_store: false)
        end

        context 'when using secondary store as default' do
          before do
            stub_feature_flags(use_primary_store_as_default_for_test_store: false)
          end

          it 'executes on secondary store', :aggregate_failures do
            expect(primary_store).not_to receive(:send).and_call_original
            expect(secondary_store).to receive(:send).and_call_original

            subject
          end
        end

        context 'when using primary store as default' do
          it 'executes on primary store', :aggregate_failures do
            expect(secondary_store).not_to receive(:send).and_call_original
            expect(primary_store).to receive(:send).and_call_original

            subject
          end
        end
      end

      context 'when with_readonly_pipeline is used' do
        it 'calls the default store only' do
          expect(primary_store).to receive(:send).and_call_original
          expect(secondary_store).not_to receive(:send).and_call_original

          multi_store.with_readonly_pipeline { subject }
        end

        context 'when used in a nested manner' do
          subject(:nested_subject) do
            multi_store.with_readonly_pipeline do
              multi_store.with_readonly_pipeline { subject }
            end
          end

          it 'raises error' do
            expect { nested_subject }.to raise_error(Gitlab::Redis::MultiStore::NestedReadonlyPipelineError)
            expect { nested_subject }.to raise_error { |e|
                                           expect(e.message).to eq('Nested use of with_readonly_pipeline is detected.')
                                         }
          end
        end
      end
    end
  end

  describe '#multi' do
    include_examples 'pipelined command', :multi
  end

  describe '#pipelined' do
    include_examples 'pipelined command', :pipelined
  end

  describe '#ping' do
    subject { multi_store.with_borrowed_connection { multi_store.ping } }

    context 'when using both stores' do
      before do
        allow(multi_store).to receive(:use_primary_and_secondary_stores?).and_return(true)
      end

      context 'without message' do
        it 'returns PONG' do
          expect(subject).to eq('PONG')
        end
      end

      context 'with message' do
        it 'returns the same message' do
          expect(multi_store.with_borrowed_connection { multi_store.ping('hello world') }).to eq('hello world')
        end
      end

      shared_examples 'returns an error' do
        before do
          allow(store).to receive(:ping).and_raise('boom')
        end

        it 'returns the error' do
          expect { subject }.to raise_error('boom')
        end
      end

      context 'when primary store returns an error' do
        let(:store) { primary_store }

        it_behaves_like 'returns an error'
      end

      context 'when secondary store returns an error' do
        let(:store) { secondary_store }

        it_behaves_like 'returns an error'
      end
    end

    shared_examples 'single store as default store' do
      context 'when the store retuns success' do
        it 'returns response from the respective store' do
          expect(store).to receive(:ping).and_return('PONG')

          subject

          expect(subject).to eq('PONG')
        end
      end

      context 'when the store returns an error' do
        before do
          allow(store).to receive(:ping).and_raise('boom')
        end

        it 'returns the error' do
          expect { subject }.to raise_error('boom')
        end
      end
    end

    context 'when using only one store' do
      before do
        allow(multi_store).to receive(:use_primary_and_secondary_stores?).and_return(false)
      end

      context 'when using primary_store as default store' do
        let(:store) { primary_store }

        before do
          allow(multi_store).to receive(:use_primary_store_as_default?).and_return(true)
        end

        it_behaves_like 'single store as default store'
      end

      context 'when using secondary_store as default store' do
        let(:store) { secondary_store }

        before do
          allow(multi_store).to receive(:use_primary_store_as_default?).and_return(false)
        end

        it_behaves_like 'single store as default store'
      end
    end
  end

  describe '#close' do
    subject { multi_store.close }

    context 'when connections are borrowed' do
      it 'closes both stores' do
        expect(primary_store).to receive(:close)
        expect(secondary_store).to receive(:close)

        multi_store.with_borrowed_connection do
          subject
        end
      end

      context 'when using identical stores' do
        before do
          allow(multi_store).to receive(:same_redis_store?).and_return(true)
        end

        it 'closes secondary store' do
          expect(secondary_store).to receive(:close)
          expect(primary_store).not_to receive(:close)

          multi_store.with_borrowed_connection do
            subject
          end
        end
      end
    end

    context 'without borrowed connections' do
      it 'directly returns nil' do
        expect(primary_store).not_to receive(:close)
        expect(secondary_store).not_to receive(:close)

        subject
      end
    end
  end

  describe '#blpop' do
    let_it_be(:key) { "mylist" }

    subject { multi_store.with_borrowed_connection { multi_store.blpop(key, timeout: 0.1) } }

    shared_examples 'calls blpop on default_store' do
      it 'calls blpop on default_store' do
        multi_store.with_borrowed_connection do
          expect(multi_store.default_store).to receive(:blpop).with(key, { timeout: 0.1 })
        end

        subject
      end
    end

    shared_examples 'does not call lpop on non_default_store' do
      it 'does not call blpop on non_default_store' do
        multi_store.with_borrowed_connection do
          expect(multi_store.non_default_store).not_to receive(:blpop)
        end

        subject
      end
    end

    context 'when using both stores' do
      before do
        allow(multi_store).to receive(:use_primary_and_secondary_stores?).and_return(true)
      end

      it_behaves_like 'calls blpop on default_store'

      context "when an element exists in the default_store" do
        before do
          multi_store.with_borrowed_connection { multi_store.default_store.lpush(key, 'abc') }
        end

        it 'calls lpop on non_default_store' do
          multi_store.with_borrowed_connection do
            expect(multi_store.non_default_store).to receive(:blpop).with(key, { timeout: 1 })
          end

          subject
        end
      end

      context 'when the list is empty in default_store' do
        it_behaves_like 'does not call lpop on non_default_store'
      end
    end

    context 'when using one store' do
      before do
        allow(multi_store).to receive(:use_primary_and_secondary_stores?).and_return(false)
      end

      it_behaves_like 'calls blpop on default_store'
      it_behaves_like 'does not call lpop on non_default_store'
    end
  end

  context 'with unsupported command' do
    let(:counter) { Gitlab::Metrics::NullMetric.instance }

    before do
      primary_store.flushdb
      secondary_store.flushdb
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
    end

    subject { multi_store.with_borrowed_connection { multi_store.command } }

    context 'when in test environment' do
      it 'raises error' do
        expect { subject }.to raise_error(instance_of(Gitlab::Redis::MultiStore::MethodMissingError))
      end
    end

    context 'when not in test environment' do
      before do
        stub_rails_env('production')
      end

      it 'responds to missing method' do
        expect(multi_store).to receive(:respond_to_missing?).and_call_original

        expect(multi_store.respond_to?(:command)).to be(true)
      end

      it 'executes method missing' do
        expect(multi_store).to receive(:method_missing)

        subject
      end

      context 'when command is not in SKIP_LOG_METHOD_MISSING_FOR_COMMANDS' do
        it 'logs MethodMissingError' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            an_instance_of(Gitlab::Redis::MultiStore::MethodMissingError),
            hash_including(command_name: :command, instance_name: instance_name)
          )

          subject
        end

        it 'increments method missing counter' do
          expect(counter).to receive(:increment).with(command: :command, instance_name: instance_name)

          subject
        end

        it 'fallback and executes only on the secondary store', :aggregate_failures do
          expect(primary_store).to receive(:command).and_call_original
          expect(secondary_store).not_to receive(:command)

          subject
        end
      end

      context 'when command is in SKIP_LOG_METHOD_MISSING_FOR_COMMANDS' do
        subject { multi_store.with_borrowed_connection { multi_store.info } }

        it 'does not log MethodMissingError' do
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

          subject
        end

        it 'does not increment method missing counter' do
          expect(counter).not_to receive(:increment)

          subject
        end
      end

      context 'with feature flag :use_primary_store_as_default_for_test_store is enabled' do
        it 'fallback and executes only on the secondary store', :aggregate_failures do
          expect(primary_store).to receive(:command).and_call_original
          expect(secondary_store).not_to receive(:command)

          subject
        end
      end

      context 'with feature flag :use_primary_store_as_default_for_test_store is disabled' do
        before do
          stub_feature_flags(use_primary_store_as_default_for_test_store: false)
        end

        it 'fallback and executes only on the secondary store', :aggregate_failures do
          expect(secondary_store).to receive(:command).and_call_original
          expect(primary_store).not_to receive(:command)

          subject
        end
      end

      context 'when the command is executed within pipelined block' do
        subject do
          multi_store.with_borrowed_connection { multi_store.pipelined(&:command) }
        end

        it 'is executed only 1 time on each instance', :aggregate_failures do
          expect(primary_store).to receive(:pipelined).once.and_call_original
          expect(secondary_store).to receive(:pipelined).once.and_call_original

          2.times do
            expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
              expect(pipeline).to receive(:command).once
            end
          end

          subject
        end
      end
    end
  end

  describe '#to_s' do
    subject { multi_store.with_borrowed_connection { multi_store.to_s } }

    it 'returns same value as primary_store' do
      is_expected.to eq(primary_store.to_s)
    end
  end

  describe '#is_a?' do
    it 'returns true for ::Redis::Store' do
      expect(multi_store.with_borrowed_connection { multi_store.is_a?(::Redis::Store) }).to be true
    end
  end

  describe '#use_primary_and_secondary_stores?' do
    subject(:use_both) do
      multi_store.with_borrowed_connection { multi_store.use_primary_and_secondary_stores? }
    end

    it 'multi store is enabled' do
      expect(use_both).to be true
    end

    context 'with empty DB' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_return(false)
      end

      it 'multi store is disabled' do
        expect(use_both).to be false
      end
    end

    context 'when FF table guard raises' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_raise
      end

      it 'multi store is disabled' do
        expect(use_both).to be false
      end
    end
  end

  describe '#use_primary_store_as_default?' do
    subject(:primary_default) do
      multi_store.with_borrowed_connection { multi_store.use_primary_store_as_default? }
    end

    it 'multi store is disabled' do
      expect(primary_default).to be true
    end

    context 'with empty DB' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_return(false)
      end

      it 'multi store is disabled' do
        expect(primary_default).to be false
      end
    end

    context 'when FF table guard raises' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_raise
      end

      it 'multi store is disabled' do
        expect(primary_default).to be false
      end
    end
  end

  # NOTE: for pub/sub, unit tests are favoured over integration tests to avoid long polling
  # with threads which could lead to flaky specs. The multiplexing behaviour are verified in
  # 'with WRITE redis commands' and 'with READ redis commands' contexts.
  context 'with pub/sub commands' do
    let(:channel_name) { 'chanA' }
    let(:message) { "msg" }

    shared_examples 'publishes to stores' do
      it 'publishes to one or more stores' do
        expect(stores).to all(receive(:publish))

        multi_store.with_borrowed_connection { multi_store.publish(channel_name, message) }
      end
    end

    shared_examples 'subscribes and unsubscribes' do
      it 'subscribes to the default store' do
        expect(default_store).to receive(:subscribe)
        expect(non_default_store).not_to receive(:subscribe)

        multi_store.with_borrowed_connection { multi_store.subscribe(channel_name) }
      end

      it 'unsubscribes to the default store' do
        expect(default_store).to receive(:unsubscribe)
        expect(non_default_store).not_to receive(:unsubscribe)

        multi_store.with_borrowed_connection { multi_store.unsubscribe }
      end
    end

    context 'when using both stores' do
      before do
        stub_feature_flags(use_primary_and_secondary_stores_for_test_store: true)
      end

      it_behaves_like 'publishes to stores' do
        let(:stores) { [primary_store, secondary_store] }
      end

      context 'with primary store set as default' do
        before do
          stub_feature_flags(use_primary_store_as_default_for_test_store: true)
        end

        it_behaves_like 'subscribes and unsubscribes' do
          let(:default_store) { primary_store }
          let(:non_default_store) { secondary_store }
        end
      end

      context 'with secondary store set as default' do
        before do
          stub_feature_flags(use_primary_store_as_default_for_test_store: false)
        end

        it_behaves_like 'subscribes and unsubscribes' do
          let(:default_store) { secondary_store }
          let(:non_default_store) { primary_store }
        end
      end
    end

    context 'when only using the primary store' do
      before do
        stub_feature_flags(
          use_primary_and_secondary_stores_for_test_store: false,
          use_primary_store_as_default_for_test_store: true
        )
      end

      it_behaves_like 'subscribes and unsubscribes' do
        let(:default_store) { primary_store }
        let(:non_default_store) { secondary_store }
      end

      it_behaves_like 'publishes to stores' do
        let(:stores) { [primary_store] }
      end
    end

    context 'when only using the secondary store' do
      before do
        stub_feature_flags(
          use_primary_and_secondary_stores_for_test_store: false,
          use_primary_store_as_default_for_test_store: false
        )
      end

      it_behaves_like 'subscribes and unsubscribes' do
        let(:default_store) { secondary_store }
        let(:non_default_store) { primary_store }
      end

      it_behaves_like 'publishes to stores' do
        let(:stores) { [secondary_store] }
      end
    end
  end

  describe '*_COMMANDS' do
    it 'checks if every command is only defined once' do
      commands = [
        described_class::REDIS_CLIENT_COMMANDS,
        described_class::PUBSUB_SUBSCRIBE_COMMANDS,
        described_class::READ_COMMANDS,
        described_class::WRITE_COMMANDS,
        described_class::PIPELINED_COMMANDS
      ].inject([], :concat)
      duplicated_commands = commands.group_by { |c| c }.select { |k, v| v.size > 1 }.map(&:first)

      expect(duplicated_commands).to be_empty, "commands #{duplicated_commands} defined more than once"
    end
  end

  describe '.with_borrowed_connection' do
    context 'when initialised with pools' do
      before do
        multi_store.instance_variable_set(:@primary_store, 'primary')
        multi_store.instance_variable_set(:@secondary_store, 'secondary')
      end

      it 'permits nested borrows' do
        multi_store.with_borrowed_connection do
          multi_store.with_borrowed_connection do
            multi_store.ping

            expect(multi_store.primary_store).not_to eq(nil)
            expect(multi_store.secondary_store).not_to eq(nil)
            expect(multi_store.primary_store).to be_instance_of(Redis::Store)
            expect(multi_store.secondary_store).to be_instance_of(Redis::Store)
          end

          multi_store.ping

          expect(multi_store.primary_store).to be_instance_of(Redis::Store)
          expect(multi_store.secondary_store).to be_instance_of(Redis::Store)
        end

        expect(multi_store.primary_store).to eq('primary')
        expect(multi_store.secondary_store).to eq('secondary')
      end
    end

    context 'when initialised without pools' do
      let(:multi_store) { described_class.create_using_client(primary_store, secondary_store, instance_name) }

      it 'skips borrowing' do
        multi_store.with_borrowed_connection do
          expect(multi_store.primary_store.inspect).to eq(primary_store.inspect)
          expect(multi_store.secondary_store.inspect).to eq(secondary_store.inspect)

          multi_store.ping
        end
      end
    end
  end
end
