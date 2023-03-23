# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::MultiStore, feature_category: :redis do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:redis_store_class) do
    Class.new(Gitlab::Redis::Wrapper) do
      def config_file_name
        config_file_name = "spec/fixtures/config/redis_new_format_host.yml"
        Rails.root.join(config_file_name).to_s
      end

      def self.name
        'Sessions'
      end
    end
  end

  let_it_be(:primary_db) { 1 }
  let_it_be(:secondary_db) { 2 }
  let_it_be(:primary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
  let_it_be(:secondary_store) { create_redis_store(redis_store_class.params, db: secondary_db, serializer: nil) }
  let_it_be(:instance_name) { 'TestStore' }
  let_it_be(:multi_store) { described_class.new(primary_store, secondary_store, instance_name) }

  subject do
    multi_store.send(name, *args)
  end

  before do
    skip_feature_flags_yaml_validation
    skip_default_enabled_yaml_check
  end

  after(:all) do
    primary_store.flushdb
    secondary_store.flushdb
  end

  context 'when primary_store is nil' do
    let(:multi_store) { described_class.new(nil, secondary_store, instance_name) }

    it 'fails with exception' do
      expect { multi_store }.to raise_error(ArgumentError, /primary_store is required/)
    end
  end

  context 'when secondary_store is nil' do
    let(:multi_store) { described_class.new(primary_store, nil, instance_name) }

    it 'fails with exception' do
      expect { multi_store }.to raise_error(ArgumentError, /secondary_store is required/)
    end
  end

  context 'when instance_name is nil' do
    let(:instance_name) { nil }
    let(:multi_store) { described_class.new(primary_store, secondary_store, instance_name) }

    it 'fails with exception' do
      expect { multi_store }.to raise_error(ArgumentError, /instance_name is required/)
    end
  end

  context 'when primary_store is not a ::Redis instance' do
    before do
      allow(primary_store).to receive(:is_a?).with(::Redis).and_return(false)
      allow(primary_store).to receive(:is_a?).with(::Redis::Namespace).and_return(false)
    end

    it 'fails with exception' do
      expect { described_class.new(primary_store, secondary_store, instance_name) }
        .to raise_error(ArgumentError, /invalid primary_store/)
    end
  end

  context 'when primary_store is a ::Redis::Namespace instance' do
    before do
      allow(primary_store).to receive(:is_a?).with(::Redis).and_return(false)
      allow(primary_store).to receive(:is_a?).with(::Redis::Namespace).and_return(true)
    end

    it 'fails with exception' do
      expect { described_class.new(primary_store, secondary_store, instance_name) }.not_to raise_error
    end
  end

  context 'when secondary_store is not a ::Redis instance' do
    before do
      allow(secondary_store).to receive(:is_a?).with(::Redis).and_return(false)
      allow(secondary_store).to receive(:is_a?).with(::Redis::Namespace).and_return(false)
    end

    it 'fails with exception' do
      expect { described_class.new(primary_store, secondary_store, instance_name) }
        .to raise_error(ArgumentError, /invalid secondary_store/)
    end
  end

  context 'when secondary_store is a ::Redis::Namespace instance' do
    before do
      allow(secondary_store).to receive(:is_a?).with(::Redis).and_return(false)
      allow(secondary_store).to receive(:is_a?).with(::Redis::Namespace).and_return(true)
    end

    it 'fails with exception' do
      expect { described_class.new(primary_store, secondary_store, instance_name) }.not_to raise_error
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  context 'with READ redis commands' do
    subject do
      multi_store.send(name, *args, **kwargs)
    end

    let_it_be(:key1) { "redis:{1}:key_a" }
    let_it_be(:key2) { "redis:{1}:key_b" }
    let_it_be(:value1) { "redis_value1" }
    let_it_be(:value2) { "redis_value2" }
    let_it_be(:skey) { "redis:set:key" }
    let_it_be(:skey2) { "redis:set:key2" }
    let_it_be(:smemberargs) { [skey, value1] }
    let_it_be(:hkey) { "redis:hash:key" }
    let_it_be(:hkey2) { "redis:hash:key2" }
    let_it_be(:zkey) { "redis:sortedset:key" }
    let_it_be(:zkey2) { "redis:sortedset:key2" }
    let_it_be(:hitem1) { "item1" }
    let_it_be(:hitem2) { "item2" }
    let_it_be(:keys) { [key1, key2] }
    let_it_be(:values) { [value1, value2] }
    let_it_be(:svalues) { [value2, value1] }
    let_it_be(:hgetargs) { [hkey, hitem1] }
    let_it_be(:hmgetval) { [value1] }
    let_it_be(:mhmgetargs) { [hkey, hitem1] }
    let_it_be(:hvalmapped) { { "item1" => value1 } }
    let_it_be(:sscanargs) { [skey2, 0] }
    let_it_be(:sscanval) { ["0", [value1]] }
    let_it_be(:sscan_eachval) { [value1] }
    let_it_be(:sscan_each_arg) { { match: '*1*' } }
    let_it_be(:hscan_eachval) { [[hitem1, value1]] }
    let_it_be(:zscan_eachval) { [[value1, 1.0]] }
    let_it_be(:scan_each_arg) { { match: 'redis*' } }
    let_it_be(:scan_each_val) { [key1, key2, skey, skey2, hkey, hkey2, zkey, zkey2] }

    # rubocop:disable  Layout/LineLength
    where(:case_name, :name, :args, :value, :kwargs, :block) do
      'execute :get command'          | :get          | ref(:key1)        | ref(:value1)     | {} | nil
      'execute :mget command'         | :mget         | ref(:keys)        | ref(:values)     | {} | nil
      'execute :mget with block'      | :mget         | ref(:keys)        | ref(:values)     | {} | ->(value) { value }
      'execute :smembers command'     | :smembers     | ref(:skey)        | ref(:svalues)    | {} | nil
      'execute :scard command'        | :scard        | ref(:skey)        | 2                | {} | nil
      'execute :sismember command'    | :sismember    | ref(:smemberargs) | true             | {} | nil
      'execute :exists command'       | :exists       | ref(:key1)        | 1                | {} | nil
      'execute :exists? command'      | :exists?      | ref(:key1)        | true             | {} | nil
      'execute :hget command'         | :hget         | ref(:hgetargs)    | ref(:value1)     | {} | nil
      'execute :hlen command'         | :hlen         | ref(:hkey)        | 1                | {} | nil
      'execute :hgetall command'      | :hgetall      | ref(:hkey)        | ref(:hvalmapped) | {} | nil
      'execute :hexists command'      | :hexists      | ref(:hgetargs)    | true             | {} | nil
      'execute :hmget command'        | :hmget        | ref(:hgetargs)    | ref(:hmgetval)   | {} | nil
      'execute :mapped_hmget command' | :mapped_hmget | ref(:mhmgetargs)  | ref(:hvalmapped) | {} | nil
      'execute :sscan command'        | :sscan        | ref(:sscanargs)   | ref(:sscanval)   | {} | nil

      # we run *scan_each here as they are reads too
      'execute :scan_each command'    | :scan_each    | nil         | ref(:scan_each_val) | ref(:scan_each_arg)  | nil
      'execute :sscan_each command'   | :sscan_each   | ref(:skey2) | ref(:sscan_eachval) | {}                   | nil
      'execute :sscan_each w block'   | :sscan_each   | ref(:skey)  | ref(:sscan_eachval) | ref(:sscan_each_arg) | nil
      'execute :hscan_each command'   | :hscan_each   | ref(:hkey)  | ref(:hscan_eachval) | {}                   | nil
      'execute :hscan_each w block'   | :hscan_each   | ref(:hkey2) | ref(:hscan_eachval) | ref(:sscan_each_arg) | nil
      'execute :zscan_each command'   | :zscan_each   | ref(:zkey)  | ref(:zscan_eachval) | {}                   | nil
      'execute :zscan_each w block'   | :zscan_each   | ref(:zkey2) | ref(:zscan_eachval) | ref(:sscan_each_arg) | nil
    end
    # rubocop:enable  Layout/LineLength

    before do
      primary_store.set(key1, value1)
      primary_store.set(key2, value2)
      primary_store.sadd?(skey, [value1, value2])
      primary_store.sadd?(skey2, [value1])
      primary_store.hset(hkey, hitem1, value1)
      primary_store.hset(hkey2, hitem1, value1, hitem2, value2)
      primary_store.zadd(zkey, 1, value1)
      primary_store.zadd(zkey2, [[1, value1], [2, value2]])

      secondary_store.set(key1, value1)
      secondary_store.set(key2, value2)
      secondary_store.sadd?(skey, [value1, value2])
      secondary_store.sadd?(skey2, [value1])
      secondary_store.hset(hkey, hitem1, value1)
      secondary_store.hset(hkey2, hitem1, value1, hitem2, value2)
      secondary_store.zadd(zkey, 1, value1)
      secondary_store.zadd(zkey2, [[1, value1], [2, value2]])
    end

    after do
      primary_store.flushdb
      secondary_store.flushdb
    end

    RSpec.shared_examples_for 'reads correct value' do
      it 'returns the correct value' do
        if value.is_a?(Array)
          # :smembers does not guarantee the order it will return the values (unsorted set)
          is_expected.to match_array(value)
        else
          is_expected.to eq(value)
        end
      end
    end

    RSpec.shared_examples_for 'secondary store' do
      it 'execute on the secondary instance' do
        expect(secondary_store).to receive(name).with(*expected_args).and_call_original

        subject
      end

      include_examples 'reads correct value'

      it 'does not execute on the primary store' do
        expect(primary_store).not_to receive(name)

        subject
      end
    end

    with_them do
      describe name.to_s do
        let(:expected_args) { kwargs&.present? ? [*args, { **kwargs }] : Array(args) }

        before do
          allow(primary_store).to receive(name).and_call_original
          allow(secondary_store).to receive(name).and_call_original
        end

        context 'when reading from the primary is successful' do
          it 'returns the correct value' do
            expect(primary_store).to receive(name).with(*expected_args).and_call_original

            subject
          end

          include_examples 'reads correct value'
        end

        context 'when reading from default instance is raising an exception' do
          before do
            allow(multi_store.default_store).to receive(name).with(*expected_args).and_raise(StandardError)
            allow(Gitlab::ErrorTracking).to receive(:log_exception)
          end

          it 'logs the exception and re-raises the error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
              hash_including(:multi_store_error_message, instance_name: instance_name, command_name: name))

            expect { subject }.to raise_error(an_instance_of(StandardError))
          end
        end

        context 'when reading from empty default instance' do
          before do
            # this ensures a cache miss without having to stub the default store
            multi_store.default_store.flushdb
          end

          it 'does not call the fallback store' do
            expect(multi_store.fallback_store).not_to receive(name)
          end
        end

        context 'when the command is executed within pipelined block' do
          subject do
            multi_store.pipelined do |pipeline|
              pipeline.send(name, *args, **kwargs)
            end
          end

          it 'is executed only 1 time on primary and secondary instance' do
            expect(primary_store).to receive(:pipelined).and_call_original
            expect(secondary_store).to receive(:pipelined).and_call_original

            2.times do
              expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
                expect(pipeline).to receive(name).with(*expected_args).once.and_call_original
              end
            end

            subject
          end
        end

        if params[:block]
          subject do
            multi_store.send(name, *expected_args, &block)
          end

          context 'when block is provided' do
            it 'only default store yields to the block' do
              expect(primary_store).to receive(name).and_yield(value)
              expect(secondary_store).not_to receive(name).and_yield(value)

              subject
            end

            it 'only default store to execute' do
              expect(primary_store).to receive(name).with(*expected_args).and_call_original
              expect(secondary_store).not_to receive(name).with(*expected_args).and_call_original

              subject
            end

            include_examples 'reads correct value'
          end
        end

        context 'with both primary and secondary store using same redis instance' do
          let(:primary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
          let(:secondary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
          let(:multi_store) { described_class.new(primary_store, secondary_store, instance_name) }

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
              expect(secondary_store).to receive(name).with(*expected_args).and_call_original
              expect(primary_store).not_to receive(name).with(*expected_args).and_call_original

              subject
            end
          end

          context 'when using primary store as default' do
            it 'executes only on primary redis store', :aggregate_failures do
              expect(primary_store).to receive(name).with(*expected_args).and_call_original
              expect(secondary_store).not_to receive(name).with(*expected_args).and_call_original

              subject
            end
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

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
      multi_store.mget(values) do |v|
        multi_store.sadd(skey, v)
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

  RSpec.shared_examples_for 'verify that store contains values' do |store|
    it "#{store} redis store contains correct values", :aggregate_failures do
      subject

      redis_store = multi_store.send(store)

      if expected_value.is_a?(Array)
        # :smembers does not guarantee the order it will return the values
        expect(redis_store.send(verification_name, *verification_args)).to match_array(expected_value)
      else
        expect(redis_store.send(verification_name, *verification_args)).to eq(expected_value)
      end
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  context 'with WRITE redis commands' do
    let_it_be(:ikey1) { "counter1" }
    let_it_be(:ikey2) { "counter2" }
    let_it_be(:iargs) { [ikey2, 3] }
    let_it_be(:ivalue1) { "1" }
    let_it_be(:ivalue2) { "3" }
    let_it_be(:key1) { "redis:{1}:key_a" }
    let_it_be(:key2) { "redis:{1}:key_b" }
    let_it_be(:key3) { "redis:{1}:key_c" }
    let_it_be(:key4) { "redis:{1}:key_d" }
    let_it_be(:value1) { "redis_value1" }
    let_it_be(:value2) { "redis_value2" }
    let_it_be(:key1_value1) { [key1, value1] }
    let_it_be(:key1_value2) { [key1, value2] }
    let_it_be(:ttl) { 10 }
    let_it_be(:key1_ttl_value1) { [key1, ttl, value1] }
    let_it_be(:skey) { "redis:set:key" }
    let_it_be(:svalues1) { [value2, value1] }
    let_it_be(:svalues2) { [value1] }
    let_it_be(:skey_value1) { [skey, [value1]] }
    let_it_be(:skey_value2) { [skey, [value2]] }
    let_it_be(:script) { %(redis.call("set", "#{key1}", "#{value1}")) }
    let_it_be(:hkey1) { "redis:{1}:hash_a" }
    let_it_be(:hkey2) { "redis:{1}:hash_b" }
    let_it_be(:item) { "item" }
    let_it_be(:hdelarg) { [hkey1, item] }
    let_it_be(:hsetarg) { [hkey2, item, value1] }
    let_it_be(:mhsetarg) { [hkey2, { "item" => value1 }] }
    let_it_be(:hgetarg) { [hkey2, item] }
    let_it_be(:expireargs) { [key3, ttl] }

    # rubocop:disable  Layout/LineLength
    where(:case_name, :name, :args, :expected_value, :verification_name, :verification_args) do
      'execute :set command'          | :set            | ref(:key1_value1)      | ref(:value1)   | :get      | ref(:key1)
      'execute :setnx command'        | :setnx          | ref(:key1_value2)      | ref(:value1)   | :get      | ref(:key2)
      'execute :setex command'        | :setex          | ref(:key1_ttl_value1)  | ref(:ttl)      | :ttl      | ref(:key1)
      'execute :sadd command'         | :sadd           | ref(:skey_value2)      | ref(:svalues1) | :smembers | ref(:skey)
      'execute :srem command'         | :srem           | ref(:skey_value1)      | []             | :smembers | ref(:skey)
      'execute :del command'          | :del            | ref(:key2)             | nil            | :get      | ref(:key2)
      'execute :unlink command'       | :unlink         | ref(:key3)             | nil            | :get      | ref(:key3)
      'execute :flushdb command'      | :flushdb        | nil                    | 0              | :dbsize   | nil
      'execute :eval command'         | :eval           | ref(:script)           | ref(:value1)   | :get      | ref(:key1)
      'execute :incr command'         | :incr           | ref(:ikey1)            | ref(:ivalue1)  | :get      | ref(:ikey1)
      'execute :incrby command'       | :incrby         | ref(:iargs)            | ref(:ivalue2)  | :get      | ref(:ikey2)
      'execute :hset command'         | :hset           | ref(:hsetarg)          | ref(:value1)   | :hget     | ref(:hgetarg)
      'execute :hdel command'         | :hdel           | ref(:hdelarg)          | nil            | :hget     | ref(:hdelarg)
      'execute :expire command'       | :expire         | ref(:expireargs)       | ref(:ttl)      | :ttl      | ref(:key3)
      'execute :mapped_hmset command' | :mapped_hmset   | ref(:mhsetarg)         | ref(:value1)   | :hget     | ref(:hgetarg)
    end
    # rubocop:enable  Layout/LineLength

    before do
      primary_store.flushdb
      secondary_store.flushdb

      primary_store.set(key2, value1)
      primary_store.set(key3, value1)
      primary_store.set(key4, value1)
      primary_store.sadd?(skey, value1)
      primary_store.hset(hkey2, item, value1)

      secondary_store.set(key2, value1)
      secondary_store.set(key3, value1)
      secondary_store.set(key4, value1)
      secondary_store.sadd?(skey, value1)
      secondary_store.hset(hkey2, item, value1)
    end

    with_them do
      describe name.to_s do
        let(:expected_args) { args || no_args }

        before do
          allow(primary_store).to receive(name).and_call_original
          allow(secondary_store).to receive(name).and_call_original
        end

        context 'when executing on primary instance is successful' do
          it 'executes on both primary and secondary redis store', :aggregate_failures do
            expect(primary_store).to receive(name).with(*expected_args).and_call_original
            expect(secondary_store).to receive(name).with(*expected_args).and_call_original

            subject
          end

          include_examples 'verify that store contains values', :primary_store
          include_examples 'verify that store contains values', :secondary_store
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
              expect(secondary_store).to receive(name).with(*expected_args).and_call_original
              expect(primary_store).not_to receive(name).with(*expected_args).and_call_original

              subject
            end
          end

          context 'when using primary store as default' do
            it 'executes only on primary redis store', :aggregate_failures do
              expect(primary_store).to receive(name).with(*expected_args).and_call_original
              expect(secondary_store).not_to receive(name).with(*expected_args).and_call_original

              subject
            end
          end
        end

        context 'when executing on the primary instance is raising an exception' do
          before do
            allow(primary_store).to receive(name).with(*expected_args).and_raise(StandardError)
            allow(Gitlab::ErrorTracking).to receive(:log_exception)
          end

          it 'logs the exception and execute on secondary instance', :aggregate_failures do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
              hash_including(:multi_store_error_message, command_name: name, instance_name: instance_name))
            expect(secondary_store).to receive(name).with(*expected_args).and_call_original

            subject
          end

          include_examples 'verify that store contains values', :secondary_store
        end

        context 'when the command is executed within pipelined block' do
          subject do
            multi_store.pipelined do |pipeline|
              pipeline.send(name, *args)
            end
          end

          it 'is executed only 1 time on each instance', :aggregate_failures do
            expect(primary_store).to receive(:pipelined).and_call_original
            expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
              expect(pipeline).to receive(name).with(*expected_args).once.and_call_original
            end

            expect(secondary_store).to receive(:pipelined).and_call_original
            expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
              expect(pipeline).to receive(name).with(*expected_args).once.and_call_original
            end

            subject
          end

          include_examples 'verify that store contains values', :primary_store
          include_examples 'verify that store contains values', :secondary_store
        end
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

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
        multi_store.send(name) do |redis|
          redis.set(key1, value1)
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

      context 'when executing on the primary instance is raising an exception' do
        before do
          allow(primary_store).to receive(name).and_raise(StandardError)
          allow(Gitlab::ErrorTracking).to receive(:log_exception)
        end

        it 'logs the exception and execute on secondary instance', :aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
            hash_including(:multi_store_error_message, command_name: name))
          expect(secondary_store).to receive(name).and_call_original

          subject
        end

        include_examples 'verify that store contains values', :secondary_store
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
          multi_store.send(name) do |redis|
            redis.get(key1)
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
            primary_store.set(key1, value1)
            secondary_store.set(key1, value2)
          end

          it 'returns the value from the secondary store, logging an error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              pipeline_diff_error_with_stacktrace(
                'Pipelined command executed on both stores successfully but results differ between them. ' \
                  "Result from the primary: [#{value1.inspect}]. Result from the secondary: [#{value2.inspect}]."
              ),
              hash_including(command_name: name, instance_name: instance_name)
            ).and_call_original
            expect(counter).to receive(:increment).with(command: name, instance_name: instance_name)

            expect(subject).to eq([value2])
          end
        end

        context 'when the value does not exist on the primary but it does on the secondary' do
          before do
            secondary_store.set(key1, value2)
          end

          it 'returns the value from the secondary store, logging an error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              pipeline_diff_error_with_stacktrace(
                'Pipelined command executed on both stores successfully but results differ between them. ' \
                  "Result from the primary: [nil]. Result from the secondary: [#{value2.inspect}]."
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
    end
  end

  describe '#multi' do
    include_examples 'pipelined command', :multi
  end

  describe '#pipelined' do
    include_examples 'pipelined command', :pipelined
  end

  describe '#ping' do
    subject { multi_store.ping }

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
          expect(multi_store.ping('hello world')).to eq('hello world')
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

  context 'with unsupported command' do
    let(:counter) { Gitlab::Metrics::NullMetric.instance }

    before do
      primary_store.flushdb
      secondary_store.flushdb
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
    end

    subject { multi_store.command }

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
        subject { multi_store.info }

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
          multi_store.pipelined(&:command)
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
    subject { multi_store.to_s }

    it 'returns same value as primary_store' do
      is_expected.to eq(primary_store.to_s)
    end
  end

  describe '#is_a?' do
    it 'returns true for ::Redis::Store' do
      expect(multi_store.is_a?(::Redis::Store)).to be true
    end
  end

  describe '#use_primary_and_secondary_stores?' do
    it 'multi store is enabled' do
      expect(multi_store.use_primary_and_secondary_stores?).to be true
    end

    context 'with empty DB' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_return(false)
      end

      it 'multi store is disabled' do
        expect(multi_store.use_primary_and_secondary_stores?).to be false
      end
    end

    context 'when FF table guard raises' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_raise
      end

      it 'multi store is disabled' do
        expect(multi_store.use_primary_and_secondary_stores?).to be false
      end
    end
  end

  describe '#use_primary_store_as_default?' do
    it 'multi store is disabled' do
      expect(multi_store.use_primary_store_as_default?).to be true
    end

    context 'with empty DB' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_return(false)
      end

      it 'multi store is disabled' do
        expect(multi_store.use_primary_and_secondary_stores?).to be false
      end
    end

    context 'when FF table guard raises' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_raise
      end

      it 'multi store is disabled' do
        expect(multi_store.use_primary_and_secondary_stores?).to be false
      end
    end
  end

  def create_redis_store(options, extras = {})
    ::Redis::Store.new(options.merge(extras))
  end
end
