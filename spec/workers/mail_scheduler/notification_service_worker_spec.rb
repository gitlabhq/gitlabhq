require 'spec_helper'

describe MailScheduler::NotificationServiceWorker do
  let(:worker) { described_class.new }
  let(:method) { 'new_key' }
  set(:key) { create(:personal_key) }

  def serialize(*args)
    ActiveJob::Arguments.serialize(args)
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

    context 'when the method is not a public method' do
      it 'raises NoMethodError' do
        expect { worker.perform('notifiable?', *serialize(key)) }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.perform_async' do
    it 'serializes arguments as global IDs when scheduling' do
      Sidekiq::Testing.fake! do
        described_class.perform_async(method, key)

        expect(described_class.jobs.count).to eq(1)
        expect(described_class.jobs.first).to include('args' => [method, *serialize(key)])
      end
    end
  end
end
