# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/general.html.haml' do
  let(:app_settings) { build(:application_setting) }
  let(:user) { create(:admin) }

  describe 'sourcegraph integration' do
    let(:sourcegraph_flag) { true }

    before do
      assign(:application_setting, app_settings)
      allow(Gitlab::Sourcegraph).to receive(:feature_available?).and_return(sourcegraph_flag)
      allow(view).to receive(:current_user).and_return(user)
    end

    context 'when sourcegraph feature is enabled' do
      it 'show the form' do
        render

        expect(rendered).to have_field('application_setting_sourcegraph_enabled')
      end
    end

    context 'when sourcegraph feature is disabled' do
      let(:sourcegraph_flag) { false }

      it 'show the form' do
        render

        expect(rendered).not_to have_field('application_setting_sourcegraph_enabled')
      end
    end
  end

  describe 'prompt user about registration features' do
    before do
      assign(:application_setting, app_settings)
      allow(view).to receive(:current_user).and_return(user)
    end

    context 'when service ping is enabled' do
      before do
        stub_application_setting(usage_ping_enabled: true)
      end

      it_behaves_like 'does not render registration features prompt', :application_setting_disabled_repository_size_limit
    end

    context 'with no license and service ping disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)

        if Gitlab.ee?
          allow(License).to receive(:current).and_return(nil)
        end
      end

      it_behaves_like 'renders registration features prompt', :application_setting_disabled_repository_size_limit
    end
  end
end
