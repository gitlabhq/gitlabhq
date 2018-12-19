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

    # actionmailer wasn't actually upgraded from 4.2.10 to 4.2.11 in
    # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/23520.
    #
    # Attempting to run this spec in Rails 4 will fail until
    # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/23396
    # is merged. Let's disable it since we are only using Rails 5 on
    # this branch.
    context 'when the arguments cannot be deserialized', :rails5 do
      it 'does nothing' do
        expect(worker.notification_service).not_to receive(method)

        worker.perform(method, key.to_global_id.to_s.succ)
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
