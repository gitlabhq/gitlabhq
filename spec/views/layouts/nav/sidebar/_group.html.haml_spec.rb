# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_group' do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) do
    create(:group).tap do |g|
      g.add_owner(owner)
    end
  end

  before do
    assign(:group, group)

    allow(view).to receive(:current_user).and_return(owner)
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

  describe 'Issues' do
    it 'has a default link to the issue list path' do
      render

      expect(rendered).to have_link('Issues', href: issues_group_path(group))
    end

    it 'has a link to the issue list page' do
      render

      expect(rendered).to have_link('List', href: issues_group_path(group))
    end

    it 'has a link to the boards page' do
      render

      expect(rendered).to have_link('Board', href: group_boards_path(group))
    end

    it 'has a link to the milestones page' do
      render

      expect(rendered).to have_link('Milestones', href: group_milestones_path(group))
    end
  end

  describe 'Merge Requests' do
    it 'has a link to the merge request list path' do
      render

      expect(rendered).to have_link('Merge requests', href: merge_requests_group_path(group))
    end

    it 'shows pill with the number of merge requests' do
      render

      expect(rendered).to have_css('span.badge.badge-pill.merge_counter.js-merge-counter')
    end
  end

  describe 'CI/CD' do
    it 'has a default link to the runners list path' do
      render

      expect(rendered).to have_link('CI/CD', href: group_runners_path(group))
    end

    it 'has a link to the runners list page' do
      render

      expect(rendered).to have_link('Runners', href: group_runners_path(group))
    end
  end
end
