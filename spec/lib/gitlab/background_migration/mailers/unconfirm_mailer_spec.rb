# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::Mailers::UnconfirmMailer do
  let(:user) { User.new(id: 1111) }
  let(:subject) { described_class.unconfirm_notification_email(user) }

  it 'contains abuse report url' do
    expect(subject.body.encoded).to include(Rails.application.routes.url_helpers.new_abuse_report_url(user_id: user.id))
  end
end
