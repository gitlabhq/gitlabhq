# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Applications::CreateService, feature_category: :system_access do
  include TestRequestHelpers

  let(:user) { create(:user) }

  subject(:service) { described_class.new(user, test_request, params) }

  context 'when scopes are present' do
    let(:params) { attributes_for(:application, scopes: ['read_user']) }

    it { expect { subject.execute }.to change { Authn::OauthApplication.count }.by(1) }

    it 'leaves ROPC enabled' do
      expect(service.execute.ropc_enabled?).to be_truthy
    end
  end

  context 'when scopes are missing' do
    let(:params) { attributes_for(:application) }

    it { expect { subject.execute }.not_to change { Authn::OauthApplication.count } }

    it 'includes blank scopes error message' do
      application = subject.execute

      expect(application.errors.full_messages).to include "Scopes can't be blank"
    end
  end

  describe '.disable_ropc_for_all_applications?' do
    it 'returns false by default' do
      expect(described_class).not_to be_disable_ropc_for_all_applications
    end
  end
end
