# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_group' do
  let_it_be(:group) { create(:group) }

  before do
    assign(:group, group)
  end

  it_behaves_like 'has nav sidebar'
  it_behaves_like 'sidebar includes snowplow attributes', 'render', 'groups_side_navigation', 'groups_side_navigation'

  describe 'Group context menu' do
    it 'has a link to the group path' do
      render

      expect(rendered).to have_link(group.name, href: group_path(group))
    end
  end

  describe 'Group information' do
    it 'has a link to the group activity path' do
      render

      expect(rendered).to have_link('Group information', href: activity_group_path(group))
    end

    it 'has a link to the group labels path' do
      render

      expect(rendered).to have_link('Labels', href: group_labels_path(group))
    end

    it 'has a link to the members page' do
      render

      expect(rendered).to have_link('Members', href: group_group_members_path(group))
    end
  end
end
