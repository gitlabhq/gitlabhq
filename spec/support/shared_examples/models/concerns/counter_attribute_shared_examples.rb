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
        let(:amount) { 10 }
        let(:increment) { Gitlab::Counters::Increment.new(amount: amount, ref: 3) }
        let(:counter_key) { model.counter(attribute).key }
        let(:returns_current) do
          model.class.counter_attributes
               .find { |a| a[:attribute] == attribute }
               .fetch(:returns_current, false)
        end

        subject { model.increment_counter(attribute, increment) }

        context 'when attribute is a counter attribute' do
          where(:amount) { [10, -3] }

          with_them do
            it 'increments the counter in Redis and logs it' do
              expect(Gitlab::AppLogger).to receive(:info).with(
                hash_including(
                  message: 'Increment counter attribute',
                  attribute: attribute,
                  project_id: model.project_id,
                  increment: amount,
                  ref: increment.ref,
                  new_counter_value: 0 + amount,
                  current_db_value: model.read_attribute(attribute),
                  'correlation_id' => an_instance_of(String),
                  'meta.feature_category' => 'test',
                  'meta.caller_id' => 'caller'
                )
              )

              subject

              Gitlab::Redis::SharedState.with do |redis|
                counter = redis.get(counter_key)
                expect(counter).to eq(amount.to_s)
              end
            end

            it 'does not increment the counter for the record' do
              expect { subject }.not_to change { model.reset.read_attribute(attribute) }
            end

            it 'schedules a worker to flush counter increments asynchronously' do
              expect(FlushCounterIncrementsWorker).to receive(:perform_in)
                .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, model.class.name, model.id, attribute.to_s)
                .and_call_original

              subject
            end
          end

          describe '#increment_amount' do
            it 'increases the egress in cache' do
              model.increment_amount(attribute, 3)

              expect(model.counter(attribute).get).to eq(3)
            end
          end

          describe '#current_counter' do
            let(:data_transfer_node) do
              args = { project: project }
              args[attribute] = 2
              create(:project_data_transfer, **args)
            end

            it 'increases the amount in cache' do
              if returns_current
                incremented_by = 4
                db_state = model.read_attribute(attribute)

                model.send("increment_#{attribute}".to_sym, incremented_by)

                expect(model.send(attribute)).to eq(db_state + incremented_by)
              end
            end
          end

          context 'when increment amount is 0' do
            let(:amount) { 0 }

            it 'does nothing' do
              expect(FlushCounterIncrementsWorker).not_to receive(:perform_in)
              expect(model).not_to receive(:update!)

              subject
            end
          end
        end
      end

      describe '#bulk_increment_counter', :redis do
        let(:increments) do
          [
            Gitlab::Counters::Increment.new(amount: 10, ref: 1),
            Gitlab::Counters::Increment.new(amount: 5, ref: 2)
          ]
        end

        let(:total_amount) { increments.sum(&:amount) }
        let(:counter_key) { model.counter(attribute).key }

        subject { model.bulk_increment_counter(attribute, increments) }

        context 'when attribute is a counter attribute' do
          it 'increments the counter in Redis and logs each increment' do
            increments.each do |increment|
              expect(Gitlab::AppLogger).to receive(:info).with(
                hash_including(
                  message: 'Increment counter attribute',
                  attribute: attribute,
                  project_id: model.project_id,
                  increment: increment.amount,
                  ref: increment.ref,
                  new_counter_value: 0 + total_amount,
                  current_db_value: model.read_attribute(attribute),
                  'correlation_id' => an_instance_of(String),
                  'meta.feature_category' => 'test',
                  'meta.caller_id' => 'caller'
                )
              )
            end

            subject

            Gitlab::Redis::SharedState.with do |redis|
              counter = redis.get(counter_key)
              expect(counter).to eq(total_amount.to_s)
            end
          end

          context 'when feature flag split_log_bulk_increment_counter is disabled' do
            before do
              stub_feature_flags(split_log_bulk_increment_counter: false)
            end

            it 'logs a single total increment' do
              expect(Gitlab::AppLogger).to receive(:info).with(
                hash_including(
                  message: 'Increment counter attribute',
                  attribute: attribute,
                  project_id: model.project_id,
                  increment: increments.sum(&:amount),
                  new_counter_value: 0 + total_amount,
                  current_db_value: model.read_attribute(attribute),
                  'correlation_id' => an_instance_of(String),
                  'meta.feature_category' => 'test',
                  'meta.caller_id' => 'caller'
                )
              )

              subject
            end
          end

          it 'does not increment the counter for the record' do
            expect { subject }.not_to change { model.reset.read_attribute(attribute) }
          end

          it 'schedules a worker to flush counter increments asynchronously' do
            expect(FlushCounterIncrementsWorker).to receive(:perform_in)
              .with(Gitlab::Counters::BufferedCounter::WORKER_DELAY, model.class.name, model.id, attribute.to_s)
              .and_call_original

            subject
          end
        end
      end
    end
  end

  describe '#update_counters_with_lease' do
    let_it_be(:first_attribute) { counter_attributes.first }
    let_it_be(:second_attribute) { counter_attributes.second }

    let_it_be(:increments) do
      increments_hash = {}

      increments_hash[first_attribute] = 1
      increments_hash[second_attribute] = 2

      increments_hash
    end

    subject { model.update_counters_with_lease(increments) }

    it 'updates counters of the record' do
      expect { subject }
        .to change { model.reload.send(first_attribute) }.by(1)
        .and change { model.reload.send(second_attribute) }.by(2)
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
end
