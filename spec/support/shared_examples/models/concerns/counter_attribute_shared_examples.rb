# frozen_string_literal: true
require 'spec_helper'

RSpec.shared_examples_for CounterAttribute do |counter_attributes|
  it 'defines a Redis counter_key' do
    expect(model.counter_key(:counter_name))
      .to eq("project:{#{model.project_id}}:counters:CounterAttributeModel:#{model.id}:counter_name")
  end

  it 'defines a method to store counters' do
    expect(model.class.counter_attributes.to_a).to eq(counter_attributes)
  end

  counter_attributes.each do |attribute|
    describe attribute do
      describe '#delayed_increment_counter', :redis do
        let(:increment) { 10 }

        subject { model.delayed_increment_counter(attribute, increment) }

        context 'when attribute is a counter attribute' do
          where(:increment) { [10, -3] }

          with_them do
            it 'increments the counter in Redis' do
              subject

              Gitlab::Redis::SharedState.with do |redis|
                counter = redis.get(model.counter_key(attribute))
                expect(counter).to eq(increment.to_s)
              end
            end

            it 'does not increment the counter for the record' do
              expect { subject }.not_to change { model.reset.read_attribute(attribute) }
            end

            it 'schedules a worker to flush counter increments asynchronously' do
              expect(FlushCounterIncrementsWorker).to receive(:perform_in)
                .with(CounterAttribute::WORKER_DELAY, model.class.name, model.id, attribute)
                .and_call_original

              subject
            end
          end

          context 'when increment is 0' do
            let(:increment) { 0 }

            it 'does nothing' do
              expect(FlushCounterIncrementsWorker).not_to receive(:perform_in)
              expect(model).not_to receive(:update!)

              subject
            end
          end
        end

        context 'when attribute is not a counter attribute' do
          it 'delegates to ActiveRecord update!' do
            expect { model.delayed_increment_counter(:unknown_attribute, 10) }
              .to raise_error(ActiveModel::MissingAttributeError)
          end
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(efficient_counter_attribute: false)
          end

          it 'delegates to ActiveRecord update!' do
            expect { subject }
              .to change { model.reset.read_attribute(attribute) }.by(increment)
          end

          it 'does not increment the counter in Redis' do
            subject

            Gitlab::Redis::SharedState.with do |redis|
              counter = redis.get(model.counter_key(attribute))
              expect(counter).to be_nil
            end
          end
        end
      end
    end
  end

  describe '.flush_increments_to_database!', :redis do
    let(:incremented_attribute) { counter_attributes.first }

    subject { model.flush_increments_to_database!(incremented_attribute) }

    it 'obtains an exclusive lease during processing' do
      expect(model)
        .to receive(:in_lock)
        .with(model.counter_lock_key(incremented_attribute), ttl: described_class::WORKER_LOCK_TTL)
        .and_call_original

      subject
    end

    context 'when there is a counter to flush' do
      before do
        model.delayed_increment_counter(incremented_attribute, 10)
        model.delayed_increment_counter(incremented_attribute, -3)
      end

      it 'updates the record' do
        expect { subject }.to change { model.reset.read_attribute(incremented_attribute) }.by(7)
      end

      it 'removes the increment entry from Redis' do
        Gitlab::Redis::SharedState.with do |redis|
          key_exists = redis.exists(model.counter_key(incremented_attribute))
          expect(key_exists).to be_truthy
        end

        subject

        Gitlab::Redis::SharedState.with do |redis|
          key_exists = redis.exists(model.counter_key(incremented_attribute))
          expect(key_exists).to be_falsey
        end
      end
    end

    context 'when there are no counters to flush' do
      context 'when there are no counters in the relative :flushed key' do
        it 'does not change the record' do
          expect { subject }.not_to change { model.reset.attributes }
        end
      end

      # This can be the case where updating counters in the database fails with error
      # and retrying the worker will retry flushing the counters but the main key has
      # disappeared and the increment has been moved to the "<...>:flushed" key.
      context 'when there are counters in the relative :flushed key' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.incrby(model.counter_flushed_key(incremented_attribute), 10)
          end
        end

        it 'updates the record' do
          expect { subject }.to change { model.reset.read_attribute(incremented_attribute) }.by(10)
        end

        it 'deletes the relative :flushed key' do
          subject

          Gitlab::Redis::SharedState.with do |redis|
            key_exists = redis.exists(model.counter_flushed_key(incremented_attribute))
            expect(key_exists).to be_falsey
          end
        end
      end
    end

    context 'when deleting :flushed key fails' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.incrby(model.counter_flushed_key(incremented_attribute), 10)

          expect(redis).to receive(:del).and_raise('could not delete key')
        end
      end

      it 'does a rollback of the counter update' do
        expect { subject }.to raise_error('could not delete key')

        expect(model.reset.read_attribute(incremented_attribute)).to eq(0)
      end
    end
  end
end
