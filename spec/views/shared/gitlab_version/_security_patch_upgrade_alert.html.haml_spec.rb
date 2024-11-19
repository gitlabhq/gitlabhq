# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/gitlab_version/_security_patch_upgrade_alert' do
  let_it_be(:user) { build_stubbed(:user) }
  let(:version_check_response) { { 'critical_vulnerability' => 'true' } }

  before do
    stub_application_setting(version_check_enabled: true)

    allow_next_instance_of(VersionCheck) do |service|
      allow(service).to receive(:response).and_return(version_check_response)
    end
  end

  describe 'when version check is enabled and is admin' do
    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(user).to receive(:can_admin_all_resources?).and_return(true)

      render
    end

    it 'renders the security patch upgrade alert modal' do
      expect(rendered).to have_selector('#js-security-patch-upgrade-alert-modal')
    end
  end
end
