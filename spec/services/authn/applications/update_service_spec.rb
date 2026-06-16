# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Authn::Applications::UpdateService, feature_category: :system_access do
  include TestRequestHelpers

  let(:user) { create(:user) }
  let(:application) { create(:oauth_application, owner: user) }

  subject(:service) { described_class.new(user, test_request, application, params) }

  context 'with valid params and immutable attributes' do
    let(:params) { { 'name' => 'Updated App', 'redirect_uri' => 'https://attacker.com', 'confidential' => true } }

    before do
      application.update!(confidential: false)
    end

    it 'updates mutable attributes and filters out immutable attributes' do
      expect { service.execute }
        .to change { application.reload.name }.to('Updated App')
        .and not_change { application.reload.redirect_uri }
        .and not_change { application.reload.confidential }
    end

    it 'returns the updated application' do
      expect(service.execute).to eq(application)
      expect(application.errors).to be_empty
    end
  end

  context 'when user is not authorized' do
    let(:other_user) { create(:user) }
    let(:params) { { name: 'Updated App' } }

    subject(:service) { described_class.new(other_user, test_request, application, params) }

    it 'does not update the application' do
      expect { service.execute }.not_to change { application.reload.name }
    end

    it 'returns the application with authorization errors' do
      result = service.execute

      expect(result.errors.full_messages).to include('Not authorized')
    end
  end
end
