# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/network.html.haml', feature_category: :projects do
  let_it_be(:admin) { build_stubbed(:admin) }
  let_it_be(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
  end

  context 'for Projects API rate limit' do
    it 'renders the `projects_api_rate_limit_unauthenticated` field' do
      render

      expect(rendered).to have_field('application_setting_projects_api_rate_limit_unauthenticated')
    end
  end
end
