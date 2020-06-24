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

  describe 'Maintenance mode' do
    let(:maintenance_mode_flag) { true }

    before do
      assign(:application_setting, app_settings)
      stub_feature_flags(maintenance_mode: maintenance_mode_flag)
      allow(view).to receive(:current_user).and_return(user)
    end

    context 'when maintenance_mode feature is enabled' do
      it 'show the Maintenance mode section' do
        render

        expect(rendered).to have_css('#js-maintenance-mode-toggle')
      end
    end

    context 'when maintenance_mode feature is disabled' do
      let(:maintenance_mode_flag) { false }

      it 'hide the Maintenance mode section' do
        render

        expect(rendered).not_to have_css('#js-maintenance-mode-toggle')
      end
    end
  end
end
