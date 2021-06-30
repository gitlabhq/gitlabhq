# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mailer retries', :sidekiq_mailers do
  it 'sets retries for mailers to 3' do
    DeviseMailer.user_admin_approval(create(:user)).deliver_later

    expect(Sidekiq::Queues['mailers'].first).to include('retry' => 3)
  end
end
