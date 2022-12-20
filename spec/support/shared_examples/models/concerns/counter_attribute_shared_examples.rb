# frozen_string_literal: true
require 'spec_helper'

RSpec.shared_examples_for CounterAttribute do |counter_attributes|
  before do
    Gitlab::ApplicationContext.push(feature_category: 'test', caller_id: 'caller')
  end

  it 'defines a method to store counters' do
    registered_attributes = model.class.counter_attributes.map { |e| e[:attribute] } # rubocop:disable Rails/Pluck
    expect(registered_attributes).to contain_exactly(*counter_attributes)
  end

  counter_attributes.each do |attribute|
    describe attribute do
      describe '#increment_counter', :redis do
        let(:increment) { 10 }
        let(:counter_key) { model.counter(attribute).key }

        subject { model.increment_counter(attribute, increment) }

        context 'when attribute is a counter attribute' do
          where(:increment) { [10, -3] }

          with_them do
            it 'increments the counter in Redis and logs it' do
              expect(Gitlab::AppLogger).to receive(:info).with(
                hash_including(
                  message: 'Increment counter attribute',
                  attribute: attribute,
                  project_id: model.project_id,
                  increment: increment,
                  new_counter_value: 0 + increment,
                  current_db_value: model.read_attribute(attribute),
                  'correlation_id' => an_instance_of(String),
                  'meta.feature_category' => 'test',
                  'meta.caller_id' => 'caller'
                )
              )

              subject

              Gitlab::Redis::SharedState.with do |redis|
                counter = redis.get(counter_key)
                expect(counter).to eq(increment.to_s)
              end
            end

            it 'does not increment the counter for the record' do
              expect { subject }.not_to change { model.reset.read_attribute(attribute) }
            end

            it 'schedules a worker to flush counter increments asynchronously' do
              expect(FlushCounterIncrementsWorker).to receive(:perform_in)
                .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, model.class.name, model.id, attribute)
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
      end

      describe '#bulk_increment_counter', :redis do
        let(:increments) { [10, 5] }
        let(:total_amount) { increments.sum }
        let(:counter_key) { model.counter(attribute).key }

        subject { model.bulk_increment_counter(attribute, increments) }

        context 'when attribute is a counter attribute' do
          it 'increments the counter in Redis and logs it' do
            expect(Gitlab::AppLogger).to receive(:info).with(
              hash_including(
                message: 'Increment counter attribute',
                attribute: attribute,
                project_id: model.project_id,
                increment: total_amount,
                new_counter_value: 0 + total_amount,
                current_db_value: model.read_attribute(attribute),
                'correlation_id' => an_instance_of(String),
                'meta.feature_category' => 'test',
                'meta.caller_id' => 'caller'
              )
            )

            subject

            Gitlab::Redis::SharedState.with do |redis|
              counter = redis.get(counter_key)
              expect(counter).to eq(total_amount.to_s)
            end
          end

          it 'does not increment the counter for the record' do
            expect { subject }.not_to change { model.reset.read_attribute(attribute) }
          end

          it 'schedules a worker to flush counter increments asynchronously' do
            expect(FlushCounterIncrementsWorker).to receive(:perform_in)
              .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, model.class.name, model.id, attribute)
              .and_call_original

            subject
          end
        end
      end
    end
  end

  describe '#reset_counter!' do
    let(:attribute) { counter_attributes.first }
    let(:counter_key) { model.counter(attribute).key }

    before do
      model.update!(attribute => 123)
      model.increment_counter(attribute, 10)
    end

    subject { model.reset_counter!(attribute) }

    it 'resets the attribute value to 0 and clears existing counter', :aggregate_failures do
      expect { subject }.to change { model.reload.send(attribute) }.from(123).to(0)

      Gitlab::Redis::SharedState.with do |redis|
        key_exists = redis.exists?(counter_key)
        expect(key_exists).to be_falsey
      end
    end

    it_behaves_like 'obtaining lease to update database' do
      context 'when the execution raises error' do
        before do
          allow(model).to receive(:update!).and_raise(StandardError, 'Something went wrong')
        end

        it 'reraises error' do
          expect { subject }.to raise_error(StandardError, 'Something went wrong')
        end
      end
    end
  end

  describe '#update_counters_with_lease' do
    let(:increments) { { build_artifacts_size: 1, packages_size: 2 } }

    subject { model.update_counters_with_lease(increments) }

    it 'updates counters of the record' do
      expect { subject }
        .to change { model.reload.build_artifacts_size }.by(1)
        .and change { model.reload.packages_size }.by(2)
    end

    it_behaves_like 'obtaining lease to update database' do
      context 'when the execution raises error' do
        before do
          allow(model.class).to receive(:update_counters).and_raise(StandardError, 'Something went wrong')
        end

        it 'reraises error' do
          expect { subject }.to raise_error(StandardError, 'Something went wrong')
        end
      end
    end
  end
end

RSpec.shared_examples 'obtaining lease to update database' do
  context 'when it is unable to obtain lock' do
    before do
      allow(model).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end

    it 'logs a warning' do
      allow(model).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)

      expect(Gitlab::AppLogger).to receive(:warn).once

      expect { subject }.not_to raise_error
    end
  end

  context 'when feature flag counter_attribute_db_lease_for_update is disabled' do
    before do
      stub_feature_flags(counter_attribute_db_lease_for_update: false)
      allow(model).to receive(:in_lock).and_call_original
    end

    it 'does not attempt to get a lock' do
      expect(model).not_to receive(:in_lock)

      subject
    end
  end
end
