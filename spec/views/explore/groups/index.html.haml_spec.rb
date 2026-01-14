# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'explore/groups/index.html.haml', feature_category: :groups_and_projects do
  let_it_be(:user) { build_stubbed(:user) }

  context 'when explore_groups_vue feature flag is enabled' do
    before do
      assign(:explore_groups_vue_enabled, true)
      render
    end

    it 'renders the Vue app' do
      expect(rendered).to have_selector('#js-explore-groups')
    end

    it 'does not render the legacy partials' do
      expect(rendered).not_to render_template('explore/groups/_groups')
    end
  end

  context 'when explore_groups_vue feature flag is disabled' do
    let_it_be(:groups) { [build_stubbed(:group, :public)] }

    before do
      assign(:explore_groups_vue_enabled, false)
      assign(:groups, groups)
      render
    end

    it 'does not render the Vue app' do
      expect(rendered).not_to have_selector('#js-explore-groups')
    end

    it 'renders the legacy partials' do
      expect(rendered).to render_template('explore/groups/_groups')
    end
  end
end
