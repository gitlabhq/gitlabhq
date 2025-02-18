# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Instance::EmailsOnPush, feature_category: :integrations do
  it_behaves_like Integrations::Base::EmailsOnPush do
    let_it_be(:project) { nil }
  end

  subject(:integration) { described_class.create!(active: true, recipients: 'example@gitlab.com') }

  describe '#execute' do
    it 'does not send the email' do
      expect(EmailsOnPushWorker).not_to receive(:perform_async)

      integration.execute({})
    end
  end
end
