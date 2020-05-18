# frozen_string_literal: true

require 'spec_helper'

describe Emails::ConfirmService do
  let(:user) { create(:user) }

  subject(:service) { described_class.new(user) }

  describe '#execute' do
    it 'enqueues a background job to send confirmation email again' do
      email = user.emails.create(email: 'new@email.com')

      expect { service.execute(email) }.to have_enqueued_job.on_queue('mailers')
    end
  end
end
