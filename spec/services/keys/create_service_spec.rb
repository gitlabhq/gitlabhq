# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::CreateService, feature_category: :source_code_management do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
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

  describe 'organization_id handling' do
    it 'sets organization_id from user when not provided' do
      key = subject.execute

      expect(key).to be_persisted
      expect(key.organization_id).to eq(user.organization_id)
    end

    it 'uses explicitly provided organization_id' do
      other_organization = create(:organization)
      service = described_class.new(user, params.merge(organization: other_organization))

      key = service.execute

      expect(key).to be_persisted
      expect(key.organization_id).to eq(other_organization.id)
    end
  end
end
