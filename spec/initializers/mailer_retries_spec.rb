# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mailer retries' do
  # We need to ensure that this runs through Sidekiq to take
  # advantage of the middleware. There is a Rails bug that means we
  # have to do some extra steps to make this happen:
  # https://github.com/rails/rails/issues/37270#issuecomment-553927324
  around do |example|
    descendants = ActiveJob::Base.descendants + [ActiveJob::Base]
    descendants.each(&:disable_test_adapter)
    ActiveJob::Base.queue_adapter = :sidekiq

    example.run

    descendants.each { |a| a.queue_adapter = :test }
  end

  it 'sets retries for mailers to 3' do
    DeviseMailer.user_admin_approval(create(:user)).deliver_later

    expect(Sidekiq::Queues['mailers'].first).to include('retry' => 3)
  end
end
