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

  describe 'Kubernetes menu', :request_store do
    it 'has a link to the group cluster list path' do
      render

      expect(rendered).to have_link('Kubernetes', href: group_clusters_path(group))
    end
  end

  describe 'Packages and registries' do
    it 'has a link to the package registry page' do
      stub_config(packages: { enabled: true })

      render

      expect(rendered).to have_link('Package Registry', href: group_packages_path(group))
    end

    it 'has a link to the container registry page' do
      stub_container_registry_config(enabled: true)

      render

      expect(rendered).to have_link('Container Registry', href: group_container_registries_path(group))
    end

    it 'has a link to the dependency proxy page' do
      stub_config(dependency_proxy: { enabled: true })

      render

      expect(rendered).to have_link('Dependency Proxy', href: group_dependency_proxy_path(group))
    end
  end

  describe 'Settings' do
    it 'default link points to edit group page' do
      render

      expect(rendered).to have_link('Settings', href: edit_group_path(group))
    end

    it 'has a link to the General settings page' do
      render

      expect(rendered).to have_link('General', href: edit_group_path(group))
    end

    it 'has a link to the Integrations settings page' do
      render

      expect(rendered).to have_link('Integrations', href: group_settings_integrations_path(group))
    end

    it 'has a link to the group Projects settings page' do
      render

      expect(rendered).to have_link('Projects', href: projects_group_path(group))
    end

    it 'has a link to the Repository settings page' do
      render

      expect(rendered).to have_link('Repository', href: group_settings_repository_path(group))
    end

    it 'has a link to the CI/CD settings page' do
      render

      expect(rendered).to have_link('CI/CD', href: group_settings_ci_cd_path(group))
    end

    it 'has a link to the Applications settings page' do
      render

      expect(rendered).to have_link('Applications', href: group_settings_applications_path(group))
    end

    it 'has a link to the Package and registry settings page' do
      render

      expect(rendered).to have_link('Packages and registries', href: group_settings_packages_and_registries_path(group))
    end
  end
end
