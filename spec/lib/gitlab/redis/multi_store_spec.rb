# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::MultiStore do
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
  let_it_be(:multi_store) { described_class.new(primary_store, secondary_store, instance_name)}

  subject { multi_store.send(name, *args) }

  after(:all) do
    primary_store.flushdb
    secondary_store.flushdb
  end

  context 'when primary_store is nil' do
    let(:multi_store) { described_class.new(nil, secondary_store, instance_name)}

    it 'fails with exception' do
      expect { multi_store }.to raise_error(ArgumentError, /primary_store is required/)
    end
  end

  context 'when secondary_store is nil' do
    let(:multi_store) { described_class.new(primary_store, nil, instance_name)}

    it 'fails with exception' do
      expect { multi_store }.to raise_error(ArgumentError, /secondary_store is required/)
    end
  end

  context 'when primary_store is not a ::Redis instance' do
    before do
      allow(primary_store).to receive(:is_a?).with(::Redis).and_return(false)
    end

    it 'fails with exception' do
      expect { described_class.new(primary_store, secondary_store, instance_name) }.to raise_error(ArgumentError, /invalid primary_store/)
    end
  end

  context 'when secondary_store is not a ::Redis instance' do
    before do
      allow(secondary_store).to receive(:is_a?).with(::Redis).and_return(false)
    end

    it 'fails with exception' do
      expect { described_class.new(primary_store, secondary_store, instance_name) }.to raise_error(ArgumentError, /invalid secondary_store/)
    end
  end

  context 'with READ redis commands' do
    let_it_be(:key1) { "redis:{1}:key_a" }
    let_it_be(:key2) { "redis:{1}:key_b" }
    let_it_be(:value1) { "redis_value1"}
    let_it_be(:value2) { "redis_value2"}
    let_it_be(:skey) { "redis:set:key" }
    let_it_be(:keys) { [key1, key2] }
    let_it_be(:values) { [value1, value2] }
    let_it_be(:svalues) { [value2, value1] }

    where(:case_name, :name, :args, :value, :block) do
      'execute :get command'      | :get      | ref(:key1)  | ref(:value1)  | nil
      'execute :mget command'     | :mget     | ref(:keys)  | ref(:values)  | nil
      'execute :mget with block'  | :mget     | ref(:keys)  | ref(:values)  | ->(value) { value }
      'execute :smembers command' | :smembers | ref(:skey)  | ref(:svalues) | nil
      'execute :scard command'    | :scard    | ref(:skey)  | 2             | nil
    end

    before(:all) do
      primary_store.multi do |multi|
        multi.set(key1, value1)
        multi.set(key2, value2)
        multi.sadd(skey, value1)
        multi.sadd(skey, value2)
      end

      secondary_store.multi do |multi|
        multi.set(key1, value1)
        multi.set(key2, value2)
        multi.sadd(skey, value1)
        multi.sadd(skey, value2)
      end
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

    RSpec.shared_examples_for 'fallback read from the secondary store' do
      it 'fallback and execute on secondary instance' do
        expect(secondary_store).to receive(name).with(*args).and_call_original

        subject
      end

      it 'logs the ReadFromPrimaryError' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(Gitlab::Redis::MultiStore::ReadFromPrimaryError),
          hash_including(command_name: name, extra: hash_including(instance_name: instance_name)))

        subject
      end

      it 'increment read fallback count metrics' do
        expect(multi_store).to receive(:increment_read_fallback_count).with(name)

        subject
      end

      include_examples 'reads correct value'

      context 'when fallback read from the secondary instance raises an exception' do
        before do
          allow(secondary_store).to receive(name).with(*args).and_raise(StandardError)
        end

        it 'fails with exception' do
          expect { subject }.to raise_error(StandardError)
        end
      end
    end

    RSpec.shared_examples_for 'secondary store' do
      it 'execute on the secondary instance' do
        expect(secondary_store).to receive(name).with(*args).and_call_original

        subject
      end

      include_examples 'reads correct value'

      it 'does not execute on the primary store' do
        expect(primary_store).not_to receive(name)

        subject
      end
    end

    with_them do
      describe "#{name}" do
        before do
          allow(primary_store).to receive(name).and_call_original
          allow(secondary_store).to receive(name).and_call_original
        end

        context 'with feature flag :use_multi_store enabled' do
          before do
            stub_feature_flags(use_multi_store: true)
          end

          context 'when reading from the primary is successful' do
            it 'returns the correct value' do
              expect(primary_store).to receive(name).with(*args).and_call_original

              subject
            end

            it 'does not execute on the secondary store' do
              expect(secondary_store).not_to receive(name)

              subject
            end

            include_examples 'reads correct value'
          end

          context 'when reading from primary instance is raising an exception' do
            before do
              allow(primary_store).to receive(name).with(*args).and_raise(StandardError)
              allow(Gitlab::ErrorTracking).to receive(:log_exception)
            end

            it 'logs the exception' do
              expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
                hash_including(extra: hash_including(:multi_store_error_message, instance_name: instance_name),
                               command_name: name))

              subject
            end

            include_examples 'fallback read from the secondary store'
          end

          context 'when reading from primary instance return no value' do
            before do
              allow(primary_store).to receive(name).and_return(nil)
            end

            include_examples 'fallback read from the secondary store'
          end

          context 'when the command is executed within pipelined block' do
            subject do
              multi_store.pipelined do
                multi_store.send(name, *args)
              end
            end

            it 'is executed only 1 time on primary instance' do
              expect(primary_store).to receive(name).with(*args).once

              subject
            end
          end

          if params[:block]
            subject do
              multi_store.send(name, *args, &block)
            end

            context 'when block is provided' do
              it 'yields to the block' do
                expect(primary_store).to receive(name).and_yield(value)

                subject
              end

              include_examples 'reads correct value'
            end
          end
        end

        context 'with feature flag :use_multi_store is disabled' do
          before do
            stub_feature_flags(use_multi_store: false)
          end

          it_behaves_like 'secondary store'
        end

        context 'with both primary and secondary store using same redis instance' do
          let(:primary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
          let(:secondary_store) { create_redis_store(redis_store_class.params, db: primary_db, serializer: nil) }
          let(:multi_store) { described_class.new(primary_store, secondary_store, instance_name)}

          it_behaves_like 'secondary store'
        end
      end
    end
  end

  context 'with WRITE redis commands' do
    let_it_be(:key1) { "redis:{1}:key_a" }
    let_it_be(:key2) { "redis:{1}:key_b" }
    let_it_be(:value1) { "redis_value1"}
    let_it_be(:value2) { "redis_value2"}
    let_it_be(:key1_value1) { [key1, value1] }
    let_it_be(:key1_value2) { [key1, value2] }
    let_it_be(:ttl) { 10 }
    let_it_be(:key1_ttl_value1) { [key1, ttl, value1] }
    let_it_be(:skey) { "redis:set:key" }
    let_it_be(:svalues1) { [value2, value1] }
    let_it_be(:svalues2) { [value1] }
    let_it_be(:skey_value1) { [skey, value1] }
    let_it_be(:skey_value2) { [skey, value2] }

    where(:case_name, :name, :args, :expected_value, :verification_name, :verification_args) do
      'execute :set command'       | :set      | ref(:key1_value1)      | ref(:value1)      | :get      | ref(:key1)
      'execute :setnx command'     | :setnx    | ref(:key1_value2)      | ref(:value1)      | :get      | ref(:key2)
      'execute :setex command'     | :setex    | ref(:key1_ttl_value1)  | ref(:ttl)         | :ttl      | ref(:key1)
      'execute :sadd command'      | :sadd     | ref(:skey_value2)      | ref(:svalues1)    | :smembers | ref(:skey)
      'execute :srem command'      | :srem     | ref(:skey_value1)      | []                | :smembers | ref(:skey)
      'execute :del command'       | :del      | ref(:key2)             | nil               | :get      | ref(:key2)
      'execute :flushdb command'   | :flushdb  | nil                    | 0                 | :dbsize   | nil
    end

    before do
      primary_store.flushdb
      secondary_store.flushdb

      primary_store.multi do |multi|
        multi.set(key2, value1)
        multi.sadd(skey, value1)
      end

      secondary_store.multi do |multi|
        multi.set(key2, value1)
        multi.sadd(skey, value1)
      end
    end

    RSpec.shared_examples_for 'verify that store contains values' do |store|
      it "#{store} redis store contains correct values", :aggregate_errors do
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

    with_them do
      describe "#{name}" do
        let(:expected_args) {args || no_args }

        before do
          allow(primary_store).to receive(name).and_call_original
          allow(secondary_store).to receive(name).and_call_original
        end

        context 'with feature flag :use_multi_store enabled' do
          before do
            stub_feature_flags(use_multi_store: true)
          end

          context 'when executing on primary instance is successful' do
            it 'executes on both primary and secondary redis store', :aggregate_errors do
              expect(primary_store).to receive(name).with(*expected_args).and_call_original
              expect(secondary_store).to receive(name).with(*expected_args).and_call_original

              subject
            end

            include_examples 'verify that store contains values', :primary_store
            include_examples 'verify that store contains values', :secondary_store
          end

          context 'when executing on the primary instance is raising an exception' do
            before do
              allow(primary_store).to receive(name).with(*expected_args).and_raise(StandardError)
              allow(Gitlab::ErrorTracking).to receive(:log_exception)
            end

            it 'logs the exception and execute on secondary instance', :aggregate_errors do
              expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
                hash_including(extra: hash_including(:multi_store_error_message), command_name: name))
              expect(secondary_store).to receive(name).with(*expected_args).and_call_original

              subject
            end

            include_examples 'verify that store contains values', :secondary_store
          end

          context 'when the command is executed within pipelined block' do
            subject do
              multi_store.pipelined do
                multi_store.send(name, *args)
              end
            end

            it 'is executed only 1 time on each instance', :aggregate_errors do
              expect(primary_store).to receive(name).with(*expected_args).once
              expect(secondary_store).to receive(name).with(*expected_args).once

              subject
            end

            include_examples 'verify that store contains values', :primary_store
            include_examples 'verify that store contains values', :secondary_store
          end
        end

        context 'with feature flag :use_multi_store is disabled' do
          before do
            stub_feature_flags(use_multi_store: false)
          end

          it 'executes only on the secondary redis store', :aggregate_errors do
            expect(secondary_store).to receive(name).with(*expected_args)
            expect(primary_store).not_to receive(name).with(*expected_args)

            subject
          end

          include_examples 'verify that store contains values', :secondary_store
        end
      end
    end
  end

  context 'with unsupported command' do
    before do
      primary_store.flushdb
      secondary_store.flushdb
    end

    let_it_be(:key) { "redis:counter" }

    subject do
      multi_store.incr(key)
    end

    it 'executes method missing' do
      expect(multi_store).to receive(:method_missing)

      subject
    end

    it 'logs MethodMissingError' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(Gitlab::Redis::MultiStore::MethodMissingError),
        hash_including(command_name: :incr, extra: hash_including(instance_name: instance_name)))

      subject
    end

    it 'increments method missing counter' do
      expect(multi_store).to receive(:increment_method_missing_count).with(:incr)

      subject
    end

    it 'fallback and executes only on the secondary store', :aggregate_errors do
      expect(secondary_store).to receive(:incr).with(key).and_call_original
      expect(primary_store).not_to receive(:incr)

      subject
    end

    it 'correct value is stored on the secondary store', :aggregate_errors do
      subject

      expect(primary_store.get(key)).to be_nil
      expect(secondary_store.get(key)).to eq('1')
    end

    context 'when the command is executed within pipelined block' do
      subject do
        multi_store.pipelined do
          multi_store.incr(key)
        end
      end

      it 'is executed only 1 time on each instance', :aggregate_errors do
        expect(primary_store).to receive(:incr).with(key).once
        expect(secondary_store).to receive(:incr).with(key).once

        subject
      end

      it "both redis stores are containing correct values", :aggregate_errors do
        subject

        expect(primary_store.get(key)).to eq('1')
        expect(secondary_store.get(key)).to eq('1')
      end
    end
  end

  def create_redis_store(options, extras = {})
    ::Redis::Store.new(options.merge(extras))
  end
end
