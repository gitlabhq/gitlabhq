# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/_more_actions_dropdown', feature_category: :groups_and_projects do
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:group, group)
    allow(view).to receive(:group_more_action_data).and_return({})
  end

  context 'when user is logged in' do
    before do
      allow(view).to receive(:current_user).and_return(user)

      render
    end

    it 'renders the group ID in a screen reader only element' do
      expect(rendered).to have_selector('span.gl-sr-only[itemprop="identifier"]', text: "Group ID: #{group.id}")
      expect(rendered).to have_selector('[data-testid="group-id-content"]')
    end

    it 'renders action dropdown' do
      expect(rendered).to have_selector('#js-group-more-actions-dropdown')
    end
  end

  context 'when current_user is nil' do
    before do
      allow(view).to receive(:current_user).and_return(nil)

      render
    end

    it 'does not render action dropdown' do
      expect(rendered).not_to have_selector('#js-group-more-actions-dropdown')
    end
  end
end
