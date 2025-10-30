# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UserMapping::AdminBypassAuthorizer, feature_category: :importers do
  subject(:authorizer) { described_class.new(reassigning_user) }

  describe '#allowed?' do
    let_it_be(:reassigning_user) { create(:user, :admin) }

    before do
      stub_application_setting(allow_bypass_placeholder_confirmation: true)
      stub_config_setting(impersonation_enabled: true)
    end

    it 'returns true for admins with bypass application setting and impersonation enabled', :enable_admin_mode do
      expect(authorizer).to be_allowed
    end

    context 'when the allow_bypass_placeholder_confirmation application setting is disabled', :enable_admin_mode do
      before do
        stub_application_setting(allow_bypass_placeholder_confirmation: false)
      end

      it { is_expected.not_to be_allowed }
    end

    context 'when admin mode is disabled for the admin user' do
      it { is_expected.not_to be_allowed }
    end

    context 'when the reassigning user is not an admin', :enable_admin_mode do
      let!(:reassigning_user) { create(:user) }

      it { is_expected.not_to be_allowed }
    end

    context 'when the reassigning user is nil', :enable_admin_mode do
      let!(:reassigning_user) { nil }

      it { is_expected.not_to be_allowed }
    end

    context 'when user impersonation is disabled', :enable_admin_mode do
      before do
        stub_config_setting(impersonation_enabled: false)
      end

      it { is_expected.not_to be_allowed }
    end
  end
end
