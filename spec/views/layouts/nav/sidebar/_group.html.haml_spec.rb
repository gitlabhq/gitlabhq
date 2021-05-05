# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_group' do
  let_it_be(:group) { create(:group) }

  before do
    assign(:group, group)
  end

  it_behaves_like 'has nav sidebar'
  it_behaves_like 'sidebar includes snowplow attributes', 'render', 'groups_side_navigation', 'groups_side_navigation'

  describe 'Group information' do
    it 'has a link to the group path' do
      render

      expect(rendered).to have_link('Group information', href: group_path(group))
    end

    it 'does not have a link to the details menu item' do
      render

      expect(rendered).not_to have_link('Details', href: details_group_path(group))
    end

    context 'when feature flag :sidebar_refactor is disabled' do
      before do
        stub_feature_flags(sidebar_refactor: false)
      end

      it 'has a link to the group path with the "Group overview" title' do
        render

        expect(rendered).to have_link('Group overview', href: group_path(group))
      end

      it 'has a link to the details menu item' do
        render

        expect(rendered).to have_link('Details', href: details_group_path(group))
      end
    end
  end
end
