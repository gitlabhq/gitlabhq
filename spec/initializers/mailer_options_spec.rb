# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mailer retries', :sidekiq_mailers, feature_category: :shared do
  subject(:mail) { DeviseMailer.user_admin_approval(create(:user)).deliver_later }

  it 'sets retries for mailers to 3' do
    mail

    expect(Sidekiq::Queues['mailers'].first).to include('retry' => 3)
  end

  it 'sets data consistency for mailers to :delayed' do
    mail

    expect(Sidekiq::Queues['mailers'].first).to include('worker_data_consistency' => 'delayed')
    expect(ActionMailer::MailDeliveryJob.get_data_consistency_per_database.values.uniq).to eq([:delayed])
  end

  it 'sets store for mailers to ActionMailer::MailDeliveryJob routing target' do
    mail

    # The store name depends on config/gitlab.yml's sidekiq.routingRules. This is set in the
    # initializers which makes it unwieldy to stub.
    store_name = Gitlab::SidekiqConfig::WorkerRouter.global.store(
      Gitlab::SidekiqConfig::DEFAULT_WORKERS['ActionMailer::MailDeliveryJob'].klass
    )

    expect(ActionMailer::MailDeliveryJob.sidekiq_options['store']).to eq(store_name)
  end

  it 'sets store for mailers to ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper routing target' do
    mail

    # The store name depends on config/gitlab.yml's sidekiq.routingRules. This is set in the
    # initializers which makes it unwieldy to stub.
    store_name = Gitlab::SidekiqConfig::WorkerRouter.global.store(
      Gitlab::SidekiqConfig::DEFAULT_WORKERS['ActionMailer::MailDeliveryJob'].klass
    )

    expect(ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper.sidekiq_options['store']).to eq(store_name)
  end
end
