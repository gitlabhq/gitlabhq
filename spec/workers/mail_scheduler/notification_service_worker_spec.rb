# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailScheduler::NotificationServiceWorker, feature_category: :team_planning do
  let(:worker) { described_class.new }
  let(:method) { 'new_key' }

  let_it_be(:key) { create(:personal_key) }

  def serialize(*args)
    ActiveJob::Arguments.serialize(args)
  end

  def deserialize(args)
    ActiveJob::Arguments.deserialize(args)
  end

  describe '#perform' do
    it 'deserializes arguments from global IDs' do
      expect(worker.notification_service).to receive(method).with(key)

      worker.perform(method, *serialize(key))
    end

    context 'when the arguments cannot be deserialized' do
      context 'when the arguments are not deserializeable' do
        it 'raises exception' do
          expect(worker.notification_service).not_to receive(method)
          expect { worker.perform(method, key.to_global_id.to_s.succ) }.to raise_exception(ArgumentError)
        end
      end

      context 'when the arguments are deserializeable' do
        it 'does nothing' do
          serialized_arguments = *serialize(key)
          key.destroy!

          expect(worker.notification_service).not_to receive(method)
          expect { worker.perform(method, serialized_arguments) }.not_to raise_exception
        end
      end
    end

    context 'when the method is allowed' do
      it 'calls the method on NotificationService' do
        NotificationService.permitted_actions.each do |action|
          expect(worker.notification_service).to receive(action).with(key)

          worker.perform(action, *serialize(key))
        end
      end
    end

    context 'when the method is not allowed' do
      it 'raises ArgumentError' do
        expect(worker.notification_service).not_to receive(:async)
        expect(worker.notification_service).not_to receive(:foo)

        expect { worker.perform('async', *serialize(key)) }
          .to raise_error(ArgumentError, 'async not allowed for MailScheduler::NotificationServiceWorker')

        expect { worker.perform('foo', *serialize(key)) }
          .to raise_error(ArgumentError, 'foo not allowed for MailScheduler::NotificationServiceWorker')
      end
    end
  end

  describe '.perform_async' do
    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    it 'serializes arguments as global IDs when scheduling' do
      described_class.perform_async(method, key)

      expect(described_class.jobs.count).to eq(1)
      expect(described_class.jobs.first).to include('args' => [method, *serialize(key)])
    end

    context 'with ActiveController::Parameters' do
      let(:parameters) { ActionController::Parameters.new(hash) }

      let(:hash) do
        {
          "nested" => {
            "hash" => true
          }
        }
      end

      context 'when permitted' do
        before do
          parameters.permit!
        end

        it 'serializes as a serializable Hash' do
          described_class.perform_async(method, parameters)

          expect(described_class.jobs.count).to eq(1)
          expect(deserialize(described_class.jobs.first['args']))
            .to eq([method, hash])
        end
      end

      context 'when not permitted' do
        it 'fails to serialize' do
          expect { described_class.perform_async(method, parameters) }
            .to raise_error(ActionController::UnfilteredParameters)
        end
      end
    end
  end
end
