# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Authorizations::NotificationService, feature_category: :integrations do
  include TestRequestHelpers

  let(:user) { create(:user) }

  subject { described_class.new(user) }

  it 'receive notification' do
    notification_service = instance_double(NotificationService)
    allow(NotificationService).to receive(:new).and_return(notification_service)

    expect(notification_service).to receive(:application_authorized).with(user)
    subject.execute
  end
end
