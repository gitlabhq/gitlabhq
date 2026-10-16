# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/_home_panel', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }

  context 'admin area link' do
    before do
      assign(:group, group)
    end

    it 'renders admin area link for admin' do
      allow(view).to receive(:current_user).and_return(create(:admin))

      render

      expect(rendered).to have_link(href: admin_group_path(group))
    end

    it 'does not render admin area link for non-admin' do
      allow(view).to receive(:current_user).and_return(user)

      render

      expect(rendered).not_to have_link(href: admin_group_path(group))
    end

    it 'does not render admin area link for anonymous' do
      allow(view).to receive(:current_user).and_return(nil)

      render

      expect(rendered).not_to have_link(href: admin_group_path(group))
    end
  end

  context 'when group is in default organization' do
    let_it_be(:default_organization) { create(:organization, :default, owners: user) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- required for testing default organization functionality
    let_it_be(:group_in_default_org) { create(:group, organization: default_organization, owners: user) }

    before do
      allow(view).to receive(:current_user).and_return(user)
      assign(:group, group_in_default_org)
      render
    end

    it 'renders Create subgroup link with unscoped URL' do
      expect(rendered).to have_link('Create subgroup',
        href: "/groups/new?parent_id=#{group_in_default_org.id}#create-group-pane")
    end

    it 'renders Create project link with unscoped URL' do
      expect(rendered).to have_link('Create project', href: "/projects/new?namespace_id=#{group_in_default_org.id}")
    end
  end

  context 'when group is in common organization' do
    before do
      allow(view).to receive(:current_user).and_return(user)
      assign(:group, group)
      render
    end

    it 'renders Create subgroup link with org-scoped URL' do
      expect(rendered).to have_link('Create subgroup',
        href: "/o/#{group.organization.path}/groups/new?parent_id=#{group.id}#create-group-pane")
    end

    it 'renders Create project link with org-scoped URL' do
      expect(rendered).to have_link('Create project',
        href: "/o/#{group.organization.path}/projects/new?namespace_id=#{group.id}")
    end
  end
end
