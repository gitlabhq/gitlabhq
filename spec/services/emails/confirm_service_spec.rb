# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::ConfirmService, feature_category: :user_management do
  let_it_be(:user) { create(:user) }

  subject(:service) { described_class.new(user) }

  describe '#execute' do
    it 'enqueues a background job to send confirmation email again' do
      email = user.emails.create!(email: 'new@email.com')

      travel_to(10.minutes.from_now) do
        expect { service.execute(email) }.to have_enqueued_job.on_queue('mailers')
      end
    end
  end
end
