# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_organization_url_routes'

RSpec.describe RuboCop::Cop::Gitlab::AvoidOrganizationUrlRoutes, feature_category: :organization do
  describe 'bad examples' do
    it 'registers an offense for organization_root_path' do
      expect_offense(<<~RUBY)
        organization_root_path(self)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid direct use of organization-scoped [...]
      RUBY
    end

    it 'registers an offense for organization_root_url' do
      expect_offense(<<~RUBY)
        organization_root_url(path, **options)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid direct use of organization-scoped [...]
      RUBY
    end

    it 'registers an offense for organization_projects_path' do
      expect_offense(<<~RUBY)
        organization_projects_path(namespace, organization_path: org.path)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid direct use of organization-scoped [...]
      RUBY
    end

    it 'registers an offense for organization_project_issues_path' do
      expect_offense(<<~RUBY)
        organization_project_issues_path(project, organization_path: org.path)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid direct use of organization-scoped [...]
      RUBY
    end

    it 'registers an offense for organization_projects_url' do
      expect_offense(<<~RUBY)
        organization_projects_url(namespace)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid direct use of organization-scoped [...]
      RUBY
    end

    it 'registers an offense for safe navigation calls' do
      expect_offense(<<~RUBY)
        helper&.organization_root_path(org)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid direct use of organization-scoped [...]
      RUBY
    end
  end

  describe 'good examples' do
    it 'does not register an offense for organization_path' do
      expect_no_offenses('organization_path(organization)')
    end

    it 'does not register an offense for organization_url' do
      expect_no_offenses('organization_url(organization)')
    end

    it 'does not register an offense for organizations_path' do
      expect_no_offenses('organizations_path')
    end

    it 'does not register an offense for new_organization_path' do
      expect_no_offenses('new_organization_path')
    end

    it 'does not register an offense for standard route helpers' do
      expect_no_offenses('projects_path(namespace)')
    end

    it 'does not register an offense for organization management routes' do
      expect_no_offenses('activity_organization_path(organization)')
    end
  end
end
