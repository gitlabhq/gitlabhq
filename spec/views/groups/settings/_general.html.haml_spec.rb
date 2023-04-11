# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_general.html.haml', feature_category: :subgroups do
  describe 'Group Settings README' do
    let_it_be(:group) { build_stubbed(:group) }
    let_it_be(:user) { build_stubbed(:admin) }

    before do
      assign(:group, group)
      allow(view).to receive(:current_user).and_return(user)
    end

    describe 'with :show_group_readme FF true' do
      before do
        stub_feature_flags(show_group_readme: true)
      end

      it 'renders #js-group-settings-readme' do
        render

        expect(rendered).to have_selector('#js-group-settings-readme')
      end
    end

    describe 'with :show_group_readme FF false' do
      before do
        stub_feature_flags(show_group_readme: false)
      end

      it 'does not render #js-group-settings-readme' do
        render

        expect(rendered).not_to have_selector('#js-group-settings-readme')
      end
    end
  end
end
