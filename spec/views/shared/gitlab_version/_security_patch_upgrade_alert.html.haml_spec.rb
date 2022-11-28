# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/gitlab_version/_security_patch_upgrade_alert' do
  describe 'when show_security_patch_upgrade_alert? is true' do
    before do
      allow(view).to receive(:show_security_patch_upgrade_alert?).and_return(true)
      render
    end

    it 'renders the security patch upgrade alert' do
      expect(rendered).to have_selector('#js-security-patch-upgrade-alert')
    end
  end
end
