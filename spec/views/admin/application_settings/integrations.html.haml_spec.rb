# frozen_string_literal: true

require 'spec_helper'

describe 'admin/application_settings/integrations.html.haml' do
  let(:app_settings) { build(:application_setting) }

  describe 'sourcegraph integration' do
    let(:sourcegraph_flag) { true }

    before do
      assign(:application_setting, app_settings)
      allow(Gitlab::Sourcegraph).to receive(:feature_available?).and_return(sourcegraph_flag)
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
end
