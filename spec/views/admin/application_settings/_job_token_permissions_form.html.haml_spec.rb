# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/ci_cd.html.haml', feature_category: :shared do
  let(:app_settings) { build(:application_setting) }
  let(:user) { build_stubbed(:admin) }
  let(:default_plan_limits) { build_stubbed(:plan_limits, :default_plan, :with_package_file_sizes) }

  before do
    assign(:application_setting, app_settings)
    assign(:plans, [default_plan_limits.plan])
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'Job token permission settings' do
    context 'when allowlist is not enforced' do
      before do
        stub_application_setting(enforce_ci_inbound_job_token_scope_enabled: false)
      end

      it 'renders enforce allowlist checkbox' do
        render

        expect(rendered).to have_css('input[id=application_setting_enforce_ci_inbound_job_token_scope_enabled]')
      end
    end

    context 'when allowlist is enforced' do
      before do
        stub_application_setting(enforce_ci_inbound_job_token_scope_enabled: true)
      end

      it 'renders enforce allowlist checkbox' do
        render

        expect(rendered).to have_css(
          'input[id=application_setting_enforce_ci_inbound_job_token_scope_enabled][checked="checked"]'
        )
      end
    end
  end
end
