# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_account_and_limit.html.haml', feature_category: :settings do
  let(:app_settings) { build(:application_setting) }
  let(:user) { build_stubbed(:admin) }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'session expire from init' do
    context 'when session_expire_from_init is enabled' do
      before do
        stub_feature_flags(session_expire_from_init: true)
      end

      it 'has the setting section' do
        render

        expect(rendered).to have_content('Session settings')
        expect(rendered).to have_field('Expire from time of session creation',
          type: 'radio')
      end
    end

    context 'when session_expire_from_init is disabled' do
      before do
        stub_feature_flags(session_expire_from_init: false)
      end

      it 'does not have the setting section' do
        render

        expect(rendered).not_to have_content('Session settings')
      end
    end
  end
end
