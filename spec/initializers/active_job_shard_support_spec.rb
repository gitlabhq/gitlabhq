# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActionMailer::MailDeliveryJob', :sidekiq_mailers, feature_category: :scalability do
  let(:mailer_class) do
    Class.new(ApplicationMailer) do
      def self.name
        'Notify'
      end

      def test_mail; end
    end
  end

  before do
    # The client middleware is invoked in a Sidekiq::Client.push, where
    # ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper is passed into the Router.
    allow(Gitlab::SidekiqSharding::Router).to receive(:get_shard_instance).with(nil).and_call_original
  end

  context 'when routing is not enabled' do
    before do
      allow(Gitlab::SidekiqSharding::Router).to receive(:enabled?).and_return(false)
    end

    it 'does not check for shard instance' do
      expect(Gitlab::SidekiqSharding::Router)
        .to receive(:route).with(ActionMailer::MailDeliveryJob).and_call_original
      expect(Sidekiq::Client).not_to receive(:via)

      mailer_job_args = [ActionMailer::MailDeliveryJob.new(mailer_class.name, "", "deliver_now", [])]
      ActiveJob::QueueAdapters::SidekiqAdapter.new.enqueue_all(mailer_job_args)
    end
  end

  context 'when routing is enabled' do
    before do
      allow(Gitlab::SidekiqSharding::Router).to receive(:enabled?).and_return(true)
    end

    it 'checks for shard instance and sets Sidekiq redis pool' do
      expect(Gitlab::SidekiqSharding::Router)
        .to receive(:route).with(ActionMailer::MailDeliveryJob).ordered.and_call_original
      expect(Sidekiq::Client).to receive(:via).ordered.and_call_original

      mailer_job_args = [ActionMailer::MailDeliveryJob.new(mailer_class.name, "", "deliver_now", [])]
      ActiveJob::QueueAdapters::SidekiqAdapter.new.enqueue_all(mailer_job_args)
    end
  end
end
