# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_deletion_protection_settings', feature_category: :system_access do
  let_it_be(:application_setting) do
    build(
      :application_setting,
      deletion_adjourned_period: 1
    )
  end

  before do
    assign(:application_setting, application_setting)
  end

  context 'when feature flag is enabled' do
    before do
      stub_feature_flags(downtier_delayed_deletion: true)
    end

    it 'renders the deletion protection settings app root' do
      render

      expect(rendered).to have_selector('#js-admin-deletion-protection-settings')
    end
  end
end
