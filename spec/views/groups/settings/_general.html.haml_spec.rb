# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_general.html.haml', feature_category: :groups_and_projects do
  describe 'Group Settings README' do
    let_it_be(:group) { build_stubbed(:group) }
    let_it_be(:user) { build_stubbed(:admin) }

    before do
      assign(:group, group)
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'renders #js-group-settings-readme' do
      render

      expect(rendered).to have_selector('#js-group-settings-readme')
    end
  end
end
