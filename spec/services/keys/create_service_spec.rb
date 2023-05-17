# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::CreateService, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:params) { attributes_for(:key) }

  subject { described_class.new(user, params) }

  context 'notification', :mailer do
    it 'sends a notification' do
      perform_enqueued_jobs do
        subject.execute
      end
      should_email(user)
    end
  end

  it 'creates a key' do
    expect { subject.execute }.to change { user.keys.where(params).count }.by(1)
  end
end
