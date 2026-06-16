# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Authn::Applications::DestroyService, feature_category: :system_access do
  include TestRequestHelpers

  let(:user) { create(:user) }
  let(:application) { create(:oauth_application, owner: user) }

  subject(:service) { described_class.new(user, test_request, application) }

  context 'when user is the owner' do
    it 'destroys the application' do
      application # Force eager evaluation
      expect { service.execute }.to change { Authn::OauthApplication.count }.by(-1)
    end

    it 'returns the destroyed application' do
      expect(service.execute).to eq(application)
      expect(application.errors).to be_empty
    end
  end

  context 'when user is not authorized' do
    let(:other_user) { create(:user) }

    subject(:service) { described_class.new(other_user, test_request, application) }

    it 'does not destroy the application' do
      application # Force eager evaluation
      expect { service.execute }.not_to change { Authn::OauthApplication.count }
    end

    it 'returns the application with authorization errors' do
      result = service.execute

      expect(result.errors.full_messages).to include('Not authorized')
    end
  end
end
